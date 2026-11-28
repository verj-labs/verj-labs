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
        ("rain: water reaches the bottom of the default nest", RainReachesDefaultNest),
        ("determinism: the same seed gives the same colony", SameSeedSameColony),
        ("default colony: runs ten minutes without breaking", DefaultColonyRuns),
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
        float total = TotalWater(w);
        float nursery = 0;
        for (int i = 0; i < w.Water.Length; i++) if (w.Rooms[i] == Room.Nursery) nursery += w.Water[i];
        Console.WriteLine($"        water in nest {total:F2}, in nursery {nursery:F2}, mound {w.Mound.Sum()}");
        Check(nursery > 1f, $"rain should pool in the nursery at the bottom of the shaft, found {nursery:F2}");
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
