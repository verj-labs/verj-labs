using System;

namespace Undermound.Core;

/// <summary>Small deterministic random generator (xorshift), so runs repeat from a seed.</summary>
public sealed class Rng
{
    private ulong _state;

    public Rng(ulong seed) => _state = seed == 0 ? 0x9E3779B97F4A7C15UL : seed;

    public ulong NextULong()
    {
        _state ^= _state << 13;
        _state ^= _state >> 7;
        _state ^= _state << 17;
        return _state;
    }

    /// <summary>A float in [0, 1).</summary>
    public float NextFloat() => (NextULong() >> 40) / (float)(1UL << 24);

    /// <summary>An int in [min, max).</summary>
    public int Range(int min, int max) => max <= min ? min : min + (int)(NextULong() % (ulong)(max - min));

    public float Range(float min, float max) => min + (max - min) * NextFloat();

    public bool Chance(float p) => NextFloat() < p;

    /// <summary>Smooth value noise in [0, 1] for terrain, from integer hashing.</summary>
    public static float ValueNoise(float x, float y, int seed)
    {
        int x0 = (int)MathF.Floor(x), y0 = (int)MathF.Floor(y);
        float fx = x - x0, fy = y - y0;
        float sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy);
        float a = Hash(x0, y0, seed), b = Hash(x0 + 1, y0, seed);
        float c = Hash(x0, y0 + 1, seed), d = Hash(x0 + 1, y0 + 1, seed);
        return Lerp(Lerp(a, b, sx), Lerp(c, d, sx), sy);
    }

    public static float Hash(int x, int y, int seed)
    {
        unchecked
        {
            uint h = (uint)(x * 374761393 + y * 668265263 + seed * 982451653);
            h = (h ^ (h >> 13)) * 1274126177;
            h ^= h >> 16;
            return (h & 0xFFFFFF) / (float)0x1000000;
        }
    }

    private static float Lerp(float a, float b, float t) => a + (b - a) * t;
}
