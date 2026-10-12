# Capybara player directional sprite generation record

Created 2026-09-07 using the built-in image_gen tool. Final sprites use a natural caramel-brown quadruped capybara, a broad blunt muzzle, small round ears and eyes, four short legs, and no tail or accessories. Each direction is an individual generated image. Left and right were regenerated from the canonical front to match its detailed cel shading, after review found inconsistent placeholder direction files in the sprite folder.

## Canonical sources and final files

Destination: `C:/Users/limji/Desktop/game/sokoban/assets/sprites/`.

| Sprite | Final generated original | Packaged dimensions | Visible content extent | Fully transparent pixels |
|---|---|---|---|---|
| player.png and player_down.png | `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-b4cbeee9-e1a2-4630-ae4e-20bb50f97dff.png` | 256×256 | 172×215 | 36820 |
| player_up.png | `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-6b876b1f-3efc-4d68-9797-7e70c1596e64.png` | 256×256 | 179×215 | 38350 |
| player_left.png | `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-f40aa625-62a8-44e0-927b-05b29b101f8a.png` | 256×256 | 215×171 | 41685 |
| player_right.png | `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-4e80287e-a83b-441d-9980-ffb7153b3c8f.png` | 256×256 | 215×180 | 39983 |

All final images use real RGBA alpha transparency. Left and right final generation outputs already contained real alpha and needed no background extraction. Both were visually inspected at final game-asset size for matching style, direction, anatomy, clear margins, and absence of a baked background.

The back-facing sprite was generated and verified separately; its exact prompts are in [capybara-player-up-prompts.md](capybara-player-up-prompts.md). Front prompts are in [capybara-player-front-prompts.md](capybara-player-front-prompts.md).

## Packaging

`tools/art_player_pack.ps1` now maps all four capybara originals by absolute path. It retains the existing `-DirectionsOnly` option; `-SideDirectionsOnly` packages left and right without changing front/down/up. It was run via `C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe` with `-SideDirectionsOnly`. Source alpha is preserved, visible bounds use alpha > 16 to exclude near-transparent generation specks, the maximum extent is resized to215px, and the image is centered on256×256. System.Drawing is used for deterministic crop/resize only, not for artwork generation or background removal.

## player_left.png — final prompt

Identity reference: canonical transparent front original listed above, viewed before use.

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_left.png, isolated game sprite.
Turn this exact capybara to face LEFT. Match the reference's detailed soft cel-shading, warm light caramel fur, dark brown crisp outlines, rounded barrel body, broad blunt muzzle and friendly small dark eye. The muzzle points left and rump points right. Natural quadruped standing on four short legs, no visible tail. Slightly overhead 2D puzzle game camera, top of back and head visible; entire animal fully within frame. Keep same identity, detail and style; only direction changes.
Transparent background PNG with real alpha channel. Remove any backdrop entirely. No floor, scenery, halo, glow, shadow cloud, accessories or clothes. Center with at least8% clear margin. One animal only.
```

## player_right.png — final prompt

Identity reference: canonical transparent front original listed above, viewed before use.

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_right.png, isolated game sprite.
Turn this exact capybara to face RIGHT. Match the reference's detailed soft cel-shading, warm light caramel fur, dark brown crisp outlines, rounded barrel body, broad blunt muzzle and friendly small dark eye. The muzzle points right and rump points left. Natural quadruped standing on four short legs, no visible tail. Slightly overhead 2D puzzle game camera, top of back and head visible; entire animal fully within frame. Keep same identity, detail and style; only direction changes.
Transparent background PNG with real alpha channel. Remove any backdrop entirely. No floor, scenery, halo, glow, shadow cloud, accessories or clothes. Center with at least8% clear margin. One animal only.
```

## Earlier drafts (not packaged)

Earlier direction drafts from an opaque design reference and an interrupted extraction pass are retained in the generated-images folder but are not current assets: `exec-187a01b2-3300-440b-88ab-e586c8cb084a.png`, `exec-949bbfd9-5a67-4316-8d09-5e1e0fb67f75.png`, `exec-2c1560c1-e645-4ab2-a4e4-13821d6dec82.png`, `exec-b9895aa4-b342-4cf7-bd1f-a278eff24719.png`, and `exec-dd68817d-23ad-4dc2-a32c-efd83389c4ab.png`. The last had an unwanted background glow and was rejected.

