# 농장 호박 에셋 생성 기록

2026-09-07 · 내장 `image_gen`으로 생성/투명 배경 편집. `ASSETS.md` 최신 농장 명세. 모든 호출에 `assets/sprites/player.png` 참조. 최종 포장은 `tools/package_sprite.ps1`의 크기·중앙 배치만 사용.

## 일반 호박 디자인

원본: C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-bfd9677a-4b44-40ea-bc42-f58167376d50.png

```text
Cozy farm-pantry puzzle game art, clean 2D vector cartoon with soft cel shading,
thick dark-brown outlines (#2A1608) like the reference capybara, warm palette:
straw yellow #E8C46A, wood brown #A86E40, pumpkin orange #E8983F, leaf green #6FA05A,
cream #F6E7C9, deep brown #3B2314. Top-down view for tiles, no text, no watermark,
centered, transparent background unless the item says "fully filling the tile".

Create ONE standalone game object sprite, NOT a scene: a big round harvest pumpkin the reference capybara can push. Pumpkin orange #E8983F, short bent leafy green stem with one simple green leaf, thick dark-brown clean outline, broad readable pumpkin ribs and simple two-tone cel shading. Directly top-down with a little front thickness, compact round shape. Match the capybara reference illustration style and line weight exactly, but DO NOT include the animal. Pumpkin is centered, same visual density, with about 6% blank padding around its silhouette (88% of tile occupied). Tiny soft cast shadow directly underneath only, not a floor. Actual RGBA transparent background outside pumpkin, no checkerboard drawn into pixels, no opaque backdrop. Square 256x256 game asset.
```

## 일반 호박 실제 알파 편집 (최종)

원본: C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-bca33e0b-3ff7-4d7e-9868-b1f00c265f3f.png

```text
Cozy farm-pantry puzzle game art, clean 2D vector cartoon with soft cel shading,
thick dark-brown outlines (#2A1608) like the reference capybara, warm palette:
straw yellow #E8C46A, wood brown #A86E40, pumpkin orange #E8983F, leaf green #6FA05A,
cream #F6E7C9, deep brown #3B2314. Top-down view for tiles, no text, no watermark,
centered, transparent background unless the item says "fully filling the tile".

Remove the entire gray-white checkered background from this single pumpkin sprite. Keep this exact pumpkin unchanged, with the same stem, leaf, colors, dark contour and orientation. Only a transparent pumpkin cutout remains. Genuine RGBA transparency around the pumpkin, empty transparent corners. Do not draw checkerboard or any backdrop. The capybara reference only defines illustration style and must not appear.
```

## 목표 상태 디자인

원본: C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-ef9c0ac8-1c23-45e7-8509-1c17d7527f03.png

```text
Cozy farm-pantry puzzle game art, clean 2D vector cartoon with soft cel shading,
thick dark-brown outlines (#2A1608) like the reference capybara, warm palette:
straw yellow #E8C46A, wood brown #A86E40, pumpkin orange #E8983F, leaf green #6FA05A,
cream #F6E7C9, deep brown #3B2314. Top-down view for tiles, no text, no watermark,
centered, transparent background unless the item says "fully filling the tile".

Edit the pumpkin reference to make its SUCCESS / ON-GOAL state for a Sokoban game. Keep EXACTLY the same single round pumpkin shape, rib positions, stem and leaf, same orientation, scale and center. Slightly brighter warm orange pumpkin, a very soft golden glow hugging the contour, and ONE tiny cream-gold four-point sparkle at upper right inside the tile. It must remain clearly orange. No mat, basket, floor, text, character or extra object. Genuine transparent PNG outside the pumpkin and the small glow/sparkle. No painted checkerboard, no opaque backdrop. The capybara image is only illustration style reference; do not include the animal. Square sprite, visually identical footprint to original.
```

## 목표 상태 실제 알파 편집 (최종)

원본: C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-fffde378-426e-4286-91ee-34b277cfb8eb.png

```text
Cozy farm-pantry puzzle game art, clean 2D vector cartoon with soft cel shading,
thick dark-brown outlines (#2A1608) like the reference capybara, warm palette:
straw yellow #E8C46A, wood brown #A86E40, pumpkin orange #E8983F, leaf green #6FA05A,
cream #F6E7C9, deep brown #3B2314. Top-down view for tiles, no text, no watermark,
centered, transparent background unless the item says "fully filling the tile".

Remove the gray-white checkered background. Transparent PNG cutout of the exact glowing pumpkin in the first image. Keep pumpkin, green stem, leaf, golden contour glow and tiny star completely unchanged. Empty genuine transparent alpha outside the object. Only this pumpkin remains; no background surface or checkerboard pixels. Capybara reference for style only.
```

최종 파일: `assets/sprites/box.png` 256×256 RGBA, 최대 윤곽 225px(약 88%). `box_on_goal.png` 256×256 RGBA, 외곽 발광 포함 최대 231px. 호박의 둥근 실루엣과 중앙 배치를 유지하고, 발광 여유를 더했습니다. 초기 생성물의 체크 배경은 납품하지 않고, image_gen 알파 편집본을 사용했습니다.

