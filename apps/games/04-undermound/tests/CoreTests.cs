using System;
using System.Collections.Generic;
using System.Linq;
using Undermound.Core;

namespace Undermound.Tests;

/// <summary>Tests for the simulation core. Run with tools/test.sh; exit code 0 when all pass.</summary>
public static class CoreTests
{
    private static readonly List<(string Name, Action Body)> Tests = new()
    {
        ("flow field: distances and steps lead to the source", FlowFieldLeadsToSource),
        ("flow field: walled-off cells are unreachable", FlowFieldUnreachable),
        ("dig: ordered cells next to the nest get dug and soil piles on the surface", DigOrdersGetDug),
        ("dig: orders on rock and in the air are ignored", DigOrdersIgnoredOnRock),
        ("dig: an order cut off by rock is left alone and ants do not get stuck", UnreachableOrderLeftAlone),
        ("forage: ants bring food home and lay a scent trail", ForagersBringFood),
        ("scent: trails fade when nobody walks them", ScentFades),
        ("brood: the queen lays eggs and they become workers", BroodBecomesWorkers),
        ("brood: no nursery means no eggs", NoNurseryNoEggs),
        ("starvation: with no food the colony shrinks", StarvationShrinksColony),
        ("water: falls, pools at the bottom and never enters rock", WaterPoolsAtBottom),
        ("water: soil soaks it up over time", WaterSoaksAway),
        ("rain: a low nursery floods and its brood drowns", RainDrownsLowBrood),
        ("rain: a mound around the entrance lets less water in", MoundShelters),
        ("rain: the starter sump catches the first rain", RainReachesDefaultNest),
        ("determinism: the same seed gives the same colony", SameSeedSameColony),
        ("default colony: runs ten minutes without breaking", DefaultColonyRuns),
        ("seasons: spring, summer, autumn, winter, then a new year", SeasonsCycle),
        ("temperature: deep soil is warmer than the air in winter and cooler in summer", DepthTemperature),
        ("winter: no eggs, no new food, no foraging", WinterIsQuiet),
        ("winter: an ant left on the frozen surface dies", AntsFreezeOnSurface),
        ("spring: snow melts into the nest", SnowMeltFloods),
        ("priorities: dig-only sends nobody out; forage-only digs nothing", PrioritiesSteerJobs),
        ("nurses: tended brood grows faster", NursesSpeedBrood),
        ("soldiers: the soldier share decides the caste of new brood", SoldierShare),
        ("spider: with no soldiers it catches foragers", SpiderCatchesForagers),
        ("spider: soldiers drive it off or kill it", SoldiersFightSpider),
        ("alarm: foragers turn back from alarm scent", AlarmTurnsForagersBack),
        ("trail: a painted trail leads foragers to food", PaintedTrailLeads),
        ("avoid: foragers do not walk past an avoid mark", AvoidMarkBlocks),
        ("flood: ants climb out of deep water and brood is carried to dry cells", AntsEscapeWater),
        ("alates: a big summer colony raises winged queens and they fly", NuptialFlight),
        ("game over: the queen drowns in a flooded nursery", QueenDrowns),
        ("year: a report is made when the second spring begins", YearReportMade),
        ("zz report: a year of the default colony", YearReportDiag),
    };

    public static int Main(string[] args)
    {
        string filter = args.Length > 0 ? args[0] : "";
        int passed = 0, failed = 0;
        foreach (var (name, body) in Tests.Where(t => t.Name.Contains(filter)))
        {
            try
            {
                body();
                passed++;
                Console.WriteLine($"  ok    {name}");
            }
            catch (Exception e)
            {
                failed++;
                Console.WriteLine($"  FAIL  {name}\n        {e.Message}");
            }
        }
        Console.WriteLine($"\n{passed} passed, {failed} failed");
        return failed == 0 ? 0 : 1;
    }

    // ---------- helpers ----------

    private static void Check(bool condition, string message)
    {
        if (!condition) throw new Exception(message);
    }

    /// <summary>A plain world: surface lane on top, everything below one material.</summary>
    private static World Plain(int w = 40, int h = 30, CellType fill = CellType.Clay)
    {
        var world = new World(w, h);
        for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
            world.Cells[world.Index(x, y)] = y == 0 ? CellType.Air : fill;
        return world;
    }

