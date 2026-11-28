using System.Collections.Generic;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Draws the soil slab of the ant farm: the cut face of the soil at the front, hollow tunnels
/// with walls and a darker back wall, and a wooden frame. Built in chunks; a chunk is rebuilt
/// only when its cells change.
/// </summary>
public partial class SoilView : Node3D
{
    private World _world = null!;
    private MeshInstance3D[] _chunks = null!;
    private int[] _built = null!;
    private StandardMaterial3D _material = null!;

    private readonly List<Vector3> _v = new();
    private readonly List<Vector3> _n = new();
    private readonly List<Color> _c = new();

    public void Init(World world)
    {
        _world = world;
        _chunks = new MeshInstance3D[world.ChunksX * world.ChunksY];
        _built = new int[_chunks.Length];
        System.Array.Fill(_built, -1);
        _material = new StandardMaterial3D
        {
            VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true,
            Roughness = 0.95f,
            CullMode = BaseMaterial3D.CullModeEnum.Disabled,
            AlbedoTexture = GrainTexture(),
            Uv1Triplanar = true,
            Uv1Scale = new Vector3(0.35f, 0.35f, 0.35f),
        };
        for (int k = 0; k < _chunks.Length; k++)
        {
            _chunks[k] = new MeshInstance3D
            {
                MaterialOverride = _material,
                // The slab would shade every tunnel; let light in so the nest reads clearly.
                CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
            };
            AddChild(_chunks[k]);
        }
        BuildFrame();
        Refresh();
    }

    public void Refresh()
    {
        for (int k = 0; k < _chunks.Length; k++)
        {
            if (_built[k] == _world.ChunkVersion[k]) continue;
            _built[k] = _world.ChunkVersion[k];
            BuildChunk(k);
        }
    }

    private static NoiseTexture2D GrainTexture()
    {
        var gradient = new Gradient();
        gradient.SetColor(0, new Color(0.78f, 0.78f, 0.78f));
        gradient.SetColor(1, new Color(1.12f, 1.12f, 1.12f));
        return new NoiseTexture2D
        {
            Width = 256,
            Height = 256,
            Seamless = true,
            ColorRamp = gradient,
            Noise = new FastNoiseLite { Frequency = 0.08f, FractalOctaves = 4 },
        };
    }

