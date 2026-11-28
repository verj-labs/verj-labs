using System.Collections.Generic;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// The macro garden on top of the ant farm: ground, grass blades that tower over the ants,
/// pebbles, the food sources and the mound of dug-out soil.
/// </summary>
public partial class SurfaceView : Node3D
{
    private World _world = null!;
    private MultiMeshInstance3D _pellets = null!;
    private readonly float[] _height = new float[SimConfig.Width];
    private int _moundTotal = -1;
    private readonly Dictionary<FoodSource, MeshInstance3D> _food = new();
    private Mesh _berry = null!, _crumb = null!, _seeds = null!;
    private Material _berryMat = null!, _crumbMat = null!;
    private Mesh? _spiderMesh;
    private Material? _spiderMat;
    private ShaderMaterial _grassMat = null!;
    private StandardMaterial3D _groundMat = null!;
    private MeshInstance3D _snow = null!;
    private StandardMaterial3D _snowMat = null!;
    private MultiMeshInstance3D _flags = null!;
    private int _flagHash = -1;

    private const string GrassShader = @"
shader_type spatial;
render_mode cull_disabled;
varying float t;
void vertex() {
    t = clamp(VERTEX.y, 0.0, 1.0);
    vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float sway = sin(TIME * 1.1 + wp.x * 0.21 + wp.z * 0.17) * 0.09 * t * t;
    VERTEX.x += sway;
    VERTEX.z += sway * 0.5;
}
uniform vec3 season_color = vec3(0.5, 0.6, 0.2);
uniform float season_mix = 0.0;
uniform float snow = 0.0;
void fragment() {
    vec3 c = mix(pow(COLOR.rgb, vec3(2.2)), season_color, season_mix);
    vec3 tip = c * vec3(1.3, 1.2, 0.75);
    vec3 root = c * 0.35;
    ALBEDO = mix(root, tip, t);
    ALBEDO = mix(ALBEDO, vec3(0.85, 0.88, 0.92), clamp(snow * (0.2 + 0.8 * smoothstep(0.3, 1.0, t)), 0.0, 0.85));
    ROUGHNESS = 0.75;
    SPECULAR = 0.2;
    BACKLIGHT = vec3(0.18, 0.24, 0.08);
}";

