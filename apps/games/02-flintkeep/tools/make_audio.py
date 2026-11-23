#!/usr/bin/env python3
"""Synthesises every Flintkeep sound and the music loop with the Python standard library only:
no samples, no downloads, no licences. Bright, soft "casual game" sounds: pops, chimes and
little horns rather than harsh chiptune.

Run `python3 tools/make_audio.py` to (re)create the .wav files in godot/assets/audio/.
Each sound is a small function; the numbers inside are the knobs (pitch, length, volume).
"""
import math
import os
import random
import struct
import wave

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "godot", "assets", "audio")
SFX_RATE = 44100
MUSIC_RATE = 22050
TAU = math.tau


# --- plumbing ------------------------------------------------------------------------

def write_wav(name, samples, rate, peak, fade_out_ms=12):
    """Normalises to `peak` (0..1) and writes 16-bit mono PCM. One-shot sounds get a short
    fade-out so they never end with a click (the music loop passes fade_out_ms=0)."""
    samples = list(samples)
    fade = int(rate * fade_out_ms / 1000)
    for i in range(min(fade, len(samples))):
        samples[len(samples) - 1 - i] *= i / fade
    loudest = max(1e-9, max(abs(x) for x in samples))
    gain = peak / loudest
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x * gain)) * 32767)) for x in samples)
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(frames)
    print("wrote %-12s %5.2fs  %6.1f KB" % (name, len(samples) / rate, os.path.getsize(path) / 1024))


def lerp(a, b, t):
    return a + (b - a) * t


def clamp01(x):
    return max(0.0, min(1.0, x))


# Oscillators take a phase in cycles (0..1 repeating) and return -1..1.
def square(duty):
    """A pulse wave, re-centred on zero so narrow pulses carry no DC offset."""
    offset = 2.0 * duty - 1.0
    scale = 1.0 + abs(offset)
    return lambda p: ((1.0 if (p % 1.0) < duty else -1.0) - offset) / scale


def triangle(p):
    return 4.0 * abs((p % 1.0) - 0.5) - 1.0


def saw(p):
    return 2.0 * (p % 1.0) - 1.0


def sine(p):
    return math.sin(TAU * p)


def pluck(tau, attack=0.003):
    """Envelope: instant attack, exponential decay."""
    return lambda t, dur: min(1.0, t / attack) * math.exp(-t / tau)


def held(attack=0.005, release=0.03):
    """Envelope: stays at full volume, with short fades in and out."""
    return lambda t, dur: min(1.0, t / attack) * clamp01((dur - t) / release)


def voice(buf, rate, start, dur, freq, wave_fn, amp, env, vibrato=None, circular=False):
    """Adds one oscillator note into `buf`. `freq` is a number or a function of time (so notes
    can slide). `vibrato` is (hz, depth) with depth as a fraction of the pitch."""
    first = int(start * rate)
    phase = 0.0
    for k in range(int(dur * rate)):
        t = k / rate
        f = freq(t) if callable(freq) else freq
        if vibrato:
            f *= 1.0 + vibrato[1] * math.sin(TAU * vibrato[0] * t)
        phase += f / rate
        i = first + k
        if circular:
            i %= len(buf)
        elif i >= len(buf):
            break
        buf[i] += amp * wave_fn(phase) * env(t, dur)


def noise(buf, rate, start, dur, hold_hz, amp, env, seed=0, circular=False):
    """Crunchy sample-and-hold noise, like a console noise channel. `hold_hz` may be a function
    of time: lower values give a darker rumble."""
    rng = random.Random(seed)
    first = int(start * rate)
    value, countdown = 0.0, 0.0
    for k in range(int(dur * rate)):
        t = k / rate
        countdown -= 1.0
        if countdown <= 0:
            value = rng.uniform(-1, 1)
            hz = hold_hz(t) if callable(hold_hz) else hold_hz
            countdown = rate / max(hz, 50.0)
        i = first + k
        if circular:
            i %= len(buf)
        elif i >= len(buf):
            break
        buf[i] += amp * value * env(t, dur)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def blank(seconds, rate=SFX_RATE):
    return [0.0] * int(seconds * rate)




def softsq(p):
    """A rounded square: square plus a little sine, gentler on the ear."""
    return 0.55 * (1.0 if (p % 1.0) < 0.5 else -1.0) + 0.45 * math.sin(TAU * p)


def env_ad(attack, decay):
    return lambda t, dur: min(1.0, t / attack) * math.exp(-t / decay)


# --- weapons ---------------------------------------------------------------------------------

