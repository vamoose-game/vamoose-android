import subprocess
import wave
from pathlib import Path

import numpy as np

RATE = 44100
BPM = 72
BAR = 4 * 60 / BPM
BARS = 32
LENGTH = BARS * BAR
TAIL = 6.0
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'music' / 'calm.ogg'

CHORDS = [
    (36, [60, 64, 67, 71]),
    (45, [57, 60, 64, 67]),
    (41, [53, 57, 60, 64]),
    (43, [55, 59, 62, 64]),
    (36, [60, 64, 67, 71]),
    (40, [52, 55, 59, 62]),
    (38, [53, 57, 60, 64]),
    (43, [55, 60, 62, 67]),
]
PENTATONIC = [72, 74, 76, 79, 81, 84, 86]


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def timeline(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def add(track, start, part):
    begin = int(RATE * start)
    end = min(track.shape[-1], begin + part.shape[-1])
    track[..., begin:end] += part[..., : end - begin]


def pad_note(note, seconds):
    t = timeline(seconds + 2.5)
    freq = hz(note)
    tone = sum(np.sin(2 * np.pi * freq * (1 + cents / 1200) * t + phase) for cents, phase in [(0, 0), (4, 1.3), (-4, 2.1)])
    tone += 0.15 * np.sin(2 * np.pi * 2 * freq * t)
    attack = np.clip(t / 1.6, 0, 1) ** 2
    release = np.clip((seconds + 2.5 - t) / 2.5, 0, 1)
    breathe = 1 + 0.08 * np.sin(2 * np.pi * 0.15 * t)
    return tone * attack * release * breathe * 0.045


def bass_note(note, seconds):
    t = timeline(seconds)
    freq = hz(note)
    tone = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * 2 * freq * t)
    return tone * np.clip(t / 0.08, 0, 1) * np.exp(-t / 2.2) * 0.16


def pluck(note, velocity):
    t = timeline(2.4)
    freq = hz(note)
    tone = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.9)
    tone += 0.22 * np.sin(2 * np.pi * 2 * freq * t) * np.exp(-t / 0.35)
    tone += 0.08 * np.sin(2 * np.pi * 5.4 * freq * t) * np.exp(-t / 0.12)
    return tone * np.clip(t / 0.004, 0, 1) * velocity * 0.11


def pan(mono, position):
    angle = (position + 1) * np.pi / 4
    return np.stack([mono * np.cos(angle), mono * np.sin(angle)])


def melody(rng, track, first_bar, bars):
    index = 2
    for bar in range(first_bar, first_bar + bars):
        chord = CHORDS[(bar // 4) % len(CHORDS)][1]
        for slot in range(8):
            chance = 0.55 if slot == 0 else (0.3 if slot % 2 == 0 else 0.16)
            if rng.random() > chance:
                continue
            index = int(np.clip(index + rng.integers(-2, 3), 0, len(PENTATONIC) - 1))
            note = PENTATONIC[index]
            if note % 12 not in {tone % 12 for tone in chord} and rng.random() < 0.5:
                continue
            start = bar * BAR + slot * BAR / 8 + rng.normal(0, 0.008)
            add(track, max(0.0, start), pan(pluck(note, rng.uniform(0.55, 0.95)), rng.uniform(-0.45, 0.45)))


def lowpass(signal, cutoff):
    spectrum = np.fft.rfft(signal, axis=-1)
    freqs = np.fft.rfftfreq(signal.shape[-1], 1 / RATE)
    spectrum *= 1 / np.sqrt(1 + (freqs / cutoff) ** 4)
    return np.fft.irfft(spectrum, signal.shape[-1], axis=-1)


def reverb(signal, seconds=3.2, wet=0.32):
    out = np.empty_like(signal)
    t = timeline(seconds)
    for channel in range(2):
        impulse = np.random.default_rng(21 + channel).normal(0, 1, len(t)) * np.exp(-t / (seconds / 6))
        impulse = lowpass(impulse, 4200)
        impulse /= np.sqrt(np.sum(impulse ** 2))
        size = signal.shape[-1] + len(impulse)
        tail = np.fft.irfft(np.fft.rfft(signal[channel], size) * np.fft.rfft(impulse, size), size)
        out[channel] = signal[channel] + wet * tail[: signal.shape[-1]]
    return out


def render():
    track = np.zeros((2, int(RATE * (LENGTH + TAIL))))
    chord_bars = 4
    for bar in range(0, BARS, chord_bars):
        bass, voicing = CHORDS[(bar // chord_bars) % len(CHORDS)]
        start = bar * BAR
        for offset, note in enumerate(voicing):
            add(track, start, pan(pad_note(note, chord_bars * BAR), (offset - 1.5) * 0.25))
        for hit in range(chord_bars):
            add(track, start + hit * BAR, pan(bass_note(bass, BAR * 1.2), 0))
    melody(np.random.default_rng(3), track, 0, BARS // 2)
    melody(np.random.default_rng(8), track, BARS // 2, BARS // 2)
    track = lowpass(track, 6000)
    track = reverb(track)
    looped = track[:, : int(RATE * LENGTH)].copy()
    tail = track[:, int(RATE * LENGTH):]
    looped[:, : tail.shape[-1]] += tail
    return looped / np.max(np.abs(looped)) * 0.85


def main():
    music = render()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    temp = OUT.with_suffix('.wav')
    with wave.open(str(temp), 'wb') as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(np.int16(music.T * 32767).tobytes())
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(temp), '-c:a', 'libvorbis', '-q:a', '3', str(OUT)], check=True)
    temp.unlink()


if __name__ == '__main__':
    main()
