# 카피바라 창고 — 에셋 적용 결과

2026-09-07 최신 ASSETS.md의 농장 창고 명세로 갱신했습니다. 기존 정면 카피바라를 그림체 기준으로 삼았습니다. 일러스트 생성·투명 배경 편집은 내장 image_gen, 크기·중앙 배치 포장은 System.Drawing을 사용했습니다.

최종 묶음: sokoban_assets_farm_v2_20260907.zip. 파일별 크기·알파 표본·SHA256은 docs/art/manifest.json에 있습니다.

## 게임 에셋

| 위치 / 파일 | 크기 | 내용 |
|---|---|---|
| assets/sprites/floor.png | 256×256 | 저대비 나무 판자 바닥, 불투명 |
| assets/sprites/wall.png | 256×256 | 큼직하고 밝은 나무판자 벽, 불투명 |
| assets/sprites/goal_tile.png | 256×256 | 같은 바닥 위 크림색 둥근 사각 테두리, 바구니·짚자리 없는 빈 중앙 |
| assets/sprites/box.png | 256×256 | 호박, 투명·약 6% 여백 |
| assets/sprites/box_on_goal.png | 256×256 | 같은 호박의 발광·반짝임 상태 |
| assets/sprites/player.png, player_down.png | 256×256 | 기준 카피바라 정면, 두 파일 동일 |
| assets/sprites/player_up.png, player_left.png, player_right.png | 256×256 | 같은 카피바라의 뒤·왼쪽·오른쪽, 실제 생성 그림 |
| assets/sprites/bg.png | 1920×1080 | 등불이 켜진 농장 창고, 문자·캐릭터 없음 |
| assets/sprites/logo.png | 1040×400 | 투명 한글 로고 “카피바라 창고” |
| assets/ui/panel.png | 96×96 | 크림색 면·나무와 밧줄 테두리 |
| assets/ui/button.png, button_hover.png, button_pressed.png, button_disabled.png | 96×96 | 어두운 나무 버튼의 기본·포커스·누름·비활성 상태 |
| assets/icon.png | 512×512 | 게임·안드로이드 런처에 연결한 카피바라 얼굴 |

UI 5종은 모서리 28px의 9분할 이미지입니다. 기존 선택용 assets/sprites/goal.png도 보존합니다. 게임은 새 goal_tile.png를 우선 사용하므로 기존 링은 화면에 표시되지 않습니다.

## 상점 에셋

| assets/store/ 파일 | 크기 | 내용 |
|---|---|---|
| capsule_header.png | 460×215 | 새 로고와 호박을 미는 카피바라 |
| capsule_small.png | 231×87 | 로고 중심 |
| capsule_main.png | 616×353 | 농장 창고·호박·카피바라·로고 |
| capsule_vertical.png | 374×448 | 카피바라 클로즈업과 로고 |
| library_hero.png | 3840×1240 | 문자 없는 창고와 카피바라 풍경 |
| library_logo.png | 1280×720 | 투명 로고 |
| icon.png | 512×512 | 카피바라 얼굴, assets/icon.png와 동일 |
| screenshots/stage1.png, stage9.png, stage24.png | 1920×1080 | 어려움 난이도 1·9·24판의 실제 게임 캡처 |

assets/store/는 게임 내보내기에서 제외되며, 실행용 아이콘은 assets/icon.png를 사용합니다.

## 코드 적용

- Global.gd: 제목 “카피바라 창고” / “Capybara Pantry”, 창 제목도 언어에 맞춰 표시합니다. 저장 경로 식별자 Sokoban은 유지합니다.
- UITheme.gd, UIKit.gd, SettingsPanel.gd, Game.gd: 크림 패널의 안내·설정·일시정지·클리어 문구는 진한 갈색, 나무 버튼 문구는 밝은 크림색으로 조정했습니다.
- 버튼 높이는 60px로 조정해 28px 모서리가 겹치지 않게 했습니다.
- project.godot, export_presets.cfg: 새 아이콘과 안드로이드 런처 경로를 연결했습니다.

## 검증·재현

