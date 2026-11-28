using System;

namespace Undermound.Core;

/// <summary>
/// Breadth-first distance over walkable cells from a set of source cells. Ants step to the
/// neighbour with the smallest distance, so any number of ants share one field.
/// </summary>
public sealed class FlowField
{
    public const int Unreachable = int.MaxValue;

    private readonly World _world;
    private readonly int[] _queue;
    public readonly int[] Dist;
    public int SourceCount { get; private set; }

    private static readonly int[] Dx = { 0, 0, -1, 1 };
    private static readonly int[] Dy = { -1, 1, 0, 0 };

    public FlowField(World world)
    {
        _world = world;
        Dist = new int[world.Cells.Length];
        _queue = new int[world.Cells.Length];
    }

    public void Build(Func<int, bool> isSource)
    {
        Array.Fill(Dist, Unreachable);
        int head = 0, tail = 0;
        SourceCount = 0;
        for (int i = 0; i < Dist.Length; i++)
        {
            if (!_world.IsWalkable(i) || !isSource(i)) continue;
            Dist[i] = 0;
            _queue[tail++] = i;
            SourceCount++;
        }
        while (head < tail)
        {
            int i = _queue[head++];
            int x = _world.X(i), y = _world.Y(i);
            int nd = Dist[i] + 1;
            for (int k = 0; k < 4; k++)
            {
                int nx = x + Dx[k], ny = y + Dy[k];
                if (!_world.InBounds(nx, ny)) continue;
                int n = _world.Index(nx, ny);
                if (Dist[n] != Unreachable || !_world.IsWalkable(n)) continue;
                Dist[n] = nd;
                _queue[tail++] = n;
            }
        }
    }

    public bool Reachable(int i) => Dist[i] != Unreachable;

    /// <summary>The neighbour one step closer to a source, or -1 at a source or when cut off.</summary>
    public int Next(int i, int salt)
    {
        int d = Dist[i];
        if (d == 0 || d == Unreachable) return -1;
        int x = _world.X(i), y = _world.Y(i);
        int best = -1;
        for (int k = 0; k < 4; k++)
        {
            int kk = (k + salt) & 3;
            int nx = x + Dx[kk], ny = y + Dy[kk];
            if (!_world.InBounds(nx, ny)) continue;
            int n = _world.Index(nx, ny);
            if (Dist[n] < d) { best = n; d = Dist[n]; }
        }
        return best;
    }
}
