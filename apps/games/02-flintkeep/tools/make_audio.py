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


# --- music ------------------------------------------------------------------------------------------
# Three looping tracks plus a drum layer. Each is built from instruments rendered into mono
# stems, panned into stereo, sent through a small reverb, and wrapped so the loop is seamless.

def karplus(buf, rate, start, dur, freq, amp, damping=0.996, seed=0, circular=True):
    """A plucked string (lute / harp): a burst of noise in a delay line that softens as it rings."""
    rng = random.Random(seed)
    n = max(2, int(rate / freq))
    line = [rng.uniform(-1, 1) for _ in range(n)]
    first = int(start * rate)
    idx = 0
    for k in range(int(dur * rate)):
        a = line[idx]
        b = line[(idx + 1) % n]
        line[idx] = (a + b) * 0.5 * damping
        i = first + k
        if circular:
            i %= len(buf)
        elif i >= len(buf):
            break
        env = min(1.0, (dur * rate - k) / (0.02 * rate))  # short release, no clicks
        buf[i] += amp * a * env
        idx = (idx + 1) % n


def kick(buf, rate, start, amp):
    voice(buf, rate, start, 0.25, lambda t: lerp(140, 45, min(t / 0.12, 1.0)), sine, amp, env_ad(0.002, 0.08), circular=True)


def snare(buf, rate, start, amp, seed):
    noise(buf, rate, start, 0.18, 6000, amp, env_ad(0.001, 0.05), seed=seed, circular=True)
    voice(buf, rate, start, 0.1, 190, triangle, amp * 0.5, env_ad(0.001, 0.04), circular=True)


def reverb(mono, rate, wet=0.25, offset=0):
    """A small Schroeder reverb (four combs, two all-passes). The buffer is run twice so the tail
    at the end flows into the start, keeping the loop seamless."""
    n = len(mono)
    combs = [int(d * rate / 44100) + offset for d in (1557, 1617, 1491, 1422)]
    out = [0.0] * n
    for d in combs:
        line = [0.0] * d
        j = 0
        for k in range(2 * n):
            y = line[j]
            line[j] = mono[k % n] + y * 0.8
            j = (j + 1) % d
            if k >= n:
                out[k - n] += y * 0.25
    for d in (int(556 * rate / 44100), int(441 * rate / 44100)):
        line = [0.0] * d
        j = 0
        res = [0.0] * n
        for k in range(2 * n):
            x = out[k % n]
            y = line[j]
            line[j] = x + y * 0.5
            j = (j + 1) % d
            if k >= n:
                res[k - n] = y - x * 0.5
        out = res
    return [m + o * wet for m, o in zip(mono, out)]


class Mix:
    """Mono stems with a pan each (-1 left .. 1 right), mixed to stereo with reverb."""

    def __init__(self, seconds):
        self.n = int(seconds * MUSIC_RATE)
        self.stems = []

    def stem(self, pan, send=1.0):
        buf = [0.0] * self.n
        self.stems.append((buf, pan, send))
        return buf

    def render(self, wet=0.22):
        left = [0.0] * self.n
        right = [0.0] * self.n
        send_l = [0.0] * self.n
        send_r = [0.0] * self.n
        for buf, pan, send in self.stems:
            gl = math.sqrt(0.5 * (1.0 - pan))
            gr = math.sqrt(0.5 * (1.0 + pan))
            for i, x in enumerate(buf):
                if x:
                    left[i] += x * gl
                    right[i] += x * gr
                    send_l[i] += x * gl * send
                    send_r[i] += x * gr * send
        rl = reverb(send_l, MUSIC_RATE, 1.0, 0)
        rr = reverb(send_r, MUSIC_RATE, 1.0, 23)
        for i in range(self.n):
            left[i] += (rl[i] - send_l[i]) * wet
            right[i] += (rr[i] - send_r[i]) * wet
        return left, right


def write_stereo(name, left, right, peak=0.8):
    loudest = max(1e-9, max(max(abs(x) for x in left), max(abs(x) for x in right)))
    gain = peak / loudest
    frames = bytearray()
    for l, r in zip(left, right):
        frames += struct.pack("<hh", int(max(-1.0, min(1.0, l * gain)) * 32767), int(max(-1.0, min(1.0, r * gain)) * 32767))
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(MUSIC_RATE)
        f.writeframes(bytes(frames))
    print("wrote %-12s %5.2fs  %6.1f KB (stereo)" % (name, len(left) / MUSIC_RATE, os.path.getsize(path) / 1024))


