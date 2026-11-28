namespace Undermound.Core;

/// <summary>All tuning values in one place. Times are in seconds, distances in cells, heat in °C.</summary>
public static class SimConfig
{
    // World
    public const int Width = 160;
    public const int SoilRows = 90;          // rows below the surface
    public const int Height = SoilRows + 1;  // row 0 is the surface lane
    public const float TickSeconds = 0.1f;

    // Time
    public const float DaySeconds = 240f;
    public const float SeasonSeconds = 1080f;  // 4.5 days; a year is 72 minutes

    // Ants
    public const float TunnelSpeed = 3.4f;    // cells per second
    public const float SurfaceSpeed = 4.2f;
    public const float SoldierSpeedFactor = 0.85f;
    public const float WaterSpeedFactor = 0.35f;
    public const float DrownSeconds = 25f;
    public const float ChillDeathSeconds = 30f;
    public const float RestMinSeconds = 3f;
    public const float RestMaxSeconds = 7f;
    public const int DiggersPerFrontierCell = 4;
    public const float NurseSeconds = 15f;
    public const float GuardRange = 6;         // cells either side of the entrance
    public const float SoldierHp = 10f;

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
    public const float GuideStrength = 3f;           // a painted trail, in scent units
    public const float GuideDecayPerSecond = 0.004f;
    public const float AlarmDecayPerSecond = 0.4f;
    public const float AlarmFleeLevel = 0.5f;
    public const int MaxFoodSources = 7;
    public const float FoodSpawnMinSeconds = 25f;
    public const float FoodSpawnMaxSeconds = 50f;

    // Colony
    public const float StartFood = 60f;
    public const int StartWorkers = 14;
    public const float BaseFoodCapacity = 15f;
    public const float FoodPerStoreCell = 4f;
    public const float WorkerFoodPerSecond = 0.004f;
    public const float SoldierFoodFactor = 1.5f;
    public const float AlateFoodFactor = 2f;
    public const float WinterAppetite = 0.15f;
    public const float LarvaFoodPerSecond = 0.02f;
    public const float QueenFoodPerSecond = 0.01f;
    public const float StarveKillSeconds = 5f;
    public const float EggLaySeconds = 8f;
    public const float EggFoodCost = 1f;
    public const float AlateEggFoodCost = 3f;
    public const int BroodPerNurseryCell = 2;
    public const int BroodPerPile = 4;          // brood stacked in one cell
    public const float EggSeconds = 40f;
    public const float LarvaSeconds = 60f;
    public const float AlateLarvaFactor = 1.5f;
    public const float BroodDrownSeconds = 8f;
    public const float QueenDrownSeconds = 30f;
    public const float NursesPerBrood = 0.34f;   // one nurse per three brood is full care
    public const float UntendedGrowth = 0.6f;    // brood growth with no nurses
    public const float TendedGrowth = 1.4f;      // brood growth with full care

    // Winged queens and the nuptial flight
    public const int AlateMinColony = 40;
    public const int MaxAlates = 12;
    public const float AlateChance = 0.3f;
    public const float FlightSeconds = 8f;

    // Temperature
    public const float DeepSoilTemp = 11f;
    public const float TempDepthScale = 14f;     // rows over which surface heat fades
    public const float SpringTemp = 14f, SummerTemp = 26f, AutumnTemp = 11f, WinterTemp = -4f;
    public const float SlowTemp = 2f;            // ants at their slowest
    public const float ActiveTemp = 10f;         // ants at full speed
    public const float BroodStopTemp = 6f;
    public const float BroodWarmTemp = 14f;
    public const float LayingTemp = 10f;
    public const float ForageTemp = 5f;
    public const float FreezeTemp = -1f;

    // Water
    public const float RainPerOpeningPerSecond = 0.7f;
    public const int RainCatchCells = 3;
    public const float MoundShelter = 200f;   // mound pellets that halve inflow
    public const float WaterSideShare = 0.25f;
    public const float AbsorbFraction = 0.002f; // share of a cell's water soaked per second, per unit of soil absorbency
    public const float SandAbsorb = 2f;
    public const float TopsoilAbsorb = 1f;
    public const float ClayAbsorb = 0.3f;
    public const float RockAbsorb = 0f;
    public const float WetLevel = 0.5f;
    public const float SnowPerSecond = 0.004f;    // snow depth gained while it snows
    public const float MeltPerOpeningPerSecond = 1.0f;
    public const float MeltSecondsPerSnow = 120f; // melt time per unit of snow

    // Weather
    public const float RainWarningSeconds = 20f;
    public const float RainMinGapSeconds = 240f;
    public const float RainMaxGapSeconds = 360f;
    public const float RainMinSeconds = 25f;
    public const float RainMaxSeconds = 45f;

    // The wolf spider
    public const float SpiderFirstSeconds = 300f;
    public const float SpiderMinGapSeconds = 240f;
    public const float SpiderMaxGapSeconds = 420f;
    public const float SpiderSpeed = 4.6f;
    public const float SpiderHp = 40f;
    public const float SpiderKillSeconds = 1.5f;
    public const float SpiderEatSeconds = 6f;
    public const int SpiderMeals = 3;
    public const float SpiderMaxStay = 100f;
    public const float SpiderFleeHp = 0.4f;
    public const float SpiderDamagePerSecond = 2.5f;
    public const float SoldierBitePerSecond = 4f;
    public const float WorkerBitePerSecond = 0.3f;
    public const float SpiderSight = 30f;
}
