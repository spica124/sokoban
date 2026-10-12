# 디자인 명세서 — GPT에게 그대로 넘기는 문서

## 1. 게임 콘셉트

**카피바라가 먹이를 창고 자리까지 밀어 나르는 퍼즐 게임(소코반).**
아늑한 시골 농장 창고. 주인공 카피바라가 수확한 먹이(호박, 수박, 옥수수, 유자 바구니 등)를 몸으로 밀어 창고 안 정해진 자리에 차곡차곡 넣는다. 먹이는 밀 수만 있고 끌 수 없으며, 모두 자리에 넣으면 스테이지 클리어.

- **분위기**: 따뜻하고 느긋함. 포근한 나무·짚·흙 질감. 밤이 아니라 해 질 녘 창고의 노란 등불 느낌.
- **대상**: 전 연령. 귀엽지만 유치하지 않게.
- **화면 비율**: 가로 16:9 (PC, 모바일 가로).
- **이미 있는 것**: 정면 카피바라(`player.png`)를 캐릭터 기준으로 삼는다. 다른 모든 그림은 이 카피바라와 같은 그림체여야 한다.

## 2. 스타일 문장 (모든 프롬프트 맨 앞에 붙이기)

```
Cozy farm-pantry puzzle game art, clean 2D vector cartoon with soft cel shading,
thick dark-brown outlines (#2A1608) like the reference capybara, warm palette:
straw yellow #E8C46A, wood brown #A86E40, pumpkin orange #E8983F, leaf green #6FA05A,
cream #F6E7C9, deep brown #3B2314. Top-down view for tiles, no text, no watermark,
centered, transparent background unless the item says "fully filling the tile".
```

참고 이미지로 항상 `assets/sprites/player.png`(정면 카피바라)를 함께 첨부한다.

## 3. 공통 규칙

- 형식: PNG, 투명 배경(알파). 타일은 정사각형 256×256.
- 타일마다 파일을 따로 생성. 한 장에 여러 개 넣지 않는다.
- 파일 이름은 아래와 정확히 같아야 하며(대소문자 포함) 폴더에 넣으면 코드 수정 없이 자동 적용된다.
- "꽉 채움" 항목은 여백 없이 가장자리까지, 나머지는 타일 안에 여백을 둔다.
- 새 파일을 넣은 뒤 게임을 껐다 켠다.

## 4. 게임 타일 — `assets/sprites/`

| 파일명 | 역할 | 여백 | 프롬프트 |
|---|---|---|---|
| `floor.png` | 창고 바닥 | 꽉 채움, 이어 붙임 가능 | `Seamless wooden plank pantry floor tile, warm brown #A86E40 with subtle grain and a few straw bits, tileable on all four edges, fully filling the tile, low contrast so items on top stay readable.` |
| `wall.png` | 벽(못 지나감) | 꽉 채움, 이어 붙임 가능 | `Clean barn wall block made of a few broad vertical wooden boards, warm light honey-brown, darker outline and a slight bevel, clearly lighter than the floor, sparse subtle grain, no hay or rope lattice, fully filling the tile, tileable.` |
| `goal_tile.png` | 창고 자리(먹이를 놓을 곳) | 꽉 채움 | `The same wooden floor with only a clean cream rounded-square outline painted on it, empty wooden center, no basket, no straw mat, no center icon, fully filling the tile.` |
| `box.png` | 먹이 (아직 자리 밖) | 가장자리 6% 여백 | `A big round pumpkin the capybara pushes, pumpkin orange #E8983F with a green stem and leaf, top-down view, small drop shadow underneath, transparent background, filling about 88% of the tile.` |
| `box_on_goal.png` | 먹이 (자리에 놓임) | box와 동일 | `The same pumpkin now settled on its storage spot, slightly brighter with a soft golden glow and a tiny sparkle, same size and position, transparent background.` |
| `goal.png` | (선택) 자리 표시 링 | 투명, 가운데 표식 | `goal_tile.png`가 있으면 쓰이지 않는다. 필요 없으면 만들지 않아도 됨. |

먹이를 호박 하나로 통일하는 이유: 소코반은 모든 먹이가 같은 규칙이라 종류가 달라도 의미가 없고, 한 종류가 화면 가독성이 가장 좋다. 종류를 바꾸고 싶으면 수박·옥수수 묶음·유자 바구니 중 하나로 `box.png`/`box_on_goal.png`만 바꾸면 된다.

