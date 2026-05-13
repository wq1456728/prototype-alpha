from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "raw" / "Knight"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "Knight"
FRAME_SIZE = (96, 84)

ANIMATIONS = {
    "ATTACK 1.png": "attack_1",
    "ATTACK 2.png": "attack_2",
    "ATTACK 3.png": "attack_3",
    "DEATH.png": "death",
    "DEFEND.png": "defend",
    "HURT.png": "hurt",
    "IDLE.png": "idle",
    "JUMP.png": "jump",
    "RUN.png": "run",
    "WALK.png": "walk",
}


def slice_sheet(source_path: Path, target_dir: Path, anim_name: str) -> int:
    sheet = Image.open(source_path).convert("RGBA")
    frame_width, frame_height = FRAME_SIZE

    if sheet.height != frame_height:
        raise ValueError(f"{source_path} height {sheet.height} does not match {frame_height}")
    if sheet.width % frame_width != 0:
        raise ValueError(f"{source_path} width {sheet.width} is not divisible by {frame_width}")

    frame_count = sheet.width // frame_width
    target_dir.mkdir(parents=True, exist_ok=True)

    for index in range(frame_count):
        left = index * frame_width
        frame = sheet.crop((left, 0, left + frame_width, frame_height))
        frame.save(target_dir / f"{anim_name}_{index:02d}.png")

    return frame_count


def write_preview(variant_dir: Path, counts: dict[str, int]) -> None:
    max_frames = max(counts.values())
    preview = Image.new("RGBA", (FRAME_SIZE[0] * max_frames, FRAME_SIZE[1] * len(counts)), (0, 0, 0, 0))

    for row_index, (anim_name, frame_count) in enumerate(counts.items()):
        for index in range(frame_count):
            frame = Image.open(variant_dir / f"{anim_name}_{index:02d}.png").convert("RGBA")
            preview.alpha_composite(frame, (index * FRAME_SIZE[0], row_index * FRAME_SIZE[1]))

    preview.save(variant_dir / "knight_preview.png")


def process_variant(variant: str) -> None:
    source_variant_dir = SOURCE_DIR / variant
    target_variant_dir = OUTPUT_DIR / variant
    counts = {}

    for sheet_name, anim_name in ANIMATIONS.items():
        counts[anim_name] = slice_sheet(source_variant_dir / sheet_name, target_variant_dir, anim_name)

    write_preview(target_variant_dir, counts)


def main() -> None:
    process_variant("with_outline")
    process_variant("without_outline")


if __name__ == "__main__":
    main()
