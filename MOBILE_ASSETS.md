# 모바일 추가 에셋 13종

2026-09-18 요청한 13개 PNG를 지정 경로에 저장했습니다. 내장 image_gen으로 생성했으며 보통 난이도 아이콘은 기존 호박 그림을 재사용했습니다. 실제 투명 알파와 지정 크기, 여백, 별 두 상태의 정렬을 검사했습니다.

**현재 상태: 13종 제작·게임 연결·Windows/Android 빌드 완료.** 후속 요청에 따라 PNG 방향키·별·자물쇠·난이도 아이콘, 충돌/클리어 표정, 먼지·반짝임·낙엽을 실제 화면에 연결했습니다. 상세 변경과 디자인 피드백은 `GAME_FEEL.md`를 참고하세요.

묶음: sokoban_mobile_assets_20260918.zip
미리보기: docs/art/mobile-preview.html (이미지 포함, 단독으로 열 수 있음)

| 파일 | 크기 | 내용 |
|---|---|---|
| assets/ui/arrow.png | 128×128 | 위쪽 나무 화살표 |
| assets/ui/star_on.png | 128×128 | 획득한 금색 별 |
| assets/ui/star_off.png | 128×128 | 크림색·갈색 점선의 빈 별 |
| assets/ui/lock.png | 128×128 | 나무 몸체·쇠고리 자물쇠 |
| assets/sprites/player_happy.png | 256×256 | 눈을 감고 앞발을 든 기쁜 표정 |
| assets/sprites/player_bump.png | 256×256 | 어지러운 눈·작은 땀방울 |
| assets/fx/sparkle.png | 64×64 | 외곽선 없는 네 갈래 금빛 반짝임 |
| assets/fx/dust.png | 64×64 | 부드러운 연갈색 먼지 |
| assets/fx/leaf.png | 48×48 | 주황·노랑 낙엽 한 장 |
| assets/ui/tier_easy.png | 128×128 | 초록 새싹 |
| assets/ui/tier_normal.png | 128×128 | 호박 하나 |
| assets/ui/tier_hard.png | 128×128 | 호박 세 개 |
| assets/ui/tier_expert.png | 128×128 | 작은 왕관을 쓴 호박 |

## 코드 연결 명세 (아래 항목 적용 완료)

- 모든 경로는 프로젝트 기준이며 Godot에서는 앞에 res://를 붙입니다. 기계가 읽을 목록은 docs/art/mobile-manifest.json입니다.
- StageSelect.gd의 _make_card(): 잠긴 카드의 자물쇠 이모지를 lock.png로 대체합니다. 번호와 이미지는 별개로 배치하면 이모지 글꼴에 의존하지 않습니다.
- Game.gd의 _build_dpad(): arrow.png는 위쪽 기준입니다. 중심을 기준으로 0° 위 / 90° 오른쪽 / 180° 아래 / 270° 왼쪽으로 회전합니다. 클릭 영역은 버튼에 유지하고 이미지 자식만 회전하면 됩니다.
- UIKit.stars_text()를 사용하는 결과 창·스테이지 카드: 별 세 칸에 star_on/off를 배치합니다. 두 PNG의 캔버스와 시각적 경계가 맞춰져 있습니다.
- Game.gd: 클리어 시 player_happy, 이동 불가 반응 시 player_bump를 잠시 표시합니다. 일시 표정 종료 때 현재 이동 방향 이미지를 복원합니다. 두 파일은 현재 캐릭터와 같은 256px 캔버스·최대215px 크기입니다.
- DifficultySelect.gd: tier_easy / tier_normal / tier_hard / tier_expert를 카드에 연결합니다.
- Juice.gd의 burst(): 현재는 _dot_tex() / _chip_tex()를 사용하므로 요청 종류에 맞는 FX 텍스처를 선택할 수 있게 연결해야 합니다. 기존16px 점 대신64px 텍스처를 쓰면 같은 표시 크기를 위해 스케일을 약1/4부터 조정합니다. 낙엽도 원래12px 조각 대비48px 캔버스이므로 크기를 함께 조정합니다.
- Assets.gd의 기존 tex()는 assets/sprites/를 읽습니다. assets/ui/ 및 assets/fx/에는 해당 경로를 읽는 로더 또는 직접 Texture2D 로딩을 사용해야 합니다.

## 검증과 생성 기록

- tools/check_mobile_art.ps1: 13개 PNG 전체 픽셀의 알파, 크기, 여백, 별 정렬 검사.
- docs/art/mobile-manifest.json: 크기·용량·알파 수치·SHA256·res:// 경로.
- docs/art/mobile-prompts.md: 실제 생성 프롬프트, 참고 이미지, 원본 경로.
- docs/art/mobile-generation-log.json: 원본·프롬프트·포장 수치의 구조화 기록.
- tools/package_cutout.ps1: Windows PowerShell5.1에서 사용하는 크기·배치 포장 도구. 그림이나 배경을 코드로 생성하지 않습니다.

PNG는 모두 최종 저장 크기로 육안 확인했습니다. ZIP 내부 PNG 해시도 manifest와 비교합니다. Godot 실행 화면, 데스크톱에서 강제한 모바일 배치, 이동/되돌리기/재시작/일시정지/효과 끄기 검사가 통과했습니다. 실제 Android 기기의 터치·진동·성능은 아직 검사하지 않았습니다. 위 ZIP은 이미지 제작 시점의 보관본이며 최신 게임은 build/Sokoban.exe, build/Sokoban.apk입니다.
