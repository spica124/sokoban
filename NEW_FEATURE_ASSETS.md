# 새 기능 에셋 적용 기록 — 2026-10-06

ASSETS.md 13장의 **19개 PNG**를 제작해 프로젝트에 저장했다. 내장 `image_gen`으로 파일별 그림을 생성했으며, 실제 생성된 알파를 보존한 채 크기와 위치만 패키징했다.

## 저장 파일

| 폴더 | 파일 | 규격 |
|---|---|---|
| `assets/sprites/` | `hat_straw`, `hat_mandarin`, `hat_flower`, `hat_leaf`, `hat_chef`, `hat_beanie`, `hat_grad`, `hat_crown` | 각각 256×256 PNG |
| `assets/sprites/` | `box_c1`, `box_on_goal_c1`, `ice`, `oneway` | 각각 256×256 PNG |
| `assets/ui/` | `rule_color`, `rule_ice`, `rule_oneway`, `rule_mix`, `daily`, `trophy`, `hanger` | 각각 128×128 PNG |

- 모자: 가운데 정렬, 보이는 밑변 경계 y=200, 폭≤224px·높이≤166px. 크기가 다른 모자도 같은 착용 기준을 사용한다.
- 초록 단호박: 기존 호박과 어울리는 진갈색 선과 셀 음영. 도착 상태는 같은 호박에 금빛 테두리와 작은 반짝임을 더했다.
- 얼음: 칸 전체를 채우는 실제 반투명 PNG. 중앙 128×128의 16,384픽셀 모두 반투명으로 검사됐고, 게임 캡처에서 나무 바닥이 비치는 것을 확인했다.
- 화살표: 위쪽 크림색 바닥 표시. 게임에서 방향에 맞춰 회전한다.
- UI: 최대 108px 실루엣에 투명 여백. 달력에 숫자나 글자는 없다.

## 적용 및 착용 위치 수정

`Assets.gd`는 PNG를 우선 읽으므로 모자·호박·타일·규칙 아이콘 **16종은 기존 화면에 자동 적용**된다. `daily/trophy/hanger` 3종은 문서에 명시된 메뉴 확장용이며, 현재 메인 메뉴는 글자 버튼을 사용한다. 실행 중인 게임은 텍스처 캐시를 쓰므로 다시 실행해야 새 파일이 반영된다. EXE/APK에는 별도 재빌드가 필요하며 이 작업에서는 배포 바이너리를 갱신하지 않았다.

실제 착용 화면에서 정면 모자가 머리가 아니라 뒤쪽 몸통에 올라가는 것을 확인했다. `Game.gd`와 `Wardrobe.gd`의 정면 기준점 y를 -92에서 -66으로 맞춰 이마 위에 얹히도록 수정했다. 다른 방향 기준점은 유지했다. 갤러리 합성 위치도 이 값과 같다.

## 생성 프롬프트와 원본

모든 생성은 **built-in image_gen** 모드다. 정확한 최종 프롬프트, 참고 그림, 생성 원본의 절대 경로와 패키징 옵션을 다음 파일에 보관했다.

- [자연 모자 4종](docs/art/new-features-hats-nature-prompts.json)
- [특수 모자 4종](docs/art/new-features-hats-special-prompts.json)
- [보드 4종](docs/art/new-features-board-prompts.json)
- [UI 7종](docs/art/new-features-ui-prompts.json)

원본은 각 JSON의 `source` 또는 원본 경로 필드가 가리키는 `.codex/generated_images/` 아래에 보존했다. 프로젝트는 `assets/`에 저장된 최종 PNG만 사용한다. 귤의 첫 시안은 귤 모양 모자로 나와 폐기하고, 명세대로 귤 한 개로 다시 만들었다.

## 확인 결과

- `powershell.exe -NoProfile -File tools/check_new_features_art.ps1`: **19/19 통과**. 파일·크기·알파·모자 기준점·얼음 반투명·SHA256을 [manifest](docs/art/new-features-manifest.json)에 기록했다.
- Godot 4.7.1의 별도 `Sokoban Art QA` 프로젝트 복사본에서 **19/19 PNG 리소스 로딩 확인**. 가져오기 과정의 투명 경계 보정 때문에 원본/엔진 이미지 바이트 비교 대신 리소스 경로와 크기를 검증한다.
- 꾸미기 3화면, 새 규칙 선택 1화면, 규칙별 실제 보드 4화면을 캡처하고 확인했다. [실행 기록](docs/art/new-features-runtime-qa.log), [오류 기록](docs/art/new-features-runtime-qa-errors.log)(빈 파일).
- 게임 저장 데이터는 검사 전후 동일하다. 캡처의 별·진행도·모자 해금은 별도 QA 복사본의 임시 상태다.
- QA는 이 에셋 작업의 코드 스냅샷을 사용했다. 동시에 추가되던 광고 플러그인 관련 설정은 복사본에서 제외했으며 실제 프로젝트의 광고 설정은 변경하지 않았다. 모바일 실기기·광고 기능·최종 배포 빌드 검증은 포함하지 않는다.

## 미리보기

[전체 에셋 갤러리](docs/art/new-features-preview.html)는 모자 착용·단독 그림, 바닥 합성, 작은 아이콘을 비교할 수 있다. 체커·크림·갈색 배경을 바꿔 투명 여백도 확인할 수 있다.

실제 화면: [꾸미기](docs/screenshots/new_art_wardrobe_straw.png), [규칙 선택](docs/screenshots/new_art_rules.png), [초록 호박](docs/screenshots/new_art_rule_4.png), [얼음](docs/screenshots/new_art_rule_5.png), [화살표](docs/screenshots/new_art_rule_6.png), [규칙 조합](docs/screenshots/new_art_rule_7.png).