tools/verify_farm_art.ps1 -Build: Godot 임포트, 실제 화면 캡처, PNG 규격 검사, Windows 실행 파일·Android 디버그 APK 내보내기. 캡처는 진행도를 저장하지 않으며 전후 save.json 해시를 비교합니다.

메뉴·설정·일시정지·튜토리얼·클리어 캡처는 docs/screenshots/, 실행 기록은 docs/art/qa-farm-*.log에 있습니다.

- tools/check_art.ps1: 29개 PNG 규격·투명 모서리·불투명 배경·정면/아래 동일성 검사.
- tools/bundle_art.ps1: ZIP 안의 모든 PNG SHA256 검증.
- Windows: build/Sokoban.exe.
- Android: build/Sokoban.apk (디버그 서명, 테스트용).

## 실제 생성 프롬프트

- docs/art/farm-environment-prompts.md: 바닥·배경 및 이전 벽·짚자리 기록.
- docs/art/simple-wall-prompts.md, simple-goal-prompts.md: 단순한 나무판자 벽·도착 표식으로 교체한 최신 프롬프트.
- docs/art/farm-pumpkin-prompts.md: 일반/도착 호박과 알파 편집.
- docs/art/farm-ui-prompts.md: UI 5종.
- docs/art/farm-brand-store-prompts.md: 새 로고·상점 7종.
- docs/art/capybara-player-front-prompts.md: 현재 정면 기준.
- docs/art/capybara-player-up-prompts.md, capybara-player-directions-prompts.md: 현재 세 방향.

이전 캐릭터·창고 스타일은 이전 ZIP과 프롬프트 기록에 보존했습니다. 생성 원본은 각 기록에 적힌 Codex generated_images 절대 경로에 남아 있습니다.


## 최종 확인 결과 (2026-09-07)

29개 PNG 검사 통과. Godot 4.7.1 임포트·메뉴·어려움 1/9/24판·네 방향·설정·일시정지·튜토리얼·클리어 UI 캡처에 런타임 오류가 없었습니다. 패널·버튼·문구 잘림 없이 육안 검수를 통과했고, 검증 전후 저장 파일 해시도 동일했습니다. Windows 릴리스·Android 디버그 빌드 성공 및 내보낸 Windows EXE의 시작/종료(exit 0)를 확인했습니다. Android는 빌드 완료이며 실기기 설치 테스트는 수행하지 않았습니다.

build/Sokoban.zip도 최신 실행 파일로 갱신합니다. 아이콘은 런처용 크림색 불투명 배경이며, library_hero는 생성 원본을 3840×1240에 맞춰 확대·크롭했습니다.

## 벽·도착 지점 단순화 (2026-09-07 후속 요청)

사용자가 승인한 방향에 따라 wall.png를 큼직한 밝은 세로 나무판자로, goal_tile.png를 바구니와 짚자리 없이 나무 바닥 위 크림색 사각 테두리로 변경했습니다. 두 파일 모두 256×256 불투명 PNG이며 내장 image_gen으로 각각 제작했습니다. 실제 프롬프트는 simple-wall-prompts.md와 simple-goal-prompts.md에 기록했습니다.

변경 전 manifest와 비교해 PNG 변경은 두 타일과 실제 게임 스크린샷 3장뿐임을 확인했습니다. 나머지 24개 PNG는 동일합니다. 새 타일을 적용한 화면과 29개 파일 검사가 통과했고 Windows·Android 빌드를 다시 완료했습니다. 최신 에셋 ZIP은 sokoban_assets_farm_v2_20260907.zip이며 이전 ZIP은 보존합니다.

## 모바일 추가 에셋 (2026-09-18)

UI 아이콘8종, 카피바라 표정2종, 효과3종을 지정 경로에 추가했습니다. 13개 모두 크기·RGBA·투명 모서리·여백 검사를 통과했습니다. 후속 요청으로 게임 연결과 Game Feel 개선도 완료했습니다. 상세 내용은 GAME_FEEL.md, 에셋 목록은 MOBILE_ASSETS.md, 이미지 미리보기는 docs/art/mobile-preview.html을 참고하세요. 이전 에셋 ZIP은 제작 시점의 보관본으로 유지합니다.