    /// <summary>A small colony: shaft at x=20, nursery and store at the bottom of it.</summary>
    private static Sim SmallColony(int workers = 6, float food = 20, bool nursery = true, bool store = true)
    {
        var w = Plain();
        w.Carve(20, 1, 20, 6);
        if (nursery) w.Carve(16, 7, 24, 8, Room.Nursery);
        else w.Carve(16, 7, 24, 8);
        if (store) w.Carve(25, 5, 28, 6, Room.Store);
        if (store) w.Carve(21, 5, 24, 5);
        var sim = new Sim(w, 1) { Food = food, AutoWeather = false };
        for (int i = 0; i < workers; i++) sim.SpawnAnt(w.Index(17 + i % 6, 8));
        sim.RefreshFields();
        return sim;
    }

    private static void Run(Sim sim, float seconds)
    {
        int ticks = (int)(seconds / SimConfig.TickSeconds);
        for (int t = 0; t < ticks; t++) sim.Step();
    }

    private static float TotalWater(World w) => w.Water.Sum();

    // ---------- tests ----------

    private static void FlowFieldLeadsToSource()
    {
        var w = Plain();
        w.Carve(5, 1, 5, 10);
        w.Carve(5, 10, 15, 10);
        var f = new FlowField(w);
        f.Build(i => w.Y(i) == 0);
        int far = w.Index(15, 10);
        Check(f.Dist[far] == 10 + 10, $"distance to the surface should be 20, was {f.Dist[far]}");
        int steps = 0, at = far;
        while (f.Dist[at] > 0 && steps < 100) { at = f.Next(at, 0); steps++; }
        Check(w.Y(at) == 0 && steps == 20, $"following the field should reach the surface in 20 steps, took {steps}");
    }

    private static void FlowFieldUnreachable()
    {
        var w = Plain();
        w.Carve(10, 10, 12, 12);   // a sealed pocket
        var f = new FlowField(w);
        f.Build(i => w.Y(i) == 0);
        Check(!f.Reachable(w.Index(11, 11)), "a sealed pocket should be unreachable");
        Check(f.Next(w.Index(11, 11), 0) == -1, "no step out of a sealed pocket");
    }

    private static void DigOrdersGetDug()
    {
        var sim = SmallColony();
        var w = sim.World;
        sim.PaintDig(12, 7, 0, true);
        for (int x = 12; x <= 15; x++) sim.PaintDig(x, 7, 0, true);
        Run(sim, 90);
        for (int x = 12; x <= 15; x++)
            Check(w.Cells[w.Index(x, 7)] == CellType.Tunnel, $"cell ({x},7) should be dug");
        Check(sim.CellsDug >= 4, $"at least 4 cells dug, was {sim.CellsDug}");
        Check(w.Mound.Sum() >= 3, $"soil should pile on the surface, mound was {w.Mound.Sum()}");
        Check(sim.Ants.All(a => a.Carrying != Carry.Soil || a.Job is AntJob.CarrySoil or AntJob.DropSoil),
            "ants carrying soil should be taking it up");
    }

    private static void DigOrdersIgnoredOnRock()
    {
        var w = Plain();
        w.Cells[w.Index(10, 10)] = CellType.Rock;
        w.SetDigOrder(w.Index(10, 10), true);
        w.SetDigOrder(w.Index(10, 0), true);
        Check(!w.DigOrder[w.Index(10, 10)], "rock cannot be ordered dug");
        Check(!w.DigOrder[w.Index(10, 0)], "the surface cannot be ordered dug");
        w.SetRoom(w.Index(10, 10), Room.Nursery);
        Check(w.Rooms[w.Index(10, 10)] == Room.None, "rock cannot be a room");
    }

    private static void UnreachableOrderLeftAlone()
    {
        var sim = SmallColony();
        var w = sim.World;
        // A cell deep in solid clay, nowhere near a tunnel.
        sim.PaintDig(5, 25, 0, true);
        Run(sim, 30);
        Check(w.Cells[w.Index(5, 25)] == CellType.Clay, "an unreachable order should not be dug");
        Check(sim.Ants.All(a => a.Job != AntJob.Digging), "no ant should be digging");
        Check(sim.Frontier == 0, "an order with no tunnel beside it is not a dig front");
    }

