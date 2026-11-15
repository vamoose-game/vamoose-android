from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / 'assets' / 'icon'
INK = (27, 35, 64, 255)
BLOCKS = [
    ((59, 99, 240), 'up', 0, 0),
    ((239, 90, 60), 'right', 1, 0),
    ((132, 87, 240), 'left', 0, 1),
    ((14, 159, 138), 'down', 1, 1),
]


def shade(color):
    return tuple(int(c * 0.78 + i * 0.22) for c, i in zip(color, INK[:3])) + (255,)


def arrow(draw, cx, cy, size, direction):
    half = size / 2
    head = size * 0.38
    width = max(2, int(size * 0.16))
    vectors = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}
    dx, dy = vectors[direction]
    tip = (cx + dx * half, cy + dy * half)
    tail = (cx - dx * half, cy - dy * half)
    px, py = -dy, dx
    wing_a = (tip[0] - dx * head + px * head, tip[1] - dy * head + py * head)
    wing_b = (tip[0] - dx * head - px * head, tip[1] - dy * head - py * head)
    for start, end in [(tail, tip), (wing_a, tip), (wing_b, tip)]:
        draw.line([start, end], fill=(255, 255, 255, 255), width=width)
        for x, y in (start, end):
            r = width / 2
            draw.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 255))


def mark(size):
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    tile = size * 0.47
    gap = size - tile * 2
    edge = tile * 0.08
    radius = tile * 0.24
    for color, direction, column, row in BLOCKS:
        x = column * (tile + gap)
        y = row * (tile + gap)
        draw.rounded_rectangle([x, y + edge, x + tile, y + tile], radius, fill=shade(color))
        draw.rounded_rectangle([x, y, x + tile, y + tile - edge], radius, fill=color + (255,))
        arrow(draw, x + tile / 2, y + (tile - edge) / 2, tile * 0.42, direction)
    return image


def centered(canvas_size, mark_size, background=(0, 0, 0, 0)):
    canvas = Image.new('RGBA', (canvas_size, canvas_size), background)
    offset = (canvas_size - mark_size) // 2
    canvas.alpha_composite(mark(mark_size), (offset, offset))
    return canvas


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    centered(1024, 560, INK).save(OUT / 'icon.png')
    centered(1024, 470).save(OUT / 'foreground.png')
    centered(768, 400).save(OUT / 'splash.png')
    centered(1152, 520).save(OUT / 'splash_android12.png')
    centered(512, 280, INK).save(OUT / 'play_store_512.png')


if __name__ == '__main__':
    main()
