# 카피바라 뒷모습 / 위 방향 제작 기록

2026-09-07 내장 image_gen으로 정면 기준 카피바라를 위 방향으로 회전한 모습을 만들었습니다. 앞서 남아 있던 그림체가 다른 방향 파일을 교체했습니다.

최종 파일: `assets/sprites/player_up.png`, 256×256 RGBA. `tools/package_sprite.ps1`로 알파 16 초과 영역 최대 길이를 215px로 맞춰 중앙에 배치했습니다.

참조 원본: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-b4cbeee9-e1a2-4630-ae4e-20bb50f97dff.png`

## 방향 생성

디자인 원본(체크 배경, 최종에 직접 사용하지 않음): `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-17c1fb13-c5ef-4658-8a9f-56634b873ff2.png`

```text
Clean 2D top-down game tile, flat vector illustration with soft cel shading,
warm color palette (amber #F5B84B accent, dark navy #1B1F2A background),
crisp outlines, no text, no watermark, centered, square 256x256 pixels.
Use case: identity-preserve.
Asset: player_up.png, single transparent Sokoban directional sprite.
Input image is the exact capybara character and rendering reference. Turn this SAME animal around 180 degrees to face UP, toward the top of canvas, away from the viewer. The camera remains slightly overhead as in the reference, now looking at the animal's back and rump. Its small round ears and rear of head are at the far/top end; its large barrel-shaped back occupies the middle, rounded rump toward the lower edge. Four short natural animal legs support the barrel body, no upright human-like pose. No face, nose or eyes visible from this rear view. No visible tail at all, no round tail mark.
Preserve the reference's exact warm caramel-tan fur palette, broad clean color planes, soft high quality cel shading, amber upper-left highlights, dark brown crisp outlines, subtle sparse fur accents, short dark toes and chubby natural quadruped anatomy. Same apparent size, same peaceful neutral standing pose. The rear-view animal must convincingly be this exact capybara rotated in place; don't simplify into geometric circles or doodles, don't add a crown or accessories.
One centered full-body animal with maximum visible dimension about84% of canvas and at least8% clear margins. Actual RGBA PNG transparency outside the animal and between feet. No floor, scenery, background, checkerboard, lettering, border, clothes, cap, props, hands or bipedal posture. One capybara facing UP only, not a spritesheet.
```

## 실제 알파 배경 편집

최종 원본: `C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-6b876b1f-3efc-4d68-9797-7e70c1596e64.png`

```text
Remove background. Transparent PNG cutout of the exact rear-facing capybara in the input image. Erase the entire gray-white checked surface outside the animal, leaving empty transparent alpha instead. Keep the capybara artwork identical: same upward direction, back and rump, ears, caramel fur, four feet, outlines and shading. Only the animal should remain. Genuine transparent background.
```

