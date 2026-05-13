from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "raw" / "Knight" / "without_outline" / "shield_attack.jpg"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "Knight" / "without_outline" / "shield_attack"

COLS = 4
ROWS = 2
BACKGROUND = (90, 157, 91)
HARD_THRESHOLD = 42
SOFT_THRESHOLD = 78


def keyed_alpha(r: int, g: int, b: int) -> int:
    distance = ((r - BACKGROUND[0]) ** 2 + (g - BACKGROUND[1]) ** 2 + (b - BACKGROUND[2]) ** 2) ** 0.5
    looks_like_green_screen = g > r + 18 and g > b + 8

    if not looks_like_green_screen or distance >= SOFT_THRESHOLD:
        return 255
    if distance <= HARD_THRESHOLD:
        return 0

    t = (distance - HARD_THRESHOLD) / (SOFT_THRESHOLD - HARD_THRESHOLD)
    return int(round(255 * t))


def remove_green_screen(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _a = pixels[x, y]
            pixels[x, y] = (r, g, b, keyed_alpha(r, g, b))
    return rgba


def write_preview(frames: list[Image.Image], frame_size: tuple[int, int]) -> None:
    frame_width, frame_height = frame_size
    preview = Image.new("RGBA", (frame_width * COLS, frame_height * ROWS), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        x = (index % COLS) * frame_width
        y = (index // COLS) * frame_height
        preview.alpha_composite(frame, (x, y))
    preview.save(OUTPUT_DIR / "shield_attack_preview.png")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGB")
    frame_width = source.width // COLS
    frame_height = source.height // ROWS

    if source.width % COLS != 0 or source.height % ROWS != 0:
        raise ValueError(f"{SOURCE.name} size {source.size} is not divisible by {COLS}x{ROWS}")

    frames = []
    for index in range(COLS * ROWS):
        col = index % COLS
        row = index // COLS
        cell = source.crop((col * frame_width, row * frame_height, (col + 1) * frame_width, (row + 1) * frame_height))
        frame = remove_green_screen(cell)
        frame.save(OUTPUT_DIR / f"shield_attack_{index:02d}.png")
        frames.append(frame)

    write_preview(frames, (frame_width, frame_height))


if __name__ == "__main__":
    main()
