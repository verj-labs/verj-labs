using System;
using Godot;
using Undermound.Core;

namespace Undermound.Game;

/// <summary>
/// Sound, all made in code: a garden ambience (breeze and birds; wind in winter), rain, the
/// crunch of digging, chimes for new life and the nuptial flight, an alarm for the spider.
/// Events are read from the simulation's counters, so the core stays free of sound.
/// </summary>
public partial class Sfx : Node
{
    private const int Rate = 22050;
    private AudioStreamPlayer _ambient = null!, _wind = null!, _rain = null!;
    private AudioStreamPlayer[] _dig = null!;
    private AudioStreamPlayer _chime = null!, _alarm = null!, _bell = null!, _flight = null!;
    private AudioStreamWav _digSound = null!;
    private int _digIndex, _lastDug, _lastHatched, _lastFlown;
    private bool _lastSpider;
    private Season _lastSeason;
    private float _digCooldown;
    private readonly Random _rng = new(5);

    public override void _Ready()
    {
        _ambient = Loop(Garden(6f), -14);
        _wind = Loop(Wind(5f), -60);
        _rain = Loop(RainNoise(3f), -60);
        _digSound = Crunch();
        _dig = new AudioStreamPlayer[6];
        for (int k = 0; k < _dig.Length; k++) _dig[k] = Player(_digSound, -16);
        _chime = Player(Tones(new[] { 784f, 988f, 1175f }, 0.12f, 0.5f), -14);
        _flight = Player(Tones(new[] { 523f, 659f, 784f, 1047f, 1319f }, 0.1f, 0.9f), -10);
        _alarm = Player(Tones(new[] { 1400f, 1100f, 1400f, 1100f }, 0.07f, 0.12f), -12);
        _bell = Player(Tones(new[] { 392f, 523f }, 0.35f, 1.6f), -12);
    }

    public void Update(Sim sim, double delta)
    {
        float dt = (float)delta;
        bool winter = sim.Season == Season.Winter;
        Fade(_ambient, winter || sim.Raining ? -40 : -14, dt);
        Fade(_wind, winter ? -16 : -40, dt);
        Fade(_rain, sim.Raining && !sim.Snowing ? -10 : sim.Melting ? -22 : -60, dt);

        _digCooldown -= dt;
        if (sim.CellsDug > _lastDug && _digCooldown <= 0)
        {
            var p = _dig[_digIndex++ % _dig.Length];
            p.PitchScale = 0.8f + (float)_rng.NextDouble() * 0.5f;
            p.Play();
            _digCooldown = 0.12f;
        }
        _lastDug = sim.CellsDug;
        if (sim.Hatched > _lastHatched && sim.Hatched % 5 == 0) _chime.Play();
        _lastHatched = sim.Hatched;
        if (sim.QueensFlown > _lastFlown && !_flight.Playing) _flight.Play();
        _lastFlown = sim.QueensFlown;
        bool spider = sim.SpiderAbout;
        if (spider && !_lastSpider) _alarm.Play();
        _lastSpider = spider;
        if (sim.Season != _lastSeason) _bell.Play();
        _lastSeason = sim.Season;
    }

    private static void Fade(AudioStreamPlayer p, float target, float dt) =>
        p.VolumeDb = Mathf.MoveToward(p.VolumeDb, target, dt * 20);

    private AudioStreamPlayer Player(AudioStream stream, float db)
    {
        var p = new AudioStreamPlayer { Stream = stream, VolumeDb = db };
        AddChild(p);
        return p;
    }

    private AudioStreamPlayer Loop(AudioStreamWav stream, float db)
    {
        var p = Player(stream, db);
        p.Autoplay = true;
        p.Play();
        return p;
    }

    // ---------- sound synthesis ----------

