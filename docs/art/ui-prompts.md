# UI asset generation record

Generated with the built-in `image_gen` tool on 2026-09-06. Each source artwork was generated in a separate call. Original files are preserved.

## Deliverables

| Asset | Dimensions | Background |
|---|---|---|
| `assets/sprites/logo.png` | 1040 × 400 | Genuine alpha transparency |
| `assets/sprites/bg.png` | 1920 × 1080 | Opaque dark navy |
| `assets/store/library_logo.png` | 1280 × 720 | Genuine alpha transparency |

The UI logo and library logo use the same generated artwork, scaled proportionally and centered in the requested canvases. The background uses proportional cover scaling. Packaging uses `tools/art_ui_package.ps1` and Windows System.Drawing; it does not redraw or replace generated art. Existing destination files are never overwritten by that script.

## Logo source and exact prompt

Source: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-57bd973d-d045-4ba4-ab9b-00a9fef2a87c.png`

Original dimensions: 2030 × 775, 32-bit RGBA. The generated wordmark was visually checked for the exact Korean text “소코반” and the small crate icon.

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.

Use case: logo-brand.
Asset type: Korean Sokoban game's UI title logo, PNG with genuine transparent background.
The style statement above defines the shared visual style; for this logo only, override its no-text and square-size clauses with the exact lettering and wide canvas requirements below.
Primary request: Game logo text "소코반" (Korean) in bold rounded amber #F5B84B letters with a small wooden crate icon, transparent background, no other text.
Text (verbatim): "소코반" — exactly three Hangul syllables in that order: 소 / 코 / 반.
Composition: wide horizontal wordmark, intended final size 1040x400. Center the complete wordmark as one compact group. Put a small, simple warm brown wooden crate with diagonal crossed planks beside the lettering. Keep the icon smaller than the lettering. Keep useful transparent margins on every side.
Typography: very legible, cheerful, thick rounded Korean display lettering in amber with a restrained darker warm rim and gentle cel-shaded depth. All three syllables on one horizontal line.
Constraints: real alpha transparency outside the logo. Do not draw a white or checkerboard background. No English, no subtitle, no extraneous symbols, no watermark. Do not draw UI controls or a game board.
```

## Background source and exact prompt

Source: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-28a0fde4-9811-4c17-ad22-d304e4c3ed5b.png`

Original dimensions: 1672 × 941. The generated background was visually checked for low-contrast warehouse silhouettes, dark vignette and a readable, quiet center.

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.

Use case: stylized-concept.
Asset type: full screen background for a Sokoban puzzle game UI.
The shared style statement defines the visual style; override its tile and square format clauses for this wide background.
Primary request: Dark navy #1B1F2A background with a very subtle warehouse silhouette and soft vignette, low contrast so white text stays readable, no text.
Composition/framing: 16:9 landscape, intended final resolution 1920x1080. Sparse, flat 2D warehouse interior silhouettes suggested along outer edges: storage shelving and crates in closely related navy tones. Keep center 60% mostly empty and uniformly dark for a large game board and text overlay. Depth should remain shallow and unobtrusive. Soft vignette gently darkens corners.
Palette and contrast: predominantly dark navy #1B1F2A; silhouettes are only slightly lighter/darker blue navy. Extremely restrained, quiet, low contrast. No bright light source. No large amber object.
Constraints: opaque full-bleed background. No words, no lettering, no logo, no characters, no UI, no grid lines, no watermark.
```

## Small capsule

Output: `assets/store/capsule_small.png`, 231 × 87, opaque dark navy. Generated individually with the UI logo reference and then proportionally resized to its final size.

Source: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-0dddb3ca-2dea-4a47-9f3d-c2fb06ce0423.png`

Reference: `assets/sprites/logo.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.

Use case: ads-marketing.
Asset type: small Steam capsule for a Korean Sokoban game.
Input image 1 is the exact approved game logo; preserve its exact Korean lettering, rounded amber shapes, depth and crate icon.
The shared style statement gives the visual language; override no-text and square format clauses for this logo capsule.
Primary request: the reference logo on a solid dark navy #1B1F2A backdrop, logo only, no other art.
Composition: horizontal 231:87 aspect ratio, intended final output 231x87 pixels. Scale the complete reference wordmark and small crate icon as a group to fill the canvas prominently while maintaining a safe margin around the entire group. Maximize clear readability at a tiny store thumbnail size. Keep all three Korean syllables on one line.
Text (verbatim): "소코반". Render no other text.
Constraints: opaque dark navy background edge to edge, no scenery, no characters, no UI, no extra symbols, no watermark, no English words. Preserve reference identity and exact letter shapes.
```

## Vertical capsule

Output: `assets/store/capsule_vertical.png`, 374 × 448, opaque. Generated individually with approved logo and worker references, then proportionally resized to its final size.

Source: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-1f4965c6-789a-4836-bafd-3ce9e5b4eec7.png`

References:
- `assets/sprites/logo.png`
- `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-90872fa8-829d-4007-8a3a-b429c3e78fce.png` (worker identity)

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.

Use case: ads-marketing.
Asset type: vertical store capsule for Korean Sokoban puzzle game.
The style statement above defines the visual language; override its no-text and square-size clauses with the vertical capsule requirements below.
Input image 1: approved logo reference, preserve the exact Korean lettering "소코반", amber rounded glyphs and small crate icon.
Input image 2: approved worker identity reference, preserve the friendly round face, brown hair, amber cap, bright sky blue work suit, navy shoes with amber details. Pose can change naturally.
Primary request: a polished vertical 374:448 game-store capsule with the approved "소코반" logo prominently across the top and a representative warehouse box-pushing puzzle scene below.
Composition: keep complete logo within the top quarter, readable and unobstructed. Below, show a clean, visually comprehensible elevated overhead 2D puzzle area: muted blue-gray warehouse floor, slate blue-gray low walls forming simple pathways, warm brown crates with diagonal X-brace planks, and glowing amber target rings. In the central lower area, the same cute small worker is in the action of pushing one crate toward an open glowing amber ring. Only one worker. Surrounding warehouse shelving can be hinted in dark navy at the edges. Strong clear silhouettes; plenty of room around the logo and focal action.
Color palette: amber #F5B84B, dark navy #1B1F2A, blue-gray floor #3A4052, wall #6B7390, wooden crate #B8763A, sky blue outfit #4FC3F7.
Style: cohesive polished flat 2D game illustration, crisp contours, soft cel shading, warm accents. No photorealism.
Text (verbatim): "소코반". No other text.
Constraints: opaque full-bleed vertical composition. No UI controls, no score, no badges, no platform brand, no watermark. Keep all logo lettering and worker within safe margins; no cropped letters or body.
```

