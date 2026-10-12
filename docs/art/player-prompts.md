# Player sprite generation record

Created 2026-09-06 using the built-in image_gen tool. Each direction was generated separately. The original downward-facing image was the identity reference for all direction edits. Direction edits with opaque checkerboards were followed by background-extraction edits; only verified real-alpha outputs are packaged.

Final destination: `C:/Users/limji/Desktop/game/sokoban/assets/sprites/`.

Validation: all five final PNGs are 256×256 with real transparency, and have a visible height of 215 px, occupying y=20 through y=234. Transparent-pixel counts: player/player_down 45164; player_up 45632; player_left 50506; player_right 51085. Final images were viewed individually to confirm identity, facing direction, clear margins and no baked checkerboard.

Packaging: `tools/art_player_pack.ps1` (Windows PowerShell 5.1) retains the source PNG alpha, uses the visible alpha extent (alpha > 16) to ignore near-transparent generation specks when framing, scales proportionally to a 215 px maximum extent, and centers on a 256×256 RGBA canvas. player_down.png is byte-identical to player.png. Original generated PNG files are retained at the paths below.

## player.png and player_down.png

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-90872fa8-829d-4007-8a3a-b429c3e78fce.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: stylized-concept.
Asset type: player.png, one single transparent game character sprite for Sokoban.
A cute small warehouse worker character seen from above, facing down/toward the camera, round friendly shape, sky blue #4FC3F7 outfit, transparent background, occupying about 84% of the tile.
Create ONE isolated character only, full body, clearly facing the bottom of the canvas. Rounded amber work cap, sky-blue work clothes, small dark navy shoes, friendly simple face. Use a readable straight-down top-down game view with face visible as in a classic 2D top-down puzzle character, simple chunky forms and soft cel shading, no isometric camera, no scene.
Canvas must have real alpha transparency, not a checkerboard texture, no solid background; the navy palette instruction applies only to outlines/details here. All character and small soft contact shadow stay inside the central 84% of the canvas with an approximately 8% clear margin, centered, feet toward the bottom. No floor, tools, scenery, border, extra characters, lettering, or sprite sheet.
```

## player_up.png direction edit

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-99f7936a-c100-4b0b-8b2c-93968c9b0389.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_up.png, single top-down Sokoban game character directional sprite.
Input image: EDIT TARGET and exact identity/style reference.
Turn this same cute small warehouse worker to face UP, toward the top of the canvas and away from the viewer. Show the BACK of the amber cap and head, the back of the sky blue #4FC3F7 work outfit, and back of the dark navy shoes. No face visible. Match the original character's exact costume, colors, proportions, line weight, rendering style and full body size. Preserve the slightly overhead classic 2D puzzle-game camera angle; only change the facing direction, no walking pose.
Real alpha transparent background, no checkerboard pattern and no solid color backdrop. Keep the whole isolated character centered with approximately 8% clear margin and tiny contained contact shadow. No floor, scenery, tools, text, watermark, extra character or sprite sheet.
```

## player_up.png final alpha extraction

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-d08eee40-06b8-40b6-b232-50d417e7d0a0.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: background-extraction.
Remove the background entirely from the provided character image, making every pixel outside the character fully transparent alpha. Export an actual RGBA PNG cutout. Keep the exact upward-facing warehouse worker unchanged: back of amber cap, brown hair, sky-blue outfit, navy shoes. Preserve its size, position, colors, lines and detail. The only requested edit is actual alpha background transparency. No visible background of any kind.
```

## player_left.png direction edit

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-19a56f59-4250-4392-b670-113fa8d17624.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_left.png, one single isolated character sprite for Sokoban.
Input image: EDIT TARGET and exact identity/style reference.
Turn this same cute small warehouse worker to face LEFT in profile, with cap brim, nose and toes pointing toward the left edge of the canvas. Match the original character's exact costume, colors, proportions, line weight, rendering style and full body size: amber cap, brown hair, sky blue #4FC3F7 work outfit, navy shoes with amber laces, friendly simple face. Preserve the slightly overhead classic 2D puzzle-game camera angle. Change only the facing direction, neutral standing pose.
Export as actual transparent RGBA PNG with alpha zero outside the character. Entire background is transparent. The whole isolated character stays centered, occupying about 84% of the tile height with at least 8% clear margins. No scene, no floor, no tools, no text, no watermark, no extra character, no sprite sheet.
```

## player_left.png first extraction (discarded: opaque background)

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-bfbccf92-0a9e-4c21-b795-4fd2b07427e8.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: background-extraction.
Remove the background entirely from the provided character image, making every pixel outside the character fully transparent alpha. Export an actual RGBA PNG cutout. Keep the exact LEFT-facing warehouse worker unchanged: amber cap, brown hair, sky-blue outfit, navy shoes. Preserve its left-facing profile, size, position, colors, lines and detail. The only requested edit is actual alpha background transparency. No visible background of any kind.
```

## player_left.png final alpha extraction

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-363e1ca2-7bcb-4b00-ae5a-1a3a4b9f2829.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: background-extraction.
Create a transparent-background PNG cutout of the provided exact LEFT-facing character. Erase the visible gray-and-white background completely to alpha transparency. The background must be empty/transparent in the actual PNG alpha channel, including between his limbs. Keep the left-facing warehouse worker identical: amber cap with brim pointing left, brown hair, blue work suit, dark shoes. No visible background, no white, no gray, no pattern, no scene. Real transparency only.
```

## player_right.png direction edit

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-8e0d1971-366e-439b-97f0-fb52f24dc0a9.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_right.png, one single isolated character sprite for Sokoban.
Input image: EDIT TARGET and exact identity/style reference.
Turn this same cute small warehouse worker to face RIGHT in profile, with cap brim, nose and toes pointing toward the right edge of the canvas. Match the original character's exact costume, colors, proportions, line weight, rendering style and full body size: amber cap, brown hair, sky blue #4FC3F7 work outfit, navy shoes with amber laces, friendly simple face. Preserve the slightly overhead classic 2D puzzle-game camera angle. Change only the facing direction, neutral standing pose.
Export as actual transparent RGBA PNG with alpha zero outside the character. Remove the background entirely so no visible background of any kind remains. The whole isolated character stays centered, occupying about 84% of the tile height with at least 8% clear margins. No scene, no floor, no tools, no text, no watermark, no extra character, no sprite sheet.
```

## player_right.png final alpha extraction

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-3154c999-d2c2-4227-9d9f-329e69cb9a77.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: background-extraction.
Remove the background entirely from the provided character image, making every pixel outside the character fully transparent alpha. Export an actual RGBA PNG cutout. Keep the exact RIGHT-facing warehouse worker unchanged: amber cap, brown hair, sky-blue outfit, navy shoes. Preserve its right-facing profile, size, position, colors, lines and detail. The only requested edit is actual alpha background transparency. No visible background of any kind.
```