## 5. 캐릭터 — `assets/sprites/`

정면(`player.png`)은 이미 있음. 나머지 세 방향을 같은 카피바라로 만든다. 항상 `player.png`를 참고 이미지로 첨부.

| 파일명 | 프롬프트 |
|---|---|
| `player_down.png` | `player.png`와 같은 파일을 복사해서 사용 |
| `player_up.png` | `The exact same capybara character as the reference, seen from behind (back of head, two round ears, rump, hind feet), same proportions, same outline thickness and colors, transparent background, same size as the reference.` |
| `player_left.png` | `The exact same capybara as the reference in left-facing side profile, walking pose with one front paw forward, same style and size, transparent background.` |
| `player_right.png` | `The exact same capybara as the reference in right-facing side profile, walking pose, same style and size, transparent background.` |

`player_up/left/right.png`는 정면 카피바라를 참조한 실제 생성 이미지로 교체 완료했다.

## 6. UI 스킨 — `assets/ui/` (선택, 넣으면 버튼·창이 그림으로 바뀜)

96×96 PNG, **9분할(9-slice)**: 네 모서리 28px은 늘어나지 않고 가운데만 늘어난다. 모서리 안쪽은 단순한 면으로. 글자는 코드가 위에 얹으므로 그림에 글자를 넣지 않는다.

| 파일명 | 역할 | 프롬프트 |
|---|---|---|
| `panel.png` | 창(일시정지, 클리어, 설정, 안내 말풍선) 배경 | `A 9-slice UI panel: wooden board with rounded corners and a thin rope or straw border, cream #F6E7C9 inner face for readable dark text, 28 px corners, no text, 96x96.` |
| `button.png` | 버튼 기본 | `A 9-slice wooden button, plank brown #A86E40 with rounded corners and dark outline, flat face, 28 px corners, no text, 96x96.` |
| `button_hover.png` | 버튼 위에 커서/포커스 | `Same wooden button but lighter, straw-yellow #E8C46A glow on the edge, 96x96.` |
| `button_pressed.png` | 누른 상태 | `Same wooden button pressed in, darker face, 96x96.` |
| `button_disabled.png` | 잠김/비활성 | `Same wooden button faded and greyed out, 96x96.` |

UI 스킨을 넣으면 글자색은 코드에서 밝은 색으로 그대로 두므로, 버튼 면은 어두운 갈색 계열이어야 글자가 보인다. `panel.png`를 크림색 밝은 면으로 만들 경우 글자색을 어둡게 바꿔야 하니 알려줄 것.

## 7. 메뉴 이미지 — `assets/sprites/`

| 파일명 | 크기 | 프롬프트 |
|---|---|---|
| `bg.png` | 1920×1080 | `Wide illustration of a cozy barn pantry interior at dusk: wooden shelves stacked with pumpkins and baskets, hanging lantern light, straw on the floor, soft vignette and low contrast so white UI text stays readable, no characters, no text.` |
| `logo.png` | 1040×400, 투명 | `Game logo: the Korean title "카피바라 창고" in bold rounded wooden-sign letters with straw yellow #E8C46A fill and dark outline, a small pumpkin tucked beside the letters, transparent background, no other text.` |

게임 제목을 바꾸려면 `scripts/Global.gd`의 `"title"` 문자열(한/영)을 고친다. 로고 그림이 있으면 제목 글자 대신 로고가 표시된다.

## 8. 스팀 상점 이미지 — `assets/store/` (게임 빌드에는 안 들어감)

| 용도 | 크기 | 내용 |
|---|---|---|
| 캡슐(헤더) | 460×215 | 로고 + 카피바라가 호박을 미는 장면 |
| 캡슐(소형) | 231×87 | 로고만 |
| 캡슐(메인) | 616×353 | 위와 같은 장면, 여백 넉넉히 |
| 세로 캡슐 | 374×448 | 카피바라 클로즈업 + 로고 |
| 라이브러리 히어로 | 3840×1240 | 글자 없이 창고 풍경 + 카피바라 |
| 라이브러리 로고 | 1280×720, 투명 | 로고만 |
| 스크린샷 | 1920×1080 | 게임에서 캡처 (README의 `--shot` 옵션) |
| 아이콘 | 512×512 | 카피바라 얼굴, 안드로이드 런처 아이콘으로도 사용 |

