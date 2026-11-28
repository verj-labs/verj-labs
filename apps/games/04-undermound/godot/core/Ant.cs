namespace Undermound.Core;

public enum AntJob : byte
{
    Idle, ToDig, Digging, CarrySoil, DropSoil, ForageOut, CarryFood, ReturnHome, Resting,
    Nursing, Guarding, Fighting, AlateWaiting, ToFlight, Flying,
}

public enum Carry : byte { None, Soil, Food }

public sealed class Ant
{
    public readonly int Id;
    public Caste Caste;
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
    public float Chill;       // seconds spent in freezing soil or air
    public float Hp = 1f;
    public float Flight;      // seconds in the air on the nuptial flight
    public bool Dead;
    public bool Grabbed;      // held by a spider
    public float FacingX = 1, FacingY;  // for the view: last movement direction
    public int Side = 1;                // for the view: last horizontal direction (+1 right, -1 left)

    public Ant(int id, int cell, Caste caste = Caste.Worker)
    {
        Id = id;
        Cell = cell;
        Caste = caste;
        Hp = caste == Caste.Soldier ? SimConfig.SoldierHp : 1f;
    }

    public bool Moving => Next >= 0;
}

public enum BroodStage : byte { Egg, Larva }

public sealed class Brood
{
    public int Cell;
    public BroodStage Stage;
    public Caste Caste;
    public float Age;
    public float Wet;
    public float Jitter;   // fixed per brood, for the view
}
