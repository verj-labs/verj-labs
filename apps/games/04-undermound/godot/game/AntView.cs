using System.Collections.Generic;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Draws every ant, what it carries, the brood and the queen, with MultiMesh so thousands are
/// cheap. Positions are interpolated between simulation ticks for smooth movement.
/// </summary>
public partial class AntView : Node3D
{
    private Sim _sim = null!;
    private SurfaceView _surface = null!;
    private MultiMeshInstance3D _ants = null!, _soil = null!, _food = null!, _eggs = null!, _larvae = null!;
    private MeshInstance3D _queen = null!;

    private readonly Dictionary<int, Transform3D> _prev = new();
    private readonly Dictionary<int, Transform3D> _curr = new();
    private readonly List<Ant> _order = new();

    private static readonly Vector3 CarryOffset = new(0.42f, 0.16f, 0);

    private const string AntShader = @"
shader_type spatial;
render_mode cull_disabled;
uniform float speed = 22.0;
void vertex() {
    float leg = UV2.x;
    if (leg > 0.5) {
        float phase = INSTANCE_CUSTOM.y + (UV2.y > 0.5 ? 3.14159 : 0.0);
        float swing = sin(TIME * speed + phase) * INSTANCE_CUSTOM.x;
        float lift = max(0.0, cos(TIME * speed + phase)) * INSTANCE_CUSTOM.x;
        float k = clamp(1.0 - VERTEX.y / 0.24, 0.0, 1.0);
        VERTEX.x += swing * 0.07 * k;
        VERTEX.y += lift * 0.035 * k;
    }
}
void fragment() {
    ALBEDO = pow(COLOR.rgb, vec3(2.2));
    ROUGHNESS = 0.32;
    SPECULAR = 0.7;
    RIM = 0.25;
    RIM_TINT = 0.6;
}";

    public void Init(Sim sim, SurfaceView surface)
    {
        _sim = sim;
        _surface = surface;
        var antMat = new ShaderMaterial { Shader = new Shader { Code = AntShader } };
        _ants = Multi(MeshKit.Ant(), antMat, custom: true);

        var matte = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.9f };
        var glossy = new StandardMaterial3D { VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true, Roughness = 0.35f };
        _soil = Multi(MeshKit.Blob(new Vector3(0.1f, 0.09f, 0.1f), Colors.White, 5, 7), matte, colors: true);
        _food = Multi(MeshKit.Blob(new Vector3(0.12f, 0.1f, 0.11f), Colors.White, 5, 8), glossy, colors: true);
        var broodMat = new StandardMaterial3D
        {
            VertexColorUseAsAlbedo = true, VertexColorIsSrgb = true,
            Roughness = 0.4f,
            SubsurfScatterEnabled = false,
            Rim = 0.4f,
            RimEnabled = true,
        };
        _eggs = Multi(MeshKit.Blob(new Vector3(0.11f, 0.08f, 0.08f), Palette.Egg, 6, 8), broodMat);
        _larvae = Multi(MeshKit.Blob(new Vector3(0.17f, 0.095f, 0.095f), Palette.Larva, 7, 10), broodMat);

        _queen = new MeshInstance3D { Mesh = MeshKit.Ant(), MaterialOverride = antMat };
        AddChild(_queen);
        Tick();
        Tick();
    }

    private MultiMeshInstance3D Multi(Mesh mesh, Material mat, bool colors = false, bool custom = false)
    {
        var mm = new MultiMesh
        {
            TransformFormat = MultiMesh.TransformFormatEnum.Transform3D,
            UseColors = colors,
            UseCustomData = custom,
            Mesh = mesh,
        };
        var inst = new MultiMeshInstance3D { Multimesh = mm, MaterialOverride = mat };
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
        _queen.Visible = _sim.QueenCell > w.Width;
    }

    /// <summary>Called every frame with how far we are toward the next tick (0..1).</summary>
    public void Draw(float alpha)
    {
        var mm = _ants.Multimesh;
        Ensure(mm, _sim.Ants.Count);
        int soil = 0, food = 0;
        _order.Clear();
        _order.AddRange(_sim.Ants);
        Ensure(_soil.Multimesh, _order.Count);
        Ensure(_food.Multimesh, _order.Count);
        for (int k = 0; k < _order.Count; k++)
        {
            var a = _order[k];
            var cur = _curr.TryGetValue(a.Id, out var c) ? c : Transform3D.Identity;
            var t = _prev.TryGetValue(a.Id, out var p) ? p.InterpolateWith(cur, alpha) : cur;
            mm.SetInstanceTransform(k, t);
            bool walking = a.Moving || a.Job == AntJob.Digging;
            mm.SetInstanceCustomData(k, new Color(walking ? 1f : 0.15f, a.Id * 1.7f % 6.28f, 0, 0));
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
        mm.VisibleInstanceCount = _order.Count;
        _soil.Multimesh.VisibleInstanceCount = soil;
        _food.Multimesh.VisibleInstanceCount = food;
    }

    private Transform3D AntTransform(World w, Ant a)
    {
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
        return new Transform3D(basis, pos);
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
                var pos = p + new Vector3(jx, 0.095f + n * 0.12f, jz);
                _larvae.Multimesh.SetInstanceTransform(larvae++, new Transform3D(basis * new Basis(Vector3.Back, 0.4f), pos));
            }
        }
        _eggs.Multimesh.VisibleInstanceCount = eggs;
        _larvae.Multimesh.VisibleInstanceCount = larvae;
    }
}