## 9. 확인 방법

1. PNG를 해당 폴더에 넣는다.
2. 게임을 실행해 타일이 바뀌었는지 본다. 편집기 없이도 파일을 직접 읽는다.
3. 빌드에 반영하려면 `python tools/build_windows.py` (PC), README의 안드로이드 명령(앱).

## 10. 색이 서로 어울리게 하는 팁

- 바닥은 어둡고 무늬가 약하게, 벽은 밝은 큼직한 세로 판자로 → 길이 한눈에 보인다.
- 먹이(호박)는 바닥과 대비되는 색(주황)으로, 창고 자리는 바닥과 같은 톤에 밝은 테두리만.
- 카피바라는 먹이보다 살짝 작게 보이도록 여백을 조금 더 둔다.

## 11. 적용 기록 (2026-09-07)

이 명세의 타일·카피바라 방향·선택 UI 5종·메뉴·상점 이미지를 모두 적용했다. panel.png는 크림색 면이며 패널 안 글자색을 진한 갈색으로 코드에서 조정했다. 도착 표시는 goal_tile.png를 사용한다. 전체 목록과 검증 기록은 ART_ASSETS.md 참고.

## 12. 추가 요청 이미지 (2026-09-18, 게임 필·모바일용)

모두 투명 배경 PNG. 스타일 문장(2번)을 앞에 붙이고 `player.png`를 참고 이미지로 첨부. 최초에는 이미지/코드 작업을 분담했으며, 2026-09-18 후속 요청으로 게임 코드 연결까지 완료했다. 상세 사항은 GAME_FEEL.md 참고.

| 우선 | 파일명 | 크기 | 용도 | 프롬프트 |
|---|---|---|---|---|
| 1 | `assets/ui/arrow.png` | 128×128 | 폰 십자키 (위쪽 화살표 하나만, 코드가 돌려 씀) | `A chunky rounded wooden arrow pointing straight up, carved wood with dark-brown outline and a small highlight, centered, no background, no text.` |
| 1 | `assets/ui/star_on.png` | 128×128 | 결과 창·스테이지 카드의 획득 별 | `A plump golden star badge with dark-brown outline, warm glow, slight shine, centered, no text.` |
| 1 | `assets/ui/star_off.png` | 128×128 | 못 얻은 별 | `The same star shape as an empty slot: flat cream fill with a dashed brown outline, no glow.` |
| 1 | `assets/ui/lock.png` | 128×128 | 잠긴 스테이지 (폰 글꼴에 자물쇠 이모지가 없을 수 있음) | `A small cute wooden padlock with an iron shackle, dark-brown outline, centered, no text.` |
| 2 | `assets/sprites/player_happy.png` | 256×256 | 클리어할 때 카피바라 | `The exact same capybara as the reference, front view, eyes closed happily, paws raised in celebration, same size and outline.` |
| 2 | `assets/sprites/player_bump.png` | 256×256 | 벽에 부딪혔을 때 잠깐 | `The exact same capybara, front view, dizzy surprised face with a tiny sweat drop, same size and outline.` |
| 3 | `assets/fx/sparkle.png` | 64×64 | 호박이 자리에 들어갈 때 반짝이 | `A single four-pointed sparkle, cream-white center fading to gold, soft edges, no outline.` |
| 3 | `assets/fx/dust.png` | 64×64 | 밀 때 흙먼지 | `A single soft round dust puff, light tan, fluffy edges, no outline.` |
| 3 | `assets/fx/leaf.png` | 48×48 | 클리어 색종이 대신 날리는 잎·짚 | `A single tiny autumn leaf, orange-yellow with dark-brown outline, flat.` |
| 3 | `assets/ui/tier_easy.png` 외 3개 (`tier_normal`, `tier_hard`, `tier_expert`) | 128×128 | 난이도 선택 카드 아이콘 | 쉬움 `a small green sprout`, 보통 `one pumpkin`, 어려움 `a stack of three pumpkins`, 극한 `a pumpkin wearing a tiny golden crown` (각각 같은 스타일, 가운데, 글자 없음) |

추가 이미지 제작 완료(2026-09-18): 위13종을 지정 경로에 저장했고 투명도·크기 검증을 마쳤다. 코드 연결용 목록은 MOBILE_ASSETS.md, 실제 생성 프롬프트는 docs/art/mobile-prompts.md에 있다.

