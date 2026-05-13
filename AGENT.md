# Prototype Alpha Agent Notes

This project is a Godot 2D pixel-art ARPG prototype in a demo stage. The goal is a small playable combat demo, not a complete game.

## Current Goal

Build a short, readable, satisfying ARPG loop:

```text
move -> attack -> hit feedback -> defeat enemies -> gain power -> keep fighting
```

The current priority is combat feel.

## Development Priorities

Prefer:

- playable changes
- responsive controls
- stable animation
- readable combat
- satisfying hit feedback
- enemy pressure
- simple short-term growth
- fast iteration

Avoid unless explicitly requested:

- full inventory systems
- large loot frameworks
- procedural generation
- multiplayer
- complex UI frameworks
- save/load architecture
- ECS migration
- broad refactors

When uncertain, choose the smaller implementation that can be tested in-game quickly.

## Godot Code Style

Keep prototype code simple and local. Use clear constants for timing, speed, damage, range, cooldown, and animation tuning.

Avoid unnecessary managers, singletons, framework layers, and speculative abstractions.

## Sprite And Animation Rules

Prefer regular transparent sprite sheets with:

- consistent frame size
- stable character position
- feet aligned
- same scale and camera angle
- readable silhouettes

For Godot animation resources, prefer `SpriteFrames` and `AtlasTexture` over manual frame cutting when the sheet is regular. Use `AtlasTexture.margin` to add transparent padding when the character body is the right size but the frame canvas is too small.

Do not fix padding or baseline problems by changing the node scale unless the character body itself is truly the wrong size.

## Combat Tuning Rules

Align hit detection with visible hit frames. If a key attack frame is too fast, increase that frame duration or repeat it instead of moving hit detection earlier.

Keep action lock duration aligned with the animation duration so idle or movement animations do not interrupt attacks.
