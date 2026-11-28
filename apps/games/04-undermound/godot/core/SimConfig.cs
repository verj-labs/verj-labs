namespace Undermound.Core;

/// <summary>All tuning values in one place. Times are in seconds, distances in cells.</summary>
public static class SimConfig
{
    // World
    public const int Width = 160;
    public const int SoilRows = 90;          // rows below the surface
    public const int Height = SoilRows + 1;  // row 0 is the surface lane
    public const float TickSeconds = 0.1f;

    // Ants
    public const float TunnelSpeed = 3.4f;    // cells per second
    public const float SurfaceSpeed = 4.2f;
    public const float WaterSpeedFactor = 0.35f;
    public const float DrownSeconds = 25f;
    public const float RestMinSeconds = 3f;
    public const float RestMaxSeconds = 7f;
    public const float DigShare = 0.5f;       // share of workers that may dig
    public const float ForageShare = 0.5f;    // share of workers that may forage
    public const int DiggersPerFrontierCell = 4;

    // Digging (seconds for one ant to dig one cell of hardness 1)
    public const float BaseDigSeconds = 2f;
    public const float TopsoilHardness = 1f;
    public const float SandHardness = 0.7f;
    public const float ClayHardness = 1.6f;

    // Foraging and scent
    public const int ForageMaxRange = 70;
    public const float ScentDeposit = 1f;
    public const float ScentDecayPerSecond = 0.035f;
    public const float ScentFollowThreshold = 0.15f;
    public const int ScentSenseCells = 4;
    public const float RandomTurnChance = 0.04f;
    public const int MaxFoodSources = 7;
    public const float FoodSpawnMinSeconds = 25f;
    public const float FoodSpawnMaxSeconds = 50f;

    // Colony
    public const float StartFood = 40f;
    public const int StartWorkers = 14;
    public const float BaseFoodCapacity = 15f;
    public const float FoodPerStoreCell = 4f;
    public const float WorkerFoodPerSecond = 0.004f;
    public const float LarvaFoodPerSecond = 0.03f;
    public const float QueenFoodPerSecond = 0.01f;
    public const float StarveKillSeconds = 5f;
    public const float EggLaySeconds = 8f;
    public const float EggFoodCost = 1f;
    public const int BroodPerNurseryCell = 2;
    public const int BroodPerPile = 4;          // brood stacked in one cell
    public const float EggSeconds = 40f;
    public const float LarvaSeconds = 60f;
    public const float BroodDrownSeconds = 8f;

    // Water
    public const float RainPerOpeningPerSecond = 1.2f;
    public const int RainCatchCells = 3;
    public const float MoundShelter = 200f;   // mound pellets that halve inflow
    public const float WaterSideShare = 0.25f;
    public const float AbsorbFraction = 0.002f; // share of a cell's water soaked per second, per unit of soil absorbency
    public const float SandAbsorb = 2f;
    public const float TopsoilAbsorb = 1f;
    public const float ClayAbsorb = 0.3f;
    public const float RockAbsorb = 0f;
    public const float WetLevel = 0.5f;

    // Weather
    public const float RainWarningSeconds = 20f;
    public const float RainMinGapSeconds = 240f;
    public const float RainMaxGapSeconds = 360f;
    public const float RainMinSeconds = 25f;
    public const float RainMaxSeconds = 45f;

    public const float DaySeconds = 240f;
}