def musket():
    out = blank(0.16)
    noise(out, SFX_RATE, 0, 0.09, lambda t: lerp(9000, 2500, t / 0.09), 0.6, env_ad(0.001, 0.025), seed=2)
    voice(out, SFX_RATE, 0, 0.12, lambda t: lerp(260, 90, t / 0.12), sine, 0.8, env_ad(0.002, 0.04))
    return out


def cannon():
    out = blank(0.6)
    voice(out, SFX_RATE, 0, 0.55, lambda t: lerp(110, 38, (t / 0.55) ** 0.5), sine, 1.0, env_ad(0.003, 0.18))
    noise(out, SFX_RATE, 0, 0.5, lambda t: lerp(2500, 300, t / 0.5), 0.55, env_ad(0.002, 0.12), seed=3)
    return out


def volley():
    out = blank(0.2)
    for i in range(4):
        start = i * 0.035
        noise(out, SFX_RATE, start, 0.05, 7000, 0.45, env_ad(0.001, 0.012), seed=10 + i)
        voice(out, SFX_RATE, start, 0.05, 300 - i * 20, sine, 0.5, env_ad(0.001, 0.015))
    return out


def sniper():
    out = blank(0.35)
    noise(out, SFX_RATE, 0, 0.05, 12000, 0.7, env_ad(0.0005, 0.01), seed=4)
    voice(out, SFX_RATE, 0, 0.3, lambda t: lerp(1900, 1500, t / 0.3), sine, 0.25, env_ad(0.002, 0.08))
    voice(out, SFX_RATE, 0, 0.12, lambda t: lerp(200, 70, t / 0.12), sine, 0.7, env_ad(0.001, 0.03))
    return out


def arcane():
    out = blank(0.3)
    voice(out, SFX_RATE, 0, 0.28, lambda t: lerp(1400, 500, t / 0.28), softsq, 0.35, env_ad(0.004, 0.09), vibrato=(38, 0.06))
    voice(out, SFX_RATE, 0, 0.28, lambda t: lerp(2100, 900, t / 0.28), sine, 0.3, env_ad(0.004, 0.07))
    return out


def keep():
    out = blank(0.16)
    voice(out, SFX_RATE, 0, 0.15, lambda t: lerp(700, 1500, t / 0.15), triangle, 0.5, env_ad(0.003, 0.05))
    voice(out, SFX_RATE, 0, 0.15, lambda t: lerp(1400, 3000, t / 0.15), sine, 0.15, env_ad(0.003, 0.04))
    return out


# --- battlefield -------------------------------------------------------------------------------

def kill():
    out = blank(0.2)
    noise(out, SFX_RATE, 0, 0.16, lambda t: lerp(5000, 800, t / 0.16), 0.4, env_ad(0.002, 0.05), seed=5)
    voice(out, SFX_RATE, 0, 0.1, lambda t: lerp(600, 1200, t / 0.1), sine, 0.35, env_ad(0.002, 0.03))
    return out


def coin():
    out = blank(0.35)
    voice(out, SFX_RATE, 0, 0.08, midi(88), sine, 0.5, env_ad(0.002, 0.05))
    voice(out, SFX_RATE, 0.07, 0.28, midi(93), sine, 0.6, env_ad(0.002, 0.1))
    voice(out, SFX_RATE, 0.07, 0.28, midi(105), sine, 0.12, env_ad(0.002, 0.05))
    return out


def build():
    out = blank(0.5)
    voice(out, SFX_RATE, 0, 0.14, lambda t: lerp(220, 110, t / 0.14), sine, 0.9, env_ad(0.002, 0.05))
    noise(out, SFX_RATE, 0, 0.1, 1500, 0.3, env_ad(0.001, 0.03), seed=6)
    for i, n in enumerate((72, 76, 79)):
        voice(out, SFX_RATE, 0.08 + i * 0.07, 0.3, midi(n), triangle, 0.35, env_ad(0.003, 0.12))
    return out


def upgrade():
    out = blank(0.6)
    for i, n in enumerate((72, 76, 79, 84)):
        voice(out, SFX_RATE, i * 0.07, 0.35, midi(n), triangle, 0.4, env_ad(0.003, 0.12))
        voice(out, SFX_RATE, i * 0.07, 0.35, midi(n + 12), sine, 0.12, env_ad(0.003, 0.08))
    return out


def wall_break():
    out = blank(0.55)
    noise(out, SFX_RATE, 0, 0.5, lambda t: lerp(1800, 250, t / 0.5), 0.8, env_ad(0.004, 0.15), seed=7)
    for i in range(5):
        voice(out, SFX_RATE, i * 0.06, 0.08, 120 + i * 25, sine, 0.4, env_ad(0.001, 0.02))
    return out


