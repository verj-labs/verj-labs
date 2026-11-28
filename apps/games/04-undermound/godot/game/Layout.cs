using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Maps simulation cells to 3D space. One cell is one unit. The ground surface is at Y = 0;
/// soil row y (1..SoilRows) spans Y from -y to -(y - 1). The slab is centred on Z = 0.
/// </summary>
public static class Layout
{
    public const float SlabDepth = 1.4f;
    public const float FrontZ = SlabDepth / 2f;
    public const float BackZ = -SlabDepth / 2f;
    public static readonly float HalfWidth = SimConfig.Width / 2f;

    public static float CellLeft(int x) => x - HalfWidth;
    public static float CellCentreX(int x) => x + 0.5f - HalfWidth;

    /// <summary>Y of the top edge of soil row y.</summary>
    public static float RowTop(int y) => -(y - 1);

    /// <summary>Where an ant stands in a cell: on the floor underground, on the ground on the surface.</summary>
    public static Vector3 AntSpot(World w, int cell)
    {
        int x = w.X(cell), y = w.Y(cell);
        float ay = y == 0 ? 0.02f : RowTop(y) - 0.99f;
        return new Vector3(CellCentreX(x), ay, 0);
    }

    public static Vector3 CellCentre(int x, int y) => new(CellCentreX(x), RowTop(y) - 0.5f, 0);

    /// <summary>The cell under a point on the front of the slab, or false when outside the soil.</summary>
    public static bool PointToCell(Vector3 p, out int x, out int y)
    {
        x = Mathf.FloorToInt(p.X + HalfWidth);
        y = Mathf.FloorToInt(-p.Y) + 1;
        return x >= 0 && x < SimConfig.Width && y >= 1 && y < SimConfig.Height;
    }
}

/// <summary>The colours of the world: stylised-realistic, warm surface, earthy soil.</summary>
public static class Palette
{
    public static readonly Color Topsoil = new(0.27f, 0.18f, 0.12f);
    public static readonly Color Clay = new(0.47f, 0.26f, 0.15f);
    public static readonly Color Sand = new(0.64f, 0.50f, 0.32f);
    public static readonly Color Rock = new(0.36f, 0.34f, 0.32f);
    public static readonly Color AntBody = new(0.10f, 0.06f, 0.045f);
    public static readonly Color AntLeg = new(0.16f, 0.10f, 0.07f);
    public static readonly Color Egg = new(0.97f, 0.95f, 0.86f);
    public static readonly Color Larva = new(0.95f, 0.90f, 0.78f);
    public static readonly Color Berry = new(0.62f, 0.05f, 0.10f);
    public static readonly Color Crumb = new(0.85f, 0.66f, 0.38f);
    public static readonly Color Seed = new(0.55f, 0.42f, 0.24f);
    public static readonly Color Wood = new(0.42f, 0.27f, 0.15f);

    public static Color Soil(CellType m) => m switch
    {
        CellType.Topsoil => Topsoil,
        CellType.Clay => Clay,
        CellType.Sand => Sand,
        CellType.Rock => Rock,
        _ => Topsoil,
    };
}
