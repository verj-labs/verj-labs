using System;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

public enum Tool { Dig, Nursery, Store, Trail, Avoid, Cancel }

/// <summary>
/// The on-screen interface: colony and season stats, priority sliders, messages, the tool bar,
/// an alert banner, and the title, year report and game over screens.
/// </summary>
public partial class Hud : CanvasLayer
{
    public event Action<Tool>? ToolPicked;
    public event Action<int>? SpeedPicked;
    public event Action? RainPicked;
    public event Action? ScentToggled;
    public event Action? StartPressed;
    public event Action? ContinuePressed;
    public event Action? RestartPressed;

    private Label _season = null!, _colony = null!, _brood = null!, _food = null!, _weather = null!, _queen = null!;
    private ProgressBar _foodBar = null!;
    private Label _log = null!, _hint = null!, _banner = null!;
    private PanelContainer _info = null!, _prio = null!, _bar = null!, _logBox = null!, _bannerBox = null!, _modal = null!;
    private VBoxContainer _modalBody = null!;
    private readonly Button[] _tools = new Button[6];
    private readonly Button[] _speeds = new Button[4];
    private HSlider _dig = null!, _forage = null!, _nurse = null!, _soldiers = null!;
    private Priorities? _priorities;
    private StyleBoxFlat _bannerStyle = null!;

    private static readonly Color Panel = new(0.09f, 0.065f, 0.045f, 0.84f);
    private static readonly Color Cream = new(0.96f, 0.91f, 0.80f);
    private static readonly Color Amber = new(1f, 0.74f, 0.3f);
    private static readonly Color Danger = new(1f, 0.42f, 0.35f);

    public bool ModalOpen => _modal.Visible;

    public override void _Ready()
    {
        var theme = new Theme { DefaultFontSize = 16 };
        var root = new Control { Theme = theme, MouseFilter = Control.MouseFilterEnum.Ignore };
        root.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        AddChild(root);

        BuildInfo(root);
        BuildPriorities(root);
        _logBox = Box();
        _logBox.CustomMinimumSize = new Vector2(430, 0);
        root.AddChild(_logBox);
        _log = Text(_logBox);
        _log.AutowrapMode = TextServer.AutowrapMode.WordSmart;
        _log.CustomMinimumSize = new Vector2(404, 0);
        BuildBar(root);
        BuildBanner(root);
        BuildModal(root);
    }

    // ---------- building ----------

    private void BuildInfo(Control root)
    {
        _info = Box();
        root.AddChild(_info);
        var col = new VBoxContainer();
        col.AddThemeConstantOverride("separation", 3);
        _info.AddChild(col);
        var title = new Label { Text = "UNDERMOUND" };
        title.AddThemeColorOverride("font_color", Amber);
        title.AddThemeFontSizeOverride("font_size", 22);
        col.AddChild(title);
        _season = Text(col);
        _colony = Text(col);
        _brood = Text(col);
        var foodRow = new HBoxContainer();
        col.AddChild(foodRow);
        _food = Text(foodRow);
        _food.CustomMinimumSize = new Vector2(120, 0);
        _foodBar = new ProgressBar { ShowPercentage = false, CustomMinimumSize = new Vector2(150, 14), SizeFlagsVertical = Control.SizeFlags.ShrinkCenter };
        _foodBar.AddThemeStyleboxOverride("background", Flat(new Color(0.2f, 0.14f, 0.09f), 4));
        _foodBar.AddThemeStyleboxOverride("fill", Flat(new Color(0.85f, 0.62f, 0.25f), 4));
        foodRow.AddChild(_foodBar);
        _weather = Text(col);
        _queen = Text(col);
    }

    private void BuildPriorities(Control root)
    {
        _prio = Box();
        root.AddChild(_prio);
        var col = new VBoxContainer();
        _prio.AddChild(col);
        var head = new Label { Text = "WORKERS" };
        head.AddThemeColorOverride("font_color", Amber);
        head.AddThemeFontSizeOverride("font_size", 14);
        col.AddChild(head);
        _dig = Slider(col, "Dig", 1, v => { if (_priorities != null) _priorities.Dig = v; });
        _forage = Slider(col, "Forage", 1, v => { if (_priorities != null) _priorities.Forage = v; });
        _nurse = Slider(col, "Nurse", 1, v => { if (_priorities != null) _priorities.Nurse = v; });
        var head2 = new Label { Text = "NEW BROOD" };
        head2.AddThemeColorOverride("font_color", Amber);
        head2.AddThemeFontSizeOverride("font_size", 14);
        col.AddChild(head2);
        _soldiers = Slider(col, "Soldiers", 0.4f, v => { if (_priorities != null) _priorities.Soldiers = v; });
    }

