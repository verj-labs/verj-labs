using System.Collections.Generic;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Draws every ant (workers, soldiers, winged queens), what they carry, the brood, the queen and
/// the wolf spiders. Ants use MultiMesh so thousands are cheap; positions are interpolated
/// between simulation ticks for smooth movement.
/// </summary>
public partial class AntView : Node3D
{
    private Sim _sim = null!;
    private SurfaceView _surface = null!;
    private MultiMeshInstance3D _workers = null!, _soldiers = null!, _alates = null!;
    private MultiMeshInstance3D _soil = null!, _food = null!, _eggs = null!, _larvae = null!;
    private MeshInstance3D _queen = null!;
    private Mesh _spiderMesh = null!;
    private ShaderMaterial _spiderMat = null!;
    private readonly Dictionary<Spider, MeshInstance3D> _spiders = new();
    private readonly Dictionary<Spider, (float Prev, float Curr)> _spiderX = new();

    private readonly Dictionary<int, Transform3D> _prev = new();
    private readonly Dictionary<int, Transform3D> _curr = new();

    private static readonly Vector3 CarryOffset = new(0.42f, 0.16f, 0);

    private const string AntShader = @"
shader_type spatial;
render_mode cull_disabled;
uniform float speed = 22.0;
void vertex() {
    float walk = INSTANCE_CUSTOM.x;
    float phase = INSTANCE_CUSTOM.y;
    if (UV2.x > 0.9 && UV2.x < 1.5) {
        float p = phase + (UV2.y > 0.5 ? 3.14159 : 0.0);
        float swing = sin(TIME * speed + p) * walk;
        float lift = max(0.0, cos(TIME * speed + p)) * walk;
        float k = clamp(1.0 - VERTEX.y / 0.24, 0.0, 1.0);
        VERTEX.x += swing * 0.07 * k;
        VERTEX.y += lift * 0.035 * k;
    } else if (UV2.x > 0.25 && UV2.x < 0.75) {
        float k = clamp((VERTEX.x - 0.25) / 0.25, 0.0, 1.0);
        VERTEX.y += sin(TIME * 7.0 + phase) * 0.035 * k;
        VERTEX.z += cos(TIME * 5.0 + phase * 1.3) * 0.025 * k;
    } else if (UV2.x < 0.1) {
        VERTEX.y += abs(sin(TIME * speed * 0.5 + phase)) * 0.012 * walk;
    }
}
void fragment() {
    ALBEDO = pow(COLOR.rgb, vec3(2.2));
    ROUGHNESS = 0.32;
    SPECULAR = 0.7;
    RIM = 0.25;
    RIM_TINT = 0.6;
}";

    private const string WingShader = @"
shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;
void vertex() {
    float fly = INSTANCE_CUSTOM.z;
    VERTEX.y += sin(TIME * 70.0 + INSTANCE_CUSTOM.y) * 0.22 * abs(VERTEX.z) * fly;
}
void fragment() {
    // Clear wings with a faint oily sheen that shifts with the view.
    float sheen = 0.5 + 0.5 * sin(dot(NORMAL, VIEW) * 9.0 + UV.x * 4.0);
    ALBEDO = mix(vec3(0.78, 0.84, 0.95), vec3(0.95, 0.85, 1.0), sheen);
    ALPHA = 0.58;
    ROUGHNESS = 0.08;
    SPECULAR = 0.9;
}";

    private const string SpiderShader = @"
shader_type spatial;
render_mode cull_disabled;
instance uniform float walking = 0.0;
instance uniform float phase = 0.0;
void vertex() {
    if (UV2.x > 0.9) {
        float p = phase + (UV2.y > 0.5 ? 3.14159 : 0.0);
        float k = clamp(1.0 - VERTEX.y / 1.15, 0.0, 1.0);
        VERTEX.x += sin(TIME * 13.0 + p) * 0.35 * k * walking;
        VERTEX.y += max(0.0, cos(TIME * 13.0 + p)) * 0.2 * k * walking;
    }
    VERTEX.y += sin(TIME * 2.0 + phase) * 0.015;
}
void fragment() {
    ALBEDO = pow(COLOR.rgb, vec3(2.2));
    ROUGHNESS = 0.6;
    SPECULAR = 0.4;
    RIM = 0.3;
}";