    private static void ForagersBringFood()
    {
        var sim = SmallColony(food: 5);
        sim.World.Food.Add(new FoodSource { X = 30, Amount = 30, Max = 30, Kind = FoodKind.Berry });
        Run(sim, 120);
        Check(sim.FoodGathered >= 5, $"foragers should bring in food, brought {sim.FoodGathered}");
        float trail = 0;
        for (int x = 21; x < 29; x++) trail += sim.World.Scent[x];
        Check(trail > 0.5f, $"a scent trail should lie between the nest and the berry, was {trail:F2}");
    }

    private static void ScentFades()
    {
        var w = Plain();
        var sim = new Sim(w, 1) { AutoWeather = false };
        w.Scent[10] = 5f;
        Run(sim, 200);
        Check(w.Scent[10] < 0.01f, $"scent should fade, was {w.Scent[10]}");
    }

    private static void BroodBecomesWorkers()
    {
        var sim = SmallColony(workers: 4, food: 60);
        int before = sim.Ants.Count;
        Run(sim, 200);
        Check(sim.Hatched >= 1, $"at least one worker should hatch, hatched {sim.Hatched}");
        Check(sim.Ants.Count > before, "the colony should grow");
    }

    private static void NoNurseryNoEggs()
    {
        var sim = SmallColony(food: 60, nursery: false);
        Run(sim, 60);
        Check(sim.Brood.Count == 0, "without a nursery the queen cannot lay");
    }

    private static void StarvationShrinksColony()
    {
        var sim = SmallColony(workers: 6, food: 0);
        Run(sim, 60);
        Check(sim.Ants.Count < 6, $"workers should starve, still {sim.Ants.Count}");
        Check(sim.WorkersDied > 0, "deaths should be counted");
    }

    private static void WaterPoolsAtBottom()
    {
        var w = Plain(fill: CellType.Rock);
        w.Carve(10, 1, 10, 10);
        w.Carve(8, 11, 12, 12);
        var sim = new Sim(w, 1) { AutoWeather = false };
        for (int y = 2; y <= 4; y++) w.Water[w.Index(10, y)] = 1f;
        float start = TotalWater(w);
        Run(sim, 5);
        float bottom = 0;
        for (int x = 8; x <= 12; x++) bottom += w.Water[w.Index(x, 12)];
        Check(bottom > 2.5f, $"water should pool in the bottom row, found {bottom:F2}");
        Check(MathF.Abs(TotalWater(w) - start) < 0.01f, "rock soaks nothing up, so water is conserved");
        for (int i = 0; i < w.Water.Length; i++)
            if (!w.IsWalkable(i)) Check(w.Water[i] == 0, "no water inside solid cells");
    }

    private static void WaterSoaksAway()
    {
        var w = Plain(fill: CellType.Sand);
        w.Carve(10, 1, 10, 5);
        var sim = new Sim(w, 1) { AutoWeather = false };
        w.Water[w.Index(10, 5)] = 1f;
        Run(sim, 200);
        Check(TotalWater(w) < 0.2f, $"sand should soak the water up, {TotalWater(w):F2} left");
    }

    private static void RainDrownsLowBrood()
    {
        var w = Plain(fill: CellType.Rock);
        w.Carve(20, 1, 20, 6);
        w.Carve(16, 7, 24, 8, Room.Nursery);
        var sim = new Sim(w, 1) { Food = 100, AutoWeather = false };
        sim.RefreshFields();
        sim.Brood.Add(new Brood { Cell = w.Index(18, 8), Stage = BroodStage.Egg });
        sim.StartRain(60);
        Run(sim, 40);
        Check(sim.BroodDrowned >= 1, "brood at the bottom of a flooded nursery should drown");
    }

    private static void MoundShelters()
    {
        float Inflow(int mound)
        {
            var w = Plain(fill: CellType.Rock);
            w.Carve(20, 1, 20, 20);
            for (int x = 17; x <= 23; x++) w.Mound[x] = mound;
            var sim = new Sim(w, 1) { AutoWeather = false };
            sim.StartRain(10);
            Run(sim, 5);
            return TotalWater(w);
        }
        float open = Inflow(0), sheltered = Inflow(60);
        Check(sheltered < open * 0.7f, $"a mound should cut inflow: open {open:F2}, sheltered {sheltered:F2}");
    }

