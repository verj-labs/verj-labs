using System;
using System.Collections.Generic;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Screenshot mode: digs a scripted nest, runs the colony for a while, then frames a series of
/// shots and saves each as a PNG before quitting. Started with: -- --shots=DIR
/// </summary>
public partial class ShotDirector : Node
{
    private readonly Main _main;
    private readonly string _dir;
    private readonly List<(string Name, Action Setup)> _shots = new();
    private int _index = -1;
    private int _wait;

    private const int FramesPerShot = 8;

    public ShotDirector(Main main, string dir)
    {
        _main = main;
        _dir = dir;
    }

    public override void _Ready()
    {
        DirAccess.MakeDirRecursiveAbsolute(_dir);
        _main.Pause();
        var sim = _main.Sim;
        sim.AutoWeather = false;
        DigScriptedNest(sim);
        _main.FastForward(900);
        GD.Print($"After 15 minutes: {sim.Ants.Count} workers, {sim.Brood.Count} brood, food {sim.Food:0}, dug {sim.CellsDug}");

        var rig = _main.Rig;
        _shots.Add(("01-overview", () =>
        {
            _main.Hud.SetBarVisible(true);
            _main.SetScentVisible(true);
            Frame(rig, new Vector3(0, -21, 0), 112, -3);
        }));
        _shots.Add(("02-nest", () =>
        {
            _main.Hud.SetBarVisible(false);
            var q = Layout.AntSpot(sim.World, sim.QueenCell);
            int dir = sim.World.X(sim.QueenCell) < SimConfig.Width / 2 ? 1 : -1;
            Frame(rig, q + new Vector3(dir * 3.5f, 1.6f, 0), 14, -4);
        }));
        _shots.Add(("03-surface", () =>
        {
            float x = BusiestSurfaceX(sim);
            Frame(rig, new Vector3(x, 1.4f, 0), 10, -12, dof: true);
        }));
        _shots.Add(("04-digging", () =>
        {
            int x0 = 104, y0 = 8;
            DigLine(sim, x0 - 2, 6, x0 + 10, y0 + 6);
            _main.FastForward(60);
            int fx = x0, fy = y0;
            for (int i = 0; i < sim.World.Cells.Length; i++)
                if (sim.World.DigOrder[i] && sim.ToDig.Reachable(i) || sim.ToDig.Dist[i] == 0) { fx = sim.World.X(i); fy = sim.World.Y(i); break; }
            Frame(rig, Layout.CellCentre(fx, fy) + new Vector3(-1, 0.5f, 0), 13, -3);
        }));
        _shots.Add(("05-rain", () =>
        {
            sim.StartRain(45);
            _main.FastForward(25);
            _main.SnapWeatherLook();
            float water = 0, max = 0;
            foreach (float v in sim.World.Water) { water += v; max = Mathf.Max(max, v); }
            GD.Print($"Rain shot: water {water:F1} (deepest cell {max:F2}), mound {System.Linq.Enumerable.Sum(sim.World.Mound)}");
            Frame(rig, new Vector3(0, -17, 0), 62, -3);
        }));
        _shots.Add(("06-hero", () =>
        {
            Frame(rig, new Vector3(-6, -4, -4), 62, -24, autoTilt: false);
        }));
    }

    private static void Frame(CameraRig rig, Vector3 target, float distance, float pitch, bool dof = false, bool autoTilt = false)
    {
        rig.Target = target;
        rig.Distance = distance;
        rig.Pitch = pitch;
        rig.AutoTilt = autoTilt;
        rig.SetDepthOfField(dof, distance);
        rig.Apply();
    }

    /// <summary>A nest plan: a gallery to a big store on the left, a deep shaft to a nursery, a branch to the right.</summary>
    private static void DigScriptedNest(Sim sim)
    {
        int ex = SimConfig.Width / 2;
        // Left: a sloping gallery to a second food store.
        DigLine(sim, ex - 6, 13, ex - 22, 22);
        for (int y = 21; y <= 24; y++)
        for (int x = ex - 30; x <= ex - 22; x++) sim.PaintDig(x, y, 0, true);
        sim.PaintRoom(ex - 26, 22, 3, Room.Store);
        // Down: a shaft to a deep nursery.
        for (int y = 14; y <= 31; y++) sim.PaintDig(ex, y, 0, true);
        for (int y = 32; y <= 35; y++)
        for (int x = ex - 7; x <= ex + 7; x++) sim.PaintDig(x, y, 0, true);
        sim.PaintRoom(ex, 33, 4, Room.Nursery);
        for (int dx = -7; dx <= 7; dx += 7) sim.PaintRoom(ex + dx, 34, 1, Room.Nursery);
        // Right: a gallery off the food store.
        for (int x = ex + 12; x <= ex + 22; x++) sim.PaintDig(x, 6, 0, true);
    }

    /// <summary>Order a tunnel from one cell to another as a connected staircase.</summary>
    private static void DigLine(Sim sim, int x0, int y0, int x1, int y1)
    {
        int x = x0, y = y0;
        sim.PaintDig(x, y, 0, true);
        while (x != x1 || y != y1)
        {
            // Step along whichever axis is further behind, so every cell touches the last.
            float tx = x1 == x0 ? 1 : (float)(x - x0) / (x1 - x0);
            float ty = y1 == y0 ? 1 : (float)(y - y0) / (y1 - y0);
            if (x != x1 && (tx <= ty || y == y1)) x += System.Math.Sign(x1 - x0);
            else y += System.Math.Sign(y1 - y0);
            sim.PaintDig(x, y, 0, true);
        }
    }

    private static float BusiestSurfaceX(Sim sim)
    {
        var w = sim.World;
        int best = w.Width / 2;
        float bestScore = -1;
        foreach (var f in w.Food)
        {
            int x = (int)f.X;
            float score = 0;
            for (int k = -12; k <= 12; k++)
                if (x + k >= 0 && x + k < w.Width) score += w.Scent[x + k];
            if (score > bestScore) { bestScore = score; best = x; }
        }
        // Stand a little toward the nest from the food, so both food and the trail are in view.
        int dir = best < w.Width / 2 ? 1 : -1;
        return best + dir * 4 - w.Width / 2f;
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
        if (_index >= _shots.Count)
        {
            GetTree().Quit();
            return;
        }
        _shots[_index].Setup();
        _wait = FramesPerShot;
    }

    private void Capture()
    {
        string path = $"{_dir}/{_shots[_index].Name}.png";
        GetViewport().GetTexture().GetImage().SavePng(path);
        GD.Print($"Saved {path}");
    }
}
