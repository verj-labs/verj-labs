using System;

namespace Undermound.Core;

/// <summary>Seasons, temperature, rain, snow and the spring melt.</summary>
public sealed partial class Sim
{
    public bool Raining { get; private set; }
    public float RainLeft { get; private set; }
    public float NextRainIn;
    public bool AutoWeather = true;
    /// <summary>Snow lying on the ground (0 = none, about 1 = deep).</summary>
    public float Snow { get; private set; }
    public float MeltLeft { get; private set; }
    public bool Snowing => Raining && Season == Season.Winter;
    public bool Melting => MeltLeft > 0;
    public float RainIn => Raining ? 0 : NextRainIn;

    private bool _rainWarned;

    // ---------- seasons ----------

    private void UpdateSeason()
    {
        var season = Season;
        int year = Year;
        if (season == _lastSeason && year == _lastYear) return;
        _lastSeason = season;
        switch (season)
        {
            case Season.Spring:
                Say("Spring. The ground warms and the queen starts laying again.");
                if (Snow > 0.02f)
                {
                    MeltLeft = Snow * SimConfig.MeltSecondsPerSnow;
                    Say("The snow is melting. Meltwater is running into the nest!");
                }
                break;
            case Season.Summer:
                Say("Summer. Food is plentiful. A big colony will raise winged queens.");
                break;
            case Season.Autumn:
                Say("Autumn. Store food: nothing new will be found in winter.");
                break;
            case Season.Winter:
                Say("Winter. The surface freezes. Keep the colony and the brood deep and warm.");
                break;
        }
        if (year != _lastYear)
        {
            _lastYear = year;
            EndYear(year - 1);
        }
    }

    private static float SeasonMidTemp(Season s) => s switch
    {
        Season.Spring => SimConfig.SpringTemp,
        Season.Summer => SimConfig.SummerTemp,
        Season.Autumn => SimConfig.AutumnTemp,
        _ => SimConfig.WinterTemp,
    };

    /// <summary>Air temperature at the surface: eases from one season's middle to the next.</summary>
    public float SurfaceTemp
    {
        get
        {
            // Each season's typical temperature is reached a quarter of the way in, so the game
            // opens in a mild spring and the cold arrives with the first days of winter.
            float t = Time / SeasonLength - 0.25f;
            int k = (int)MathF.Floor(t);
            float f = t - k;
            var a = (Season)(((k % 4) + 4) % 4);
            var b = (Season)(((k + 1) % 4 + 4) % 4);
            float e = f * f * (3 - 2 * f);
            float temp = SeasonMidTemp(a) + (SeasonMidTemp(b) - SeasonMidTemp(a)) * e;
            return Raining ? temp - 3 : temp;
        }
    }

    /// <summary>Soil temperature: deep soil stays near the yearly mean; near the top it follows the air.</summary>
    public float TempAt(int cell)
    {
        int y = World.Y(cell);
        float surface = SurfaceTemp;
        if (y == 0) return surface;
        return SimConfig.DeepSoilTemp + (surface - SimConfig.DeepSoilTemp) * MathF.Exp(-y / SimConfig.TempDepthScale);
    }

    /// <summary>How fast ants move at a temperature: slow in the cold, full speed when warm.</summary>
    public static float ColdFactor(float temp)
    {
        if (temp >= SimConfig.ActiveTemp) return 1f;
        if (temp <= SimConfig.SlowTemp) return 0.3f;
        return 0.3f + 0.7f * (temp - SimConfig.SlowTemp) / (SimConfig.ActiveTemp - SimConfig.SlowTemp);
    }

    // ---------- rain and snow ----------

    public void StartRain(float seconds)
    {
        Raining = true;
        RainLeft = seconds;
        Say(Season == Season.Winter ? "It's snowing." : "It's raining. Water is running into the nest.");
    }

    public void StartMelt(float seconds) => MeltLeft = seconds;

    private float RainGapFactor => Season switch
    {
        Season.Spring => 0.7f,
        Season.Summer => 1.3f,
        Season.Autumn => 0.8f,
        _ => 1f,
    };

    private void UpdateWeather(float dt)
    {
        if (MeltLeft > 0)
        {
            MeltLeft = MathF.Max(0, MeltLeft - dt);
            Snow = MathF.Max(0, Snow - dt / SimConfig.MeltSecondsPerSnow);
            if (MeltLeft == 0) { Snow = 0; Say("The meltwater has stopped."); }
        }
        if (Snowing) Snow = MathF.Min(1.5f, Snow + SimConfig.SnowPerSecond * dt);

        if (Raining)
        {
            RainLeft -= dt;
            if (RainLeft > 0) return;
            Raining = false;
            NextRainIn = _rng.Range(SimConfig.RainMinGapSeconds, SimConfig.RainMaxGapSeconds) * RainGapFactor;
            _rainWarned = false;
            Say(Season == Season.Winter ? "The snow has stopped." : "The rain has stopped.");
            OnRainStopped();
            return;
        }
        if (!AutoWeather) return;
        NextRainIn -= dt;
        if (!_rainWarned && NextRainIn <= SimConfig.RainWarningSeconds && Season != Season.Winter)
        {
            _rainWarned = true;
            Say("Rain is coming. Keep the nursery high and dry.");
        }
        if (NextRainIn <= 0) StartRain(_rng.Range(SimConfig.RainMinSeconds, SimConfig.RainMaxSeconds));
    }
}
