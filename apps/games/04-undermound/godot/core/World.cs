using System;
using System.Collections.Generic;

namespace Undermound.Core;

public enum CellType : byte { Air, Tunnel, Topsoil, Clay, Sand, Rock }

public enum Room : byte { None, Nursery, Store }

public enum FoodKind : byte { Berry, Crumb, Seeds, Insect }

public sealed class FoodSource
{
    public float X;
    public int Amount;
    public int Max;
    public FoodKind Kind;
    public float Radius => 1f + 1.5f * MathF.Sqrt(Max / 60f);
}

/// <summary>
/// The cross-section of the ant farm. Row 0 is the surface lane (always walkable air);
/// rows 1..SoilRows are soil. Index = y * Width + x.
/// </summary>
public sealed class World
{
    public const int ChunkSize = 16;

    public readonly int Width;
    public readonly int Height;
    public readonly CellType[] Cells;
    /// <summary>What each cell was made of before it was dug (for drawing tunnel walls).</summary>
    public readonly CellType[] Base;
    public readonly bool[] DigOrder;
    public readonly float[] DigProgress;
    public readonly Room[] Rooms;
    public readonly float[] Water;
    public readonly float[] Scent;     // per surface column: food trails laid by foragers
    public readonly float[] Guide;     // per surface column: trails painted by the player
    public readonly bool[] Avoid;      // per surface column: places the player told ants to avoid
    public readonly float[] Alarm;     // per surface column: alarm scent where ants were attacked
    public readonly int[] Mound;       // soil pellets piled per surface column
    public readonly List<FoodSource> Food = new();

    /// <summary>Bumped when a chunk's cells change, so the view rebuilds only that chunk.</summary>
    public readonly int[] ChunkVersion;
    public readonly int ChunksX;
    public readonly int ChunksY;

    /// <summary>Bumped when anything that the flow fields depend on changes.</summary>
    public int LayoutVersion { get; private set; }
    public int OrdersVersion { get; private set; }

    public World(int width, int height)
    {
        Width = width;
        Height = height;
        int n = width * height;
        Cells = new CellType[n];
        Base = new CellType[n];
        DigOrder = new bool[n];
        DigProgress = new float[n];
        Rooms = new Room[n];
        Water = new float[n];
        Scent = new float[width];
        Guide = new float[width];
        Avoid = new bool[width];
        Alarm = new float[width];
        Mound = new int[width];
        ChunksX = (width + ChunkSize - 1) / ChunkSize;
        ChunksY = (height + ChunkSize - 1) / ChunkSize;
        ChunkVersion = new int[ChunksX * ChunksY];
    }

    public int Index(int x, int y) => y * Width + x;
    public int X(int i) => i % Width;
    public int Y(int i) => i / Width;
    public bool InBounds(int x, int y) => x >= 0 && y >= 0 && x < Width && y < Height;

    public bool IsWalkable(int i) => Cells[i] == CellType.Air || Cells[i] == CellType.Tunnel;
    public bool IsWalkable(int x, int y) => InBounds(x, y) && IsWalkable(Index(x, y));

    public static bool IsDiggable(CellType m) => m is CellType.Topsoil or CellType.Clay or CellType.Sand;

    public static float Hardness(CellType m) => m switch
    {
        CellType.Topsoil => SimConfig.TopsoilHardness,
        CellType.Clay => SimConfig.ClayHardness,
        CellType.Sand => SimConfig.SandHardness,
        _ => float.PositiveInfinity,
    };

    public static float Absorbency(CellType m) => m switch
    {
        CellType.Sand => SimConfig.SandAbsorb,
        CellType.Topsoil => SimConfig.TopsoilAbsorb,
        CellType.Clay => SimConfig.ClayAbsorb,
        _ => SimConfig.RockAbsorb,
    };

    public void SetMaterial(int i, CellType m)
    {
        if (Cells[i] == m) return;
        Cells[i] = m;
        TouchChunk(i);
        LayoutVersion++;
    }

    public void SetDigOrder(int i, bool on)
    {
        if (on && !IsDiggable(Cells[i])) return;
        if (DigOrder[i] == on) return;
        DigOrder[i] = on;
        if (!on) DigProgress[i] = 0;
        OrdersVersion++;
    }

