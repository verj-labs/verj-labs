using System;
using System.Collections.Generic;

namespace Undermound.Core;

/// <summary>
/// The whole simulation: the world, the ants, the brood, the queen, food, seasons, weather,
/// water and the spider. Plain C# with no engine types, stepped at a fixed tick.
/// Split across files: Sim.Weather, Sim.Water, Sim.Colony, Sim.Ants, Sim.Threats.
/// </summary>
public sealed partial class Sim
{
    public readonly World World;
    public readonly List<Ant> Ants = new();
    public readonly List<Brood> Brood = new();
    public readonly List<Spider> Spiders = new();
    public readonly List<(float Time, string Text)> Log = new();
    public readonly Priorities Priorities = new();

    public readonly FlowField ToSurface;
    public readonly FlowField ToDig;
    public readonly FlowField ToStore;
    public readonly FlowField ToNursery;

    public float Time { get; private set; }
    public float Food;
    public int QueenCell;
    public bool QueenAlive = true;
    /// <summary>Set when the colony is lost; the simulation stops.</summary>
    public string? GameOver { get; private set; }
    /// <summary>Set when a new spring begins; the HUD shows it and clears it.</summary>
    public YearReport? Report;
    /// <summary>Length of one season. Shorter in tests and scripted scenes.</summary>
    public float SeasonLength = SimConfig.SeasonSeconds;

    // Stats, for the year report and the HUD
    public int Hatched, WorkersDied, BroodDrowned, CellsDug, FoodGathered, QueensFlown, PeakColony, SpidersDrivenOff;

    private readonly Rng _rng;
    private int _nextAntId;
    private int _fieldLayout = -1, _fieldOrders = -1;
    private Season _lastSeason;
    private int _lastYear = 1;
    private YearReport _yearStart = new();

    private static readonly int[] Dx = { 0, 0, -1, 1 };
    private static readonly int[] Dy = { -1, 1, 0, 0 };

    public Sim(World world, int seed)
    {
        World = world;
        _rng = new Rng((ulong)seed * 6364136223846793005UL + 1442695040888963407UL);
        ToSurface = new FlowField(world);
        ToDig = new FlowField(world);
        ToStore = new FlowField(world);
        ToNursery = new FlowField(world);
        NextRainIn = SimConfig.RainMinGapSeconds;
        _foodSpawnTimer = SimConfig.FoodSpawnMinSeconds;
        _spiderTimer = SimConfig.SpiderFirstSeconds;
    }

    /// <summary>A new colony with a starter nest: an entrance shaft, a nursery and a food store.</summary>
    public static Sim CreateDefault(int seed)
    {
        var w = new World(SimConfig.Width, SimConfig.Height);
        w.Generate(seed);
        int ex = SimConfig.Width / 2;
        w.Carve(ex, 1, ex, 10);
        w.Carve(ex - 5, 11, ex + 4, 13, Room.Nursery);
        // A small sump below the nursery floor catches the first rain.
        w.Carve(ex, 14, ex, 16);
        w.Carve(ex - 2, 17, ex + 2, 18);
        w.Carve(ex + 1, 6, ex + 6, 6);
        w.Carve(ex + 7, 5, ex + 11, 7, Room.Store);
        var sim = new Sim(w, seed) { Food = SimConfig.StartFood };
        for (int i = 0; i < SimConfig.StartWorkers; i++)
            sim.SpawnAnt(w.Index(ex - 4 + i % 8, 13));
        w.Food.Add(new FoodSource { X = ex - 25, Amount = 40, Max = 40, Kind = FoodKind.Berry });
        w.Food.Add(new FoodSource { X = ex + 32, Amount = 30, Max = 30, Kind = FoodKind.Crumb });
        w.Food.Add(new FoodSource { X = ex - 55, Amount = 35, Max = 35, Kind = FoodKind.Seeds });
        sim.RefreshFields();
        sim.PeakColony = sim.Ants.Count;
        return sim;
    }

    // ---------- queries for the view and the HUD ----------

    public float Day => Time / SimConfig.DaySeconds;
    public float YearLength => SeasonLength * 4;
    public int Year => (int)(Time / YearLength) + 1;
    public Season Season => (Season)((int)(Time / SeasonLength) % 4);
    public float SeasonProgress => Time % SeasonLength / SeasonLength;
    public float FoodCapacity =>
        SimConfig.BaseFoodCapacity + World.CountRoomCells(Room.Store) * SimConfig.FoodPerStoreCell;
    public int Eggs => CountBrood(BroodStage.Egg);
    public int Larvae => CountBrood(BroodStage.Larva);
    public int Frontier => ToDig.SourceCount;
    public int Workers => CountCaste(Caste.Worker);
    public int Soldiers => CountCaste(Caste.Soldier);
    public int Alates => CountCaste(Caste.Alate);
    public int AlateBrood => Brood.FindAll(b => b.Caste == Caste.Alate).Count;

