namespace Undermound.Core;

public enum Season : byte { Spring, Summer, Autumn, Winter }

public enum Caste : byte { Worker, Soldier, Alate }

/// <summary>How the player wants workers split between jobs. Values are relative weights, 0..1.</summary>
public sealed class Priorities
{
    public float Dig = 0.45f;
    public float Forage = 0.4f;
    public float Nurse = 0.15f;
    /// <summary>Share of new brood raised as soldiers, 0..0.4.</summary>
    public float Soldiers = 0.1f;
}

/// <summary>What the colony achieved in a year, shown when the next spring begins.</summary>
public sealed class YearReport
{
    public int Year;
    public int QueensFlown;
    public int PeakColony;
    public int CellsDug;
    public int FoodGathered;
    public int AntsLost;
    public int BroodLost;
    public int SpidersDrivenOff;
}

public enum SpiderState : byte { Hunting, Eating, Leaving }

/// <summary>A wolf spider: hunts ants on the surface, never enters the tunnels.</summary>
public sealed class Spider
{
    public float X;
    public int Dir = 1;
    public float Hp = SimConfig.SpiderHp;
    public SpiderState State = SpiderState.Hunting;
    public float Timer;        // time in the current state
    public float Age;          // time since it arrived
    public int Kills;
    public int PreyId = -1;    // the ant it is holding or chasing
    public bool Gone;
    public bool Fighting;      // soldiers are biting it
}
