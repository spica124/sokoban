# Female player directional sprite generation record

Created 2026-09-06 using the built-in image_gen tool in response to the user's request to change to a female character. Each direction was generated separately, preserving the new front character's amber cap, brown ponytail, sky blue uniform, navy shoes, and rendering style. The intermediate direction outputs had opaque checkerboards and were not used as final files; each was followed by an alpha-background extraction edit.

Design reference for up and left: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-f9be1bd6-13a2-4e2f-a5d1-7ea0ecf8dac1.png`

Final front identity reference for right and canonical player.png packaging source: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-ac863e11-f970-4187-9c59-ac8cdc2b65de.png`

Final destination: `C:/Users/limji/Desktop/game/sokoban/assets/sprites/`.

Validation: player_up.png, player_left.png, and player_right.png are all 256×256 RGBA PNGs. Visible alpha extent is centered with 215 px body height (y=20..234), preserving about 8% top/bottom margin. Fully transparent pixel counts are 46380, 51307, and 50140 respectively. Final files were viewed individually to verify identity, direction, clear margins and no baked checkerboard.

Packaging helper: `tools/art_player_pack.ps1` now maps all four female originals by absolute path. Its `-DirectionsOnly` switch updates only up/left/right. Run with `C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`. The helper preserves source alpha, uses alpha > 16 for framing to ignore near-transparent generation specks, scales proportionally and centers on a 256×256 canvas. No code-drawn artwork or raster background-removal workaround was used.

## player_up.png direction edit

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-ca839f3d-4d89-453e-ae0a-256af76f10df.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_up.png, one single isolated transparent directional sprite for Sokoban.
Input image: exact female worker identity and costume reference.
Show THIS SAME female warehouse worker turned to face UP away from the viewer, so the back of her head/cap and back of her work suit are visible and no face is visible. Keep her amber baseball cap, warm brown hair tied into ONE short shoulder-length ponytail behind the head slightly to her own left (appearing at image left in this rear view), sky-blue #4FC3F7 work suit, dark navy shoes, rounded friendly proportions, identical flat-vector/cel shading and outline weight. Keep the neutral full body standing pose and slightly overhead classic 2D puzzle-game view, feet toward bottom.
Actual transparent RGBA PNG cutout with no visible background; erase all background to transparent alpha. Single character only, no floor, no scene, no pattern, no text, no border, no sprite sheet. Character centered, entire body inside central 84% tile height with about 8% clear margin.
```

## player_up.png final alpha extraction

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-b9809e0d-0274-4f30-ab69-9e8c70d723ff.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: background-extraction.
Create a transparent-background PNG cutout of the provided exact UP-facing female character. Erase the visible gray-and-white background completely to alpha transparency. The background must be empty/transparent in the actual PNG alpha channel, including between her limbs. Keep the rear-view female warehouse worker identical: amber cap, brown ponytail offset left, blue work suit, dark shoes. No visible background, no white, no gray, no pattern, no scene. Real transparency only.
```

## player_left.png direction edit

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-77240979-bce3-4244-836b-e42e309a0228.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_left.png, one single isolated transparent directional sprite for Sokoban.
Input image: exact female worker identity and costume reference.
Show THIS SAME female warehouse worker turned to face LEFT in profile, with nose/cap brim/toes pointing to left edge. Keep her amber baseball cap, warm brown hair tied into ONE short shoulder-length ponytail behind the head (visible toward image right behind head), feminine friendly face with modest eyelashes and brown side locks, sky-blue #4FC3F7 work suit, dark navy shoes with amber laces, rounded friendly proportions, identical flat-vector/cel shading and outline weight. Keep the neutral full body standing pose and slightly overhead classic 2D puzzle-game view.
Actual transparent RGBA PNG cutout with no visible background; erase all background to transparent alpha. Single character only, no floor, no scene, no pattern, no text, no border, no sprite sheet. Character centered, entire body inside central 84% tile height with about 8% clear margin.
```

## player_left.png final alpha extraction

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-f8c868e8-0daa-4256-8e66-336c38949cd6.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: background-extraction.
Create a transparent-background PNG cutout of the provided exact LEFT-facing female character. Erase the visible gray-and-white background completely to alpha transparency. The background must be empty/transparent in the actual PNG alpha channel, including between her limbs and behind her ponytail. Keep the left-facing female warehouse worker identical: amber cap with brim pointing left, brown ponytail, feminine face with side lock and eyelashes, blue work suit, dark shoes. No visible background, no white, no gray, no pattern, no scene. Real transparency only.
```

## player_right.png direction edit

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-49181913-a585-4dc8-b5e9-fea0546e705a.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset type: player_right.png, one single isolated transparent directional sprite for Sokoban.
Input image: exact female worker identity and costume reference.
Show THIS SAME female warehouse worker turned to face RIGHT in profile, with nose/cap brim/toes pointing to right edge. Keep her amber baseball cap, warm brown hair tied into ONE short shoulder-length ponytail behind the head (visible toward image left behind head), feminine friendly face with modest eyelashes and brown side locks, sky-blue #4FC3F7 work suit, dark navy shoes with amber laces, rounded friendly proportions, identical flat-vector/cel shading and outline weight. Keep the neutral full body standing pose and slightly overhead classic 2D puzzle-game view.
Actual transparent RGBA PNG cutout with no visible background; erase all background to transparent alpha. Single character only, no floor, no scene, no pattern, no text, no border, no sprite sheet. Character centered, entire body inside central 84% tile height with about 8% clear margin.
```

## player_right.png final alpha extraction

Original generation path: `C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-f841ccea-6813-4ec3-ad52-7f546a253970.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: background-extraction.
Create a transparent-background PNG cutout of the provided exact RIGHT-facing female character. Erase the visible gray-and-white background completely to alpha transparency. The background must be empty/transparent in the actual PNG alpha channel, including between her limbs and behind her ponytail. Keep the right-facing female warehouse worker identical: amber cap with brim pointing right, brown ponytail, feminine face with side lock and eyelashes, blue work suit, dark shoes. No visible background, no white, no gray, no pattern, no scene. Real transparency only.
```