    public void SetRoom(int i, Room room)
    {
        if (Y(i) == 0 || Cells[i] == CellType.Rock) return;
        if (Rooms[i] == room) return;
        Rooms[i] = room;
        TouchChunk(i);
        OrdersVersion++;
    }

    private void TouchChunk(int i)
    {
        int cx = X(i) / ChunkSize, cy = Y(i) / ChunkSize;
        ChunkVersion[cy * ChunksX + cx]++;
        // Neighbouring chunks draw walls against this cell, so touch them at the edges.
        int lx = X(i) % ChunkSize, ly = Y(i) % ChunkSize;
        if (lx == 0 && cx > 0) ChunkVersion[cy * ChunksX + cx - 1]++;
        if (lx == ChunkSize - 1 && cx < ChunksX - 1) ChunkVersion[cy * ChunksX + cx + 1]++;
        if (ly == 0 && cy > 0) ChunkVersion[(cy - 1) * ChunksX + cx]++;
        if (ly == ChunkSize - 1 && cy < ChunksY - 1) ChunkVersion[(cy + 1) * ChunksX + cx]++;
    }

    /// <summary>Surface columns where a tunnel opens to the surface.</summary>
    public IEnumerable<int> Openings()
    {
        for (int x = 0; x < Width; x++)
            if (Cells[Index(x, 1)] == CellType.Tunnel) yield return x;
    }

    public int CountRoomCells(Room room)
    {
        int n = 0;
        for (int i = Width; i < Cells.Length; i++)
            if (Rooms[i] == room && Cells[i] == CellType.Tunnel) n++;
        return n;
    }

    public FoodSource? FoodAt(float x)
    {
        foreach (var f in Food)
            if (f.Amount > 0 && MathF.Abs(f.X - x) <= f.Radius) return f;
        return null;
    }

    /// <summary>Soil layers with noise, sand pockets and rocks.</summary>
    public void Generate(int seed)
    {
        var rng = new Rng((ulong)seed * 2654435761UL + 1);
        for (int y = 0; y < Height; y++)
        for (int x = 0; x < Width; x++)
        {
            int i = Index(x, y);
            if (y == 0) { Cells[i] = CellType.Air; continue; }
            float wobble = (Rng.ValueNoise(x * 0.08f, 0, seed) - 0.5f) * 6f;
            float depth = y + wobble;
            float blob = Rng.ValueNoise(x * 0.12f, y * 0.12f, seed + 7);
            CellType m;
            if (depth < 10) m = blob > 0.78f ? CellType.Sand : CellType.Topsoil;
            else if (depth < 40) m = blob > 0.72f ? CellType.Sand : CellType.Clay;
            else if (depth < 66) m = blob > 0.68f ? CellType.Clay : CellType.Sand;
            else m = blob > 0.7f ? CellType.Rock : CellType.Clay;
            Cells[i] = m;
        }

        // Rocks and pebbles.
        int rocks = Width * Height / 400;
        for (int r = 0; r < rocks; r++)
        {
            int cx = rng.Range(0, Width), cy = rng.Range(4, Height);
            int rad = rng.Chance(0.6f) ? 1 : rng.Range(2, 5);
            for (int dy = -rad; dy <= rad; dy++)
            for (int dx = -rad; dx <= rad; dx++)
            {
                int x = cx + dx, y = cy + dy;
                if (!InBounds(x, y) || y < 2) continue;
                if (dx * dx + dy * dy <= rad * rad + 1) Cells[Index(x, y)] = CellType.Rock;
            }
        }
        Array.Copy(Cells, Base, Cells.Length);
        LayoutVersion++;
        for (int c = 0; c < ChunkVersion.Length; c++) ChunkVersion[c]++;
    }

    /// <summary>Dig out a rectangle immediately (used for the starter nest and tests).</summary>
    public void Carve(int x0, int y0, int x1, int y1, Room room = Room.None)
    {
        for (int y = y0; y <= y1; y++)
        for (int x = x0; x <= x1; x++)
        {
            if (!InBounds(x, y) || y == 0) continue;
            int i = Index(x, y);
            SetMaterial(i, CellType.Tunnel);
            if (room != Room.None) Rooms[i] = room;
        }
        OrdersVersion++;
    }
}
