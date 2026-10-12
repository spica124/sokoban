# Female worker store capsule update

Date: 2026-09-06. Method: built-in `image_gen`, one targeted edit per capsule. Each high-resolution original and the new female identity reference were visually inspected before editing.

The user requested a female character. These edits preserve each capsule's Korean “소코반” wordmark, composition, objects, palette, and illustration style while replacing the existing worker with the new female identity. The original generated source files remain in place. Existing destination capsule files were overwritten as authorized.

Female identity reference: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-f9be1bd6-13a2-4e2f-a5d1-7ea0ecf8dac1.png`

The reference's checkerboard backdrop is not part of the design; it was explicitly excluded in every edit prompt.

Final dimensions are packaged with `tools/art_ui_female_capsules.ps1` using proportional cover resize. All outputs are opaque PNGs.

## capsule_main.png (616 × 353)

Output: `assets/store/capsule_main.png`

Edit target: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-5ef62534-62ea-4468-a8d5-bff6f718fc22.png`

Edited source: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-19c10bc5-4026-4711-9dc7-0963673a783e.png`

```text
Use case: precise-object-edit.
Asset type: Korean Sokoban main store capsule, final 616x353 PNG.
Input image 1 is the EDIT TARGET: existing finished main capsule.
Input image 2 is ONLY the new female worker IDENTITY REFERENCE. Ignore its checkerboard backdrop completely; do not copy that background.
Change exactly one thing in input image 1: replace the existing small worker near the lower-left wooden crate with the same female worker design shown in image 2.
Female identity requirements: brown side ponytail, softer side-swept bangs and cheek-length side locks, subtle small upper lashes, friendly rounded face, same amber baseball cap, same sky blue work uniform, navy shoes with amber laces. Keep the clean cel-shaded 2D illustration style.
Pose invariants: keep the worker's existing position, scale, overhead angle, pushing gesture, hands contacting the crate, foot positions and friendly expression. Adapt the female hair to this existing pose. The ponytail must be visible but compact.
Everything else is locked: preserve the exact existing Korean logo "소코반", its glyphs, size and position; preserve the little logo crate; preserve all wooden crates, amber target rings, floor tiles, walls, background, decorative sparks, lighting, shadows, palette, composition, crop, camera angle and canvas aspect ratio.
Do not redraw, move, add, remove or reinterpret any non-character element. No additional worker. No new text, no watermark, no border, no transparent area.
Output the complete original capsule with only the worker changed to the reference female identity.
```

## capsule_header.png (460 × 215)

Output: `assets/store/capsule_header.png`

Edit target: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-2bfaf155-da2f-494d-9009-fbd26cb79767.png`

Edited source: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-4d332eaf-9020-406b-8c8f-f56a407501d8.png`

```text
Use case: precise-object-edit.
Asset type: Korean Sokoban header store capsule, final 460x215 PNG.
Input image 1 is the EDIT TARGET: existing finished wide header capsule.
Input image 2 is ONLY the new female worker IDENTITY REFERENCE. Ignore its checkerboard backdrop completely; do not copy that background.
Change exactly one thing in input image 1: replace the existing small worker on the right-hand side, pushing a wooden crate, with the same female worker design shown in image 2.
Female identity requirements: brown side ponytail, softer side-swept bangs and cheek-length side locks, subtle small upper lashes, friendly rounded face, same amber baseball cap, same sky blue work uniform, navy shoes with amber laces. Keep the existing polished cel-shaded 2D illustration style.
Pose invariants: keep the worker's existing location, scale, overhead angle, rightward pushing pose, hands contacting the crate, leg gesture and friendly expression. Adapt the female hair to this existing pose, with a visible but compact ponytail behind her head.
Everything else is locked: preserve the exact existing Korean logo "소코반", its glyphs, size and position; preserve the little logo crate; preserve the gameplay crate, amber target ring, floor tiles, walls, background, decorative sparks, lighting, shadows, palette, composition, crop, camera angle and the same wide canvas aspect ratio.
Do not redraw, move, add, remove or reinterpret any non-character element. No additional worker. No new text, no watermark, no border, no transparent area.
Output the complete original header capsule with only the worker changed to the reference female identity.
```

## capsule_vertical.png (374 × 448)

Output: `assets/store/capsule_vertical.png`

Edit target: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-1f4965c6-789a-4836-bafd-3ce9e5b4eec7.png`

Edited source: `C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-7866410f-14ac-4b11-8607-b12c2affb0ce.png`

```text
Use case: precise-object-edit.
Asset type: Korean Sokoban vertical store capsule, final 374x448 PNG.
Input image 1 is the EDIT TARGET: existing finished vertical capsule.
Input image 2 is ONLY the new female worker IDENTITY REFERENCE. Ignore its checkerboard backdrop completely; do not copy that background.
Change exactly one thing in input image 1: replace the existing worker in the middle of the puzzle scene, pushing the wooden crate rightward, with the same female worker design shown in image 2.
Female identity requirements: brown side ponytail, softer side-swept bangs and cheek-length side locks, subtle small upper lashes, friendly rounded face, same amber baseball cap, same sky blue work uniform, navy shoes with amber laces. Keep the existing polished cel-shaded 2D illustration style.
Pose invariants: keep the worker's exact existing position, scale, overhead angle, rightward pushing pose, hands contacting the same crate, bent leg gesture and friendly expression. Adapt the female hair naturally to this pose, showing a compact ponytail behind the head.
Everything else is locked: preserve the exact existing Korean logo "소코반", its glyphs, size and position; preserve the little logo crate; preserve every wooden crate, all amber goal rings, floor tiles, wall pathways, warehouse shelving, barrels, yellow safety posts, background, lighting, shadows, palette, composition, crop, camera angle and the same vertical canvas aspect ratio.
Do not redraw, move, add, remove or reinterpret any non-character element. No additional worker. No new text, no watermark, no border, no transparent area.
Output the complete original vertical capsule with only the worker changed to the reference female identity.
```


