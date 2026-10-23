#!/usr/bin/env python3
"""Synthesizes every sound in the game as 8-bit-arcade chiptune, using only the Python standard
library: no samples, no downloads, no licences.

Run `python3 tools/generate_audio.py` to (re)create the .wav files in godot/assets/audio/.
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


# --- card and interface sounds ------------------------------------------------------------

def throw():
    """A card flicked across the table: a chirpy blip over a quick noise swish."""
    out = blank(0.22)
    voice(out, SFX_RATE, 0, 0.09, lambda t: lerp(520, 1500, t / 0.09), square(0.25), 0.5, pluck(0.05))
    noise(out, SFX_RATE, 0, 0.2, lambda t: lerp(12000, 3000, t / 0.2), 0.35,
          lambda t, d: math.sin(math.pi * clamp01(t / d)) ** 1.5, seed=1)
    return out


def land():
    """A card slapping onto the table: a dry tick and a short low thump."""
    out = blank(0.12)
    noise(out, SFX_RATE, 0, 0.06, 5000, 0.6, pluck(0.012), seed=2)
    voice(out, SFX_RATE, 0, 0.1, lambda t: lerp(150, 55, clamp01(t / 0.08)), triangle, 0.9, pluck(0.04))
    return out


def select_blip():
    out = blank(0.07)
    voice(out, SFX_RATE, 0.0, 0.03, 1318.5, square(0.5), 0.5, held(0.002, 0.01))
    voice(out, SFX_RATE, 0.03, 0.04, 1760.0, square(0.5), 0.5, held(0.002, 0.02))
    return out


def click():
    out = blank(0.09)
    voice(out, SFX_RATE, 0.0, 0.035, 784.0, square(0.5), 0.5, held(0.002, 0.01))
    voice(out, SFX_RATE, 0.035, 0.05, 1175.0, square(0.5), 0.5, held(0.002, 0.03))
    return out


def ping():
    """The classic two-note coin chime: it is your turn."""
    out = blank(0.5)
    voice(out, SFX_RATE, 0.0, 0.07, 987.8, square(0.5), 0.5, held(0.002, 0.01))
    voice(out, SFX_RATE, 0.07, 0.42, 1318.5, square(0.5), 0.5, pluck(0.16))
    return out


def swoosh_out():
    """Cards sucked away: a stair-stepped laser sliding down, with a breath of noise."""
    dur = 0.6
    steps = 14

    def slide(t):
        stepped = int(clamp01(t / dur) * steps) / steps
        return 2100.0 * (170.0 / 2100.0) ** stepped

    out = blank(dur + 0.02)
    voice(out, SFX_RATE, 0, dur, slide, square(0.25), 0.45, lambda t, d: min(1.0, t / 0.02) * (1 - t / d) ** 1.2)
    noise(out, SFX_RATE, 0, dur, lambda t: lerp(9000, 1200, t / dur), 0.18,
          lambda t, d: math.sin(math.pi * clamp01(t / d)), seed=3)
    return out


def swoosh_in():
    """The same slide played backwards: cards arriving."""
    return list(reversed(swoosh_out()))


# --- event sounds --------------------------------------------------------------------

def reset_blast():
    """Dramatic: a power-up arpeggio runs up, then an explosion rumbles out."""
    out = blank(1.4)
    for i, note in enumerate((72, 76, 79, 84, 88, 91)):
        voice(out, SFX_RATE, i * 0.055, 0.1, midi(note), square(0.25), 0.4, pluck(0.07))
    blast = 0.36
    noise(out, SFX_RATE, blast, 0.9, lambda t: lerp(7000, 300, clamp01(t / 0.8)), 0.85, pluck(0.28), seed=4)
    voice(out, SFX_RATE, blast, 0.9, lambda t: lerp(110, 28, clamp01(t / 0.7)), saw, 0.7, pluck(0.3))
    return out


def sad_trumpet():
    """Skip! 'Wah, wah, wah, waaaah': a muted brass note through an opening and closing filter."""
    notes = [(0.00, 0.24, 392.0, 392.0), (0.30, 0.24, 370.0, 370.0), (0.60, 0.24, 349.2, 349.2), (0.90, 0.95, 329.6, 262.0)]
    out = blank(2.0)
    for start, dur, f0, f1 in notes:
        long = dur > 0.5
        first = int(start * SFX_RATE)
        phase, low = 0.0, 0.0
        for k in range(int(dur * SFX_RATE)):
            t = k / SFX_RATE
            u = t / dur
            f = lerp(f0, f1, u ** 1.5) * (1 + (0.014 * math.sin(TAU * 5.5 * t) if long and t > 0.2 else 0.0))
            phase += f / SFX_RATE
            cutoff = 600 + 1800 * math.sin(math.pi * clamp01(u * (0.9 if long else 1.0))) ** 1.2
            a = 1 - math.exp(-TAU * cutoff / SFX_RATE)
            raw = 0.75 * saw(phase) + 0.25 * square(0.3)(phase)
            low += a * (raw - low)
            out[first + k] += 0.9 * low * min(1.0, t / 0.015) * clamp01((dur - t) / 0.05)
    return out


def boing():
    """A cartoon spring: the pitch leaps up, then wobbles and settles."""
    dur = 0.8
    out = blank(dur)
    voice(out, SFX_RATE, 0, dur,
          lambda t: 250 + 360 * math.exp(-t / 0.06) + 150 * math.sin(TAU * 12 * t) * math.exp(-t / 0.3),
          triangle, 0.9, pluck(0.35))
    voice(out, SFX_RATE, 0, dur,
          lambda t: 500 + 720 * math.exp(-t / 0.06) + 300 * math.sin(TAU * 12 * t) * math.exp(-t / 0.3),
          square(0.5), 0.12, pluck(0.2))
    return out


def win_fanfare():
    out = blank(2.0)
    for i, note in enumerate((72, 76, 79, 84, 88, 91)):
        voice(out, SFX_RATE, i * 0.075, 0.12, midi(note), square(0.25), 0.4, pluck(0.08))
    for note in (84, 88, 91):
        voice(out, SFX_RATE, 0.5, 1.3, midi(note), square(0.25), 0.28, pluck(0.55))
    voice(out, SFX_RATE, 0.5, 1.3, midi(60), triangle, 0.5, pluck(0.7))
    return out


def game_over_sting():
    out = blank(2.0)
    for start, note in ((0.0, 72), (0.2, 71), (0.4, 70)):
        voice(out, SFX_RATE, start, 0.19, midi(note), square(0.5), 0.45, held(0.005, 0.04))
    voice(out, SFX_RATE, 0.6, 1.2, lambda t: lerp(midi(69), midi(57), clamp01(t / 1.1)),
          square(0.5), 0.5, held(0.01, 0.2), vibrato=(6.0, 0.02))
    return out


# --- background music ----------------------------------------------------------------

def music_loop():
    """An upbeat arcade attract-mode loop: bouncy square-wave arpeggios, a walking triangle
    bass, punchy noise drums and, from bar 5, a catchy lead. 16 bars at 132 BPM, looping
    seamlessly (notes that ring past the end wrap to the start)."""
    rate, bpm = MUSIC_RATE, 132.0
    beat = 60.0 / bpm
    bars = 16
    total = int(bars * 4 * beat * rate)
    buf = [0.0] * total

    # (bass root, triad for arpeggio) per bar
    chords = {
        "Am": (45, [69, 72, 76]),
        "F": (41, [69, 72, 77]),
        "C": (48, [67, 72, 76]),
        "G": (43, [67, 71, 74]),
        "Dm": (50, [69, 74, 77]),
        "E": (40, [68, 71, 76]),
    }
    progression = ["Am", "F", "C", "G"] * 2 + ["Dm", "G", "C", "Am", "Dm", "G", "C", "E"]
    lead = {  # bar -> [(beat, midi note, length in beats)]
        4: [(0, 76, 1), (1, 79, 0.5), (1.5, 76, 0.5), (2, 81, 2)],
        5: [(0, 81, 1), (1, 79, 0.5), (1.5, 77, 0.5), (2, 76, 2)],
        6: [(0, 79, 1), (1, 76, 1), (2, 72, 1), (3, 76, 1)],
        7: [(0, 74, 1.5), (1.5, 79, 0.5), (2, 83, 2)],
        8: [(0, 81, 1), (1, 77, 1), (2, 74, 1), (3, 77, 1)],
        9: [(0, 79, 1), (1, 74, 1), (2, 79, 1), (3, 83, 1)],
        10: [(0, 84, 1.5), (1.5, 79, 0.5), (2, 76, 2)],
        11: [(0, 81, 1), (1, 76, 1), (2, 72, 1), (3, 69, 1)],
        12: [(0, 74, 1), (1, 77, 1), (2, 81, 1), (3, 77, 1)],
        13: [(0, 83, 1), (1, 79, 1), (2, 74, 2)],
        14: [(0, 76, 1), (1, 79, 1), (2, 84, 2)],
        15: [(0, 83, 1), (1, 80, 1), (2, 76, 2)],
    }
    arp_a = [0, 1, 2, 1] * 4
    arp_b = [0, 2, 1, 2, 0, 2, 1, 3] * 2
    bass_pattern = [0, 0, 12, 0, 0, 0, 12, 7]

    for bar in range(bars):
        root, triad = chords[progression[bar]]
        t0 = bar * 4 * beat
        pattern = arp_a if bar < 8 else arp_b
        for step, idx in enumerate(pattern):
            note = triad[idx] if idx < 3 else triad[0] + 12
            voice(buf, rate, t0 + step * beat / 4, beat / 4 * 0.95, midi(note), square(0.25), 0.13,
                  pluck(0.07), circular=True)
        for step, offset in enumerate(bass_pattern):
            voice(buf, rate, t0 + step * beat / 2, beat / 2 * 0.9, midi(root + offset), triangle, 0.55,
                  held(0.004, 0.04), circular=True)
        for kick in (0, 2):
            voice(buf, rate, t0 + kick * beat, 0.14, lambda t: lerp(170, 45, clamp01(t / 0.1)), triangle, 0.7,
                  pluck(0.07), circular=True)
        for snare in (1, 3):
            noise(buf, rate, t0 + snare * beat, 0.12, 9000, 0.3, pluck(0.04), seed=bar * 7 + snare, circular=True)
            voice(buf, rate, t0 + snare * beat, 0.08, 210, triangle, 0.25, pluck(0.03), circular=True)
        for hat in range(8):
            level = 0.09 if hat % 2 else 0.06
            noise(buf, rate, t0 + hat * beat / 2, 0.035, 14000, level, pluck(0.012), seed=bar * 11 + hat, circular=True)
        if bar in (7, 15):  # snare roll into the next section
            for roll in range(4):
                noise(buf, rate, t0 + 3 * beat + roll * beat / 4, 0.08, 9000, 0.28, pluck(0.04), seed=900 + roll, circular=True)
        for offset, note, length in lead.get(bar, []):
            voice(buf, rate, t0 + offset * beat, length * beat * 0.92, midi(note), square(0.5), 0.2,
                  held(0.005, 0.05), vibrato=(5.5, 0.008), circular=True)
    return buf


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    write_wav("throw", throw(), SFX_RATE, 0.5)
    write_wav("land", land(), SFX_RATE, 0.75)
    write_wav("select", select_blip(), SFX_RATE, 0.35)
    write_wav("click", click(), SFX_RATE, 0.35)
    write_wav("ping", ping(), SFX_RATE, 0.4)
    write_wav("swoosh_out", swoosh_out(), SFX_RATE, 0.45)
    write_wav("swoosh_in", swoosh_in(), SFX_RATE, 0.45)
    write_wav("reset", reset_blast(), SFX_RATE, 0.9)
    write_wav("skip", sad_trumpet(), SFX_RATE, 0.55)
    write_wav("boing", boing(), SFX_RATE, 0.55)
    write_wav("win", win_fanfare(), SFX_RATE, 0.45)
    write_wav("game_over", game_over_sting(), SFX_RATE, 0.38)
    write_wav("music", music_loop(), MUSIC_RATE, 0.7, fade_out_ms=0)


if __name__ == "__main__":
    main()
