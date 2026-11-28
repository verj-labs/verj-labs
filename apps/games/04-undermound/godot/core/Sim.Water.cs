using System;

namespace Undermound.Core;

/// <summary>Water: rain and meltwater run into the openings, fall, spread, pool and soak away.</summary>
public sealed partial class Sim
{
    private bool _sweepLeft;

    private void UpdateWater(float dt)
    {
        var w = World;
        var water = w.Water;
        int width = w.Width, height = w.Height;

        float perOpening = 0;
        if (Raining && !Snowing) perOpening += SimConfig.RainPerOpeningPerSecond;
        if (Melting) perOpening += SimConfig.MeltPerOpeningPerSecond;
        if (perOpening > 0)
        {
            foreach (int x in w.Openings())
            {
                int shelter = 0;
                for (int dx = -SimConfig.RainCatchCells; dx <= SimConfig.RainCatchCells; dx++)
                    if (x + dx >= 0 && x + dx < width) shelter += w.Mound[x + dx];
                water[w.Index(x, 1)] += perOpening * dt / (1f + shelter / SimConfig.MoundShelter);
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
            if (water[i] <= 0.001f) continue;
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

        // Soil soaks water up, in proportion to the water present.
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
            water[i] -= water[i] * SimConfig.AbsorbFraction * soak * dt;
            if (water[i] < 0.002f) water[i] = 0;
        }
    }
}
