import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / 'assets' / 'sounds'


def envelope(t, length, attack=0.005):
    if t < attack:
        return t / attack
    return max(0.0, 1 - (t - attack) / (length - attack)) ** 2


def tone(freq_start, freq_end, length, volume=0.5, harmonic=0.0, noise=0.0, seed=1):
    rng = random.Random(seed)
    samples = []
    phase = 0.0
    count = int(RATE * length)
    for i in range(count):
        t = i / RATE
        freq = freq_start + (freq_end - freq_start) * (i / count)
        phase += 2 * math.pi * freq / RATE
        value = math.sin(phase) + harmonic * math.sin(2 * phase)
        value += noise * (rng.random() * 2 - 1)
        samples.append(value * envelope(t, length) * volume / (1 + harmonic + noise))
    return samples


def mix(parts, length):
    out = [0.0] * int(RATE * length)
    for offset, samples in parts:
        start = int(RATE * offset)
        for i, value in enumerate(samples):
            if start + i < len(out):
                out[start + i] += value
    return out


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(b''.join(
            struct.pack('<h', int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        ))


def main():
    write('tap', tone(900, 700, 0.05, volume=0.35))
    write('slide', tone(320, 880, 0.22, volume=0.45, harmonic=0.3, noise=0.15))
    write('bump', tone(150, 80, 0.14, volume=0.7, harmonic=0.4))
    write('hint', mix([(0.0, tone(880, 880, 0.18, 0.4, 0.3)), (0.11, tone(1320, 1320, 0.25, 0.4, 0.3))], 0.4))
    notes = [523.25, 659.25, 783.99, 1046.5]
    write('clear', mix([(i * 0.1, tone(n, n, 0.45, 0.4, 0.35)) for i, n in enumerate(notes)], 0.8))
    write('star', tone(1568, 1568, 0.22, volume=0.35, harmonic=0.25))


if __name__ == '__main__':
    main()