    private static AudioStreamWav Wav(float[] samples, bool loop)
    {
        var bytes = new byte[samples.Length * 2];
        for (int i = 0; i < samples.Length; i++)
        {
            short v = (short)(Math.Clamp(samples[i], -1f, 1f) * 32000);
            bytes[i * 2] = (byte)(v & 0xFF);
            bytes[i * 2 + 1] = (byte)((v >> 8) & 0xFF);
        }
        var wav = new AudioStreamWav { Format = AudioStreamWav.FormatEnum.Format16Bits, MixRate = Rate, Data = bytes };
        if (loop)
        {
            wav.LoopMode = AudioStreamWav.LoopModeEnum.Forward;
            wav.LoopEnd = samples.Length;
        }
        return wav;
    }

    /// <summary>Soft breeze (low-passed noise) with a bird calling now and then.</summary>
    private AudioStreamWav Garden(float seconds)
    {
        int n = (int)(seconds * Rate);
        var s = new float[n];
        float lp = 0;
        for (int i = 0; i < n; i++)
        {
            lp += ((float)_rng.NextDouble() * 2 - 1 - lp) * 0.02f;
            s[i] = lp * 0.6f;
        }
        for (int call = 0; call < 3; call++)
        {
            int start = _rng.Next(0, n - Rate);
            float f0 = 2400 + _rng.Next(0, 1400);
            for (int chirp = 0; chirp < 3; chirp++)
            {
                int c0 = start + chirp * Rate / 7;
                for (int i = 0; i < Rate / 12 && c0 + i < n; i++)
                {
                    float t = i / (float)Rate;
                    float env = MathF.Sin(MathF.PI * i / (Rate / 12f));
                    s[c0 + i] += MathF.Sin(MathF.Tau * (f0 + 1800 * t * 8) * t) * env * 0.12f;
                }
            }
        }
        Smooth(s);
        return Wav(s, true);
    }

    private AudioStreamWav Wind(float seconds)
    {
        int n = (int)(seconds * Rate);
        var s = new float[n];
        float lp = 0;
        for (int i = 0; i < n; i++)
        {
            lp += ((float)_rng.NextDouble() * 2 - 1 - lp) * 0.01f;
            float gust = 0.6f + 0.4f * MathF.Sin(MathF.Tau * i / n * 2);
            s[i] = lp * gust * 1.4f;
        }
        Smooth(s);
        return Wav(s, true);
    }

    private AudioStreamWav RainNoise(float seconds)
    {
        int n = (int)(seconds * Rate);
        var s = new float[n];
        float prev = 0;
        for (int i = 0; i < n; i++)
        {
            float white = (float)_rng.NextDouble() * 2 - 1;
            s[i] = (white - prev * 0.6f) * 0.25f;   // a little high-pass: hiss
            prev = white;
            if (_rng.NextDouble() < 0.0008) s[i] += 0.5f;  // the odd heavy drop
        }
        Smooth(s);
        return Wav(s, true);
    }

    private AudioStreamWav Crunch()
    {
        int n = Rate / 12;
        var s = new float[n];
        float lp = 0;
        for (int i = 0; i < n; i++)
        {
            lp += ((float)_rng.NextDouble() * 2 - 1 - lp) * 0.3f;
            float env = MathF.Exp(-i / (n * 0.18f));
            s[i] = lp * env * 0.9f;
        }
        return Wav(s, false);
    }

    private static AudioStreamWav Tones(float[] notes, float each, float tail)
    {
        int n = (int)((notes.Length * each + tail) * Rate);
        var s = new float[n];
        for (int k = 0; k < notes.Length; k++)
        {
            int start = (int)(k * each * Rate);
            for (int i = 0; start + i < n; i++)
            {
                float t = i / (float)Rate;
                float env = MathF.Exp(-t * 3.5f) * MathF.Min(1, t * 200);
                s[start + i] += (MathF.Sin(MathF.Tau * notes[k] * t) + 0.3f * MathF.Sin(MathF.Tau * notes[k] * 2 * t)) * env * 0.25f;
            }
        }
        return Wav(s, false);
    }

    /// <summary>Cross-fade the ends of a loop so it does not click.</summary>
    private static void Smooth(float[] s)
    {
        int fade = Math.Min(2000, s.Length / 4);
        for (int i = 0; i < fade; i++)
        {
            float t = i / (float)fade;
            s[i] = s[i] * t + s[s.Length - fade + i] * (1 - t);
        }
    }
}
