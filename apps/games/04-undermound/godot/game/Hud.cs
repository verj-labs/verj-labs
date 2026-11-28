using System;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

public enum Tool { Dig, Nursery, Store, Cancel }

/// <summary>The on-screen interface: colony stats, weather, messages and the tool bar.</summary>
public partial class Hud : CanvasLayer
{
    public event Action<Tool>? ToolPicked;
    public event Action<int>? SpeedPicked;
    public event Action? RainPicked;
    public event Action? ScentToggled;

    private Label _stats = null!, _weather = null!, _log = null!, _hint = null!;
    private PanelContainer _bar = null!, _logBox = null!;
    private readonly Button[] _tools = new Button[4];
    private readonly Button[] _speeds = new Button[4];

    private static readonly Color Panel = new(0.09f, 0.065f, 0.045f, 0.82f);
    private static readonly Color Cream = new(0.96f, 0.91f, 0.80f);
    private static readonly Color Amber = new(1f, 0.74f, 0.3f);

    public override void _Ready()
    {
        var theme = new Theme { DefaultFontSize = 17 };
        var root = new Control { Theme = theme };
        root.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        root.MouseFilter = Control.MouseFilterEnum.Ignore;
        AddChild(root);

        // Top-left: title and stats.
        var top = Box(new Vector2(18, 16));
        root.AddChild(top);
        var col = new VBoxContainer();
        top.AddChild(col);
        var title = new Label { Text = "UNDERMOUND" };
        title.AddThemeColorOverride("font_color", Amber);
        title.AddThemeFontSizeOverride("font_size", 22);
        col.AddChild(title);
        _stats = Text(col);
        _weather = Text(col);

        // Top-right: messages.
        var logBox = _logBox = Box(Vector2.Zero);
        logBox.CustomMinimumSize = new Vector2(420, 0);
        root.AddChild(logBox);
        _log = Text(logBox);
        _log.AutowrapMode = TextServer.AutowrapMode.WordSmart;
        _log.CustomMinimumSize = new Vector2(396, 0);

        // Bottom: tools and speed.
        var bar = _bar = Box(Vector2.Zero);
        root.AddChild(bar);
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 8);
        bar.AddChild(row);
        string[] names = { "1  Dig", "2  Nursery", "3  Food store", "4  Cancel" };
        for (int k = 0; k < 4; k++)
        {
            int tool = k;
            _tools[k] = MakeButton(names[k], () => ToolPicked?.Invoke((Tool)tool));
            row.AddChild(_tools[k]);
        }
        row.AddChild(new VSeparator());
        row.AddChild(MakeButton("R  Rain", () => RainPicked?.Invoke()));
        row.AddChild(MakeButton("T  Scent", () => ScentToggled?.Invoke()));
        row.AddChild(new VSeparator());
        string[] speeds = { "II", "1×", "2×", "4×" };
        for (int k = 0; k < 4; k++)
        {
            int speed = k;
            _speeds[k] = MakeButton(speeds[k], () => SpeedPicked?.Invoke(speed));
            _speeds[k].CustomMinimumSize = new Vector2(44, 0);
            row.AddChild(_speeds[k]);
        }

        _hint = new Label { Text = "Left drag: use tool   Right drag / WASD: move   Wheel: zoom   [ ]: brush size" };
        _hint.AddThemeColorOverride("font_color", new Color(Cream, 0.7f));
        _hint.AddThemeFontSizeOverride("font_size", 13);
        root.AddChild(_hint);
    }

    private static PanelContainer Box(Vector2 position)
    {
        var style = new StyleBoxFlat
        {
            BgColor = Panel,
            CornerRadiusTopLeft = 10, CornerRadiusTopRight = 10,
            CornerRadiusBottomLeft = 10, CornerRadiusBottomRight = 10,
            ContentMarginLeft = 14, ContentMarginRight = 14, ContentMarginTop = 10, ContentMarginBottom = 10,
            BorderColor = new Color(0.55f, 0.38f, 0.2f, 0.7f),
            BorderWidthBottom = 1, BorderWidthTop = 1, BorderWidthLeft = 1, BorderWidthRight = 1,
        };
        var p = new PanelContainer { Position = position };
        p.AddThemeStyleboxOverride("panel", style);
        return p;
    }

    private static Label Text(Control parent)
    {
        var l = new Label();
        l.AddThemeColorOverride("font_color", Cream);
        parent.AddChild(l);
        return l;
    }

    private static Button MakeButton(string text, Action onPress)
    {
        var b = new Button { Text = text, ToggleMode = false, FocusMode = Control.FocusModeEnum.None };
        var normal = new StyleBoxFlat
        {
            BgColor = new Color(0.22f, 0.15f, 0.09f),
            CornerRadiusTopLeft = 6, CornerRadiusTopRight = 6, CornerRadiusBottomLeft = 6, CornerRadiusBottomRight = 6,
            ContentMarginLeft = 12, ContentMarginRight = 12, ContentMarginTop = 6, ContentMarginBottom = 6,
        };
        var hover = (StyleBoxFlat)normal.Duplicate();
        hover.BgColor = new Color(0.32f, 0.22f, 0.12f);
        b.AddThemeStyleboxOverride("normal", normal);
        b.AddThemeStyleboxOverride("hover", hover);
        b.AddThemeStyleboxOverride("pressed", hover);
        b.AddThemeColorOverride("font_color", Cream);
        b.Pressed += onPress;
        return b;
    }

    /// <summary>Show or hide the tool bar and hint (screenshots hide them for a cleaner frame).</summary>
    public void SetBarVisible(bool on)
    {
        _bar.Visible = on;
        _hint.Visible = on;
    }

    private void Place()
    {
        var size = GetViewport().GetVisibleRect().Size;
        _bar.Position = new Vector2((size.X - _bar.Size.X) / 2, size.Y - _bar.Size.Y - 34);
        _hint.Position = new Vector2((size.X - _hint.Size.X) / 2, size.Y - 26);
        _logBox.Position = new Vector2(size.X - _logBox.Size.X - 18, 16);
    }

    public void Show(Sim sim, Tool tool, int speed, int brush)
    {
        Place();
        _stats.Text = $"Workers {sim.Ants.Count}    Eggs {sim.Eggs}    Larvae {sim.Larvae}\n"
                      + $"Food {sim.Food:0}/{sim.FoodCapacity:0}    Day {sim.Day + 1:0.0}    Brush {brush}";
        _weather.Text = sim.Raining
            ? $"Raining ({sim.RainLeft:0}s left)"
            : $"Rain in {(int)sim.RainIn / 60}:{(int)sim.RainIn % 60:00}";
        _weather.AddThemeColorOverride("font_color", sim.Raining || sim.RainIn < SimConfig.RainWarningSeconds
            ? new Color(0.6f, 0.8f, 1f) : Cream);
        var lines = new System.Text.StringBuilder();
        int from = Math.Max(0, sim.Log.Count - 4);
        for (int k = from; k < sim.Log.Count; k++)
            lines.Append($"Day {sim.Log[k].Time / SimConfig.DaySeconds + 1:0.0}  {sim.Log[k].Text}\n");
        _log.Text = lines.Length > 0 ? lines.ToString().TrimEnd() : "The colony is settling in.";
        for (int k = 0; k < 4; k++) Highlight(_tools[k], k == (int)tool);
        for (int k = 0; k < 4; k++) Highlight(_speeds[k], k == speed);
    }

    private static void Highlight(Button b, bool on) =>
        b.AddThemeColorOverride("font_color", on ? Amber : Cream);
}
