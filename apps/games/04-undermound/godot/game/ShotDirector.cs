using System;
using System.Collections.Generic;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Screenshot mode: plays a scripted year (a player who digs a granary, a deep nursery with a
/// sump and keeps some soldiers), frames a shot at each moment worth seeing, saves each as a
/// PNG and quits. Started with: -- --shots=DIR
/// </summary>
public partial class ShotDirector : Node
{
    private readonly Main _main;
    private readonly string _dir;
    private readonly List<(string Name, Action Setup)> _steps = new();
    private int _index = -1;
    private int _wait;

    private const int FramesPerShot = 10;

    public ShotDirector(Main main, string dir)
    {
        _main = main;
        _dir = dir;
    }

    private Sim Sim => _main.Sim;
    private CameraRig Rig => _main.Rig;
    private World W => _main.Sim.World;
    private static int Ex => SimConfig.Width / 2;

    public override void _Ready()
    {
        DirAccess.MakeDirRecursiveAbsolute(_dir);
        _main.Pause();
        Sim.Priorities.Soldiers = 0.15f;
        Sim.NextRainIn = 700;   // give the scripted player time to dig the sump before the first rain
        DigPlan(Sim);

        Shot("01-title", () =>
        {
            _main.Hud.ShowTitle();
            Frame(new Vector3(0, -14, 0), 92, -3, bar: false);
        });
        Shot("02-digging", () =>
        {
            _main.Hud.CloseModal();
            _main.FastForward(150);
            int f = FrontierCell();
            Frame(Layout.CellCentre(W.X(f), W.Y(f)) + new Vector3(-1.5f, 0.6f, 0), 14, -3, bar: false);
        });
        Shot("03-spring", () =>
        {
            _main.FastForward(SeasonTime(Season.Spring, 0.75f) - Sim.Time);
            _main.SetScentVisible(true);
            Frame(new Vector3(0, -19, 0), 108, -3, bar: true);
        });
        Shot("04-nest", () =>
        {
            var q = Layout.AntSpot(W, Sim.QueenCell);
            int dir = W.X(Sim.QueenCell) < Ex ? 1 : -1;
            Frame(q + new Vector3(dir * 3f, 1.5f, 0), 13, -4, bar: false);
        });
        Shot("05-spider", () =>
        {
            Sim.SpawnSpider(Ex - 16);
            _main.StepFor(6);
            float s = Sim.Spiders.Count > 0 ? Sim.Spiders[0].X : Ex - 10;
            Frame(new Vector3(s - Ex + 2, 1.6f, 0), 13, -12, dof: true, bar: false);
        });
        Shot("06-winged-queens", () =>
        {
            _main.FastForward(SeasonTime(Season.Summer, 0.55f) - Sim.Time);
            if (Sim.Alates < 4)
            {
                GD.Print($"Only {Sim.Alates} winged queens by mid-summer; adding some for the shot.");
                for (int k = Sim.Alates; k < 6; k++) Sim.SpawnAnt(Sim.QueenCell, Caste.Alate).Job = AntJob.AlateWaiting;
                _main.FastForward(3);
            }
            var q = Layout.AntSpot(W, Sim.QueenCell);
            Frame(q + new Vector3(0, 1.5f, 0), 15, -4, bar: false);
        });
        Shot("07-flight", () =>
        {
            Sim.StartFlight();
            _main.StepFor(5.5f);
            Frame(new Vector3(0, 5f, -3), 24, -6, bar: false);
        });
        Shot("08-trail", () =>
        {
            _main.FastForward(40);
            float food = FarFood();
            int from = (int)food, to = Ex;
            for (int x = Math.Min(from, to); x <= Math.Max(from, to); x++) Sim.PaintTrail(x, 0);
            int beyond = from < to ? from - 6 : from + 6;
            Sim.PaintAvoid(Math.Clamp(beyond, 0, SimConfig.Width - 1), 1, true);
            _main.FastForward(50);
            _main.SetScentVisible(true);
            Frame(new Vector3(from - Ex + (from < to ? 10 : -10), 1.8f, 0), 26, -9, bar: true);
        });
        Shot("09-autumn", () =>
        {
            _main.FastForward(SeasonTime(Season.Autumn, 0.5f) - Sim.Time);
            Frame(new Vector3(-8, -3, -4), 60, -22, bar: false);
        });
        Shot("10-winter", () =>
        {
            _main.FastForward(SeasonTime(Season.Winter, 0.25f) - Sim.Time);
            Sim.StartRain(80);
            _main.FastForward(60);
            Frame(new Vector3(0, -10, -2), 75, -14, bar: false);
        });
        Shot("11-winter-nest", () =>
        {
            Frame(new Vector3(0, -22, 0), 60, -3, bar: true);
        });
        Shot("12-melt", () =>
        {
            _main.FastForward(Sim.YearLength + 25 - Sim.Time);
            Frame(new Vector3(0, -18, 0), 70, -3, bar: true);
        });
        Shot("13-year-report", () =>
        {
            if (Sim.Report != null) _main.Hud.ShowReport(Sim.Report);
            Frame(new Vector3(0, -14, 0), 92, -3, bar: false);
        });
    }

    private void Shot(string name, Action setup) => _steps.Add((name, setup));

    private float SeasonTime(Season s, float progress) => ((int)s + progress) * Sim.SeasonLength;

    private void Frame(Vector3 target, float distance, float pitch, bool dof = false, bool bar = true)
    {
        _main.Hud.SetBarVisible(bar);
        Rig.Target = target;
        Rig.Distance = distance;
        Rig.Pitch = pitch;
        Rig.AutoTilt = false;
        Rig.SetDepthOfField(dof, distance);
        Rig.Apply();
    }

    private int FrontierCell()
    {
        for (int i = 0; i < W.Cells.Length; i++)
            if (Sim.ToDig.Dist[i] == 0) return i;
        return W.Index(Ex, 10);
    }

    private float FarFood()
    {
        float best = Ex - 30;
        float bestD = 0;
        foreach (var f in W.Food)
        {
            float d = Math.Abs(f.X - Ex);
            if (d > bestD && d < 60) { bestD = d; best = f.X; }
        }
        return best;
    }

    /// <summary>
    /// A sensible nest: a gallery to a big granary on the left, a deep shaft to a nursery with a
    /// sump below it, and a store branch on the right.
    /// </summary>
    private static void DigPlan(Sim sim)
    {
        int ex = Ex;
        DigLine(sim, ex - 6, 13, ex - 22, 22);
        for (int y = 20; y <= 25; y++)
        for (int x = ex - 34; x <= ex - 22; x++) sim.PaintDig(x, y, 0, true);
        for (int y = 20; y <= 25; y++)
        for (int x = ex - 34; x <= ex - 22; x++) sim.PaintRoom(x, y, 0, Room.Store);
        for (int y = 14; y <= 31; y++) sim.PaintDig(ex, y, 0, true);
        for (int y = 32; y <= 35; y++)
        for (int x = ex - 7; x <= ex + 7; x++) sim.PaintDig(x, y, 0, true);
        for (int y = 33; y <= 35; y++)
        for (int x = ex - 7; x <= ex + 7; x++) sim.PaintRoom(x, y, 0, Room.Nursery);
        // The sump: a pit below the far end of the nursery that the water reaches first.
        for (int y = 36; y <= 41; y++) sim.PaintDig(ex + 7, y, 0, true);
        for (int y = 40; y <= 42; y++)
        for (int x = ex + 5; x <= ex + 12; x++) sim.PaintDig(x, y, 0, true);
        DigLine(sim, ex + 12, 6, ex + 26, 12);
        for (int y = 11; y <= 14; y++)
        for (int x = ex + 26; x <= ex + 34; x++) sim.PaintDig(x, y, 0, true);
        for (int y = 12; y <= 14; y++)
        for (int x = ex + 26; x <= ex + 34; x++) sim.PaintRoom(x, y, 0, Room.Store);
    }

    /// <summary>Order a tunnel from one cell to another as a connected staircase.</summary>
    private static void DigLine(Sim sim, int x0, int y0, int x1, int y1)
    {
        int x = x0, y = y0;
        sim.PaintDig(x, y, 0, true);
        while (x != x1 || y != y1)
        {
            float tx = x1 == x0 ? 1 : (float)(x - x0) / (x1 - x0);
            float ty = y1 == y0 ? 1 : (float)(y - y0) / (y1 - y0);
            if (x != x1 && (tx <= ty || y == y1)) x += Math.Sign(x1 - x0);
            else y += Math.Sign(y1 - y0);
            sim.PaintDig(x, y, 0, true);
        }
    }

    public override void _Process(double delta)
    {
        if (_wait > 0)
        {
            _wait--;
            if (_wait == 0) Capture();
            return;
        }
        _index++;
        if (_index >= _steps.Count)
        {
            GD.Print($"Done: year {Sim.Year}, {Sim.Ants.Count} ants, {Sim.QueensFlown} queens flown, game over: {Sim.GameOver ?? "no"}");
            GetTree().Quit();
            return;
        }
        _steps[_index].Setup();
        _wait = FramesPerShot;
    }

    private void Capture()
    {
        string path = $"{_dir}/{_steps[_index].Name}.png";
        GetViewport().GetTexture().GetImage().SavePng(path);
        GD.Print($"Saved {path}  ({Sim.Season} y{Sim.Year}, {Sim.Ants.Count} ants, food {Sim.Food:0}/{Sim.FoodCapacity:0}, alates {Sim.Alates}, flown {Sim.QueensFlown})");
    }
}