def lead(mix, notes, step, octave=0, amp=0.15, wave_fn=None):
    """A whistle/flute lead doubled by a slightly detuned copy, spread left and right."""
    wave_fn = wave_fn or softsq
    l = mix.stem(-0.35)
    r = mix.stem(0.35)
    for i, n in enumerate(notes):
        if n is None:
            continue
        f = midi(n + octave)
        voice(l, MUSIC_RATE, i * step, step * 0.95, f * 1.003, wave_fn, amp, env_ad(0.01, step * 1.4), vibrato=(5.5, 0.006), circular=True)
        voice(r, MUSIC_RATE, i * step, step * 0.95, f * 0.997, wave_fn, amp, env_ad(0.01, step * 1.4), vibrato=(5.0, 0.006), circular=True)


def lute(mix, chords, beat, pattern=(0, 1, 2, 1), pan=-0.25, amp=0.35, seed=0):
    stem = mix.stem(pan)
    for bar, chord in enumerate(chords):
        for b in range(4):
            for half in range(2):
                note = chord[pattern[(b * 2 + half) % len(pattern)] % 3] + 12
                t = (bar * 4 + b + half * 0.5) * beat
                karplus(stem, MUSIC_RATE, t, beat * 1.2, midi(note), amp, 0.995, seed=seed + bar * 8 + b * 2 + half)


def bass(mix, chords, beat, amp=0.45, style="pulse"):
    stem = mix.stem(0.0, 0.3)
    for bar, chord in enumerate(chords):
        root = chord[0] - 12
        for b in range(4):
            note = root if (style == "pulse" or b % 2 == 0) else chord[2] - 12
            voice(stem, MUSIC_RATE, (bar * 4 + b) * beat, beat * 0.9, midi(note), triangle, amp, env_ad(0.004, 0.25), circular=True)


def pad(mix, chords, beat, amp=0.06):
    l = mix.stem(-0.6)
    r = mix.stem(0.6)
    for bar, chord in enumerate(chords):
        for k, n in enumerate(chord):
            target = l if k % 2 == 0 else r
            voice(target, MUSIC_RATE, bar * 4 * beat, 4 * beat, midi(n + 12), sine, amp, held(0.4, 0.5), circular=True)


def shaker(mix, bars, beat, amp=0.05):
    stem = mix.stem(0.45, 0.2)
    for i in range(bars * 8):
        noise(stem, MUSIC_RATE, i * beat / 2, 0.05, 9000, amp * (1.0 if i % 2 else 0.6), env_ad(0.001, 0.015), seed=i, circular=True)


C, AM, F, G, EM, E, DM = (48, 52, 55), (45, 48, 52), (41, 45, 48), (43, 47, 50), (40, 43, 47), (40, 44, 47), (38, 41, 45)


def menu_music():
    """Calm and warm: lute arpeggios over soft strings, a sparse flute. 76 bpm, 16 bars."""
    beat = 60.0 / 76
    chords = [AM, F, C, G] * 4
    mix = Mix(len(chords) * 4 * beat)
    lute(mix, chords, beat, (0, 1, 2, 1, 0, 2, 1, 2), amp=0.32)
    pad(mix, chords, beat, 0.07)
    bass(mix, chords, beat, 0.3, "half")
    melody = [76, None, 74, 72, 71, None, 69, None, 72, None, 71, 69, 67, None, None, None] * 4
    lead(mix, melody, beat, amp=0.08, wave_fn=sine)
    return mix.render(0.35)


BATTLE_A = [76, 79, 81, 79, 76, 74, 72, None, 74, 76, 79, 76, 74, 72, 69, None,
            72, 74, 76, 77, 76, 74, 72, 74, 71, 72, 74, 76, 74, None, 67, None]
BATTLE_B = [77, None, 77, 79, 81, 79, 77, 76, 74, None, 74, 76, 77, 76, 74, 72,
            71, 72, 74, 76, 77, 79, 81, 83, 84, None, 79, None, 76, None, None, None]


