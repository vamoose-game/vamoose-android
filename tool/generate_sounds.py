from pathlib import Path

import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / 'assets' / 'sounds'
PENTATONIC = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51]
STARS = [783.99, 1046.50, 1318.51]


def timeline(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def envelope(t, attack, decay):
    rise = np.clip(t / attack, 0, 1)
    return rise * np.exp(-np.maximum(t - attack, 0) / decay)


def pluck(freq, seconds=0.6, decay=0.28, brightness=0.25):
    t = timeline(seconds)
    body = np.sin(2 * np.pi * freq * t) * envelope(t, 0.003, decay)
    body += brightness * np.sin(2 * np.pi * 2 * freq * t) * envelope(t, 0.002, decay * 0.45)
    body += brightness * 0.3 * np.sin(2 * np.pi * 3 * freq * t) * envelope(t, 0.002, decay * 0.25)
    return body


def bell(freq, seconds=0.9, decay=0.35):
    t = timeline(seconds)
    tone = np.sin(2 * np.pi * freq * t) * envelope(t, 0.002, decay)
    tone += 0.35 * np.sin(2 * np.pi * 2.76 * freq * t) * envelope(t, 0.001, decay * 0.3)
    tone += 0.15 * np.sin(2 * np.pi * 5.4 * freq * t) * envelope(t, 0.001, decay * 0.15)
    return tone


def lowpass(signal, cutoff):
    spectrum = np.fft.rfft(signal)
    freqs = np.fft.rfftfreq(len(signal), 1 / RATE)
    spectrum *= 1 / np.sqrt(1 + (freqs / cutoff) ** 4)
    return np.fft.irfft(spectrum, len(signal))


def noise(seconds, seed):
    return np.random.default_rng(seed).uniform(-1, 1, int(RATE * seconds))


def reverb(signal, seconds=0.8, wet=0.18, seed=7):
    t = timeline(seconds)
    impulse = noise(seconds, seed) * np.exp(-t / (seconds / 5))
    impulse = lowpass(impulse, 5000)
    impulse /= np.sqrt(np.sum(impulse ** 2))
    size = len(signal) + len(impulse)
    tail = np.fft.irfft(np.fft.rfft(signal, size) * np.fft.rfft(impulse, size), size)
    dry = np.concatenate([signal, np.zeros(len(impulse))])
    return dry + wet * tail


def place(parts, seconds):
    out = np.zeros(int(RATE * seconds))
    for start, part in parts:
        begin = int(RATE * start)
        end = min(len(out), begin + len(part))
        out[begin:end] += part[: end - begin]
    return out


def finish(signal, peak):
    signal = signal / np.max(np.abs(signal))
    audible = np.nonzero(np.abs(signal) > 0.003)[0]
    signal = signal[: max(audible[-1] + 1, int(RATE * 0.05))].copy()
    fade = min(len(signal), int(RATE * 0.03))
    signal[-fade:] *= np.linspace(1, 0, fade)
    return signal * peak


def write(name, signal):
    OUT.mkdir(parents=True, exist_ok=True)
    pcm = np.int16(np.clip(signal, -1, 1) * 32767)
    import wave
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(pcm.tobytes())


def tap():
    t = timeline(0.06)
    sweep = np.sin(2 * np.pi * np.cumsum(np.linspace(1500, 900, len(t))) / RATE)
    click = lowpass(noise(0.06, 3), 4000) * envelope(t, 0.0005, 0.004)
    return finish(sweep * envelope(t, 0.001, 0.012) + 0.3 * click, 0.32)


def leave(freq):
    t = timeline(0.18)
    whoosh = lowpass(noise(0.18, 11), 2500) * np.sin(np.pi * t / 0.18) ** 2
    note = place([(0, pluck(freq)), (0.0, 0.12 * whoosh)], 0.7)
    return finish(reverb(note, wet=0.16), 0.6)


def bump():
    t = timeline(0.2)
    pitch = np.cumsum(np.linspace(170, 95, len(t))) / RATE
    thock = np.sin(2 * np.pi * pitch) * envelope(t, 0.002, 0.045)
    knock = lowpass(noise(0.2, 5), 900) * envelope(t, 0.0005, 0.012)
    return finish(thock + 0.5 * knock, 0.75)


def hint():
    notes = place([(0, bell(1318.51, 0.7)), (0.07, bell(1567.98, 0.7)), (0.14, bell(1975.53, 0.8))], 1.0)
    return finish(reverb(notes, seconds=1.0, wet=0.3), 0.45)


def clear():
    chord = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    arpeggio = place([(i * 0.07, pluck(f, 1.2, 0.5, 0.3)) for i, f in enumerate(chord)], 2.0)
    t = timeline(2.0)
    pad = sum(np.sin(2 * np.pi * f / 2 * t) for f in chord[:3]) * envelope(t, 0.25, 0.7) * 0.18
    sparkle = place([(0.38, bell(2093.0, 0.8, 0.3)), (0.46, bell(2637.0, 0.8, 0.3))], 2.0) * 0.35
    return finish(reverb(arpeggio + pad + sparkle, seconds=1.4, wet=0.3), 0.7)


def star(freq):
    return finish(reverb(bell(freq, 0.8, 0.3), seconds=0.9, wet=0.25), 0.5)


def tick():
    t = timeline(0.08)
    knock = np.sin(2 * np.pi * 1760 * t) * envelope(t, 0.0005, 0.01)
    wood = lowpass(noise(0.08, 13), 3000) * envelope(t, 0.0003, 0.004)
    return finish(knock + 0.4 * wood, 0.28)


def fail():
    notes = place([(0, pluck(392.00, 0.8, 0.3, 0.15)), (0.16, pluck(293.66, 1.0, 0.42, 0.12))], 1.3)
    return finish(reverb(lowpass(notes, 2200), seconds=1.0, wet=0.22), 0.55)


def boost():
    notes = place([(0, bell(987.77, 0.5, 0.2)), (0.06, bell(1318.51, 0.6, 0.25)), (0.12, bell(1975.53, 0.7, 0.3))], 0.9)
    return finish(reverb(notes, seconds=0.8, wet=0.25), 0.45)


def main():
    for old in OUT.glob('*.wav'):
        old.unlink()
    write('tap', tap())
    for index, freq in enumerate(PENTATONIC):
        write(f'leave_{index}', leave(freq))
    write('bump', bump())
    write('hint', hint())
    write('clear', clear())
    for index, freq in enumerate(STARS):
        write(f'star_{index}', star(freq))
    write('tick', tick())
    write('fail', fail())
    write('boost', boost())


if __name__ == '__main__':
    main()
