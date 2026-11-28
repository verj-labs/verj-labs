using Godot;

namespace Undermound.Game;

/// <summary>Builds the procedural meshes: the ant, brood, food, grass, pebbles.</summary>
public static class MeshKit
{
    // UV2.x marks leg vertices (1) for the walk animation; UV2.y is the tripod group (0 or 1).

    public static ArrayMesh Ant()
    {
        var st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        var body = Palette.AntBody;
        // Gaster (abdomen), petiole, thorax, head.
        Ellipsoid(st, new Vector3(-0.25f, 0.17f, 0), new Vector3(0.21f, 0.15f, 0.14f), body);
        Ellipsoid(st, new Vector3(-0.065f, 0.15f, 0), new Vector3(0.045f, 0.045f, 0.04f), body);
        Ellipsoid(st, new Vector3(0.05f, 0.17f, 0), new Vector3(0.12f, 0.065f, 0.065f), body);
        Ellipsoid(st, new Vector3(0.235f, 0.18f, 0), new Vector3(0.085f, 0.075f, 0.075f), body);
        // Mandibles.
        for (int s = -1; s <= 1; s += 2)
            Tube(st, new Vector3(0.3f, 0.15f, 0.03f * s), new Vector3(0.36f, 0.13f, 0.012f * s), 0.014f, body);
        // Elbowed antennae.
        for (int s = -1; s <= 1; s += 2)
        {
            var root = new Vector3(0.28f, 0.22f, 0.035f * s);
            var elbow = new Vector3(0.34f, 0.3f, 0.07f * s);
            var tip = new Vector3(0.44f, 0.23f, 0.1f * s);
            Tube(st, root, elbow, 0.014f, Palette.AntLeg);
            Tube(st, elbow, tip, 0.013f, Palette.AntLeg);
        }
        // Six legs: hip on the thorax, knee up and out, foot down on the floor.
        float[] hipX = { 0.12f, 0.05f, -0.02f };
        float[] reach = { 0.13f, 0.0f, -0.16f };
        for (int pair = 0; pair < 3; pair++)
        for (int s = -1; s <= 1; s += 2)
        {
            float group = (pair % 2 == 0) == (s > 0) ? 0f : 1f;
            var hip = new Vector3(hipX[pair], 0.14f, 0.05f * s);
            var knee = new Vector3(hipX[pair] + reach[pair] * 0.5f, 0.2f, 0.14f * s);
            var foot = new Vector3(hipX[pair] + reach[pair] * 0.85f, 0.0f, 0.2f * s);
            Tube(st, hip, knee, 0.022f, Palette.AntLeg, 1f, group);
            Tube(st, knee, foot, 0.017f, Palette.AntLeg, 1f, group);
        }
        return st.Commit();
    }

    public static ArrayMesh Blob(Vector3 radii, Color color, int rings = 8, int segments = 12)
    {
        var st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        Ellipsoid(st, Vector3.Zero, radii, color, rings, segments);
        return st.Commit();
    }

    /// <summary>A blackberry-like cluster of drupelets.</summary>
    public static ArrayMesh Berry()
    {
        var st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        Ellipsoid(st, Vector3.Zero, new Vector3(0.9f, 0.9f, 0.9f), Palette.Berry * 0.7f, 10, 14);
        var rng = new RandomNumberGenerator { Seed = 11 };
        for (int k = 0; k < 70; k++)
        {
            var dir = new Vector3(rng.RandfRange(-1, 1), rng.RandfRange(-1, 1), rng.RandfRange(-1, 1)).Normalized();
            Ellipsoid(st, dir * 0.88f, new Vector3(0.2f, 0.2f, 0.2f), Palette.Berry * rng.RandfRange(0.85f, 1.15f), 5, 7);
        }
        return st.Commit();
    }

    /// <summary>A rough bread crumb: a lumpy box of blobs.</summary>
    public static ArrayMesh Crumb()
    {
        var st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        var rng = new RandomNumberGenerator { Seed = 5 };
        for (int k = 0; k < 9; k++)
        {
            var c = new Vector3(rng.RandfRange(-0.5f, 0.5f), rng.RandfRange(-0.3f, 0.3f), rng.RandfRange(-0.5f, 0.5f));
            var r = new Vector3(rng.RandfRange(0.35f, 0.6f), rng.RandfRange(0.3f, 0.5f), rng.RandfRange(0.35f, 0.6f));
            Ellipsoid(st, c, r, Palette.Crumb * rng.RandfRange(0.85f, 1.1f), 6, 8);
        }
        return st.Commit();
    }

