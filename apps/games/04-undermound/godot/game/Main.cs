using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Builds the scene, steps the simulation at a fixed rate, turns input into colony orders,
/// and in screenshot mode (--shots=DIR) plays a scripted scene and saves pictures.
/// </summary>
public partial class Main : Node3D
{
    public Sim Sim { get; private set; } = null!;
    public CameraRig Rig { get; private set; } = null!;
    public Hud Hud { get; private set; } = null!;

    private SoilView _soil = null!;
    private OverlayView _overlay = null!;
    private SurfaceView _surface = null!;
    private AntView _ants = null!;
    private DirectionalLight3D _sun = null!;
    private Environment _env = null!;
    private GpuParticles3D _rain = null!;
    private float _wet;

    private double _accumulator;
    private int _speed = 1;                       // 0 paused, 1, 2, 3 = 1x, 2x, 4x
    private static readonly float[] SpeedScale = { 0, 1, 2, 4 };
    private Tool _tool = Tool.Dig;
    private int _brush = 1;
    private bool _painting;
    private bool _erasing;

    public override void _Ready()
    {
        Sim = Sim.CreateDefault(seed: 2026);
        BuildEnvironment();

        _soil = new SoilView();
        AddChild(_soil);
        _soil.Init(Sim.World);
        _surface = new SurfaceView();
        AddChild(_surface);
        _surface.Init(Sim.World);
        _overlay = new OverlayView();
        AddChild(_overlay);
        _overlay.Init(Sim.World);
        _ants = new AntView();
        AddChild(_ants);
        _ants.Init(Sim, _surface);

        Rig = new CameraRig();
        AddChild(Rig);
        Rig.Target = new Vector3(0, -10, 0);
        Rig.Distance = 55;

        Hud = new Hud();
        AddChild(Hud);
        Hud.ToolPicked += t => _tool = t;
        Hud.SpeedPicked += s => _speed = s;
        Hud.RainPicked += () => { if (!Sim.Raining) Sim.StartRain(30); };
        Hud.ScentToggled += () => _overlay.ShowScent = !_overlay.ShowScent;

        foreach (string arg in OS.GetCmdlineUserArgs())
            if (arg.StartsWith("--shots="))
                AddChild(new ShotDirector(this, arg.Substring("--shots=".Length)));
    }

    private void BuildEnvironment()
    {
        var sky = new ProceduralSkyMaterial
        {
            SkyTopColor = new Color(0.36f, 0.55f, 0.82f),
            SkyHorizonColor = new Color(0.85f, 0.82f, 0.72f),
            GroundHorizonColor = new Color(0.55f, 0.48f, 0.36f),
            GroundBottomColor = new Color(0.2f, 0.16f, 0.1f),
            SunAngleMax = 30,
        };
        var env = new Environment
        {
            BackgroundMode = Environment.BGMode.Sky,
            Sky = new Sky { SkyMaterial = sky },
            AmbientLightSource = Environment.AmbientSource.Sky,
            AmbientLightColor = new Color(0.75f, 0.62f, 0.5f),
            AmbientLightSkyContribution = 0.6f,
            AmbientLightEnergy = 0.75f,
            TonemapMode = Environment.ToneMapper.Filmic,
            TonemapExposure = 1.05f,
            SsaoEnabled = true,
            SsaoRadius = 0.8f,
            SsaoIntensity = 1.6f,
            GlowEnabled = false,
            FogEnabled = false,
            AdjustmentEnabled = true,
            AdjustmentSaturation = 1.08f,
            AdjustmentContrast = 1.04f,
        };
        _env = env;
        AddChild(new WorldEnvironment { Environment = env });
        BuildRain();
        _sun = new DirectionalLight3D
        {
            LightColor = new Color(1f, 0.93f, 0.8f),
            LightEnergy = 1.35f,
            ShadowEnabled = true,
            DirectionalShadowMaxDistance = 220,
            RotationDegrees = new Vector3(-38, -32, 0),
        };
        AddChild(_sun);
        // A soft fill from the front so the cut face of the soil is readable.
        AddChild(new DirectionalLight3D
        {
            LightColor = new Color(0.75f, 0.82f, 1f),
            LightEnergy = 0.25f,
            RotationDegrees = new Vector3(-10, 160, 0),
            SkyMode = DirectionalLight3D.SkyModeEnum.LightOnly,
        });
    }

