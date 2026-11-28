using System;
using System.Collections.Generic;

namespace Undermound.Core;

/// <summary>
/// The whole simulation: the world, the ants, the brood, the queen, food, weather and water.
/// Plain C# with no engine types, stepped at a fixed tick.
/// </summary>
public sealed class Sim
{
    public readonly World World;
    public readonly List<Ant> Ants = new();
    public readonly List<Brood> Brood = new();
    public readonly List<(float Time, string Text)> Log = new();

    public readonly FlowField ToSurface;
    public readonly FlowField ToDig;
    public readonly FlowField ToStore;
    public readonly FlowField ToNursery;

    public float Time { get; private set; }
    public float Food;
    public int QueenCell;
    public bool Raining { get; private set; }
    public float RainLeft { get; private set; }
    public float NextRainIn;
    public bool AutoWeather = true;

    // Stats
    public int Hatched, WorkersDied, BroodDrowned, CellsDug, FoodGathered;

    private readonly Rng _rng;
    private int _nextAntId;
    private int _fieldLayout = -1, _fieldOrders = -1;
    private float _eggTimer, _starveTimer, _foodSpawnTimer;
    private bool _rainWarned;
    private int _diggers, _foragers;
    private bool _sweepLeft;

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
    }

    /// <summary>A new colony with a starter nest: an entrance shaft, a nursery and a food store.</summary>
    public static Sim CreateDefault(int seed)
    {
        var w = new World(SimConfig.Width, SimConfig.Height);
        w.Generate(seed);
        int ex = SimConfig.Width / 2;
        w.Carve(ex, 1, ex, 10);
        w.Carve(ex - 5, 11, ex + 4, 13, Room.Nursery);
        w.Carve(ex + 1, 6, ex + 6, 6);
        w.Carve(ex + 7, 5, ex + 11, 7, Room.Store);
        var sim = new Sim(w, seed) { Food = SimConfig.StartFood };
        for (int i = 0; i < SimConfig.StartWorkers; i++)
            sim.SpawnAnt(w.Index(ex - 4 + i % 8, 13));
        w.Food.Add(new FoodSource { X = ex - 25, Amount = 40, Max = 40, Kind = FoodKind.Berry });
        w.Food.Add(new FoodSource { X = ex + 32, Amount = 30, Max = 30, Kind = FoodKind.Crumb });
        w.Food.Add(new FoodSource { X = ex - 55, Amount = 35, Max = 35, Kind = FoodKind.Seeds });
        sim.RefreshFields();
        return sim;
    }

    // ---------- queries for the view and the HUD ----------

    public float Day => Time / SimConfig.DaySeconds;
    public float FoodCapacity =>
        SimConfig.BaseFoodCapacity + World.CountRoomCells(Room.Store) * SimConfig.FoodPerStoreCell;
    public int Eggs => CountBrood(BroodStage.Egg);
    public int Larvae => CountBrood(BroodStage.Larva);
    public int Frontier => ToDig.SourceCount;
    public float RainIn => Raining ? 0 : NextRainIn;

    private int CountBrood(BroodStage s)
    {
        int n = 0;
        foreach (var b in Brood) if (b.Stage == s) n++;
        return n;
    }

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

    public void StartRain(float seconds)
    {
        Raining = true;
        RainLeft = seconds;
        Say("It's raining. Water is running into the nest.");
    }

    // ---------- the tick ----------

    public void Step()
    {
        float dt = SimConfig.TickSeconds;
        Time += dt;
        RefreshFields();
        CountJobs();
        UpdateWeather(dt);
        UpdateWater(dt * 0.5f);
        UpdateWater(dt * 0.5f);
        UpdateColony(dt);
        for (int k = 0; k < Ants.Count; k++) UpdateAnt(Ants[k], dt);
        Ants.RemoveAll(a => a.Dead);
        UpdateFood(dt);
        UpdateScent(dt);
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
        QueenCell = DeepestNurseryCell();
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

    private int DeepestNurseryCell()
    {
        int best = QueenCell, bestDepth = -1;
        for (int i = World.Width; i < World.Cells.Length; i++)
        {
            if (World.Rooms[i] != Room.Nursery || World.Cells[i] != CellType.Tunnel) continue;
            int d = ToSurface.Dist[i];
            if (d != FlowField.Unreachable && d > bestDepth) { bestDepth = d; best = i; }
        }
        return best;
    }

    private void CountJobs()
    {
        _diggers = _foragers = 0;
        foreach (var a in Ants)
        {
            if (a.Job is AntJob.ToDig or AntJob.Digging) _diggers++;
            else if (a.Job is AntJob.ForageOut or AntJob.CarryFood or AntJob.ReturnHome) _foragers++;
        }
    }

    // ---------- weather and water ----------

    private void UpdateWeather(float dt)
    {
        if (Raining)
        {
            RainLeft -= dt;
            if (RainLeft > 0) return;
            Raining = false;
            NextRainIn = _rng.Range(SimConfig.RainMinGapSeconds, SimConfig.RainMaxGapSeconds);
            _rainWarned = false;
            Say("The rain has stopped.");
            return;
        }
        if (!AutoWeather) return;
        NextRainIn -= dt;
        if (!_rainWarned && NextRainIn <= SimConfig.RainWarningSeconds)
        {
            _rainWarned = true;
            Say("Rain is coming. Keep the nursery high and dry.");
        }
        if (NextRainIn <= 0) StartRain(_rng.Range(SimConfig.RainMinSeconds, SimConfig.RainMaxSeconds));
    }

    private void UpdateWater(float dt)
    {
        var w = World;
        var water = w.Water;
        int width = w.Width, height = w.Height;

        if (Raining)
        {
            foreach (int x in w.Openings())
            {
                int shelter = 0;
                for (int dx = -SimConfig.RainCatchCells; dx <= SimConfig.RainCatchCells; dx++)
                    if (x + dx >= 0 && x + dx < width) shelter += w.Mound[x + dx];
                float inflow = SimConfig.RainPerOpeningPerSecond * dt / (1f + shelter / SimConfig.MoundShelter);
                water[w.Index(x, 1)] += inflow;
            }
        }

        // Fall: from the bottom up, so water drops one cell per pass.
        for (int y = height - 2; y >= 1; y--)
        for (int x = 0; x < width; x++)
        {
            int i = y * width + x;
            float v = water[i];
            if (v <= 0) continue;
            if (!w.IsWalkable(i)) { water[i] = 0; continue; }
            int below = i + width;
            if (!w.IsWalkable(below)) continue;
            float move = MathF.Min(v, 1f - water[below]);
            if (move <= 0) continue;
            water[i] -= move;
            water[below] += move;
        }

        // Spread sideways, alternating the sweep direction to stay symmetric.
        _sweepLeft = !_sweepLeft;
        for (int y = 1; y < height; y++)
        for (int s = 0; s < width; s++)
        {
            int x = _sweepLeft ? width - 1 - s : s;
            int i = y * width + x;
            float v = water[i];
            if (v <= 0.001f) continue;
            for (int side = -1; side <= 1; side += 2)
            {
                int nx = x + side;
                if (nx < 0 || nx >= width) continue;
                int n = i + side;
                if (!w.IsWalkable(n) || water[n] >= water[i]) continue;
                float t = (water[i] - water[n]) * SimConfig.WaterSideShare;
                water[i] -= t;
                water[n] += t;
            }
        }

        // Overfull cells push water up; at the top row it spills onto the surface and is lost.
        for (int y = height - 1; y >= 1; y--)
        for (int x = 0; x < width; x++)
        {
            int i = y * width + x;
            if (water[i] <= 1f) continue;
            float excess = water[i] - 1f;
            water[i] = 1f;
            int above = i - width;
            if (y > 1 && w.IsWalkable(above)) water[above] += excess;
        }

        // Soil soaks water up.
        for (int i = width; i < water.Length; i++)
        {
            if (water[i] <= 0) continue;
            int x = i % width, y = i / width;
            float soak = 0;
            for (int k = 0; k < 4; k++)
            {
                int nx = x + Dx[k], ny = y + Dy[k];
                if (ny < 1 || !w.InBounds(nx, ny)) continue;
                soak += World.Absorbency(w.Cells[w.Index(nx, ny)]);
            }
            // Soak in proportion to the water present, so a thin film does not vanish at once.
            water[i] -= water[i] * SimConfig.AbsorbFraction * soak * dt;
            if (water[i] < 0.002f) water[i] = 0;
        }
    }

    // ---------- colony: food, queen, brood ----------

    private void UpdateColony(float dt)
    {
        int larvae = Larvae;
        Food -= (Ants.Count * SimConfig.WorkerFoodPerSecond + larvae * SimConfig.LarvaFoodPerSecond
                 + SimConfig.QueenFoodPerSecond) * dt;
        if (Food <= 0)
        {
            Food = 0;
            _starveTimer += dt;
            if (_starveTimer >= SimConfig.StarveKillSeconds)
            {
                _starveTimer = 0;
                StarveOne();
            }
        }
        else _starveTimer = 0;

        LayEggs(dt);
        GrowBrood(dt);
    }

    private void StarveOne()
    {
        int larva = Brood.FindIndex(b => b.Stage == BroodStage.Larva);
        if (larva >= 0) { Brood.RemoveAt(larva); Say("A larva starved. Bring in more food."); return; }
        if (Ants.Count == 0) return;
        var a = Ants[_rng.Range(0, Ants.Count)];
        a.Dead = true;
        WorkersDied++;
        Say("A worker starved.");
    }

    private void LayEggs(float dt)
    {
        _eggTimer += dt;
        if (_eggTimer < SimConfig.EggLaySeconds) return;
        var nursery = NurseryCells();
        bool roomy = Brood.Count < nursery.Count * SimConfig.BroodPerNurseryCell;
        bool dry = World.Water[QueenCell] < SimConfig.WetLevel;
        if (nursery.Count == 0 || !roomy || !dry || Food < SimConfig.EggFoodCost)
        {
            _eggTimer = SimConfig.EggLaySeconds * 0.5f;
            return;
        }
        _eggTimer = 0;
        Food -= SimConfig.EggFoodCost;
        int cell = NearQueen(nursery);
        Brood.Add(new Brood { Cell = cell, Stage = BroodStage.Egg, Jitter = _rng.NextFloat() });
    }

    private List<int> NurseryCells()
    {
        var list = new List<int>();
        for (int i = World.Width; i < World.Cells.Length; i++)
            if (World.Rooms[i] == Room.Nursery && World.Cells[i] == CellType.Tunnel) list.Add(i);
        return list;
    }

    /// <summary>The nursery cell closest to the queen that still has room, so brood piles around her.</summary>
    private int NearQueen(List<int> cells)
    {
        int qx = World.X(QueenCell), qy = World.Y(QueenCell);
        int best = cells[0], bestScore = int.MaxValue;
        foreach (int c in cells)
        {
            int count = 0;
            foreach (var b in Brood) if (b.Cell == c) count++;
            if (count >= SimConfig.BroodPerPile) continue;
            int d = System.Math.Abs(World.X(c) - qx) + System.Math.Abs(World.Y(c) - qy);
            if (d < bestScore) { bestScore = d; best = c; }
        }
        return best;
    }

    private void GrowBrood(float dt)
    {
        for (int k = Brood.Count - 1; k >= 0; k--)
        {
            var b = Brood[k];
            b.Age += dt;
            if (World.Water[b.Cell] > SimConfig.WetLevel)
            {
                b.Wet += dt;
                if (b.Wet > SimConfig.BroodDrownSeconds)
                {
                    Brood.RemoveAt(k);
                    BroodDrowned++;
                    Say("Brood drowned in a flooded nursery.");
                    continue;
                }
            }
            else b.Wet = MathF.Max(0, b.Wet - dt);

            if (b.Stage == BroodStage.Egg && b.Age >= SimConfig.EggSeconds)
            {
                b.Stage = BroodStage.Larva;
                b.Age = 0;
            }
            else if (b.Stage == BroodStage.Larva && b.Age >= SimConfig.LarvaSeconds)
            {
                Brood.RemoveAt(k);
                SpawnAnt(b.Cell);
                Hatched++;
            }
        }
    }

    public Ant SpawnAnt(int cell)
    {
        var a = new Ant(_nextAntId++, cell);
        Ants.Add(a);
        return a;
    }

    // ---------- food on the surface and scent ----------

    private void UpdateFood(float dt)
    {
        World.Food.RemoveAll(f => f.Amount <= 0);
        _foodSpawnTimer -= dt;
        if (_foodSpawnTimer > 0) return;
        _foodSpawnTimer = _rng.Range(SimConfig.FoodSpawnMinSeconds, SimConfig.FoodSpawnMaxSeconds);
        if (World.Food.Count >= SimConfig.MaxFoodSources) return;
        for (int attempt = 0; attempt < 10; attempt++)
        {
            float x = _rng.Range(6f, World.Width - 6f);
            if (NearOpening(x, 12) || World.FoodAt(x) != null) continue;
            int amount = _rng.Range(30, 91);
            var kind = (FoodKind)_rng.Range(0, 3);
            World.Food.Add(new FoodSource { X = x, Amount = amount, Max = amount, Kind = kind });
            return;
        }
    }

    private bool NearOpening(float x, int distance)
    {
        foreach (int o in World.Openings()) if (MathF.Abs(o - x) < distance) return true;
        return false;
    }

    private void UpdateScent(float dt)
    {
        float keep = 1f - SimConfig.ScentDecayPerSecond * dt;
        var s = World.Scent;
        for (int x = 0; x < s.Length; x++) s[x] = s[x] * keep < 0.001f ? 0 : s[x] * keep;
    }

    // ---------- ants ----------

    private void UpdateAnt(Ant a, float dt)
    {
        float speedMul = 1f;
        if (World.Water[a.Cell] > 0.6f)
        {
            speedMul = SimConfig.WaterSpeedFactor;
            a.Submerged += dt;
            if (a.Submerged > SimConfig.DrownSeconds)
            {
                a.Dead = true;
                WorkersDied++;
                Say("A worker drowned.");
                return;
            }
        }
        else a.Submerged = MathF.Max(0, a.Submerged - 2 * dt);

        if (a.Moving)
        {
            bool surface = World.Y(a.Cell) == 0 && World.Y(a.Next) == 0;
            a.T += (surface ? SimConfig.SurfaceSpeed : SimConfig.TunnelSpeed) * speedMul * dt;
            if (a.T < 1f) return;
            a.Cell = a.Next;
            a.Next = -1;
            a.T = 0;
            OnArrive(a);
        }
        Think(a, dt);
    }

    private void OnArrive(Ant a)
    {
        if (World.Y(a.Cell) != 0) return;
        int x = World.X(a.Cell);
        if (a.Carrying == Carry.Food) World.Scent[x] += SimConfig.ScentDeposit;
        if (a.Job == AntJob.ForageOut) a.Travelled++;
    }

    private void Walk(Ant a, int cell)
    {
        a.FacingX = World.X(cell) - World.X(a.Cell);
        a.FacingY = World.Y(cell) - World.Y(a.Cell);
        if (a.FacingX != 0) a.Side = a.FacingX > 0 ? 1 : -1;
        a.Next = cell;
        a.T = 0;
    }

    /// <summary>Step along a field. Returns false when already at a source or cut off.</summary>
    private bool Follow(Ant a, FlowField f)
    {
        int n = f.Next(a.Cell, a.Id);
        if (n < 0) return false;
        Walk(a, n);
        return true;
    }

    private void Think(Ant a, float dt)
    {
        switch (a.Job)
        {
            case AntJob.Idle: ChooseJob(a); break;
            case AntJob.ToDig: ThinkToDig(a); break;
            case AntJob.Digging: ThinkDigging(a, dt); break;
            case AntJob.CarrySoil: ThinkCarrySoil(a); break;
            case AntJob.DropSoil: ThinkDropSoil(a); break;
            case AntJob.ForageOut: ThinkForage(a); break;
            case AntJob.CarryFood: ThinkCarryFood(a); break;
            case AntJob.ReturnHome: ThinkReturnHome(a); break;
            case AntJob.Resting: ThinkResting(a, dt); break;
        }
    }

    private void ChooseJob(Ant a)
    {
        int workers = Ants.Count;
        int frontier = ToDig.SourceCount;
        if (frontier > 0 && ToDig.Reachable(a.Cell))
        {
            int want = Math.Clamp((int)MathF.Ceiling(workers * SimConfig.DigShare), 1,
                frontier * SimConfig.DiggersPerFrontierCell);
            if (_diggers < want)
            {
                a.Job = AntJob.ToDig;
                _diggers++;
                return;
            }
        }
        if (Food < FoodCapacity - 0.5f)
        {
            int want = Math.Max(1, (int)MathF.Ceiling(workers * SimConfig.ForageShare));
            if (_foragers < want)
            {
                a.Job = AntJob.ForageOut;
                a.Travelled = 0;
                a.Dir = 0;
                _foragers++;
                return;
            }
        }
        a.Job = AntJob.Resting;
        a.Timer = _rng.Range(SimConfig.RestMinSeconds, SimConfig.RestMaxSeconds);
    }

    private void ThinkToDig(Ant a)
    {
        if (ToDig.Dist[a.Cell] == 0) { a.Job = AntJob.Digging; return; }
        if (!Follow(a, ToDig)) a.Job = AntJob.Idle;
    }

    private void ThinkDigging(Ant a, float dt)
    {
        int target = DigTargetNextTo(a);
        if (target < 0) { a.Job = AntJob.Idle; return; }
        a.FacingX = World.X(target) - World.X(a.Cell);
        a.FacingY = World.Y(target) - World.Y(a.Cell);
        var m = World.Cells[target];
        World.DigProgress[target] += dt / (SimConfig.BaseDigSeconds * World.Hardness(m));
        if (World.DigProgress[target] < 1f) return;
        World.DigProgress[target] = 0;
        World.SetDigOrder(target, false);
        World.SetMaterial(target, CellType.Tunnel);
        CellsDug++;
        a.Carrying = Carry.Soil;
        a.Job = AntJob.CarrySoil;
    }

    private int DigTargetNextTo(Ant a)
    {
        int x = World.X(a.Cell), y = World.Y(a.Cell);
        for (int k = 0; k < 4; k++)
        {
            int kk = (k + a.Id) & 3;
            int nx = x + Dx[kk], ny = y + Dy[kk];
            if (!World.InBounds(nx, ny)) continue;
            int n = World.Index(nx, ny);
            if (World.DigOrder[n] && World.IsDiggable(World.Cells[n])) return n;
        }
        return -1;
    }

    private void ThinkCarrySoil(Ant a)
    {
        if (World.Y(a.Cell) == 0)
        {
            int x = World.X(a.Cell);
            int side = _rng.Chance(0.5f) ? 1 : -1;
            a.TargetX = Math.Clamp(x + side * _rng.Range(2, 8), 0, World.Width - 1);
            a.Job = AntJob.DropSoil;
            ThinkDropSoil(a);
            return;
        }
        if (!Follow(a, ToSurface)) a.Job = AntJob.Idle;
    }

    private void ThinkDropSoil(Ant a)
    {
        int x = World.X(a.Cell);
        if (x == a.TargetX)
        {
            World.Mound[x]++;
            a.Carrying = Carry.None;
            a.Job = AntJob.Idle;
            return;
        }
        Walk(a, World.Index(x + Math.Sign(a.TargetX - x), 0));
    }

    private void ThinkForage(Ant a)
    {
        if (World.Y(a.Cell) != 0)
        {
            if (!Follow(a, ToSurface)) a.Job = AntJob.Idle;
            return;
        }
        int x = World.X(a.Cell);
        var food = World.FoodAt(x + 0.5f);
        if (food != null)
        {
            food.Amount--;
            a.Carrying = Carry.Food;
            a.Job = AntJob.CarryFood;
            ThinkCarryFood(a);
            return;
        }
        if (a.Travelled > SimConfig.ForageMaxRange) { a.Job = AntJob.ReturnHome; ThinkReturnHome(a); return; }

        float right = ScentAround(x, 1), left = ScentAround(x, -1);
        if (a.Dir == 0)
        {
            // Just out of the nest: pick the side that smells of food, else a random side.
            bool smell = MathF.Max(left, right) > SimConfig.ScentFollowThreshold;
            a.Dir = smell && _rng.Chance(0.85f) ? (right >= left ? 1 : -1) : (_rng.Chance(0.5f) ? 1 : -1);
        }
        else
        {
            float ahead = a.Dir > 0 ? right : left;
            if (ahead < SimConfig.ScentFollowThreshold && _rng.Chance(SimConfig.RandomTurnChance)) a.Dir = -a.Dir;
        }
        int nx = x + a.Dir;
        if (nx < 0 || nx >= World.Width) { a.Dir = -a.Dir; nx = x + a.Dir; }
        Walk(a, World.Index(nx, 0));
    }

    private float ScentAround(int x, int dir)
    {
        float sum = 0;
        for (int k = 1; k <= SimConfig.ScentSenseCells; k++)
        {
            int nx = x + dir * k;
            if (nx >= 0 && nx < World.Width) sum += World.Scent[nx];
        }
        return sum;
    }

    private FlowField? HomeField()
    {
        if (ToStore.SourceCount > 0) return ToStore;
        if (ToNursery.SourceCount > 0) return ToNursery;
        return null;
    }

    private void ThinkCarryFood(Ant a)
    {
        var home = HomeField();
        if (home == null || home.Dist[a.Cell] == 0 || !home.Reachable(a.Cell))
        {
            if (home != null && home.Reachable(a.Cell) || home == null && World.Y(a.Cell) > 0)
            {
                Food = MathF.Min(FoodCapacity, Food + 1f);
                FoodGathered++;
            }
            a.Carrying = Carry.None;
            a.Job = AntJob.Idle;
            return;
        }
        Follow(a, home);
    }

    private void ThinkReturnHome(Ant a)
    {
        var home = HomeField();
        if (home == null || home.Dist[a.Cell] == 0 || !Follow(a, home))
        {
            a.Job = AntJob.Resting;
            a.Timer = _rng.Range(SimConfig.RestMinSeconds, SimConfig.RestMaxSeconds);
        }
    }

    private void ThinkResting(Ant a, float dt)
    {
        var field = ToNursery.SourceCount > 0 ? ToNursery : HomeField();
        if (field != null && field.Reachable(a.Cell) && field.Dist[a.Cell] > 0)
        {
            Follow(a, field);
            return;
        }
        a.Timer -= dt;
        if (a.Timer <= 0) { a.Job = AntJob.Idle; return; }
        // Mill about inside the room.
        if (field != null && _rng.Chance(0.15f))
        {
            int x = World.X(a.Cell), y = World.Y(a.Cell);
            int k = _rng.Range(0, 4);
            int nx = x + Dx[k], ny = y + Dy[k];
            if (World.InBounds(nx, ny) && field.Dist[World.Index(nx, ny)] == 0) Walk(a, World.Index(nx, ny));
        }
    }

    private void Say(string text)
    {
        if (Log.Count > 0 && Log[^1].Text == text && Time - Log[^1].Time < 10) return;
        Log.Add((Time, text));
        if (Log.Count > 40) Log.RemoveAt(0);
    }
}