    private static void RainReachesDefaultNest()
    {
        var sim = Sim.CreateDefault(3);
        sim.AutoWeather = false;
        Run(sim, 5);
        sim.StartRain(25);
        Run(sim, 25);
        var w = sim.World;
        float nursery = 0, sump = 0;
        for (int i = 0; i < w.Water.Length; i++)
        {
            if (w.Rooms[i] == Room.Nursery) nursery += w.Water[i];
            else if (w.Y(i) >= 14) sump += w.Water[i];
        }
        Check(sump > 1f, $"rain should run past the nursery into the sump below it, found {sump:F2}");
        Check(nursery < sump, $"the sump should hold more than the nursery: nursery {nursery:F2}, sump {sump:F2}");
    }

    private static void SameSeedSameColony()
    {
        var a = Sim.CreateDefault(42);
        var b = Sim.CreateDefault(42);
        a.PaintDig(70, 14, 2, true);
        b.PaintDig(70, 14, 2, true);
        Run(a, 120);
        Run(b, 120);
        Check(a.Ants.Count == b.Ants.Count && a.CellsDug == b.CellsDug && a.FoodGathered == b.FoodGathered
              && MathF.Abs(a.Food - b.Food) < 1e-4f, "two runs from the same seed should match");
    }

    private static void SeasonsCycle()
    {
        var sim = SmallColony();
        sim.SeasonLength = 10;
        var seen = new List<Season>();
        for (int t = 0; t < 410; t++)
        {
            sim.Step();
            if (seen.Count == 0 || seen[^1] != sim.Season) seen.Add(sim.Season);
        }
        Check(string.Join(",", seen) == "Spring,Summer,Autumn,Winter,Spring", $"seasons were {string.Join(",", seen)}");
        Check(sim.Year == 2, $"year should be 2, was {sim.Year}");
    }

    private static void DepthTemperature()
    {
        var sim = SmallColony();
        sim.SeasonLength = 100;
        Run(sim, 335);   // deep in winter
        float air = sim.SurfaceTemp, deep = sim.TempAt(sim.World.Index(5, 28));
        Check(air < 0 && deep > air + 5, $"winter: air {air:F1}, deep {deep:F1}");
        var summer = SmallColony();
        summer.SeasonLength = 100;
        Run(summer, 130);
        Check(summer.TempAt(summer.World.Index(5, 28)) < summer.SurfaceTemp, "summer: deep soil should be cooler");
    }

    private static void WinterIsQuiet()
    {
        var sim = SmallColony(workers: 8, food: 60);
        sim.SeasonLength = 60;
        Run(sim, 185);   // into winter
        sim.Brood.Clear();
        int sources = sim.World.Food.Count;
        Run(sim, 40);
        Check(sim.Season == Season.Winter, "should be winter");
        Check(sim.Brood.Count == 0, "no eggs are laid in winter");
        Check(sim.World.Food.Count <= sources, "no new food appears in winter");
        Check(sim.Ants.All(a => sim.World.Y(a.Cell) > 0 || a.Job == AntJob.ReturnHome), "nobody stays out foraging in winter");
    }

    private static void AntsFreezeOnSurface()
    {
        var sim = SmallColony(workers: 1, food: 60);
        sim.SeasonLength = 1000;
        Run(sim, 3300);  // deep winter
        var a = sim.Ants[0];
        a.Cell = sim.World.Index(5, 0);
        a.Job = AntJob.Resting;
        a.Timer = 999;
        Run(sim, SimConfig.ChillDeathSeconds + 5);
        Check(sim.Ants.Count == 0 || sim.WorkersDied > 0, "an ant stuck out in the frost should die");
    }

    private static void SnowMeltFloods()
    {
        var sim = SmallColony(workers: 0, food: 100);
        sim.SeasonLength = 60;
        Run(sim, 190);
        sim.StartRain(30);   // snow in winter
        Run(sim, 30);
        Check(sim.Snow > 0.05f && TotalWater(sim.World) < 0.5f, $"winter rain is snow, not water (snow {sim.Snow:F2})");
        Run(sim, 245 - 220);  // into spring
        Run(sim, 5);
        Check(sim.Season == Season.Spring && TotalWater(sim.World) > 1f, $"spring melt should bring water in, found {TotalWater(sim.World):F2}");
    }

