from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "raw" / "Enemy" / "5 Mummy"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "Enemy" / "Mummy_aligned"
TARGET_DIR = ROOT / "assets" / "sprites" / "Enemy" / "Mummy"
CANVAS_SIZE = (72, 48)
ANCHOR = (36, 48)

SPECS = (
    ("idle", "Mummy_idle.png", 4),
    ("walk", "Mummy_walk.png", 6),
    ("attack", "Mummy_attack.png", 6),
    ("hurt", "Mummy_hurt.png", 2),
    ("death", "Mummy_death.png", 6),
)


def frame_bbox(frame: Image.Image) -> tuple[int, int, int, int]:
    bbox = frame.getbbox()
    if bbox is None:
        raise ValueError("empty transparent frame")
    return bbox


def estimate_foot_x(frame: Image.Image) -> float:
    bbox = frame_bbox(frame)
    alpha = frame.getchannel("A")
    content_height = bbox[3] - bbox[1]
    band_height = max(8, content_height // 3)
    band_top = max(bbox[1], bbox[3] - band_height)
    band = alpha.crop((bbox[0], band_top, bbox[2], bbox[3]))
    band_bbox = band.getbbox()
    if band_bbox is None:
        return (bbox[0] + bbox[2] - 1) / 2.0
    return bbox[0] + (band_bbox[0] + band_bbox[2] - 1) / 2.0


def stable_anchor_x(foot_x_values: list[float]) -> float:
    ordered = sorted(foot_x_values)
    midpoint = len(ordered) // 2
    if len(ordered) % 2 == 1:
        return ordered[midpoint]
    return (ordered[midpoint - 1] + ordered[midpoint]) / 2.0


def aligned_frame(frame: Image.Image, source_anchor_x: float) -> Image.Image:
    bbox = frame_bbox(frame)
    content = frame.crop(bbox)
    content_height = bbox[3] - bbox[1]
    x = round(ANCHOR[0] - (source_anchor_x - bbox[0]))
    y = ANCHOR[1] - content_height

    aligned = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    aligned.alpha_composite(content, (x, y))
    return aligned


def process_sheet(anim_name: str, sheet_name: str, frame_count: int) -> None:
    sheet_path = SOURCE_DIR / sheet_name
    sheet = Image.open(sheet_path).convert("RGBA")
    frame_width = sheet.width // frame_count
    frame_height = sheet.height

    if sheet.width % frame_count != 0:
        raise ValueError(f"{sheet_name} width {sheet.width} is not divisible by {frame_count}")

    source_frames = [
        sheet.crop((index * frame_width, 0, (index + 1) * frame_width, frame_height))
        for index in range(frame_count)
    ]
    anchor_x = stable_anchor_x([estimate_foot_x(frame) for frame in source_frames])

    for index in range(frame_count):
        frame = source_frames[index]
        aligned = aligned_frame(frame, anchor_x)

        filename = f"{anim_name}_{index:02d}.png"
        aligned_path = OUTPUT_DIR / filename
        target_path = TARGET_DIR / filename
        aligned.save(aligned_path)
        aligned.save(target_path)


def write_preview() -> None:
    rows = []
    for anim_name, _sheet_name, frame_count in SPECS:
        row = Image.new("RGBA", (CANVAS_SIZE[0] * frame_count, CANVAS_SIZE[1]), (0, 0, 0, 0))
        for index in range(frame_count):
            frame = Image.open(OUTPUT_DIR / f"{anim_name}_{index:02d}.png").convert("RGBA")
            row.alpha_composite(frame, (index * CANVAS_SIZE[0], 0))
        rows.append(row)

    preview = Image.new("RGBA", (CANVAS_SIZE[0] * 6, CANVAS_SIZE[1] * len(rows)), (0, 0, 0, 0))
    for row_index, row in enumerate(rows):
        preview.alpha_composite(row, (0, row_index * CANVAS_SIZE[1]))
    preview.save(OUTPUT_DIR / "mummy_aligned_preview.png")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    TARGET_DIR.mkdir(parents=True, exist_ok=True)

    for spec in SPECS:
        process_sheet(*spec)
    write_preview()


if __name__ == "__main__":
    main()
