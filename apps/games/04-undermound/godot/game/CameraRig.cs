using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// A camera that looks at the front of the ant farm. Pan with right-drag or WASD, zoom with
/// the wheel. Close to the surface it tilts down so the garden fills the view.
/// </summary>
public partial class CameraRig : Node3D
{
    public Camera3D Camera { get; private set; } = null!;
    public Vector3 Target = new(0, -12, 0);
    public float Distance = 60f;
    public float Pitch = -6f;      // degrees; negative looks down
    public float Yaw = 0f;
    public bool AutoTilt = true;

    private bool _dragging;
    private CameraAttributesPractical _attributes = null!;

    public const float MinDistance = 5f;
    public const float MaxDistance = 150f;

    public override void _Ready()
    {
        _attributes = new CameraAttributesPractical();
        Camera = new Camera3D { Fov = 38, Near = 0.05f, Far = 800, Attributes = _attributes };
        AddChild(Camera);
        Apply();
    }

    public void SetDepthOfField(bool on, float focus = 10f)
    {
        _attributes.DofBlurFarEnabled = on;
        _attributes.DofBlurFarDistance = focus + 6f;
        _attributes.DofBlurFarTransition = focus * 1.5f;
        _attributes.DofBlurNearEnabled = on;
        _attributes.DofBlurNearDistance = Mathf.Max(0.5f, focus * 0.35f);
        _attributes.DofBlurNearTransition = 1.5f;
        _attributes.DofBlurAmount = 0.12f;
    }

    public void Apply()
    {
        float half = SimConfig.Width / 2f;
        Target.X = Mathf.Clamp(Target.X, -half, half);
        Target.Y = Mathf.Clamp(Target.Y, -SimConfig.Height, 14);
        Distance = Mathf.Clamp(Distance, MinDistance, MaxDistance);
        float pitch = Pitch;
        if (AutoTilt)
        {
            // Near the surface and zoomed in, look down at the garden a little more.
            float nearTop = Mathf.Clamp((Target.Y + 6f) / 8f, 0, 1);
            float close = Mathf.Clamp(1f - (Distance - 8f) / 30f, 0, 1);
            pitch = Mathf.Lerp(Pitch, -16f, nearTop * close);
        }
        var basis = new Basis(Vector3.Up, Mathf.DegToRad(Yaw)) * new Basis(Vector3.Right, Mathf.DegToRad(pitch));
        Camera.GlobalTransform = new Transform3D(basis, Target + basis * new Vector3(0, 0, Distance));
    }

    public override void _UnhandledInput(InputEvent e)
    {
        if (e is InputEventMouseButton mb)
        {
            if (mb.ButtonIndex == MouseButton.WheelUp && mb.Pressed) Zoom(0.88f, mb.Position);
            else if (mb.ButtonIndex == MouseButton.WheelDown && mb.Pressed) Zoom(1f / 0.88f, mb.Position);
            else if (mb.ButtonIndex == MouseButton.Right) _dragging = mb.Pressed;
        }
        else if (e is InputEventMouseMotion mm && _dragging)
        {
            float perPixel = Distance * 0.0013f;
            Target += new Vector3(-mm.Relative.X * perPixel, mm.Relative.Y * perPixel, 0);
            Apply();
        }
    }

    private void Zoom(float factor, Vector2 mouse)
    {
        // Zoom toward the point under the mouse.
        var before = PointOnSlab(mouse);
        Distance *= factor;
        Apply();
        var after = PointOnSlab(mouse);
        if (before.HasValue && after.HasValue) Target += before.Value - after.Value;
        Apply();
    }

    public override void _Process(double delta)
    {
        var move = Vector3.Zero;
        if (Input.IsKeyPressed(Key.A) || Input.IsKeyPressed(Key.Left)) move.X -= 1;
        if (Input.IsKeyPressed(Key.D) || Input.IsKeyPressed(Key.Right)) move.X += 1;
        if (Input.IsKeyPressed(Key.W) || Input.IsKeyPressed(Key.Up)) move.Y += 1;
        if (Input.IsKeyPressed(Key.S) || Input.IsKeyPressed(Key.Down)) move.Y -= 1;
        if (move == Vector3.Zero) return;
        Target += move * Distance * 0.9f * (float)delta;
        Apply();
    }

    /// <summary>The point on the front face of the slab under a screen position.</summary>
    public Vector3? PointOnSlab(Vector2 screen)
    {
        var origin = Camera.ProjectRayOrigin(screen);
        var dir = Camera.ProjectRayNormal(screen);
        if (Mathf.Abs(dir.Z) < 1e-5f) return null;
        float t = (Layout.FrontZ - origin.Z) / dir.Z;
        return t > 0 ? origin + dir * t : null;
    }
}