## 13. 새 기능용 이미지 (2026-10-06, 힌트·데일리·새 규칙·꾸미기)

2026-10-06 제작 완료: 아래 19종 PNG를 지정 경로에 넣었다. 모자 8종·보드 4종·규칙 아이콘 4종은 기존 로더가 자동 적용하며, 메뉴 확장용 3종도 준비했다. 스타일 문장(2번)과 `player.png`를 참고해 내장 이미지 생성 도구로 제작했다. 미리보기는 `docs/art/new-features-preview.html`, 프롬프트·검증·적용 기록은 `NEW_FEATURE_ASSETS.md` 참고.

| 우선 | 파일명 | 크기 | 용도 | 프롬프트 |
|---|---|---|---|---|
| 1 | `assets/sprites/box_c1.png` | 256×256 | 초록 단호박 (짝 맞추기 규칙의 두 번째 먹이) | `A round dark-green kabocha squash with a short brown stem, same size, outline and top-down angle as the reference pumpkin, transparent background, filling about 88% of the tile.` |
| 1 | `assets/sprites/box_on_goal_c1.png` | 256×256 | 자리에 들어간 초록 단호박 | `The same green squash glowing softly with a tiny sparkle, same size and position, transparent background.` |
| 1 | `assets/sprites/ice.png` | 256×256 | 얼음 바닥 (바닥 위에 겹쳐 그림, 반투명) | `A thin sheet of pale blue ice seen from above, semi-transparent so the wooden floor shows through, a few white glints, fully filling the tile, tileable, transparent background.` |
| 1 | `assets/sprites/oneway.png` | 256×256 | 한 방향 화살표 (바닥에 그려진 위쪽 화살표 하나, 코드가 돌려 씀) | `A bold cream-colored arrow pointing straight up, painted on the floor like a stencil, dark-brown outline, centered, transparent background, about 70% of the tile.` |
| 2 | `assets/sprites/hat_straw.png` 외 7개 (`hat_mandarin`, `hat_flower`, `hat_leaf`, `hat_chef`, `hat_beanie`, `hat_grad`, `hat_crown`) | 256×256 | 카피바라가 쓰는 모자. 모자 아래쪽 가운데가 머리 꼭대기에 오도록 그림 아래쪽 1/4 지점에 놓는다 | 밀짚모자 `a small straw sun hat with a red band`, 귤 `a single mandarin orange with a green leaf, balanced like a hat`, 꽃 화관 `a ring of small pastel flowers`, 나뭇잎 `a single green leaf worn as a tiny hat`, 요리사 모자 `a puffy white chef toque`, 털모자 `a red knit beanie with a cream pom-pom`, 학사모 `a black graduation mortarboard with a gold tassel`, 왕관 `a small gold crown with red gems` (모두 정면, 투명 배경, 아래쪽 가운데 정렬) |
| 2 | `assets/ui/rule_color.png`, `rule_ice.png`, `rule_oneway.png`, `rule_mix.png` | 128×128 | 새 규칙 장 아이콘 | 짝 맞추기 `an orange pumpkin and a green squash side by side`, 얼음 `a round ice crystal badge`, 한 방향 `a wooden sign with an arrow`, 섞어서 `an ice crystal and an arrow sign together` |
| 3 | `assets/ui/daily.png`, `assets/ui/trophy.png`, `assets/ui/hanger.png` | 128×128 | 오늘의 퍼즐 / 업적 / 꾸미기 아이콘 (메뉴 확장 시 사용) | 달력 `a small paper calendar page with a pumpkin`, 트로피 `a small gold trophy`, 옷걸이 `a wooden hanger with a straw hat` |

## 14. 힌트권 아이콘 (2026-10-06, 모바일 광고 힌트)

없어도 동작함 (코드가 임시 티켓 그림을 그림). 넣으면 자동 적용.

| 우선 | 파일명 | 크기 | 용도 | 프롬프트 |
|---|---|---|---|---|
| 3 | `assets/ui/hint_pass.png` | 128×128 | 힌트권 받았을 때 알림 아이콘 | `A small cream paper ticket with notched sides and a golden sparkle in the middle, dark-brown outline, slightly tilted, centered, no text, transparent background.` |