    private HSlider Slider(Control parent, string name, float max, Action<float> changed)
    {
        var row = new HBoxContainer();
        parent.AddChild(row);
        var label = Text(row);
        label.Text = name;
        label.CustomMinimumSize = new Vector2(72, 0);
        var s = new HSlider { MinValue = 0, MaxValue = max, Step = max / 20, CustomMinimumSize = new Vector2(150, 20), FocusMode = Control.FocusModeEnum.None };
        s.ValueChanged += v => changed((float)v);
        row.AddChild(s);
        return s;
    }

    private void BuildBar(Control root)
    {
        _bar = Box();
        root.AddChild(_bar);
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 6);
        _bar.AddChild(row);
        string[] names = { "1 Dig", "2 Nursery", "3 Store", "4 Trail", "5 Avoid", "6 Cancel" };
        for (int k = 0; k < names.Length; k++)
        {
            int tool = k;
            _tools[k] = MakeButton(names[k], () => ToolPicked?.Invoke((Tool)tool));
            row.AddChild(_tools[k]);
        }
        row.AddChild(new VSeparator());
        row.AddChild(MakeButton("R Rain", () => RainPicked?.Invoke()));
        row.AddChild(MakeButton("T Scent", () => ScentToggled?.Invoke()));
        row.AddChild(new VSeparator());
        string[] speeds = { "II", "1×", "2×", "4×" };
        for (int k = 0; k < 4; k++)
        {
            int speed = k;
            _speeds[k] = MakeButton(speeds[k], () => SpeedPicked?.Invoke(speed));
            _speeds[k].CustomMinimumSize = new Vector2(40, 0);
            row.AddChild(_speeds[k]);
        }
        _hint = new Label { Text = "Left drag: use tool (Shift erases)   Right drag / WASD: move   Wheel: zoom   [ ]: brush" };
        _hint.AddThemeColorOverride("font_color", new Color(Cream, 0.7f));
        _hint.AddThemeFontSizeOverride("font_size", 13);
        root.AddChild(_hint);
    }

    private void BuildBanner(Control root)
    {
        _bannerBox = new PanelContainer { Visible = false };
        _bannerStyle = Flat(new Color(0.55f, 0.1f, 0.08f, 0.9f), 8);
        _bannerStyle.ContentMarginLeft = 22; _bannerStyle.ContentMarginRight = 22;
        _bannerStyle.ContentMarginTop = 8; _bannerStyle.ContentMarginBottom = 8;
        _bannerBox.AddThemeStyleboxOverride("panel", _bannerStyle);
        root.AddChild(_bannerBox);
        _banner = new Label();
        _banner.AddThemeColorOverride("font_color", Colors.White);
        _banner.AddThemeFontSizeOverride("font_size", 20);
        _bannerBox.AddChild(_banner);
    }

    private void BuildModal(Control root)
    {
        _modal = new PanelContainer { Visible = false, CustomMinimumSize = new Vector2(560, 0) };
        var style = Flat(new Color(0.08f, 0.055f, 0.035f, 0.95f), 14);
        style.BorderColor = new Color(0.75f, 0.52f, 0.25f);
        style.BorderWidthTop = style.BorderWidthBottom = style.BorderWidthLeft = style.BorderWidthRight = 2;
        style.ContentMarginLeft = style.ContentMarginRight = 34;
        style.ContentMarginTop = style.ContentMarginBottom = 26;
        _modal.AddThemeStyleboxOverride("panel", style);
        root.AddChild(_modal);
        _modalBody = new VBoxContainer();
        _modalBody.AddThemeConstantOverride("separation", 12);
        _modal.AddChild(_modalBody);
    }

    private static StyleBoxFlat Flat(Color c, int radius) => new()
    {
        BgColor = c,
        CornerRadiusTopLeft = radius, CornerRadiusTopRight = radius,
        CornerRadiusBottomLeft = radius, CornerRadiusBottomRight = radius,
    };

    private static PanelContainer Box()
    {
        var style = Flat(Panel, 10);
        style.ContentMarginLeft = 14; style.ContentMarginRight = 14; style.ContentMarginTop = 10; style.ContentMarginBottom = 10;
        style.BorderColor = new Color(0.55f, 0.38f, 0.2f, 0.7f);
        style.BorderWidthBottom = style.BorderWidthTop = style.BorderWidthLeft = style.BorderWidthRight = 1;
        var p = new PanelContainer();
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
        var b = new Button { Text = text, FocusMode = Control.FocusModeEnum.None };
        var normal = Flat(new Color(0.22f, 0.15f, 0.09f), 6);
        normal.ContentMarginLeft = 10; normal.ContentMarginRight = 10; normal.ContentMarginTop = 6; normal.ContentMarginBottom = 6;
        var hover = (StyleBoxFlat)normal.Duplicate();
        hover.BgColor = new Color(0.32f, 0.22f, 0.12f);
        b.AddThemeStyleboxOverride("normal", normal);
        b.AddThemeStyleboxOverride("hover", hover);
        b.AddThemeStyleboxOverride("pressed", hover);
        b.AddThemeColorOverride("font_color", Cream);
        b.Pressed += onPress;
        return b;
    }

    // ---------- modal screens ----------

    private void OpenModal(string title, string body, string button, Action onPress, Color? titleColour = null)
    {
        foreach (var child in _modalBody.GetChildren())
        {
            _modalBody.RemoveChild(child);
            child.QueueFree();
        }
        var t = new Label { Text = title, HorizontalAlignment = HorizontalAlignment.Center };
        t.AddThemeColorOverride("font_color", titleColour ?? Amber);
        t.AddThemeFontSizeOverride("font_size", 34);
        _modalBody.AddChild(t);
        var b = new Label { Text = body, AutowrapMode = TextServer.AutowrapMode.WordSmart, CustomMinimumSize = new Vector2(490, 0) };
        b.AddThemeColorOverride("font_color", Cream);
        b.AddThemeFontSizeOverride("font_size", 17);
        _modalBody.AddChild(b);
        var btn = MakeButton(button, () => { _modal.Visible = false; onPress(); });
        btn.AddThemeFontSizeOverride("font_size", 20);
        btn.SizeFlagsHorizontal = Control.SizeFlags.ShrinkCenter;
        _modalBody.AddChild(btn);
        _modal.Visible = true;
        _modal.ResetSize();
    }

    public void CloseModal() => _modal.Visible = false;

    public void ShowTitle() => OpenModal("UNDERMOUND",
        "Every tunnel you dig, your colony fills.\n\n"
        + "Dig the nest, mark nurseries and food stores, and guide your ants through a year in the garden. "
        + "Keep the queen dry when the rain comes, warm when winter falls, and safe from the wolf spider. "
        + "Raise winged queens in summer: every one that flies may found a colony of her own.",
        "Found the colony", () => StartPressed?.Invoke());

    public void ShowReport(YearReport r) => OpenModal($"Year {r.Year}",
        $"Winged queens flown: {r.QueensFlown}\n"
        + $"Largest colony: {r.PeakColony} ants\n"
        + $"Cells dug: {r.CellsDug}     Food gathered: {r.FoodGathered}\n"
        + $"Spiders driven off: {r.SpidersDrivenOff}\n"
        + $"Ants lost: {r.AntsLost}     Brood drowned: {r.BroodLost}\n\n"
        + (r.QueensFlown > 0
            ? "Somewhere out in the garden, your daughters are digging their first chambers."
            : "No queens flew this year. Grow the colony past 40 ants by summer to raise them."),
        "Into the new spring", () => ContinuePressed?.Invoke());

    public void ShowGameOver(Sim sim) => OpenModal("The colony is lost",
        $"{sim.GameOver}\n\n"
        + $"Year {sim.Year}, {sim.Season.ToString().ToLower()}.   Winged queens flown in all: {sim.QueensFlown}.   Cells dug: {sim.CellsDug}.",
        "Found a new colony", () => RestartPressed?.Invoke(), Danger);

    // ---------- every frame ----------

    public void Bind(Priorities p)
    {
        _priorities = p;
        _dig.SetValueNoSignal(p.Dig);
        _forage.SetValueNoSignal(p.Forage);
        _nurse.SetValueNoSignal(p.Nurse);
        _soldiers.SetValueNoSignal(p.Soldiers);
    }

    /// <summary>Show or hide the tool bar, sliders and hint (screenshots can hide them).</summary>
    public void SetBarVisible(bool on)
    {
        _bar.Visible = on;
        _hint.Visible = on;
        _prio.Visible = on;
    }

    public void SetLogVisible(bool on) => _logBox.Visible = on;

    private void Place()
    {
        var size = GetViewport().GetVisibleRect().Size;
        _info.Position = new Vector2(18, 16);
        _prio.Position = new Vector2(18, _info.Position.Y + _info.Size.Y + 12);
        _bar.Position = new Vector2((size.X - _bar.Size.X) / 2, size.Y - _bar.Size.Y - 34);
        _hint.Position = new Vector2((size.X - _hint.Size.X) / 2, size.Y - 26);
        _logBox.Position = new Vector2(size.X - _logBox.Size.X - 18, 16);
        _bannerBox.Position = new Vector2((size.X - _bannerBox.Size.X) / 2, 18);
        _modal.Position = (size - _modal.Size) / 2;
    }

    private static Color SeasonColour(Season s) => s switch
    {
        Season.Spring => new Color(0.6f, 0.9f, 0.5f),
        Season.Summer => new Color(1f, 0.85f, 0.35f),
        Season.Autumn => new Color(1f, 0.6f, 0.3f),
        _ => new Color(0.7f, 0.85f, 1f),
    };

    public void Show(Sim sim, Tool tool, int speed, int brush)
    {
        Place();
        _season.Text = $"{sim.Season}, year {sim.Year}    {sim.SurfaceTemp:0}°C    day {sim.Day + 1:0}";
        _season.AddThemeColorOverride("font_color", SeasonColour(sim.Season));
        _colony.Text = $"Workers {sim.Workers}   Soldiers {sim.Soldiers}"
                       + (sim.Alates > 0 ? $"   Winged queens {sim.Alates}" : "")
                       + (sim.QueensFlown > 0 ? $"   Flown {sim.QueensFlown}" : "");
        _brood.Text = $"Eggs {sim.Eggs}   Larvae {sim.Larvae}   Care {sim.NurseCare * 100:0}%";
        _food.Text = $"Food {sim.Food:0}/{sim.FoodCapacity:0}";
        _foodBar.MaxValue = sim.FoodCapacity;
        _foodBar.Value = sim.Food;
        _weather.Text = sim.Melting ? "Snow melting: water is coming in"
            : sim.Snowing ? $"Snowing ({sim.RainLeft:0}s)"
            : sim.Raining ? $"Raining ({sim.RainLeft:0}s left)"
            : sim.Season == Season.Winter ? "Frozen ground. No foraging."
            : $"Rain in {(int)sim.RainIn / 60}:{(int)sim.RainIn % 60:00}";
        _weather.AddThemeColorOverride("font_color", sim.Raining || sim.Melting || sim.RainIn < SimConfig.RainWarningSeconds
            ? new Color(0.6f, 0.8f, 1f) : Cream);
        _queen.Text = !sim.QueenAlive ? "The queen is dead" : sim.QueenInDanger ? "Queen in danger!" : "Queen safe";
        _queen.AddThemeColorOverride("font_color", !sim.QueenAlive || sim.QueenInDanger ? Danger : new Color(Cream, 0.75f));

        var lines = new System.Text.StringBuilder();
        int from = Math.Max(0, sim.Log.Count - 4);
        for (int k = from; k < sim.Log.Count; k++)
            lines.Append($"Day {sim.Log[k].Time / SimConfig.DaySeconds + 1:0}  {sim.Log[k].Text}\n");
        _log.Text = lines.Length > 0 ? lines.ToString().TrimEnd() : "The colony is settling in.";

        ShowBanner(sim);
        for (int k = 0; k < _tools.Length; k++) Highlight(_tools[k], k == (int)tool);
        for (int k = 0; k < 4; k++) Highlight(_speeds[k], k == speed);
    }

    private void ShowBanner(Sim sim)
    {
        string? text = null;
        var colour = new Color(0.55f, 0.1f, 0.08f, 0.9f);
        if (sim.QueenAlive && sim.QueenInDanger) text = "The queen is in danger!";
        else if (sim.SpiderAbout) text = "Wolf spider at the nest!";
        else if (sim.FlightUnderway) { text = "Nuptial flight! The winged queens are leaving."; colour = new Color(0.55f, 0.38f, 0.08f, 0.9f); }
        else if (sim.Melting) { text = "Spring meltwater is flooding in!"; colour = new Color(0.1f, 0.3f, 0.55f, 0.9f); }
        _bannerBox.Visible = text != null && !_modal.Visible;
        if (text == null) return;
        _banner.Text = text;
        _bannerStyle.BgColor = colour;
        _bannerBox.ResetSize();
    }

    private static void Highlight(Button b, bool on) =>
        b.AddThemeColorOverride("font_color", on ? Amber : Cream);
}
