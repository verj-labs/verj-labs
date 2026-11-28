namespace Undermound.Core;

public enum AntJob : byte { Idle, ToDig, Digging, CarrySoil, DropSoil, ForageOut, CarryFood, ReturnHome, Resting }

public enum Carry : byte { None, Soil, Food }

public sealed class Ant
{
    public readonly int Id;
    public int Cell;          // the cell the ant is leaving
    public int Next = -1;     // the cell it is walking to (-1 when standing)
    public float T;           // progress from Cell to Next, 0..1
    public AntJob Job = AntJob.Idle;
    public Carry Carrying;
    public int Dir = 1;       // walking direction on the surface
    public int Travelled;     // cells walked on this foraging trip
    public int TargetX;       // surface column to drop soil at
    public float Timer;
    public float Submerged;
    public bool Dead;
    public float FacingX = 1, FacingY;  // for the view: last movement direction
    public int Side = 1;                // for the view: last horizontal direction (+1 right, -1 left)

    public Ant(int id, int cell)
    {
        Id = id;
        Cell = cell;
    }

    public bool Moving => Next >= 0;
}

public enum BroodStage : byte { Egg, Larva }

public sealed class Brood
{
    public int Cell;
    public BroodStage Stage;
    public float Age;
    public float Wet;
    public float Jitter;   // fixed per brood, for the view
}