    private static void PrioritiesSteerJobs()
    {
        var dig = SmallColony(workers: 10, food: 5);
        dig.World.Food.Add(new FoodSource { X = 30, Amount = 50, Max = 50 });
        for (int x = 8; x <= 15; x++) dig.PaintDig(x, 7, 0, true);
        dig.Priorities.Forage = 0; dig.Priorities.Nurse = 0; dig.Priorities.Dig = 1;
        Run(dig, 30);
        Check(dig.FoodGathered == 0 && dig.CellsDug > 0, $"dig-only: food {dig.FoodGathered}, dug {dig.CellsDug}");

        var forage = SmallColony(workers: 10, food: 5);
        forage.World.Food.Add(new FoodSource { X = 30, Amount = 50, Max = 50 });
        for (int x = 8; x <= 15; x++) forage.PaintDig(x, 7, 0, true);
        forage.Priorities.Forage = 1; forage.Priorities.Nurse = 0; forage.Priorities.Dig = 0;
        Run(forage, 60);
        Check(forage.CellsDug == 0 && forage.FoodGathered > 0, $"forage-only: food {forage.FoodGathered}, dug {forage.CellsDug}");
    }

    private static void NursesSpeedBrood()
    {
        float Grown(float nurse)
        {
            var sim = SmallColony(workers: 10, food: 200);
            sim.Priorities.Nurse = nurse; sim.Priorities.Forage = 0.01f; sim.Priorities.Dig = 0.01f;
            sim.Brood.Add(new Brood { Cell = sim.World.Index(18, 8) });
            Run(sim, 30);
            return sim.Brood[0].Age;
        }
        float tended = Grown(1f), untended = Grown(0f);
        Check(tended > untended * 1.5f, $"tended brood age {tended:F1} should beat untended {untended:F1}");
    }

    private static void SoldierShare()
    {
        var sim = SmallColony(workers: 6, food: 300);
        sim.Priorities.Soldiers = 1f;
        Run(sim, 200);
        Check(sim.Soldiers > 0 && sim.Workers == 6 - sim.WorkersDied, $"all hatchlings should be soldiers: {sim.Soldiers} soldiers, {sim.Workers} workers");
    }

    private static Sim ForagingColony(int soldiers)
    {
        var sim = SmallColony(workers: 10, food: 5);
        sim.World.Food.Add(new FoodSource { X = 34, Amount = 200, Max = 200 });
        for (int k = 0; k < soldiers; k++) sim.SpawnAnt(sim.World.Index(18 + k % 5, 8), Caste.Soldier);
        Run(sim, 20);
        sim.SpawnSpider(38);
        return sim;
    }

    private static void SpiderCatchesForagers()
    {
        var sim = ForagingColony(0);
        Run(sim, 60);
        Check(sim.WorkersDied > 0, "a spider with nobody to stop it should catch someone");
    }

    private static void SoldiersFightSpider()
    {
        var sim = ForagingColony(8);
        int before = sim.SpidersDrivenOff;
        Run(sim, 90);
        Check(sim.SpidersDrivenOff > before, "eight soldiers should drive the spider off or kill it");
    }

    private static void AlarmTurnsForagersBack()
    {
        var sim = SmallColony(workers: 1, food: 5);
        var a = sim.Ants[0];
        a.Cell = sim.World.Index(24, 0);
        a.Job = AntJob.ForageOut;
        a.Dir = 1;
        sim.World.Alarm[27] = 3f;
        sim.Step();
        Check(a.Job is AntJob.ReturnHome or AntJob.Resting, $"forager should turn back from alarm, job was {a.Job}");
    }

    private static void PaintedTrailLeads()
    {
        int Gathered(bool trail)
        {
            var sim = SmallColony(workers: 8, food: 5);
            sim.World.Food.Add(new FoodSource { X = 4, Amount = 200, Max = 200 });
            if (trail) for (int x = 4; x <= 20; x++) sim.PaintTrail(x, 0);
            Run(sim, 40);
            return sim.FoodGathered;
        }
        int with = Gathered(true), without = Gathered(false);
        Check(with > without, $"a painted trail should bring in more food: {with} with, {without} without");
    }

    private static void AvoidMarkBlocks()
    {
        var sim = SmallColony(workers: 8, food: 5);
        sim.World.Food.Add(new FoodSource { X = 34, Amount = 200, Max = 200 });
        sim.PaintAvoid(26, 0, true);
        Run(sim, 60);
        Check(sim.FoodGathered == 0, $"no forager should pass the avoid mark, gathered {sim.FoodGathered}");
        for (int x = 27; x < 40; x++)
            Check(sim.Ants.All(a => sim.World.Index(x, 0) != a.Cell), "no ant beyond the mark");
    }