    /// <summary>A small heap of seeds.</summary>
    public static ArrayMesh Seeds()
    {
        var st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        var rng = new RandomNumberGenerator { Seed = 9 };
        for (int k = 0; k < 28; k++)
        {
            float a = rng.RandfRange(0, Mathf.Tau), d = rng.RandfRange(0, 0.8f);
            var c = new Vector3(Mathf.Cos(a) * d, 0.12f + (0.8f - d) * 0.35f + rng.RandfRange(0, 0.1f), Mathf.Sin(a) * d);
            Ellipsoid(st, c, new Vector3(0.22f, 0.11f, 0.13f), Palette.Seed * rng.RandfRange(0.8f, 1.2f), 5, 8);
        }
        return st.Commit();
    }

    /// <summary>A grass blade: tapered, gently curved, in a few segments, rooted at the origin.</summary>
    public static ArrayMesh GrassBlade()
    {
        var st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        const int segs = 5;
        for (int i = 0; i < segs; i++)
        {
            float t0 = i / (float)segs, t1 = (i + 1) / (float)segs;
            Vector3 P(float t, float side) =>
                new(side * 0.5f * (1 - t), t, 0.25f * t * t);
            var a = P(t0, -1); var b = P(t0, 1); var c = P(t1, 1); var d = P(t1, -1);
            var n = new Vector3(0, -0.3f, 1).Normalized();
            Quad(st, a, b, c, d, n, Colors.White, Colors.White, Colors.White, Colors.White);
        }
        return st.Commit();
    }

    public static ArrayMesh Pebble()
    {
        var st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        Ellipsoid(st, Vector3.Zero, new Vector3(1f, 0.55f, 0.8f), Colors.White, 7, 10);
        return st.Commit();
    }

    // ---------- primitives ----------

    public static void Ellipsoid(SurfaceTool st, Vector3 c, Vector3 r, Color color, int rings = 8, int segments = 12,
        float leg = 0, float group = 0)
    {
        Vector3 P(int ring, int seg)
        {
            float v = Mathf.Pi * ring / rings, u = Mathf.Tau * seg / segments;
            return new Vector3(Mathf.Cos(v), Mathf.Sin(v) * Mathf.Cos(u), Mathf.Sin(v) * Mathf.Sin(u));
        }
        for (int i = 0; i < rings; i++)
        for (int j = 0; j < segments; j++)
        {
            var s00 = P(i, j); var s10 = P(i + 1, j); var s11 = P(i + 1, j + 1); var s01 = P(i, j + 1);
            Vertex(st, c + s00 * r, (s00 / r).Normalized(), color, leg, group);
            Vertex(st, c + s10 * r, (s10 / r).Normalized(), color, leg, group);
            Vertex(st, c + s11 * r, (s11 / r).Normalized(), color, leg, group);
            Vertex(st, c + s00 * r, (s00 / r).Normalized(), color, leg, group);
            Vertex(st, c + s11 * r, (s11 / r).Normalized(), color, leg, group);
            Vertex(st, c + s01 * r, (s01 / r).Normalized(), color, leg, group);
        }
    }

    public static void Tube(SurfaceTool st, Vector3 a, Vector3 b, float radius, Color color, float leg = 0, float group = 0)
    {
        const int sides = 6;
        var axis = (b - a).Normalized();
        var side = axis.Cross(Mathf.Abs(axis.Y) < 0.9f ? Vector3.Up : Vector3.Right).Normalized();
        var up = axis.Cross(side).Normalized();
        for (int k = 0; k < sides; k++)
        {
            float a0 = Mathf.Tau * k / sides, a1 = Mathf.Tau * (k + 1) / sides;
            var n0 = side * Mathf.Cos(a0) + up * Mathf.Sin(a0);
            var n1 = side * Mathf.Cos(a1) + up * Mathf.Sin(a1);
            Vertex(st, a + n0 * radius, n0, color, leg, group);
            Vertex(st, b + n0 * radius * 0.8f, n0, color, leg, group);
            Vertex(st, b + n1 * radius * 0.8f, n1, color, leg, group);
            Vertex(st, a + n0 * radius, n0, color, leg, group);
            Vertex(st, b + n1 * radius * 0.8f, n1, color, leg, group);
            Vertex(st, a + n1 * radius, n1, color, leg, group);
        }
    }

    public static void Quad(SurfaceTool st, Vector3 a, Vector3 b, Vector3 c, Vector3 d, Vector3 n,
        Color ca, Color cb, Color cc, Color cd)
    {
        Vertex(st, a, n, ca); Vertex(st, b, n, cb); Vertex(st, c, n, cc);
        Vertex(st, a, n, ca); Vertex(st, c, n, cc); Vertex(st, d, n, cd);
    }

    private static void Vertex(SurfaceTool st, Vector3 p, Vector3 n, Color color, float leg = 0, float group = 0)
    {
        st.SetNormal(n);
        st.SetColor(color);
        st.SetUV2(new Vector2(leg, group));
        st.AddVertex(p);
    }
}