def wave_call():
    """A short, cheerful bugle call."""
    out = blank(0.9)
    for start, n, d in ((0.0, 67, 0.16), (0.17, 72, 0.16), (0.34, 76, 0.5)):
        voice(out, SFX_RATE, start, d, midi(n), softsq, 0.35, held(0.01, 0.08), vibrato=(6, 0.01))
        voice(out, SFX_RATE, start, d, midi(n - 12), triangle, 0.3, held(0.01, 0.08))
    return out


def boss():
    out = blank(1.6)
    for start, n, d in ((0.0, 50, 0.35), (0.38, 53, 0.35), (0.76, 49, 0.8)):
        voice(out, SFX_RATE, start, d, midi(n), saw, 0.3, held(0.02, 0.2), vibrato=(5, 0.012))
        voice(out, SFX_RATE, start, d, midi(n - 12), softsq, 0.35, held(0.02, 0.2))
    noise(out, SFX_RATE, 0, 0.4, 200, 0.4, env_ad(0.005, 0.15), seed=8)
    return out


def game_over():
    out = blank(1.6)
    for i, n in enumerate((67, 64, 60, 55)):
        voice(out, SFX_RATE, i * 0.28, 0.5 if i < 3 else 0.9, midi(n), triangle, 0.45, held(0.01, 0.2), vibrato=(5, 0.01))
    return out


# --- interface ----------------------------------------------------------------------------------

def click():
    out = blank(0.07)
    voice(out, SFX_RATE, 0, 0.06, lambda t: lerp(900, 600, t / 0.06), sine, 0.6, env_ad(0.001, 0.02))
    return out


def denied():
    out = blank(0.18)
    voice(out, SFX_RATE, 0, 0.16, 140, softsq, 0.35, held(0.005, 0.05))
    return out


def research_done():
    out = blank(0.9)
    for i, n in enumerate((79, 83, 86, 91, 95)):
        voice(out, SFX_RATE, i * 0.06, 0.5, midi(n), sine, 0.3, env_ad(0.002, 0.18))
    return out


# --- music ----------------------------------------------------------------------------------------

def music():
    """A bouncy 16-bar loop in C major: plucked bass, a whistly melody and a soft shaker."""
    bpm = 112
    beat = 60.0 / bpm
    bars = 16
    out = blank(bars * 4 * beat, MUSIC_RATE)
    chords = [(48, 52, 55), (45, 48, 52), (41, 45, 48), (43, 47, 50)] * 4  # C Am F G
    melody = [
        76, 79, 81, 79, 76, 74, 72, None, 74, 76, 79, 76, 74, 72, 69, None,
        72, 74, 76, 77, 76, 74, 72, 74, 71, 72, 74, 76, 74, None, 67, None,
        76, 79, 81, 84, 83, 81, 79, None, 77, 79, 81, 79, 77, 76, 74, None,
        72, 76, 74, 72, 71, 72, 74, 71, 72, None, 67, None, 72, None, None, None,
    ]
    for bar in range(bars):
        root, third, fifth = chords[bar]
        t0 = bar * 4 * beat
        for b in range(4):
            note = root - 12 if b % 2 == 0 else fifth - 12
            voice(out, MUSIC_RATE, t0 + b * beat, beat * 0.9, midi(note), triangle, 0.5, env_ad(0.004, 0.22), circular=True)
            noise(out, MUSIC_RATE, t0 + (b + 0.5) * beat, 0.05, 9000, 0.06, env_ad(0.001, 0.015), seed=bar * 4 + b, circular=True)
        for k, n in enumerate((root, third, fifth)):
            voice(out, MUSIC_RATE, t0 + 2 * beat + k * 0.02, beat * 1.5, midi(n + 12), sine, 0.07, env_ad(0.01, 0.4), circular=True)
    step = beat / 2
    for i, n in enumerate(melody * 2):
        if n is not None:
            voice(out, MUSIC_RATE, i * step, step * 0.95, midi(n), softsq, 0.16, env_ad(0.006, 0.16), vibrato=(5.5, 0.006), circular=True)
            voice(out, MUSIC_RATE, i * step, step * 0.95, midi(n + 12), sine, 0.05, env_ad(0.006, 0.1), circular=True)
    return out


SOUNDS = {
    "musket": musket, "cannon": cannon, "volley": volley, "sniper": sniper, "arcane": arcane, "keep": keep,
    "kill": kill, "coin": coin, "build": build, "upgrade": upgrade, "wall_break": wall_break, "wave": wave_call,
    "boss": boss, "game_over": game_over, "click": click, "denied": denied, "research_done": research_done,
}

if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SOUNDS.items():
        write_wav(name, fn(), SFX_RATE, 0.9)
    write_wav("music", music(), MUSIC_RATE, 0.8, fade_out_ms=0)