    public void Init(World world)
    {
        _world = world;
        BuildGround();
        BuildGrass();
        BuildPebblesAndLeaves();
        _pellets = new MultiMeshInstance3D
        {
            Multimesh = new MultiMesh
            {
                TransformFormat = MultiMesh.TransformFormatEnum.Transform3D,
                UseColors = true,
                Mesh = MeshKit.Blob(new Vector3(0.13f, 0.1f, 0.12f), Colors.White, 4, 6),
            },
            MaterialOverride = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.95f },
        };
        AddChild(_pellets);
        _berry = MeshKit.Berry();
        _crumb = MeshKit.Crumb();
        _seeds = MeshKit.Seeds();
        _berryMat = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.18f, MetallicSpecular = 0.8f };
        _crumbMat = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.85f };
        BuildSnow();
        _flags = new MultiMeshInstance3D
        {
            Multimesh = new MultiMesh { TransformFormat = MultiMesh.TransformFormatEnum.Transform3D, Mesh = MeshKit.Flag(), InstanceCount = SimConfig.Width },
            MaterialOverride = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.7f, CullMode = BaseMaterial3D.CullModeEnum.Disabled },
        };
        AddChild(_flags);
        Refresh();
    }

    /// <summary>The spider mesh, so a dead spider can lie on the ground as food.</summary>
    public void SetSpiderMesh(Mesh mesh, Material mat)
    {
        _spiderMesh = mesh;
        _spiderMat = mat;
    }

    private void BuildSnow()
    {
        _snowMat = new StandardMaterial3D
        {
            AlbedoColor = new Color(0.95f, 0.97f, 1f, 0f),
            Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
            Roughness = 0.6f,
            AlbedoTexture = new NoiseTexture2D
            {
                Width = 256, Height = 256, Seamless = true,
                Noise = new FastNoiseLite { Frequency = 0.05f, FractalOctaves = 3 },
                ColorRamp = SnowRamp(),
            },
            Uv1Scale = new Vector3(140, 60, 1),
        };
        _snow = new MeshInstance3D
        {
            Mesh = new PlaneMesh { Size = new Vector2(_world.Width + 1400, 700) },
            Position = new Vector3(0, 0.04f, Layout.FrontZ - 350),
            MaterialOverride = _snowMat,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
            Visible = false,
        };
        AddChild(_snow);
    }

    private static Gradient SnowRamp()
    {
        var g = new Gradient();
        g.SetColor(0, new Color(0.85f, 0.88f, 0.95f));
        g.SetColor(1, new Color(1f, 1f, 1f));
        return g;
    }

    // Grass colour each season blends toward (linear colour) and how far.
    private static Vector3 GrassColour(Season s) => s switch
    {
        Season.Summer => new Vector3(0.36f, 0.34f, 0.04f),
        Season.Autumn => new Vector3(0.62f, 0.22f, 0.03f),
        Season.Winter => new Vector3(0.32f, 0.26f, 0.14f),
        _ => new Vector3(0.06f, 0.3f, 0.02f),
    };

    private static float GrassMix(Season s) => s switch
    {
        Season.Summer => 0.35f,
        Season.Autumn => 0.7f,
        Season.Winter => 0.8f,
        _ => 0.1f,
    };

    private static Color GroundTint(Season s) => s switch
    {
        Season.Summer => new Color(1.08f, 1f, 0.86f),
        Season.Autumn => new Color(1.04f, 0.96f, 0.88f),
        Season.Winter => new Color(0.86f, 0.86f, 0.9f),
        _ => Colors.White,
    };

    /// <summary>Colour the garden for the time of year; seasons blend over the last fifth of each.</summary>
    public void ShowSeason(Sim sim)
    {
        var now = sim.Season;
        var next = (Season)(((int)now + 1) % 4);
        float blend = Mathf.SmoothStep(0.8f, 1f, sim.SeasonProgress);
        _grassMat.SetShaderParameter("season_color", GrassColour(now).Lerp(GrassColour(next), blend));
        _grassMat.SetShaderParameter("season_mix", Mathf.Lerp(GrassMix(now), GrassMix(next), blend));
        float snow = Mathf.Clamp(sim.Snow * 1.4f, 0, 1);
        _grassMat.SetShaderParameter("snow", snow);
        _groundMat.AlbedoColor = GroundTint(now).Lerp(GroundTint(next), blend);
        _snow.Visible = snow > 0.01f;
        _snowMat.AlbedoColor = new Color(0.95f, 0.97f, 1f, Mathf.Clamp(snow * 1.2f, 0, 0.95f));
    }

    /// <summary>Height of the ground (mound included) at a surface column, for ants walking on it.</summary>
    public float GroundHeight(float x)
    {
        int i = Mathf.Clamp((int)x, 0, _height.Length - 1);
        return _height[i];
    }

    public void Refresh()
    {
        UpdateMound();
        UpdateFood();
        UpdateFlags();
    }

    private void UpdateFlags()
    {
        int hash = 17, count = 0;
        for (int x = 0; x < _world.Width; x++) if (_world.Avoid[x]) { hash = hash * 31 + x; count++; }
        if (hash == _flagHash) return;
        _flagHash = hash;
        var mm = _flags.Multimesh;
        int n = 0;
        for (int x = 0; x < _world.Width; x++)
        {
            if (!_world.Avoid[x]) continue;
            var pos = new Vector3(x + 0.5f - _world.Width / 2f, GroundHeight(x + 0.5f), -0.55f);
            mm.SetInstanceTransform(n++, new Transform3D(new Basis(Vector3.Up, 0.3f * (x % 3 - 1)), pos));
        }
        mm.VisibleInstanceCount = n;
    }

    private void BuildGround()
    {
        var gradient = new Gradient();
        gradient.SetColor(0, new Color(0.20f, 0.15f, 0.09f));
        gradient.SetColor(1, new Color(0.38f, 0.33f, 0.16f));
        var tex = new NoiseTexture2D
        {
            Width = 512,
            Height = 512,
            Seamless = true,
            ColorRamp = gradient,
            Noise = new FastNoiseLite { Frequency = 0.012f, FractalOctaves = 5 },
        };
        var normal = new NoiseTexture2D
        {
            Width = 512,
            Height = 512,
            Seamless = true,
            AsNormalMap = true,
            BumpStrength = 6f,
            Noise = new FastNoiseLite { Frequency = 0.05f, FractalOctaves = 3 },
        };
        var mat = _groundMat = new StandardMaterial3D
        {
            AlbedoTexture = tex,
            NormalEnabled = true,
            NormalTexture = normal,
            Roughness = 0.95f,
            Uv1Scale = new Vector3(90, 30, 1),
        };
        const float depth = 700f;
        AddChild(new MeshInstance3D
        {
            Mesh = new PlaneMesh { Size = new Vector2(_world.Width + 1400, depth) },
            Position = new Vector3(0, 0, Layout.BackZ - depth / 2),
            MaterialOverride = mat,
        });
        // Strips beside the slab so the ground does not end at the frame.
        float side = 130f;
        foreach (int s in new[] { -1, 1 })
            AddChild(new MeshInstance3D
            {
                Mesh = new PlaneMesh { Size = new Vector2(side, 12) },
                Position = new Vector3(s * (_world.Width / 2f + 1.6f + side / 2), 0, Layout.BackZ + 6 - 0.01f),
                MaterialOverride = mat,
            });
    }

    private void BuildGrass()
    {
        var rng = new RandomNumberGenerator { Seed = 1234 };
        var transforms = new List<(Transform3D T, Color C)>();
        float halfW = _world.Width / 2f + 120;
        for (int k = 0; k < 9000; k++)
        {
            float x = rng.RandfRange(-halfW, halfW);
            float z = Layout.BackZ - 0.6f - 70f * Mathf.Pow(rng.Randf(), 1.1f);
            bool near = z > -6f;
            if (near && rng.Randf() < 0.6f) continue;
            // Grass grows in clumps.
            float clump = Rng.ValueNoise(x * 0.06f, z * 0.06f, 21);
            if (clump < 0.42f && rng.Randf() < 0.75f) continue;
            float height = rng.RandfRange(3f, 7.5f) * (near ? 0.7f : 1f) * (0.6f + clump);
            float width = rng.RandfRange(0.22f, 0.42f);
            var basis = new Basis(Vector3.Up, rng.RandfRange(0, Mathf.Tau))
                        * new Basis(Vector3.Right, rng.RandfRange(-0.25f, 0.25f));
            basis = basis.Scaled(new Vector3(width, height, width * 2));
            var c = new Color(rng.RandfRange(0.22f, 0.36f), rng.RandfRange(0.42f, 0.58f), rng.RandfRange(0.10f, 0.18f));
            transforms.Add((new Transform3D(basis, new Vector3(x, -0.05f, z)), c));
        }
        var mm = new MultiMesh
        {
            TransformFormat = MultiMesh.TransformFormatEnum.Transform3D,
            UseColors = true,
            Mesh = MeshKit.GrassBlade(),
            InstanceCount = transforms.Count,
        };
        for (int k = 0; k < transforms.Count; k++)
        {
            mm.SetInstanceTransform(k, transforms[k].T);
            mm.SetInstanceColor(k, transforms[k].C);
        }
        _grassMat = new ShaderMaterial { Shader = new Shader { Code = GrassShader } };
        AddChild(new MultiMeshInstance3D { Multimesh = mm, MaterialOverride = _grassMat });
    }

    private void BuildPebblesAndLeaves()
    {
        var rng = new RandomNumberGenerator { Seed = 77 };
        var pebbles = new MultiMesh
        {
            TransformFormat = MultiMesh.TransformFormatEnum.Transform3D,
            UseColors = true,
            Mesh = MeshKit.Pebble(),
            InstanceCount = 140,
        };
        float halfW = _world.Width / 2f + 60;
        for (int k = 0; k < pebbles.InstanceCount; k++)
        {
            float s = rng.RandfRange(0.15f, 1.3f);
            var pos = new Vector3(rng.RandfRange(-halfW, halfW), s * 0.25f, Layout.BackZ - 1f - rng.RandfRange(0, 40));
            var basis = new Basis(Vector3.Up, rng.RandfRange(0, Mathf.Tau)).Scaled(new Vector3(s, s, s));
            pebbles.SetInstanceTransform(k, new Transform3D(basis, pos));
            float g = rng.RandfRange(0.3f, 0.5f);
            pebbles.SetInstanceColor(k, new Color(g, g * 0.93f, g * 0.85f));
        }
        AddChild(new MultiMeshInstance3D
        {
            Multimesh = pebbles,
            MaterialOverride = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.85f },
        });

    }

    private void UpdateMound()
    {
        int total = 0;
        foreach (int m in _world.Mound) total += m;
        if (total == _moundTotal) return;
        _moundTotal = total;
        int w = _world.Width;
        for (int x = 0; x < w; x++)
        {
            float s = 0;
            for (int k = -3; k <= 3; k++)
            {
                int nx = x + k;
                if (nx >= 0 && nx < w) s += _world.Mound[nx] * (1f - Mathf.Abs(k) / 4f);
            }
            _height[x] = 0.16f * Mathf.Sqrt(s);
        }
        var mm = _pellets.Multimesh;
        const int cap = 6000;
        if (mm.InstanceCount < cap) mm.InstanceCount = cap;
        var rng = new RandomNumberGenerator { Seed = 99 };
        int n = 0;
        for (int x = 0; x < w && n < cap; x++)
        {
            if (_height[x] <= 0.01f) continue;
            int count = Mathf.Min(14 + (int)(_height[x] * 40), 90);
            for (int k = 0; k < count && n < cap; k++)
            {
                float px = x + rng.Randf();
                float pz = rng.RandfRange(-1f, 1f);
                float profile = 1f - pz * pz;
                float h = Mathf.Lerp(_height[x], _height[Mathf.Min(x + 1, w - 1)], px - x) * profile;
                float py = rng.RandfRange(0.2f, 1f) * h;
                var pos = new Vector3(px - w / 2f, py, pz * (1.2f + h * 0.8f) - 0.1f);
                float s = rng.RandfRange(0.8f, 1.4f);
                var basis = new Basis(Vector3.Up, rng.RandfRange(0, 6.28f)).Scaled(new Vector3(s, s, s));
                mm.SetInstanceTransform(n, new Transform3D(basis, pos));
                float g = rng.RandfRange(0.75f, 1.15f);
                var c = Palette.Soil(rng.Randf() < 0.6f ? CellType.Clay : CellType.Topsoil) * g;
                c.A = 1;
                mm.SetInstanceColor(n++, c);
            }
        }
        mm.VisibleInstanceCount = n;
    }

    private void UpdateFood()
    {
        foreach (var f in _world.Food)
        {
            if (!_food.TryGetValue(f, out var mi))
            {
                bool insect = f.Kind == FoodKind.Insect && _spiderMesh != null;
                mi = new MeshInstance3D
                {
                    Mesh = insect ? _spiderMesh : f.Kind switch { FoodKind.Berry => _berry, FoodKind.Crumb => _crumb, _ => _seeds },
                    MaterialOverride = insect ? _spiderMat : f.Kind == FoodKind.Berry ? _berryMat : _crumbMat,
                };
                AddChild(mi);
                _food[f] = mi;
            }
            float size = 0.45f + 1.1f * Mathf.Pow(f.Amount / 60f, 1f / 3f);
            if (f.Kind == FoodKind.Insect)
            {
                // A dead spider on its back, legs curled up, shrinking as it is eaten.
                float s = 0.5f + 0.5f * f.Amount / 60f;
                mi.Transform = new Transform3D(new Basis(Vector3.Back, Mathf.Pi).Scaled(new Vector3(s, s * 0.7f, s)),
                    new Vector3(f.X - _world.Width / 2f, 0.9f * s, -1.4f));
                continue;
            }
            float lift = f.Kind == FoodKind.Berry ? size * 0.9f : f.Kind == FoodKind.Crumb ? size * 0.4f : 0;
            mi.Scale = new Vector3(size, size, size);
            mi.Position = new Vector3(f.X - _world.Width / 2f, lift, -0.9f - size * 0.4f);
        }
        foreach (var f in new List<FoodSource>(_food.Keys))
        {
            if (_world.Food.Contains(f)) continue;
            _food[f].QueueFree();
            _food.Remove(f);
        }
    }
}
