using System;
using System.Collections.Generic;

namespace Undermound.Core;

/// <summary>The queen, eggs and larvae, castes, nurses, winged queens and the nuptial flight.</summary>
public sealed partial class Sim
{
    public bool FlightUnderway { get; private set; }

    private float _eggTimer, _starveTimer, _queenWet, _queenCold, _queenTimer;
    private int _nurses;

    // ---------- food and hunger ----------

    private void UpdateColony(float dt)
    {
        float appetite = Season == Season.Winter ? SimConfig.WinterAppetite : 1f;
        float eaters = 0;
        foreach (var a in Ants)
            eaters += a.Caste switch
            {
                Caste.Soldier => SimConfig.SoldierFoodFactor,
                Caste.Alate => SimConfig.AlateFoodFactor,
                _ => 1f,
            };
        Food -= (eaters * SimConfig.WorkerFoodPerSecond * appetite
                 + Larvae * SimConfig.LarvaFoodPerSecond
                 + SimConfig.QueenFoodPerSecond * appetite) * dt;
        if (Food <= 0)
        {
            Food = 0;
            // Dormant winter ants starve more slowly, in step with their smaller appetite.
            _starveTimer += dt * appetite;
            if (_starveTimer >= SimConfig.StarveKillSeconds)
            {
                _starveTimer = 0;
                StarveOne();
            }
        }
        else _starveTimer = 0;

        UpdateQueen(dt);
        LayEggs(dt);
        GrowBrood(dt);
        UpdateFlightTrigger();
    }

    private void StarveOne()
    {
        int larva = Brood.FindIndex(b => b.Stage == BroodStage.Larva);
        if (larva >= 0) { Brood.RemoveAt(larva); Say("A larva starved. Bring in more food."); return; }
        if (Ants.Count == 0) return;
        var a = Ants[_rng.Range(0, Ants.Count)];
        a.Dead = true;
        WorkersDied++;
        Say("An ant starved.");
    }

    // ---------- the queen ----------

    /// <summary>
    /// The queen settles in the deepest dry nursery cell, so brood piles there too. When every
    /// nursery cell is wet, workers carry her to the deepest dry tunnel anywhere.
    /// </summary>
    private void PlaceQueen()
    {
        int nursery = DeepestDry(Room.Nursery);
        if (nursery >= 0) { QueenCell = nursery; return; }
        if (World.Water[QueenCell] < 0.3f && World.IsWalkable(QueenCell)) return;
        int any = DeepestDry(null);
        if (any >= 0) QueenCell = any;
    }

    /// <summary>The deepest reachable tunnel cell that is dry, in a room or (room null) anywhere.</summary>
    private int DeepestDry(Room? room, int maxBrood = int.MaxValue)
    {
        int best = -1, bestDepth = -1;
        for (int i = World.Width; i < World.Cells.Length; i++)
        {
            if (World.Cells[i] != CellType.Tunnel || World.Water[i] >= 0.3f) continue;
            if (room != null && World.Rooms[i] != room) continue;
            int d = ToSurface.Dist[i];
            if (d == FlowField.Unreachable || d <= bestDepth) continue;
            if (maxBrood < int.MaxValue)
            {
                int count = 0;
                foreach (var b in Brood) if (b.Cell == i) count++;
                if (count >= maxBrood) continue;
            }
            bestDepth = d;
            best = i;
        }
        return best;
    }

    private void UpdateQueen(float dt)
    {
        _queenTimer += dt;
        if (_queenTimer >= 5f) { _queenTimer = 0; PlaceQueen(); }

        if (World.Water[QueenCell] > 0.6f)
        {
            _queenWet += dt;
            if (_queenWet > SimConfig.QueenDrownSeconds * 0.5f) Say("The queen is under water! Drain the nursery!");
            if (_queenWet > SimConfig.QueenDrownSeconds) { QueenAlive = false; Say("The queen drowned."); }
        }
        else _queenWet = MathF.Max(0, _queenWet - dt);

        if (TempAt(QueenCell) < SimConfig.FreezeTemp)
        {
            _queenCold += dt;
            if (_queenCold > SimConfig.ChillDeathSeconds * 2) { QueenAlive = false; Say("The queen froze. The nursery was too shallow."); }
        }
        else _queenCold = MathF.Max(0, _queenCold - dt);
    }

    public bool QueenInDanger => _queenWet > 3f || _queenCold > 5f;