    private void BuildChunk(int k)
    {
        _v.Clear(); _n.Clear(); _c.Clear();
        int cx = k % _world.ChunksX, cy = k / _world.ChunksX;
        int x0 = cx * World.ChunkSize, y0 = cy * World.ChunkSize;
        for (int y = y0; y < y0 + World.ChunkSize && y < _world.Height; y++)
        for (int x = x0; x < x0 + World.ChunkSize && x < _world.Width; x++)
        {
            if (y == 0) continue;
            int i = _world.Index(x, y);
            if (_world.Cells[i] == CellType.Tunnel) AddTunnel(x, y, i);
            else AddSolid(x, y, i);
        }
        if (_v.Count == 0) { _chunks[k].Mesh = null; return; }
        var arrays = new Godot.Collections.Array();
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = _v.ToArray();
        arrays[(int)Mesh.ArrayType.Normal] = _n.ToArray();
        arrays[(int)Mesh.ArrayType.Color] = _c.ToArray();
        var mesh = new ArrayMesh();
        mesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);
        _chunks[k].Mesh = mesh;
    }

    // Colour of a cell corner: soil colour, grain, strata bands and darkening with depth.
    private Color CornerColour(CellType m, int cx, int cy, float shade)
    {
        var baseColour = Blend(cx, cy, m);
        float grain = 0.6f * Rng.ValueNoise(cx * 0.35f, cy * 0.35f, 3) + 0.4f * Rng.Hash(cx, cy, 5);
        float band = 1f + 0.06f * Mathf.Sin(cy * 1.3f + 4f * Rng.ValueNoise(cx * 0.05f, 0, 9));
        float depth = 1f - 0.32f * cy / _world.Height;
        float f = (0.8f + 0.4f * grain) * band * depth * shade;
        if (m == CellType.Rock) f *= 0.85f + 0.4f * Rng.Hash(cx * 3, cy * 7, 2);
        return new Color(baseColour.R * f, baseColour.G * f, baseColour.B * f);
    }

    /// <summary>Average soil colour of the four cells that share a corner, so layers blend softly.</summary>
    private Color Blend(int cx, int cy, CellType fallback)
    {
        float r = 0, g = 0, b = 0;
        for (int dy = 0; dy <= 1; dy++)
        for (int dx = -1; dx <= 0; dx++)
        {
            int x = cx + dx, y = cy + dy;
            var c = Palette.Soil(x >= 0 && x < _world.Width && y >= 1 && y < _world.Height ? Mat(_world.Index(x, y)) : fallback);
            r += c.R; g += c.G; b += c.B;
        }
        return new Color(r / 4, g / 4, b / 4);
    }

    private CellType Mat(int i) => _world.Cells[i] == CellType.Tunnel ? _world.Base[i] : _world.Cells[i];

    private void AddSolid(int x, int y, int i)
    {
        var m = Mat(i);
        float l = Layout.CellLeft(x), r = l + 1, t = Layout.RowTop(y), b = t - 1;
        float z = Layout.FrontZ;
        AddQuad(new Vector3(l, t, z), new Vector3(r, t, z), new Vector3(r, b, z), new Vector3(l, b, z), Vector3.Back,
            CornerColour(m, x, y - 1, 1), CornerColour(m, x + 1, y - 1, 1),
            CornerColour(m, x + 1, y, 1), CornerColour(m, x, y, 1));
        if (y == 1)
        {
            // The top of the slab: soil with a hint of moss.
            var top = new Color(0.30f, 0.24f, 0.13f) * (0.85f + 0.3f * Rng.Hash(x, 0, 4));
            top.A = 1;
            AddQuad(new Vector3(l, 0, Layout.BackZ), new Vector3(r, 0, Layout.BackZ),
                new Vector3(r, 0, z), new Vector3(l, 0, z), Vector3.Up, top, top, top, top);
        }
    }

    private void AddTunnel(int x, int y, int i)
    {
        var m = Mat(i);
        float l = Layout.CellLeft(x), r = l + 1, t = Layout.RowTop(y), b = t - 1;
        float zb = Layout.BackZ, zf = Layout.FrontZ;
        const float back = 0.4f;
        var room = _world.Rooms[i];
        AddQuad(new Vector3(l, t, zb), new Vector3(r, t, zb), new Vector3(r, b, zb), new Vector3(l, b, zb), Vector3.Back,
            Tint(CornerColour(m, x, y - 1, back), room), Tint(CornerColour(m, x + 1, y - 1, back), room),
            Tint(CornerColour(m, x + 1, y, back), room), Tint(CornerColour(m, x, y, back), room));

        // Walls toward solid neighbours (the world edge counts as solid).
        if (Solid(x - 1, y)) Wall(new Vector3(l, t, zb), new Vector3(l, t, zf), new Vector3(l, b, zf), new Vector3(l, b, zb), Vector3.Right, WallColour(x - 1, y));
        if (Solid(x + 1, y)) Wall(new Vector3(r, t, zf), new Vector3(r, t, zb), new Vector3(r, b, zb), new Vector3(r, b, zf), Vector3.Left, WallColour(x + 1, y));
        if (Solid(x, y + 1)) Wall(new Vector3(l, b, zf), new Vector3(r, b, zf), new Vector3(r, b, zb), new Vector3(l, b, zb), Vector3.Up, WallColour(x, y + 1));
        if (y > 1 && Solid(x, y - 1)) Wall(new Vector3(l, t, zb), new Vector3(r, t, zb), new Vector3(r, t, zf), new Vector3(l, t, zf), Vector3.Down, WallColour(x, y - 1));
    }

    /// <summary>Rooms show as a warm tint on the back wall: rosy for the nursery, amber for a store.</summary>
    private static Color Tint(Color c, Room room) => room switch
    {
        Room.Nursery => c.Lerp(new Color(0.62f, 0.36f, 0.34f), 0.35f),
        Room.Store => c.Lerp(new Color(0.62f, 0.46f, 0.2f), 0.35f),
        _ => c,
    };

    private bool Solid(int x, int y) => !_world.InBounds(x, y) || !_world.IsWalkable(_world.Index(x, y));

    private Color WallColour(int x, int y)
    {
        var m = _world.InBounds(x, y) ? Mat(_world.Index(x, y)) : CellType.Clay;
        return CornerColour(m, x, y, 0.75f);
    }

    private void Wall(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Vector3 n, Color col)
    {
        var dark = new Color(col.R * 0.7f, col.G * 0.7f, col.B * 0.7f);
        // Darker toward the back wall, so the cavity reads as deep.
        bool aBack = a.Z < 0, bBack = b.Z < 0, cBack = c.Z < 0, dBack = d.Z < 0;
        // Wound the other way round from the face quads, so Godot sees the lit side as the front.
        AddQuad(d, c, b, a, n, dBack ? dark : col, cBack ? dark : col, bBack ? dark : col, aBack ? dark : col);
    }

    private void AddQuad(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Vector3 n, Color ca, Color cb, Color cc, Color cd)
    {
        _v.Add(a); _v.Add(b); _v.Add(c);
        _v.Add(a); _v.Add(c); _v.Add(d);
        for (int k = 0; k < 6; k++) _n.Add(n);
        _c.Add(ca); _c.Add(cb); _c.Add(cc);
        _c.Add(ca); _c.Add(cc); _c.Add(cd);
    }

    /// <summary>A wooden frame around the slab, like a real ant farm.</summary>
    private void BuildFrame()
    {
        var wood = new StandardMaterial3D
        {
            AlbedoColor = Palette.Wood,
            Roughness = 0.55f,
            AlbedoTexture = WoodGrain(),
            Uv1Triplanar = true,
            Uv1Scale = new Vector3(0.12f, 0.6f, 0.12f),
        };
        float h = _world.Height - 1, w = _world.Width;
        float depth = Layout.SlabDepth + 0.8f;
        void Box(Vector3 centre, Vector3 size)
        {
            AddChild(new MeshInstance3D
            {
                Mesh = new BoxMesh { Size = size },
                Position = centre,
                MaterialOverride = wood,
            });
        }
        Box(new Vector3(-w / 2 - 0.8f, -h / 2 + 0.6f, 0), new Vector3(1.6f, h + 2.8f, depth));
        Box(new Vector3(w / 2 + 0.8f, -h / 2 + 0.6f, 0), new Vector3(1.6f, h + 2.8f, depth));
        Box(new Vector3(0, -h - 0.8f, 0), new Vector3(w + 3.2f, 1.6f, depth));

    }

    private static NoiseTexture2D WoodGrain()
    {
        var g = new Gradient();
        g.SetColor(0, new Color(0.75f, 0.72f, 0.7f));
        g.SetColor(1, new Color(1.1f, 1.05f, 1f));
        return new NoiseTexture2D
        {
            Width = 256,
            Height = 256,
            Seamless = true,
            ColorRamp = g,
            Noise = new FastNoiseLite { Frequency = 0.02f, FractalOctaves = 3, NoiseType = FastNoiseLite.NoiseTypeEnum.Cellular },
        };
    }
}