    public void Init(Sim sim, SurfaceView surface)
    {
        _sim = sim;
        _surface = surface;
        var antMat = new ShaderMaterial { Shader = new Shader { Code = AntShader } };
        _workers = Multi(MeshKit.Ant(), antMat, custom: true);
        _soldiers = Multi(MeshKit.Soldier(), antMat, custom: true);
        var alate = MeshKit.Alate();
        alate.SurfaceSetMaterial(0, antMat);
        alate.SurfaceSetMaterial(1, new ShaderMaterial { Shader = new Shader { Code = WingShader } });
        _alates = Multi(alate, null, custom: true);

        var matte = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.9f };
        var glossy = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.35f };
        _soil = Multi(MeshKit.Blob(new Vector3(0.1f, 0.09f, 0.1f), Colors.White, 5, 7), matte, colors: true);
        _food = Multi(MeshKit.Blob(new Vector3(0.12f, 0.1f, 0.11f), Colors.White, 5, 8), glossy, colors: true);
        var broodMat = new StandardMaterial3D
        {
            VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true,
            Roughness = 0.4f,
            Rim = 0.4f,
            RimEnabled = true,
        };
        _eggs = Multi(MeshKit.Blob(new Vector3(0.11f, 0.08f, 0.08f), Palette.Egg, 6, 8), broodMat);
        _larvae = Multi(MeshKit.Blob(new Vector3(0.17f, 0.095f, 0.095f), Palette.Larva, 7, 10), broodMat, colors: true);

        _queen = new MeshInstance3D { Mesh = MeshKit.Ant(), MaterialOverride = antMat };
        AddChild(_queen);
        _spiderMesh = MeshKit.Spider();
        _spiderMat = new ShaderMaterial { Shader = new Shader { Code = SpiderShader } };
        Tick();
        Tick();
    }

    private MultiMeshInstance3D Multi(Mesh mesh, Material? mat, bool colors = false, bool custom = false)
    {
        var mm = new MultiMesh
        {
            TransformFormat = MultiMesh.TransformFormatEnum.Transform3D,
            UseColors = colors,
            UseCustomData = custom,
            Mesh = mesh,
        };
        var inst = new MultiMeshInstance3D { Multimesh = mm };
        if (mat != null) inst.MaterialOverride = mat;
        AddChild(inst);
        return inst;
    }

    private static void Ensure(MultiMesh mm, int count)
    {
        if (mm.InstanceCount >= count) return;
        mm.InstanceCount = Mathf.Max(count, Mathf.Max(64, mm.InstanceCount * 2));
    }

    /// <summary>Called after every simulation tick: work out where each ant is now.</summary>
    public void Tick()
    {
        var w = _sim.World;
        foreach (var kv in _curr) _prev[kv.Key] = kv.Value;
        _curr.Clear();
        foreach (var a in _sim.Ants) _curr[a.Id] = AntTransform(w, a);
        foreach (var id in new List<int>(_prev.Keys))
            if (!_curr.ContainsKey(id)) _prev.Remove(id);
        UpdateBrood(w);
        _queen.Transform = QueenTransform(w);
        _queen.Visible = _sim.QueenAlive && _sim.QueenCell > w.Width;
        TickSpiders();
    }

    /// <summary>Called every frame with how far we are toward the next tick (0..1).</summary>
    public void Draw(float alpha)
    {
        int n = _sim.Ants.Count;
        Ensure(_workers.Multimesh, n);
        Ensure(_soldiers.Multimesh, n);
        Ensure(_alates.Multimesh, n);
        Ensure(_soil.Multimesh, n);
        Ensure(_food.Multimesh, n);
        int workers = 0, soldiers = 0, alates = 0, soil = 0, food = 0;
        foreach (var a in _sim.Ants)
        {
            var cur = _curr.TryGetValue(a.Id, out var c) ? c : Transform3D.Identity;
            var t = _prev.TryGetValue(a.Id, out var p) ? p.InterpolateWith(cur, alpha) : cur;
            bool walking = a.Moving || a.Job is AntJob.Digging or AntJob.Fighting || a.Grabbed;
            var custom = new Color(walking ? 1f : 0.15f, a.Id * 1.7f % 6.28f, a.Job == AntJob.Flying ? 1f : 0f, 0);
            var mm = a.Caste switch { Caste.Soldier => _soldiers.Multimesh, Caste.Alate => _alates.Multimesh, _ => _workers.Multimesh };
            int k = a.Caste switch { Caste.Soldier => soldiers++, Caste.Alate => alates++, _ => workers++ };
            mm.SetInstanceTransform(k, t);
            mm.SetInstanceCustomData(k, custom);
            if (a.Carrying == Carry.Soil)
            {
                _soil.Multimesh.SetInstanceTransform(soil, new Transform3D(Basis.Identity, t * CarryOffset));
                _soil.Multimesh.SetInstanceColor(soil++, Palette.Soil(CellType.Clay) * 0.9f);
            }
            else if (a.Carrying == Carry.Food)
            {
                _food.Multimesh.SetInstanceTransform(food, new Transform3D(Basis.Identity, t * CarryOffset));
                _food.Multimesh.SetInstanceColor(food++, a.Id % 3 == 0 ? Palette.Berry : Palette.Crumb);
            }
        }
        _workers.Multimesh.VisibleInstanceCount = workers;
        _soldiers.Multimesh.VisibleInstanceCount = soldiers;
        _alates.Multimesh.VisibleInstanceCount = alates;
        _soil.Multimesh.VisibleInstanceCount = soil;
        _food.Multimesh.VisibleInstanceCount = food;
        DrawSpiders(alpha);
    }

    private Transform3D AntTransform(World w, Ant a)
    {
        if (a.Job == AntJob.Flying) return FlyingTransform(w, a);
        if (a.Grabbed) return HeldTransform(w, a);
        var from = Spot(w, a, a.Cell);
        var pos = a.Moving ? from.Lerp(Spot(w, a, a.Next), a.T) : from;
        float fx = a.FacingX, fy = a.FacingY;
        if (!a.Moving && a.Job != AntJob.Digging) { fx = a.Side; fy = 0; }
        int cell = a.Moving && a.T > 0.5f ? a.Next : a.Cell;
        if (OnBackWall(w, cell))
        {
            // Off the floor, ants crawl on the back wall of the farm, belly to the soil.
            var heading = new Vector3(fx, -fy, 0);
            if (heading == Vector3.Zero) heading = new Vector3(a.Side, 0, 0);
            heading = heading.Normalized();
            var normal = Vector3.Back;
            var side = heading.Cross(normal);
            return new Transform3D(new Basis(heading, normal, -side), pos);
        }
        // On a floor: the model faces +X; mirror it to walk left, tilt it on a slope.
        float s = fx != 0 ? Mathf.Sign(fx) : a.Side;
        float pitch = fy == 0 || fx == 0 ? 0 : Mathf.Pi / 4 * -Mathf.Sign(fy);
        var basis = new Basis(Vector3.Up, s < 0 ? Mathf.Pi : 0) * new Basis(Vector3.Back, pitch);
        if (a.Caste == Caste.Alate) basis = basis.Scaled(new Vector3(1.3f, 1.3f, 1.3f));
        return new Transform3D(basis, pos);
    }

    /// <summary>A winged queen rising from the mound: up, drifting with the breeze, nose high.</summary>
    private Transform3D FlyingTransform(World w, Ant a)
    {
        var start = Spot(w, a, a.Cell);
        float f = a.Flight;
        float rise = Mathf.Pow(f, 1.35f) * 2.2f;
        var pos = start + new Vector3(Mathf.Sin(f * 1.3f + a.Id) * 1.5f + f * 0.8f * a.Side, rise, -f * 1.6f);
        var basis = new Basis(Vector3.Up, a.Side < 0 ? Mathf.Pi : 0) * new Basis(Vector3.Back, 0.6f);
        return new Transform3D(basis.Scaled(new Vector3(1.4f, 1.4f, 1.4f)), pos);
    }

    private Transform3D HeldTransform(World w, Ant a)
    {
        foreach (var s in _sim.Spiders)
        {
            if (s.PreyId != a.Id) continue;
            var pos = new Vector3(s.X - w.Width / 2f + s.Dir * 1.05f, _surface.GroundHeight(s.X) + 0.35f, -0.1f);
            var basis = new Basis(Vector3.Up, s.Dir < 0 ? 0 : Mathf.Pi) * new Basis(Vector3.Back, 1.2f);
            return new Transform3D(basis, pos);
        }
        return new Transform3D(Basis.Identity, Spot(w, a, a.Cell));
    }

    /// <summary>A cell with no floor under it (a shaft, or the upper part of a room).</summary>
    private static bool OnBackWall(World w, int cell)
    {
        int x = w.X(cell), y = w.Y(cell);
        return y > 0 && y + 1 < w.Height && w.IsWalkable(w.Index(x, y + 1));
    }

    private Vector3 Spot(World w, Ant a, int cell)
    {
        var p = Layout.AntSpot(w, cell);
        if (w.Y(cell) == 0)
        {
            p.Y += _surface.GroundHeight(w.X(cell) + 0.5f);
            p.Z = ((a.Id * 37) % 7 - 3) * 0.07f;
        }
        else if (OnBackWall(w, cell))
        {
            p.Y = Layout.RowTop(w.Y(cell)) - 0.5f + ((a.Id * 13) % 5 - 2) * 0.08f;
            p.Z = Layout.BackZ + 0.02f;
        }
        else p.Z = ((a.Id * 37) % 7 - 3) * 0.07f;
        return p;
    }

    private Transform3D QueenTransform(World w)
    {
        var p = Layout.AntSpot(w, _sim.QueenCell);
        var basis = new Basis(Vector3.Up, 0).Scaled(new Vector3(1.9f, 1.6f, 1.7f));
        return new Transform3D(basis, p + new Vector3(0, -0.02f, 0));
    }

    private void UpdateBrood(World w)
    {
        int eggs = 0, larvae = 0;
        Ensure(_eggs.Multimesh, _sim.Brood.Count);
        Ensure(_larvae.Multimesh, _sim.Brood.Count);
        var perCell = new Dictionary<int, int>();
        foreach (var b in _sim.Brood)
        {
            perCell.TryGetValue(b.Cell, out int n);
            perCell[b.Cell] = n + 1;
            var p = Layout.AntSpot(w, b.Cell);
            float jx = (b.Jitter - 0.5f) * 0.7f;
            float jz = ((b.Jitter * 7.3f) % 1f - 0.5f) * 0.9f;
            var basis = new Basis(Vector3.Up, b.Jitter * 6.28f);
            if (b.Stage == BroodStage.Egg)
            {
                var pos = p + new Vector3(jx, 0.08f + n * 0.12f, jz);
                _eggs.Multimesh.SetInstanceTransform(eggs++, new Transform3D(basis, pos));
            }
            else
            {
                // Queen larvae are fat and a little golden.
                float s = b.Caste == Caste.Alate ? 1.45f : b.Caste == Caste.Soldier ? 1.15f : 1f;
                var pos = p + new Vector3(jx, 0.095f * s + n * 0.12f, jz);
                var lb = (basis * new Basis(Vector3.Back, 0.4f)).Scaled(new Vector3(s, s, s));
                _larvae.Multimesh.SetInstanceTransform(larvae, new Transform3D(lb, pos));
                _larvae.Multimesh.SetInstanceColor(larvae++, b.Caste == Caste.Alate ? new Color(1f, 0.92f, 0.7f) : Colors.White);
            }
        }
        _eggs.Multimesh.VisibleInstanceCount = eggs;
        _larvae.Multimesh.VisibleInstanceCount = larvae;
    }

    // ---------- spiders ----------

    private void TickSpiders()
    {
        foreach (var s in _sim.Spiders)
        {
            if (!_spiders.ContainsKey(s))
            {
                var mi = new MeshInstance3D { Mesh = _spiderMesh, MaterialOverride = _spiderMat };
                AddChild(mi);
                _spiders[s] = mi;
                _spiderX[s] = (s.X, s.X);
            }
            _spiderX[s] = (_spiderX[s].Curr, s.X);
        }
        foreach (var s in new List<Spider>(_spiders.Keys))
        {
            if (_sim.Spiders.Contains(s)) continue;
            _spiders[s].QueueFree();
            _spiders.Remove(s);
            _spiderX.Remove(s);
        }
    }

    private void DrawSpiders(float alpha)
    {
        var w = _sim.World;
        foreach (var (s, mi) in _spiders)
        {
            var (prev, curr) = _spiderX[s];
            float x = Mathf.Lerp(prev, curr, alpha);
            float y = _surface.GroundHeight(x);
            var basis = new Basis(Vector3.Up, s.Dir < 0 ? Mathf.Pi : 0);
            mi.Transform = new Transform3D(basis, new Vector3(x - w.Width / 2f, y, -0.6f));
            bool walking = Mathf.Abs(curr - prev) > 0.01f || s.Fighting;
            mi.SetInstanceShaderParameter("walking", walking ? 1f : 0.1f);
            mi.SetInstanceShaderParameter("phase", s.GetHashCode() % 7);
        }
    }

    /// <summary>The spider meshes, for the surface view to draw a dead spider as food.</summary>
    public Mesh SpiderMesh => _spiderMesh;
    public Material SpiderMaterial => _spiderMat;
}
