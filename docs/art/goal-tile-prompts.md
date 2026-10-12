# 도착 지점 타일

사용자 요청: 도착지점 타일을 하나 만들어줘.

최종 파일: `assets/sprites/goal_tile.png` — 256×256 RGBA PNG. 기존 바닥과 목표 링을 참조해 내장 `image_gen`으로 새 도착 패드 디자인을 만들었습니다. 정사각형 슬레이트 패드에 황금 링, 중앙 다이아몬드와 모서리 표식을 배치했습니다. 외부 여백은 투명하며 패드 내부는 거의 불투명합니다(중앙 알파 253/255). 최종 PNG를 열어 크기와 실제 알파, 모서리 투명도를 확인했습니다.

`goal.png`는 기존 원형 목표 표식으로 유지했습니다. 게임에서 이 새 패드를 사용하려면 `goal_tile.png`를 `goal.png`로 교체하면 됩니다. 이 제작 요청에서는 새 PNG 파일만 추가했습니다.

초기 디자인 원본(불투명 배경, 최종 파일에는 사용하지 않음): `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-2e846b14-79ec-4921-b7e8-f26240fe9d9c.png`

## 최종 투명 PNG 원본

`C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-5ff4399d-c0cb-4a20-9d59-9e373266b6a2.png`

배경 정리 프롬프트:

```text
Use case: background-extraction. Remove the black background OUTSIDE the square destination pad in the input image and make that outer area completely transparent in the actual PNG alpha channel. Preserve the pad itself exactly: its dark slate surface must stay opaque, including inside the golden ring, and preserve all golden rim/corner marks and the center diamond unchanged. Keep the same geometry, scale, colors and composition. Only the empty outer background is removed; do not remove any dark slate pixels within the tile. Output an isolated transparent PNG cutout with alpha=0 outside the pad and a clean antialiased edge, no replacement background.
```

크기 변환: `tools/package_art.ps1`, 원본 전체를 256×256으로 리샘플링, 생성 알파 보존. 파일별 검증: `docs/art/goal-tile-manifest.json`.

## 최종 프롬프트

참조 파일: `assets/sprites/floor.png`, `assets/sprites/goal.png`.

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: compositing.
Asset type: goal_tile.png, one destination landing pad tile for a Sokoban warehouse puzzle game.
Input image 1 is the floor material/style reference and edit target. Input image 2 is the existing amber goal ring reference.
Transform the floor into ONE clearly recognizable square crate-delivery destination pad, seen strictly orthographically from straight above. The pad is a single compact slate-blue #3A4052 square plate with slightly clipped/rounded corners and restrained soft beveled edges, occupying about 88% of the whole square canvas. Center a crisp thin luminous amber #F5B84B circular target ring, inspired by input 2, occupying about 48% of the canvas width. Inside the ring show the slate pad surface with only a tiny simple amber diamond at exact center. Add four short clean amber L-shaped corner docking marks at the pad's four corners pointing inward; no extra floating elements. Keep the pad surface mostly smooth and low-contrast with a few subtle broad geometric stone panel seams matching input 1, far less grain than the floor. A very thin amber edge line, understated upper-left highlight and contained contact shadow make the tile stand out from the ordinary floor without looking like a raised wall. Strong simple forms readable when reduced to 40 pixels. Golden glow is restrained and stays inside the 6% clear outer margin. The entire isolated pad is centered, its edges parallel to canvas edges, no rotation, no perspective or isometric visible side faces.
Output actual RGBA PNG: every pixel OUTSIDE the square pad and its narrow shadow is genuinely transparent alpha. The interior of the pad is opaque slate, including inside the target ring. No surrounding floor, no background beyond the pad, no checkerboard painted into the image. No crate, no character, no flag, no lettering, no arrows, no numbers, no multiple tiles, no sprite sheet, no watermark. One finished destination tile.
```
