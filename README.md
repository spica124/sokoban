# 카피바라 창고 (Capybara Pantry)

Godot 4.7로 만든 소코반 퍼즐 게임. 카피바라가 호박을 나무 창고의 표시된 자리까지 밀어 나릅니다. 스팀 출시를 목표로 합니다.
난이도 4단계(쉬움·보통·어려움·극한)에 각 약 200개, 총 800개 레벨. 어려움 티어 앞 24판은 스타크래프트 유즈맵 "Sokoban 1.00" 원작 배치 그대로이며, 나머지는 자작 레벨과 DeepMind Boxoban(Apache-2.0) 레벨을 솔버로 난이도 평가해 배분했습니다. 모든 레벨은 풀이 가능성을 검증했습니다.

## 실행

- Godot 편집기: `C:\Users\limji\Godot\Godot.exe` 실행 → 프로젝트 가져오기 → 이 폴더 선택 → F5
- 편집기 없이: `Godot.exe --path <이 폴더>`

## 조작

| 키 | 동작 |
|---|---|
| W A S D / 방향키 / 패드 십자키 | 이동 |
| Z / Backspace | 되돌리기 |
| R | 다시 시작 |
| H / 패드 B | 힌트 |
| ESC | 일시정지 |
| Q / E | 스테이지 선택에서 페이지 넘기기 |
| 터치 | 왼쪽 방향 버튼 이동, 오른쪽 힌트·되돌리기·다시 시작·일시정지 (앱) |

## Windows 빌드 (스팀 업로드용)

1. 내보내기 템플릿(4.7.1.stable)은 이미 설치되어 있음. 다른 PC라면 Godot 편집기 → 편집기 → 내보내기 템플릿 관리 → 다운로드
2. 빌드:
   ```
   python tools/build_windows.py
   ```
   결과: `build/Sokoban.exe` (pck 포함 단일 파일, 약 105MB)
3. `build/` 폴더 전체를 Steamworks SDK의 ContentBuilder로 업로드

## 안드로이드 빌드

- 필요: Android SDK(`%LOCALAPPDATA%\Android\Sdk`, build-tools 34+), JDK 17, Godot 편집기 설정의 SDK/JDK 경로, 디버그 키스토어. 이 PC에는 모두 설치되어 있음.
- 디버그 APK(테스트용, 폰에 바로 설치 가능):
  ```
  Godot.exe --headless --path . --export-debug "Android" build/Sokoban.apk
  ```
- 스토어 출시용 릴리스 APK/AAB는 릴리스 키스토어를 만들어 프로젝트 → 내보내기 → Android → Keystore 항목에 등록한 뒤 `--export-release`로 빌드.
- 조작: 왼쪽 아래 방향 버튼으로 이동(누르고 있으면 계속), 오른쪽 아래 힌트·되돌리기·다시 시작·일시정지.

## 스팀 연동 (선택)

- [GodotSteam](https://godotsteam.com/) 애드온을 `addons/`에 넣으면 도전과제·클라우드 저장 사용 가능
- 앱 ID를 받은 뒤 `steam_appid.txt`를 exe 옆에 두고 테스트

## 문서

- `NOTES.md` — 구조, 설계 결정, 남은 일
- `ASSETS.md` — 아트 에셋 파일명·크기·생성 프롬프트
- `ART_ASSETS.md` — 제작된 에셋 목록·검증 결과·실제 생성 프롬프트 기록