def battle_music():
    """The main battle theme: bouncy, 112 bpm, an A and a B section (32 bars, about a minute)."""
    beat = 60.0 / 112
    chords = [C, AM, F, G] * 2 + [F, G, EM, AM, F, G, C, C] + [C, AM, F, G] * 2 + [F, G, EM, AM, DM, G, C, C]
    mix = Mix(len(chords) * 4 * beat)
    lute(mix, chords, beat, (0, 2, 1, 2), amp=0.28, seed=100)
    bass(mix, chords, beat, 0.42)
    pad(mix, chords, beat, 0.04)
    shaker(mix, len(chords), beat)
    lead(mix, (BATTLE_A + BATTLE_B) * 2, beat / 2, amp=0.13)
    return mix.render(0.2)


def battle_drums():
    """A drum layer the same length as the battle theme; it fades in as the waves get tough."""
    beat = 60.0 / 112
    bars = 32
    mix = Mix(bars * 4 * beat)
    kit = mix.stem(0.0, 0.25)
    for bar in range(bars):
        t0 = bar * 4 * beat
        kick(kit, MUSIC_RATE, t0, 0.8)
        kick(kit, MUSIC_RATE, t0 + 2 * beat, 0.7)
        snare(kit, MUSIC_RATE, t0 + beat, 0.4, bar * 2)
        snare(kit, MUSIC_RATE, t0 + 3 * beat, 0.45, bar * 2 + 1)
        if bar % 8 == 7:  # a little fill at the end of each phrase
            for k in range(4):
                snare(kit, MUSIC_RATE, t0 + 3 * beat + k * beat / 4, 0.3 + 0.05 * k, 500 + bar * 4 + k)
    return mix.render(0.15)


def boss_music():
    """Driving and dark for the Juggernaut: A minor, 132 bpm, low brass and pounding drums."""
    beat = 60.0 / 132
    chords = [AM, AM, F, G, AM, AM, E, E] * 2
    mix = Mix(len(chords) * 4 * beat)
    brass = mix.stem(-0.2)
    for bar, chord in enumerate(chords):
        for k, n in enumerate(chord):
            voice(brass, MUSIC_RATE, bar * 4 * beat, 4 * beat * 0.97, midi(n), saw, 0.07, held(0.08, 0.2), vibrato=(4, 0.004), circular=True)
    stem = mix.stem(0.0, 0.3)
    for bar, chord in enumerate(chords):
        for e in range(8):
            voice(stem, MUSIC_RATE, (bar * 4 + e * 0.5) * beat, beat * 0.45, midi(chord[0] - 12), softsq, 0.3, env_ad(0.003, 0.12), circular=True)
    kit = mix.stem(0.0, 0.2)
    for bar in range(len(chords)):
        t0 = bar * 4 * beat
        for b in range(4):
            kick(kit, MUSIC_RATE, t0 + b * beat, 0.8)
        snare(kit, MUSIC_RATE, t0 + beat, 0.45, bar * 3)
        snare(kit, MUSIC_RATE, t0 + 3 * beat, 0.5, bar * 3 + 1)
    riff = [81, None, 81, 79, 77, None, 76, None, 77, 76, 74, None, 76, None, None, None] * 4
    lead(mix, riff, beat / 2, -12, amp=0.12, wave_fn=saw)
    return mix.render(0.18)


MUSIC = {"music_menu": menu_music, "music_battle": battle_music, "music_drums": battle_drums, "music_boss": boss_music}

IMPORT_LOOP = """[remap]

importer="wav"
type="AudioStreamWAV"

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=1
edit/loop_begin=0
edit/loop_end=-1
compress/mode=2
"""


def mark_loop(name):
    """Music loops forever and is compressed (QOA) when Godot imports it."""
    path = os.path.join(OUT_DIR, name + ".wav.import")
    with open(path, "w") as f:
        f.write(IMPORT_LOOP)


SOUNDS = {
    "musket": musket, "cannon": cannon, "volley": volley, "sniper": sniper, "arcane": arcane, "keep": keep,
    "kill": kill, "coin": coin, "build": build, "upgrade": upgrade, "wall_break": wall_break, "wave": wave_call,
    "boss": boss, "game_over": game_over, "click": click, "denied": denied, "research_done": research_done,
}

if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SOUNDS.items():
        write_wav(name, fn(), SFX_RATE, 0.9)
    for name, fn in MUSIC.items():
        left, right = fn()
        write_stereo(name, left, right)
        mark_loop(name)
