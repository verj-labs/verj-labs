using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// The sky, the sun and things falling from them: rain, snow and autumn leaves. The light
/// changes through the year and greys over when it rains.
/// </summary>
public partial class WeatherView : Node3D
{
    private Sim _sim = null!;
    private Environment _env = null!;
    private DirectionalLight3D _sun = null!;
    private ProceduralSkyMaterial _sky = null!;
    private GpuParticles3D _rain = null!, _snow = null!, _leaves = null!;
    private float _wet;

    private static readonly Vector3 EmitAt = new(0, 48, -31);

    public void Init(Sim sim, Environment env, DirectionalLight3D sun, ProceduralSkyMaterial sky)
    {
        _sim = sim;
        _env = env;
        _sun = sun;
        _sky = sky;
        _rain = Particles(4000, 0.9f, new Vector3(0.08f, -1, 0), 55, 70, new Vector2(0.06f, 1.6f),
            new Color(0.75f, 0.85f, 1f, 0.35f), BaseMaterial3D.BillboardModeEnum.FixedY, 29);
        _snow = Particles(2500, 9f, new Vector3(0.15f, -1, 0), 4, 6, new Vector2(0.22f, 0.22f),
            new Color(1f, 1f, 1f, 0.9f), BaseMaterial3D.BillboardModeEnum.Enabled, 29, turbulence: true);
        _leaves = Particles(70, 14f, new Vector3(0.3f, -1, 0), 2.5f, 4, new Vector2(0.9f, 0.6f),
            new Color(0.85f, 0.45f, 0.12f, 1f), BaseMaterial3D.BillboardModeEnum.Disabled, 25, turbulence: true, spin: true);
        _leaves.Position = new Vector3(0, 26, -14);
    }

    private GpuParticles3D Particles(int amount, float life, Vector3 dir, float vMin, float vMax, Vector2 size,
        Color colour, BaseMaterial3D.BillboardModeEnum billboard, float depth, bool turbulence = false, bool spin = false)
    {
        var process = new ParticleProcessMaterial
        {
            EmissionShape = ParticleProcessMaterial.EmissionShapeEnum.Box,
            EmissionBoxExtents = new Vector3(110, 1, depth),
            Direction = dir,
            Spread = turbulence ? 25 : 2,
            InitialVelocityMin = vMin,
            InitialVelocityMax = vMax,
            Gravity = new Vector3(0, turbulence ? -0.5f : -20, 0),
            TurbulenceEnabled = turbulence,
            TurbulenceNoiseStrength = 2.5f,
            TurbulenceInfluenceMin = 0.05f,
            TurbulenceInfluenceMax = 0.15f,
        };
        if (spin)
        {
            process.AngularVelocityMin = -180;
            process.AngularVelocityMax = 180;
            process.AngleMin = 0;
            process.AngleMax = 360;
            process.ParticleFlagRotateY = true;
            process.ScaleMin = 0.6f;
            process.ScaleMax = 1.4f;
            process.HueVariationMin = -0.04f;
            process.HueVariationMax = 0.06f;
        }
        var mat = new StandardMaterial3D
        {
            ShadingMode = spin ? BaseMaterial3D.ShadingModeEnum.PerPixel : BaseMaterial3D.ShadingModeEnum.Unshaded,
            Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
            AlbedoColor = colour,
            BillboardMode = billboard,
            BillboardKeepScale = true,
            CullMode = BaseMaterial3D.CullModeEnum.Disabled,
            VertexColorUseAsAlbedo = spin,
        };
        Mesh mesh = spin
            ? MeshKit.Blob(new Vector3(0.5f, 0.02f, 0.3f), Colors.White, 3, 10)
            : new QuadMesh { Size = size };
        if (mesh is QuadMesh q) q.Material = mat; else mesh.SurfaceSetMaterial(0, mat);
        var p = new GpuParticles3D
        {
            Amount = amount,
            Lifetime = life,
            Preprocess = life,
            Emitting = false,
            ProcessMaterial = process,
            DrawPass1 = mesh,
            Position = EmitAt,
            VisibilityAabb = new Aabb(new Vector3(-120, -60, -40), new Vector3(240, 70, 80)),
        };
        AddChild(p);
        return p;
    }

    private static Color SkyTop(Season s) => s switch
    {
        Season.Summer => new Color(0.30f, 0.52f, 0.86f),
        Season.Autumn => new Color(0.42f, 0.52f, 0.70f),
        Season.Winter => new Color(0.56f, 0.63f, 0.74f),
        _ => new Color(0.36f, 0.55f, 0.82f),
    };

    private static Color SkyHorizon(Season s) => s switch
    {
        Season.Summer => new Color(0.90f, 0.86f, 0.72f),
        Season.Autumn => new Color(0.92f, 0.76f, 0.56f),
        Season.Winter => new Color(0.84f, 0.86f, 0.88f),
        _ => new Color(0.85f, 0.83f, 0.74f),
    };

    private static float SunEnergy(Season s) => s switch
    {
        Season.Summer => 1.5f,
        Season.Autumn => 1.15f,
        Season.Winter => 0.85f,
        _ => 1.35f,
    };

    private static Color SunColour(Season s) => s switch
    {
        Season.Autumn => new Color(1f, 0.84f, 0.64f),
        Season.Winter => new Color(0.9f, 0.94f, 1f),
        _ => new Color(1f, 0.93f, 0.8f),
    };

    private static float SunHeight(Season s) => s switch
    {
        Season.Summer => -52,
        Season.Autumn => -34,
        Season.Winter => -22,
        _ => -40,
    };

    public void Update(double delta)
    {
        var sim = _sim;
        bool wet = sim.Raining;
        _rain.Emitting = sim.Raining && !sim.Snowing;
        _snow.Emitting = sim.Snowing;
        _leaves.Emitting = sim.Season == Season.Autumn;
        _wet = Mathf.MoveToward(_wet, wet ? 1f : 0f, (float)delta * 0.5f);

        var now = sim.Season;
        var next = (Season)(((int)now + 1) % 4);
        float blend = Mathf.SmoothStep(0.8f, 1f, sim.SeasonProgress);
        var grey = new Color(0.5f, 0.53f, 0.57f);
        _sky.SkyTopColor = SkyTop(now).Lerp(SkyTop(next), blend).Lerp(grey, _wet * 0.7f);
        _sky.SkyHorizonColor = SkyHorizon(now).Lerp(SkyHorizon(next), blend).Lerp(grey, _wet * 0.6f);
        _sun.LightEnergy = Mathf.Lerp(Mathf.Lerp(SunEnergy(now), SunEnergy(next), blend), 0.45f, _wet);
        _sun.LightColor = SunColour(now).Lerp(SunColour(next), blend);
        _sun.RotationDegrees = new Vector3(Mathf.Lerp(SunHeight(now), SunHeight(next), blend), -32, 0);
        _env.AmbientLightEnergy = Mathf.Lerp(0.75f, 0.55f, _wet);
        _env.AdjustmentSaturation = Mathf.Lerp(1.08f, 0.8f, _wet);
    }

    /// <summary>Jump straight to the current weather (for screenshots).</summary>
    public void Snap() => Update(10);
}