    private static void AntsEscapeWater()
    {
        var w = Plain(fill: CellType.Rock);
        w.Carve(20, 1, 20, 6);
        w.Carve(16, 7, 24, 8, Room.Nursery);
        w.Carve(10, 3, 19, 3, Room.Nursery);   // a higher, dry nursery off the shaft
        var sim = new Sim(w, 1) { Food = 100, AutoWeather = false };
        for (int i = 0; i < 4; i++) sim.SpawnAnt(w.Index(17 + i, 8));
        sim.RefreshFields();
        sim.Brood.Add(new Brood { Cell = w.Index(18, 8) });
        for (int x = 16; x <= 24; x++) { w.Water[w.Index(x, 8)] = 1; w.Water[w.Index(x, 7)] = 0.7f; }
        Run(sim, 12);
        Check(sim.BroodDrowned == 0 && sim.World.Y(sim.Brood[0].Cell) == 3, "brood should be carried to the dry nursery");
        Check(sim.Ants.All(a => sim.World.Water[a.Cell] < 0.6f), "ants should climb out of the water");
    }

    private static void NuptialFlight()
    {
        var sim = SmallColony(workers: 50, food: 400);
        sim.SeasonLength = 400;
        Run(sim, 420);   // into summer
        for (int k = 0; k < 4; k++) sim.SpawnAnt(sim.World.Index(18, 8), Caste.Alate).Job = AntJob.AlateWaiting;
        sim.StartRain(5);
        Run(sim, 40);
        Check(sim.QueensFlown >= 4, $"winged queens should fly after a summer rain, flown {sim.QueensFlown}");
        Check(sim.Alates == 0, "no winged queens left behind");
    }

    private static void QueenDrowns()
    {
        var w = Plain(fill: CellType.Rock);
        w.Carve(20, 1, 20, 6);
        w.Carve(16, 7, 24, 8, Room.Nursery);
        var sim = new Sim(w, 1) { Food = 100, AutoWeather = false };
        sim.SpawnAnt(w.Index(20, 3));
        sim.RefreshFields();
        sim.StartRain(400);
        Run(sim, 200);
        Check(!sim.QueenAlive && sim.GameOver != null, "a queen in a sealed, flooding nursery should drown");
    }

    private static void YearReportMade()
    {
        var sim = SmallColony(workers: 6, food: 100);
        sim.SeasonLength = 30;
        Run(sim, 125);
        Check(sim.Report != null && sim.Report.Year == 1, "a report for year 1 should be ready in the second spring");
    }

    private static void YearReportDiag()
    {
        var sim = Sim.CreateDefault(7);
        sim.PaintDig(70, 13, 1, true);
        for (int x = 62; x < 75; x++) sim.PaintDig(x, 13, 0, true);
        for (int m = 1; m <= 75; m++)
        {
            Run(sim, 60);
            if (m % 3 == 0 || sim.GameOver != null)
                Console.WriteLine($"        min {m,2} {sim.Season,-6} {sim.SurfaceTemp,5:F1}C ants {sim.Ants.Count,3} (sol {sim.Soldiers}, alates {sim.Alates}) brood {sim.Brood.Count,2} food {sim.Food,5:F0}/{sim.FoodCapacity:F0} flown {sim.QueensFlown} died {sim.WorkersDied} spiders {sim.Spiders.Count} {sim.GameOver}");
            if (sim.GameOver != null) break;
        }
        foreach (var (t, text) in sim.Log.Skip(Math.Max(0, sim.Log.Count - 12))) Console.WriteLine($"        {t / 60,5:F1}m {text}");
    }

    private static void DefaultColonyRuns()
    {
        var sim = Sim.CreateDefault(7);
        sim.PaintDig(70, 13, 1, true);
        for (int x = 62; x < 75; x++) sim.PaintDig(x, 13, 0, true);
        Run(sim, 600);
        Check(sim.Ants.Count > 0, "the colony should survive ten minutes");
        Check(sim.FoodGathered > 0, "food should be gathered");
        Check(sim.CellsDug > 5, $"digging should happen, dug {sim.CellsDug}");
        Check(!float.IsNaN(sim.Food) && sim.World.Water.All(v => !float.IsNaN(v) && v >= 0), "no NaN or negative values");
    }
}
