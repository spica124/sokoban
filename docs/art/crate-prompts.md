# Crate generation prompts

Generated 2026-09-06 using the built-in image_gen tool. One output per asset, with a reference edit for the goal variant. Originals are preserved in Codex generated_images. tools/package_art.ps1 resamples each full source with identical 5 px output padding into 256×256 RGBA PNG, yielding approximately 6% visible margins.

## box.png

Original: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-18817f08-b658-4704-9b3b-c4503bd7edb1.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
A wooden crate seen from above, warm brown #B8763A with darker edges and a diagonal cross of planks, small drop shadow, transparent background, occupying about 88% of the tile.
Use case: stylized-concept. Asset type: production Sokoban single sprite box.png. Orthographic camera straight down onto one SQUARE crate lid; its sides parallel to canvas edges, not isometric or rotated. Bold simplified sturdy dark-brown frame and two crossing wooden battens with minimal wood grain, discreet metal nail heads. Subject and restrained shadow fit within x=6%..94%, y=6%..94% canvas (roughly 6% genuinely transparent margin on every side). Actual alpha channel outside isolated crate, no background, no floor, no checkerboard, no lettering, no glow. Crisp readable silhouette at 40-pixel game size. Output one single PNG only.
```

## box_on_goal.png

Original: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-d3dfdb17-6621-46c5-8d91-ed1b030555d7.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
The same wooden crate as before but glowing golden amber #D9A441 with a subtle light rim, transparent background, same size and position as the normal crate.
Use case: precise-object-edit. Input image 1 is edit target, the normal box sprite. Change ONLY the wood color to distinct luminous golden amber, dark edges to warm gold-brown, and add a restrained warm light rim inside the existing footprint. Preserve square crate geometry, EXACT size, position, cross-plank arrangement, nail locations, wood shapes, silhouette, drop shadow and camera from input. No new ornaments or objects. All outside pixels remain genuinely transparent alpha. No floor/background/checkerboard. At small game scale the golden completed crate must be clearly distinct from the brown original. Single PNG output.
```