    private void BuildRain()
    {
        var process = new ParticleProcessMaterial
        {
            EmissionShape = ParticleProcessMaterial.EmissionShapeEnum.Box,
            EmissionBoxExtents = new Vector3(110, 1, 29),
            Direction = new Vector3(0.08f, -1, 0),
            Spread = 2,
            InitialVelocityMin = 55,
            InitialVelocityMax = 70,
            Gravity = new Vector3(0, -20, 0),
        };
        var drop = new StandardMaterial3D
        {
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
            Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
            AlbedoColor = new Color(0.75f, 0.85f, 1f, 0.35f),
            BillboardMode = BaseMaterial3D.BillboardModeEnum.FixedY,
            BillboardKeepScale = true,
        };
        _rain = new GpuParticles3D
        {
            Amount = 4000,
            Lifetime = 0.9f,
            Preprocess = 1f,
            Emitting = false,
            ProcessMaterial = process,
            DrawPass1 = new QuadMesh { Size = new Vector2(0.06f, 1.6f), Material = drop },
            Position = new Vector3(0, 48, -31),
            VisibilityAabb = new Aabb(new Vector3(-120, -60, -40), new Vector3(240, 70, 80)),
        };
        AddChild(_rain);
    }

    /// <summary>Grey the sky and dim the sun while it rains.</summary>
    private void UpdateWeatherLook(double delta)
    {
        _rain.Emitting = Sim.Raining;
        float target = Sim.Raining ? 1f : 0f;
        _wet = Mathf.MoveToward(_wet, target, (float)delta * 0.5f);
        _sun.LightEnergy = Mathf.Lerp(1.35f, 0.45f, _wet);
        _env.AmbientLightEnergy = Mathf.Lerp(0.75f, 0.55f, _wet);
        _env.AdjustmentSaturation = Mathf.Lerp(1.08f, 0.8f, _wet);
    }

    /// <summary>Jump the weather look to the current state (for screenshots).</summary>
    public void SnapWeatherLook() => UpdateWeatherLook(10);

    public override void _Process(double delta)
    {
        UpdateWeatherLook(delta);
        _accumulator += delta * SpeedScale[_speed];
        int steps = 0;
        while (_accumulator >= SimConfig.TickSeconds && steps < 8)
        {
            _accumulator -= SimConfig.TickSeconds;
            StepOnce();
            steps++;
        }
        if (steps == 8) _accumulator = 0;
        _ants.Draw(_speed == 0 ? 1f : (float)(_accumulator / SimConfig.TickSeconds));
        Hud.Show(Sim, _tool, _speed, _brush);
        if (_painting) PaintAt(GetViewport().GetMousePosition());
    }

    /// <summary>One simulation tick plus the view updates that follow it.</summary>
    public void StepOnce()
    {
        Sim.Step();
        _ants.Tick();
        RefreshViews();
    }

    public void RefreshViews()
    {
        _soil.Refresh();
        _overlay.Refresh();
        _surface.Refresh();
    }

    /// <summary>Run the simulation quickly with no drawing (for scripted scenes).</summary>
    public void FastForward(float seconds)
    {
        int ticks = (int)(seconds / SimConfig.TickSeconds);
        for (int t = 0; t < ticks; t++) Sim.Step();
        _ants.Tick();
        _ants.Tick();
        RefreshViews();
        _ants.Draw(1f);
    }

    public void SetScentVisible(bool on) => _overlay.ShowScent = on;

    public void Pause() => _speed = 0;

    public override void _UnhandledInput(InputEvent e)
    {
        if (e is InputEventMouseButton mb && mb.ButtonIndex == MouseButton.Left)
        {
            _painting = mb.Pressed;
            _erasing = mb.ShiftPressed;
            if (mb.Pressed) PaintAt(mb.Position);
        }
        else if (e is InputEventKey { Pressed: true } key)
        {
            switch (key.Keycode)
            {
                case Key.Key1: _tool = Tool.Dig; break;
                case Key.Key2: _tool = Tool.Nursery; break;
                case Key.Key3: _tool = Tool.Store; break;
                case Key.Key4: _tool = Tool.Cancel; break;
                case Key.R: if (!Sim.Raining) Sim.StartRain(30); break;
                case Key.T: _overlay.ShowScent = !_overlay.ShowScent; break;
                case Key.Space: _speed = _speed == 0 ? 1 : 0; break;
                case Key.Equal or Key.KpAdd: _speed = Mathf.Min(3, _speed + 1); break;
                case Key.Minus or Key.KpSubtract: _speed = Mathf.Max(0, _speed - 1); break;
                case Key.Bracketleft: _brush = Mathf.Max(0, _brush - 1); break;
                case Key.Bracketright: _brush = Mathf.Min(4, _brush + 1); break;
            }
        }
    }

    private void PaintAt(Vector2 screen)
    {
        var p = Rig.PointOnSlab(screen);
        if (p == null || !Layout.PointToCell(p.Value, out int x, out int y)) return;
        if (_erasing) { Sim.Cancel(x, y, _brush); return; }
        switch (_tool)
        {
            case Tool.Dig: Sim.PaintDig(x, y, _brush, true); break;
            case Tool.Nursery: Sim.PaintRoom(x, y, _brush, Room.Nursery); break;
            case Tool.Store: Sim.PaintRoom(x, y, _brush, Room.Store); break;
            case Tool.Cancel: Sim.Cancel(x, y, _brush); break;
        }
    }
}
