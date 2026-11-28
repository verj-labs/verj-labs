using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Layers drawn over the slab from one small data texture per tick: water in the tunnels,
/// striped dig orders, room tints. Also the glowing scent trail on the surface.
/// </summary>
public partial class OverlayView : Node3D
{
    private World _world = null!;
    private Image _image = null!;
    private ImageTexture _texture = null!;
    private byte[] _bytes = null!;
    private Image _scentImage = null!;
    private ImageTexture _scentTexture = null!;
    private byte[] _scentBytes = null!;
    private MeshInstance3D _scent = null!;

    public bool ShowScent
    {
        get => _scent.Visible;
        set => _scent.Visible = value;
    }

    private const string SlabShader = @"
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D data_n : filter_nearest;
uniform sampler2D data_l : filter_linear;
uniform vec2 grid;
void fragment() {
    vec4 n = texture(data_n, UV);
    vec4 l = texture(data_l, UV);
    vec2 cell = UV * grid;
    vec3 col = vec3(0.0);
    float a = 0.0;
    if (n.g > 0.01) {
        float stripe = step(0.5, fract((cell.x + cell.y) * 0.5));
        col = vec3(0.95, 0.72, 0.32);
        a = 0.10 + 0.24 * stripe * (1.0 - (n.g - 0.5) * 1.6);
    }
    float w = smoothstep(0.03, 0.4, l.r) * smoothstep(0.3, 0.7, l.a);
    if (w > 0.0) {
        float shimmer = 0.9 + 0.1 * sin(TIME * 2.0 + cell.x * 0.7 + cell.y * 0.3);
        col = mix(col, vec3(0.10, 0.30, 0.55) * shimmer, w);
        a = max(a, 0.82 * w);
    }
    ALBEDO = col;
    ALPHA = a;
}";

    private const string ScentShader = @"
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D scent : filter_linear;
void fragment() {
    float s = texture(scent, vec2(UV.x, 0.5)).r;
    float across = 1.0 - abs(UV.y - 0.5) * 2.0;
    float glow = clamp(s * 1.4, 0.0, 1.0) * smoothstep(0.3, 1.0, across);
    ALBEDO = vec3(0.9, 0.7, 0.25) * glow * 0.35;
    ALPHA = glow;
}";

    public void Init(World world)
    {
        _world = world;
        int w = world.Width, h = world.Height - 1;
        _bytes = new byte[w * h * 4];
        _image = Image.CreateFromData(w, h, false, Image.Format.Rgba8, _bytes);
        _texture = ImageTexture.CreateFromImage(_image);
        var mat = new ShaderMaterial { Shader = new Shader { Code = SlabShader } };
        mat.SetShaderParameter("data_n", _texture);
        mat.SetShaderParameter("data_l", _texture);
        mat.SetShaderParameter("grid", new Vector2(w, h));
        AddChild(new MeshInstance3D
        {
            Mesh = new QuadMesh { Size = new Vector2(w, h) },
            Position = new Vector3(0, -h / 2f, Layout.FrontZ + 0.03f),
            MaterialOverride = mat,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
        });

        _scentBytes = new byte[w * 4];
        _scentImage = Image.CreateFromData(w, 1, false, Image.Format.Rgba8, _scentBytes);
        _scentTexture = ImageTexture.CreateFromImage(_scentImage);
        var smat = new ShaderMaterial { Shader = new Shader { Code = ScentShader } };
        smat.SetShaderParameter("scent", _scentTexture);
        _scent = new MeshInstance3D
        {
            Mesh = new PlaneMesh { Size = new Vector2(w, 0.8f) },
            Position = new Vector3(0, 0.04f, 0),
            MaterialOverride = smat,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
        };
        AddChild(_scent);
        Refresh();
    }

    public void Refresh()
    {
        var wd = _world;
        int w = wd.Width, h = wd.Height - 1;
        for (int y = 1; y < wd.Height; y++)
        for (int x = 0; x < w; x++)
        {
            int i = wd.Index(x, y);
            int p = ((y - 1) * w + x) * 4;
            _bytes[p] = (byte)(Mathf.Clamp(wd.Water[i], 0, 1) * 255);
            _bytes[p + 1] = wd.DigOrder[i] ? (byte)(128 + Mathf.Clamp(wd.DigProgress[i], 0, 1) * 127) : (byte)0;
            _bytes[p + 2] = wd.Rooms[i] switch { Room.Nursery => 128, Room.Store => 255, _ => 0 };
            _bytes[p + 3] = wd.Cells[i] == CellType.Tunnel ? (byte)255 : (byte)0;
        }
        _image.SetData(w, h, false, Image.Format.Rgba8, _bytes);
        _texture.Update(_image);

        for (int x = 0; x < w; x++)
        {
            _scentBytes[x * 4] = (byte)(Mathf.Clamp(wd.Scent[x] / 4f, 0, 1) * 255);
            _scentBytes[x * 4 + 3] = 255;
        }
        _scentImage.SetData(w, 1, false, Image.Format.Rgba8, _scentBytes);
        _scentTexture.Update(_scentImage);
    }
}