    private int CountBrood(BroodStage s)
    {
        int n = 0;
        foreach (var b in Brood) if (b.Stage == s) n++;
        return n;
    }

    private int CountCaste(Caste c)
    {
        int n = 0;
        foreach (var a in Ants) if (a.Caste == c) n++;
        return n;
    }

    public Ant? FindAnt(int id) => Ants.Find(a => a.Id == id);

    // ---------- player orders ----------

    public void PaintDig(int cx, int cy, int radius, bool on)
    {
        foreach (int i in Disc(cx, cy, radius)) World.SetDigOrder(i, on);
    }

    public void PaintRoom(int cx, int cy, int radius, Room room)
    {
        foreach (int i in Disc(cx, cy, radius)) World.SetRoom(i, room);
    }

    public void Cancel(int cx, int cy, int radius)
    {
        foreach (int i in Disc(cx, cy, radius))
        {
            World.SetDigOrder(i, false);
            World.SetRoom(i, Room.None);
        }
    }

    /// <summary>Paint a trail on the surface that foragers follow, like a scent trail that lasts.</summary>
    public void PaintTrail(int cx, int radius)
    {
        for (int x = cx - radius; x <= cx + radius; x++)
            if (x >= 0 && x < World.Width) World.Guide[x] = MathF.Max(World.Guide[x], SimConfig.GuideStrength);
    }

    /// <summary>Mark surface columns that foragers must not walk past.</summary>
    public void PaintAvoid(int cx, int radius, bool on)
    {
        for (int x = cx - radius; x <= cx + radius; x++)
            if (x >= 0 && x < World.Width) World.Avoid[x] = on;
    }

    public void ClearSurface(int cx, int radius)
    {
        for (int x = cx - radius; x <= cx + radius; x++)
        {
            if (x < 0 || x >= World.Width) continue;
            World.Guide[x] = 0;
            World.Avoid[x] = false;
        }
    }

    private IEnumerable<int> Disc(int cx, int cy, int r)
    {
        for (int dy = -r; dy <= r; dy++)
        for (int dx = -r; dx <= r; dx++)
        {
            int x = cx + dx, y = cy + dy;
            if (y < 1 || !World.InBounds(x, y) || dx * dx + dy * dy > r * r + r) continue;
            yield return World.Index(x, y);
        }
    }

    // ---------- the tick ----------

    public void Step()
    {
        if (GameOver != null) return;
        float dt = SimConfig.TickSeconds;
        Time += dt;
        DugThisTick = false;
        RefreshFields();
        CountJobs();
        UpdateSeason();
        UpdateWeather(dt);
        UpdateWater(dt * 0.5f);
        UpdateWater(dt * 0.5f);
        UpdateColony(dt);
        UpdateSpiders(dt);
        for (int k = 0; k < Ants.Count; k++) UpdateAnt(Ants[k], dt);
        Ants.RemoveAll(a => a.Dead);
        UpdateFood(dt);
        UpdateScent(dt);
        PeakColony = Math.Max(PeakColony, Ants.Count);
        CheckColonyLost();
    }

    public void RefreshFields()
    {
        if (_fieldLayout == World.LayoutVersion && _fieldOrders == World.OrdersVersion) return;
        bool layoutChanged = _fieldLayout != World.LayoutVersion;
        _fieldLayout = World.LayoutVersion;
        _fieldOrders = World.OrdersVersion;
        var w = World;
        if (layoutChanged) ToSurface.Build(i => w.Y(i) == 0);
        ToDig.Build(IsDigFront);
        ToStore.Build(i => w.Rooms[i] == Room.Store && w.Y(i) > 0);
        ToNursery.Build(i => w.Rooms[i] == Room.Nursery && w.Y(i) > 0);
        PlaceQueen();
    }

    private bool IsDigFront(int i)
    {
        int x = World.X(i), y = World.Y(i);
        for (int k = 0; k < 4; k++)
        {
            int nx = x + Dx[k], ny = y + Dy[k];
            if (World.InBounds(nx, ny) && World.DigOrder[World.Index(nx, ny)]) return true;
        }
        return false;
    }

    private void CheckColonyLost()
    {
        if (PeakColony == 0) return;   // an empty test world, not a colony
        if (!QueenAlive) GameOver ??= "The queen is dead. The colony cannot go on.";
        else if (Ants.Count == 0 && Brood.Count == 0) GameOver ??= "The last of the colony is gone.";
    }

    private void Say(string text)
    {
        if (Log.Count > 0 && Log[^1].Text == text && Time - Log[^1].Time < 10) return;
        Log.Add((Time, text));
        if (Log.Count > 40) Log.RemoveAt(0);
    }
}