    private void LayEggs(float dt)
    {
        _eggTimer += dt;
        if (_eggTimer < SimConfig.EggLaySeconds) return;
        var nursery = NurseryCells();
        bool roomy = Brood.Count < nursery.Count * SimConfig.BroodPerNurseryCell;
        bool dry = World.Water[QueenCell] < SimConfig.WetLevel;
        bool warm = Season != Season.Winter && TempAt(QueenCell) >= SimConfig.LayingTemp;
        var caste = ChooseCaste();
        float cost = caste == Caste.Alate ? SimConfig.AlateEggFoodCost : SimConfig.EggFoodCost;
        if (nursery.Count == 0 || !roomy || !dry || !warm || Food < cost)
        {
            _eggTimer = SimConfig.EggLaySeconds * 0.5f;
            return;
        }
        int cell = NearQueen(nursery);
        if (World.Water[cell] >= SimConfig.WetLevel) { _eggTimer = SimConfig.EggLaySeconds * 0.5f; return; }
        _eggTimer = 0;
        Food -= cost;
        Brood.Add(new Brood { Cell = cell, Stage = BroodStage.Egg, Caste = caste, Jitter = _rng.NextFloat() });
    }

    private Caste ChooseCaste()
    {
        bool alateSeason = Season == Season.Summer && SeasonProgress < 0.75f;
        if (alateSeason && Ants.Count >= SimConfig.AlateMinColony && Alates + AlateBrood < SimConfig.MaxAlates
            && Food >= FoodCapacity * 0.4f && _rng.Chance(SimConfig.AlateChance))
            return Caste.Alate;
        return _rng.Chance(Priorities.Soldiers) ? Caste.Soldier : Caste.Worker;
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
            int d = Math.Abs(World.X(c) - qx) + Math.Abs(World.Y(c) - qy);
            if (d < bestScore) { bestScore = d; best = c; }
        }
        return best;
    }

    // ---------- brood ----------

    /// <summary>How well the brood is cared for: from untended to fully tended, by nurses per brood.</summary>
    public float NurseCare => Brood.Count == 0 ? 1f
        : MathF.Min(1f, _nurses / MathF.Max(1f, Brood.Count * SimConfig.NursesPerBrood));

    public static float BroodWarmth(float temp)
    {
        if (temp <= SimConfig.BroodStopTemp) return 0f;
        if (temp >= SimConfig.BroodWarmTemp) return 1f;
        return 0.3f + 0.7f * (temp - SimConfig.BroodStopTemp) / (SimConfig.BroodWarmTemp - SimConfig.BroodStopTemp);
    }

    private float _rescueTimer;

    /// <summary>Workers carry brood out of wet cells to the driest nursery cell, one at a time.</summary>
    private void RescueBrood(float dt)
    {
        _rescueTimer -= dt;
        if (_rescueTimer > 0 || _workers == 0) return;
        _rescueTimer = 1f / MathF.Max(1, _nurses);
        var wet = Brood.Find(b => World.Water[b.Cell] > 0.3f);
        if (wet == null) return;
        int best = DeepestDry(Room.Nursery, SimConfig.BroodPerPile);
        if (best < 0) best = DeepestDry(null, SimConfig.BroodPerPile);
        if (best < 0) return;
        wet.Cell = best;
        wet.Wet = 0;
    }

    private void GrowBrood(float dt)
    {
        RescueBrood(dt);
        float care = SimConfig.UntendedGrowth + (SimConfig.TendedGrowth - SimConfig.UntendedGrowth) * NurseCare;
        for (int k = Brood.Count - 1; k >= 0; k--)
        {
            var b = Brood[k];
            b.Age += dt * care * BroodWarmth(TempAt(b.Cell));
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

            float larvaTime = SimConfig.LarvaSeconds * (b.Caste == Caste.Alate ? SimConfig.AlateLarvaFactor : 1f);
            if (b.Stage == BroodStage.Egg && b.Age >= SimConfig.EggSeconds)
            {
                b.Stage = BroodStage.Larva;
                b.Age = 0;
            }
            else if (b.Stage == BroodStage.Larva && b.Age >= larvaTime)
            {
                Brood.RemoveAt(k);
                var ant = SpawnAnt(b.Cell, b.Caste);
                if (b.Caste == Caste.Alate)
                {
                    ant.Job = AntJob.AlateWaiting;
                    if (Alates == 1) Say("A winged queen has hatched! She will fly after a summer rain.");
                }
                Hatched++;
            }
        }
    }

    public Ant SpawnAnt(int cell, Caste caste = Caste.Worker)
    {
        var a = new Ant(_nextAntId++, cell, caste);
        Ants.Add(a);
        return a;
    }

    // ---------- the nuptial flight ----------

    private void OnRainStopped()
    {
        if (Season == Season.Summer && Alates > 0) StartFlight();
    }

    private void UpdateFlightTrigger()
    {
        // Late in summer, or if autumn comes first, the winged queens go anyway.
        bool late = Season == Season.Summer && SeasonProgress > 0.9f || Season == Season.Autumn;
        if (late && !FlightUnderway && Alates > 0 && !Raining) StartFlight();
        if (FlightUnderway && Alates == 0) FlightUnderway = false;
    }

    public void StartFlight()
    {
        if (Alates == 0) return;
        FlightUnderway = true;
        foreach (var a in Ants)
            if (a.Caste == Caste.Alate && a.Job is AntJob.AlateWaiting or AntJob.Idle) a.Job = AntJob.ToFlight;
        Say($"Nuptial flight! {Alates} winged queens are leaving to found new colonies.");
    }

    // ---------- the year ----------

    private void EndYear(int year)
    {
        Report = new YearReport
        {
            Year = year,
            QueensFlown = QueensFlown - _yearStart.QueensFlown,
            PeakColony = PeakColony,
            CellsDug = CellsDug - _yearStart.CellsDug,
            FoodGathered = FoodGathered - _yearStart.FoodGathered,
            AntsLost = WorkersDied - _yearStart.AntsLost,
            BroodLost = BroodDrowned - _yearStart.BroodLost,
            SpidersDrivenOff = SpidersDrivenOff - _yearStart.SpidersDrivenOff,
        };
        _yearStart = new YearReport
        {
            QueensFlown = QueensFlown, CellsDug = CellsDug, FoodGathered = FoodGathered,
            AntsLost = WorkersDied, BroodLost = BroodDrowned, SpidersDrivenOff = SpidersDrivenOff,
        };
        PeakColony = Ants.Count;
        Say($"Year {year} is over. {Report.QueensFlown} winged queens flew from your colony.");
    }

    // ---------- food on the surface and scent ----------

    private float _foodSpawnTimer;

    private float FoodSeasonFactor => Season switch
    {
        Season.Spring => 1f,
        Season.Summer => 1.4f,
        Season.Autumn => 0.9f,
        _ => 0f,
    };

    private void UpdateFood(float dt)
    {
        World.Food.RemoveAll(f => f.Amount <= 0);
        _foodSpawnTimer -= dt * FoodSeasonFactor;
        if (_foodSpawnTimer > 0) return;
        _foodSpawnTimer = _rng.Range(SimConfig.FoodSpawnMinSeconds, SimConfig.FoodSpawnMaxSeconds);
        if (World.Food.Count >= SimConfig.MaxFoodSources) return;
        for (int attempt = 0; attempt < 10; attempt++)
        {
            float x = _rng.Range(6f, World.Width - 6f);
            if (NearOpening(x, 12) || World.FoodAt(x) != null) continue;
            var kind = Season switch
            {
                Season.Summer => _rng.Chance(0.6f) ? FoodKind.Berry : FoodKind.Crumb,
                Season.Autumn => _rng.Chance(0.6f) ? FoodKind.Seeds : FoodKind.Berry,
                _ => (FoodKind)_rng.Range(0, 3),
            };
            int amount = _rng.Range(30, 91) + (Season == Season.Autumn ? 30 : 0);
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
        float keepGuide = 1f - SimConfig.GuideDecayPerSecond * dt;
        float keepAlarm = 1f - SimConfig.AlarmDecayPerSecond * dt;
        var w = World;
        for (int x = 0; x < w.Width; x++)
        {
            w.Scent[x] = w.Scent[x] * keep < 0.001f ? 0 : w.Scent[x] * keep;
            w.Guide[x] = w.Guide[x] * keepGuide < 0.01f ? 0 : w.Guide[x] * keepGuide;
            w.Alarm[x] = w.Alarm[x] * keepAlarm < 0.01f ? 0 : w.Alarm[x] * keepAlarm;
        }
    }
}
