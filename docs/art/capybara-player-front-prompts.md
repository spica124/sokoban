# 카피바라 플레이어 정면 제작 기록

2026-09-07 사용자 요청: 여자 캐릭터 대신 카피바라로 변경.

내장 image_gen을 사용해 기존 게임의 명암·윤곽선 스타일을 유지한 네발 카피바라를 만들었습니다. 밝은 캐러멜색 몸, 넓고 뭉툭한 주둥이, 작은 둥근 귀와 짧은 다리로 구성되며 사람의 옷이나 액세서리는 없습니다.

최종 파일: `assets/sprites/player.png`, `assets/sprites/player_down.png` (동일한 256×256 RGBA PNG).

최종 원본: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-b4cbeee9-e1a2-4630-ae4e-20bb50f97dff.png` (1312×1199, 실제 알파).

`tools/package_sprite.ps1`로 알파 16 초과 영역의 최대 길이를 215px로 맞추고 투명 256×256 캔버스 중앙에 배치했습니다. 실제 표시 영역은 172×215px입니다. 원본 알파를 보존했습니다.

## 최초 디자인

입력 스타일 참조: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-ac863e11-f970-4187-9c59-ac8cdc2b65de.png`

디자인 출력: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-4125ddb7-c758-4871-8b4b-967f060bca8c.png` (24bpp 불투명 체크 배경이 있어 최종 파일에는 직접 사용하지 않음).

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: precise-object-edit.
Asset type: player.png, one single Sokoban game player sprite.
Input image is ONLY the existing game's cel-shading/outline finish reference; replace the entire human worker with a cute natural CAPYBARA animal. Preserve the polished simple game illustration style, but keep no human anatomy, clothes or accessories.
Subject: one friendly plump capybara with a warm light-caramel tan-brown coat, large long barrel-shaped body, a large broad blunt rounded-rectangular muzzle, small high-set rounded ears, small widely spaced calm dark eyes, a tiny understated nose and peaceful expression. Four short sturdy legs with small dark toes, no visible tail. It must be unmistakably a capybara rather than a bear, beaver, hamster, dog or pig. Use clean broad flat color planes and soft warm highlights, minimal fur lines, no realistic hair texture. No large black bear nose or buck teeth.
Camera and direction: a classic slightly overhead 2D top-down puzzle-game view, facing DOWN toward the bottom of the canvas and toward the viewer, on all four legs. Show the round top of its back behind the large broad head, front face clearly visible, two forefeet below the head and rear legs subtly visible behind at the sides. Neutral standing pose, friendly chibi animal proportions, still a quadruped, not upright. No tail, no human hands, no cap, no bandana, no clothes, no tools, no props, no scene.
The entire animal is centered and occupies about84% of the square's maximum dimension, leaving 8% clear margin on every side. All body parts and a tiny restrained contact shadow stay within the canvas. The background must be genuinely TRANSPARENT in the PNG alpha channel, including gaps between feet. No navy backdrop, no black background, no white background, no painted checkerboard. Only one complete capybara cutout, no multiple poses, no sprite sheet. Actual transparent RGBA PNG.
```

## 첫 알파 편집 — 미채택

결과: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-461c321b-1d85-412c-8d98-448b0b2692c1.png`. 여전히 24bpp 불투명 배경이므로 사용하지 않았습니다.

```text
Use case: background-extraction. Remove the gray and white checkerboard background entirely from this exact capybara image and make the background actually transparent in the PNG alpha channel. Keep the whole capybara completely unchanged: same warm caramel brown body, broad blunt muzzle, calm face, small round ears, four short legs, same colors, lines, shading, size, position and pose. The only requested edit is actual alpha transparency in all empty areas outside the animal, including the gaps between the feet. Keep a very subtle small contact shadow only. No visible background, no pattern, no replacement color. Output one transparent RGBA PNG capybara cutout.
```

## 최종 알파 편집 — 채택

입력: 최초 디자인. 결과: 위 최종 원본 경로. 바깥 모서리 알파0, 몸통 표본 알파253/255 확인.

```text
Remove background. Transparent PNG cutout of the exact capybara in the input image. Erase the entire gray-white checked surface outside the animal, leaving empty transparent alpha instead. Keep the capybara artwork identical. Only the animal should remain. Genuine transparent background.
```

