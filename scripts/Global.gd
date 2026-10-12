## Global.gd — 게임 전체에서 공유하는 설정 / 저장 / 번역 담당 (autoload "Global")
##
## 역할
##  1. 설정(전체화면, 수직동기화, 언어, 애니메이션) 보관 및 적용
##  2. 스테이지 진행도(클리어 여부, 최고 기록, 별) 저장 / 불러오기  → user://save.json
##  3. 한국어 / 영어 문자열 제공  → Global.T("키")
##  4. 키 입력 액션 등록 (WASD, 방향키, 게임패드)
extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

## ---------- 설정 ----------
var settings := {
	"fullscreen": false,
	"vsync": true,
	"lang": "ko",      # "ko" 또는 "en"
	"anim": true,      # 애니메이션·화면 효과 사용 여부 (끄면 흔들림/파티클도 꺼짐)
	"vibrate": true,   # 폰 진동 / 게임패드 진동
}

## ---------- 진행도 ----------
## key: "티어id/레벨번호" (예: "easy/3"), value: {"time": float, "moves": int, "pushes": int, "stars": int}
var progress := {}

## 현재 플레이 중인(또는 마지막으로 선택한) 난이도 티어와 레벨 번호
var current_tier := 0
var current_level := 0

## "tier" = 일반/규칙 스테이지, "daily" = 오늘의 퍼즐 (daily_date 날짜)
var current_mode := "tier"
var daily_date := ""

## 업적(id -> 달성 시각), 쓰고 있는 모자, 이미 알려준 모자, 규칙 안내를 본 규칙
var achievements := {}
var hat := ""
var hats_seen: Array = []
var seen_rules := {}
var best_streak := 0
## Hint passes (phones only, see Ads.gd): one pass or one ad unlocks hints for a stage
const FREE_HINT_PASSES := 3      # topped up to this many every day
var hint_passes := 0
var hint_pass_day := ""          # last day the free passes were topped up
var hint_open := {}              # level key -> true once hints are unlocked there

## ---------- 번역 문자열 ----------
const STRINGS := {
	"ko": {
		"title": "카피바라 창고",
		"subtitle": "카피바라가 먹이를 창고 자리까지 밀어 나르는 퍼즐",
		"play": "게임 시작",
		"continue": "이어하기",
		"stage_select": "스테이지 선택",
		"settings": "설정",
		"quit": "종료",
		"back": "뒤로",
		"level": "스테이지",
		"best_time": "최고 시간",
		"best_moves": "최소 이동",
		"locked": "잠김",
		"paused": "일시정지",
		"resume": "계속하기",
		"restart": "다시 시작",
		"main_menu": "메인 메뉴",
		"clear": "클리어!",
		"all_clear": "모든 스테이지 클리어!",
		"all_clear_desc": "축하합니다. 창고가 가득 찼어요!",
		"time": "시간",
		"moves": "이동",
		"pushes": "밀기",
		"par": "기준 이동",
		"next": "다음 스테이지",
		"retry": "다시 도전",
		"new_record": "신기록!",
		"fullscreen": "전체 화면",
		"vsync": "수직 동기화",
		"language": "언어",
		"animation": "애니메이션 효과",
		"vibration": "진동",
		"reset_progress": "진행도 초기화",
		"reset_confirm": "모든 기록을 지울까요? 되돌릴 수 없습니다.",
		"yes": "예",
		"no": "아니오",
		"hint": "WASD / 방향키 이동   Z 되돌리기   R 다시 시작   H 힌트   ESC 일시정지",
		"undo": "되돌리기",
		"progress": "진행도",
		"tut_1": "이 카피바라가 당신이에요. WASD나 방향키로 움직입니다.",
		"tut_1_touch": "이 카피바라가 당신이에요. 왼쪽 아래 방향 버튼으로 움직입니다. 누르고 있으면 계속 걸어요.",
		"tut_5_touch": "막혔다면 되돌리기로 한 수 취소, 다시 시작으로 처음부터, 힌트로 다음 한 수를 볼 수 있어요.",
		"tut_2": "먹이는 몸으로 밀어서 옮겨요. 끌어당길 수는 없고, 두 개를 한꺼번에 밀 수도 없어요.",
		"tut_3": "표시가 있는 칸이 창고 자리예요. 먹이를 모두 창고 자리에 올리면 클리어!",
		"tut_4": "벽 모서리에 붙은 먹이는 다시 못 움직여요. 밀기 전에 한 번 더 생각하세요.",
		"tut_5": "막혔다면 Z로 한 수 되돌리기, R로 처음부터 다시, H로 힌트. ESC는 일시정지예요.",
		"tut_6": "창고 자리를 다 채우면 다음 스테이지로 넘어가요. 준비됐으면 시작!",
		"tut_next": "화면을 누르거나 아무 키 → 다음  (%d/%d)     ESC 건너뛰기",
		"tut_next_touch": "화면을 누르면 다음  (%d/%d)",
		"skip": "건너뛰기",
		"hint_touch": "왼쪽 방향 버튼으로 이동   오른쪽 버튼: 힌트 · 되돌리기 · 다시 시작 · 일시정지",
		"difficulty": "난이도 선택",
		"difficulty_desc": "언제든 다른 난이도로 바꿀 수 있어요. 진행도는 난이도마다 따로 저장됩니다.",
		"tier_easy": "쉬움",
		"tier_easy_desc": "규칙 익히기. 먹이 1~4개, 몇 수면 풀리는 판",
		"tier_normal": "보통",
		"tier_normal_desc": "먹이 4개, 순서를 생각해야 하는 판",
		"tier_hard": "어려움",
		"tier_hard_desc": "스타 소코반 원작 24판 + 큰 창고 퍼즐",
		"tier_expert": "극한",
		"tier_expert_desc": "가장 어려운 200판. 되돌리기와 힌트를 아끼지 마세요",
		"daily": "오늘의 퍼즐",
		"daily_streak": "%d일 연속",
		"daily_done": "오늘 완료",
		"daily_clear": "오늘의 퍼즐 완료!",
		"daily_come_back": "내일 새 퍼즐이 열려요",
		"daily_level": "난이도 %d / 7",
		"weekday_0": "월요일", "weekday_1": "화요일", "weekday_2": "수요일", "weekday_3": "목요일",
		"weekday_4": "금요일", "weekday_5": "토요일", "weekday_6": "일요일",
		"date_fmt": "%d월 %d일",
		"hint_btn": "힌트",
		"hint_thinking": "생각하는 중...",
		"hint_ok": "반짝이는 먹이를 화살표 방향으로 밀어 보세요",
		"hint_dead": "이 상태로는 풀 수 없어요. 되돌리기를 눌러 보세요",
		"hint_limit": "지금은 힌트를 찾지 못했어요. 다시 시작하면 처음부터 안내해요",
		"hint_used": "힌트 사용 · 별 최대 2개",
		"hint_btn_count": "힌트 (%d)",
		"hint_offer_title": "이 판 힌트 열기",
		"hint_offer_desc": "한 번 열면 이 판에서는 힌트를 계속 쓸 수 있어요",
		"hint_offer_stars": "힌트를 쓴 판은 별 최대 2개",
		"hint_use_pass": "힌트권 쓰기 (%d장 남음)",
		"hint_watch_ad": "광고 보고 열기",
		"hint_ad_loading": "광고 준비 중…",
		"hint_ad_failed": "광고를 보지 못했어요. 잠시 후 다시 해 주세요",
		"hint_free_note": "매일 힌트권 %d장 무료 · 오늘의 퍼즐과 업적으로도 받아요",
		"hint_pass_got": "힌트권 +%d",
		"hint_pass_from_daily": "오늘의 퍼즐 보상",
		"hint_pass_from_ach": "업적 보상",
		"ad_test": "테스트 광고 %d",
		"ad_playing": "광고 재생 중…",
		"privacy_options": "광고 개인정보 설정",
		"cancel": "취소",
		"rules_menu": "새 규칙",
		"rules_title": "새 규칙",
		"rules_desc": "규칙이 하나씩 열려요. 앞 장에서 %d판을 깨면 다음 장이 열립니다",
		"rule_locked": "%s %d판 클리어 시 열림",
		"tier_rule_color": "짝 맞추기",
		"tier_rule_color_desc": "초록 단호박은 초록 자리에, 주황 호박은 주황 자리에",
		"tier_rule_ice": "미끄러운 얼음",
		"tier_rule_ice_desc": "얼음 위로 밀린 먹이는 막힐 때까지 미끄러져요",
		"tier_rule_oneway": "한 방향 길",
		"tier_rule_oneway_desc": "화살표 칸은 화살표 방향으로만 들어갈 수 있어요",
		"tier_rule_mix": "섞어서",
		"tier_rule_mix_desc": "두 가지 규칙이 한 판에 함께 나와요",
		"rule_color_1": "이번 장은 짝 맞추기예요. 초록 단호박은 초록 표시가 있는 자리에만 들어가요.",
		"rule_color_2": "주황 호박은 주황 표시 자리에. 색이 맞는 자리에 모두 올려야 클리어!",
		"rule_ice_1": "파랗게 빛나는 칸은 얼음이에요. 얼음 위로 밀린 먹이는 막힐 때까지 쭉 미끄러져요.",
		"rule_ice_2": "카피바라는 미끄러지지 않아요. 먹이가 어디서 멈출지 먼저 생각해 보세요.",
		"rule_oneway_1": "화살표가 그려진 칸은 화살표 방향으로만 들어갈 수 있어요.",
		"rule_oneway_2": "카피바라도 먹이도 마찬가지예요. 거꾸로는 지나갈 수 없어요.",
		"rule_mix_1": "이제 두 규칙이 한 판에 함께 나와요. 막히면 힌트를 써 보세요.",
		"achievements": "업적",
		"ach_count": "%d / %d 달성",
		"ach_unlocked": "업적 달성!",
		"hat_unlocked": "새 모자를 얻었어요!",
		"wardrobe": "꾸미기",
		"wardrobe_desc": "별과 업적으로 모자를 모아 보세요",
		"hat_none": "모자 없음",
		"equipped": "쓰는 중",
		"req_stars": "별 %d개",
		"req_ach": "업적: %s",
	},
	"en": {
		"title": "Capybara Pantry",
		"subtitle": "A capybara hauls food into the pantry",
		"play": "Play",
		"continue": "Continue",
		"stage_select": "Stage Select",
		"settings": "Settings",
		"quit": "Quit",
		"back": "Back",
		"level": "Stage",
		"best_time": "Best Time",
		"best_moves": "Fewest Moves",
		"locked": "Locked",
		"paused": "Paused",
		"resume": "Resume",
		"restart": "Restart",
		"main_menu": "Main Menu",
		"clear": "Clear!",
		"all_clear": "All Stages Clear!",
		"all_clear_desc": "Congratulations, the pantry is full!",
		"time": "Time",
		"moves": "Moves",
		"pushes": "Pushes",
		"par": "Par",
		"next": "Next Stage",
		"retry": "Retry",
		"new_record": "New Record!",
		"fullscreen": "Fullscreen",
		"vsync": "VSync",
		"language": "Language",
		"animation": "Animations & Effects",
		"vibration": "Vibration",
		"reset_progress": "Reset Progress",
		"reset_confirm": "Erase all records? This cannot be undone.",
		"yes": "Yes",
		"no": "No",
		"hint": "WASD / Arrows Move   Z Undo   R Restart   H Hint   ESC Pause",
		"undo": "Undo",
		"progress": "Progress",
		"tut_1": "This capybara is you. Move with WASD or the arrow keys.",
		"tut_1_touch": "This capybara is you. Move with the arrow buttons at the bottom left. Hold to keep walking.",
		"tut_5_touch": "Stuck? Undo takes back a move, Restart begins again, Hint shows the next push.",
		"tut_2": "Push food by walking into it. You can never pull, and you cannot push two at once.",
		"tut_3": "Marked tiles are pantry spots. Put every food item on a spot to clear the stage!",
		"tut_4": "Food pushed into a wall corner can never move again. Think before you push.",
		"tut_5": "Stuck? Z undoes one move, R restarts, H shows a hint. ESC pauses.",
		"tut_6": "Fill every pantry spot and you move on to the next stage. Ready? Go!",
		"tut_next": "Click or press any key → next  (%d/%d)     ESC skip",
		"tut_next_touch": "Tap to continue  (%d/%d)",
		"skip": "Skip",
		"hint_touch": "Arrow buttons on the left move   Right buttons: Hint · Undo · Restart · Pause",
		"difficulty": "Choose Difficulty",
		"difficulty_desc": "Switch any time. Progress is saved per difficulty.",
		"tier_easy": "Easy",
		"tier_easy_desc": "Learn the rules. 1-4 food items, solved in a few moves",
		"tier_normal": "Normal",
		"tier_normal_desc": "4 food items, ordering matters",
		"tier_hard": "Hard",
		"tier_hard_desc": "The 24 StarCraft sokoban stages + big pantry puzzles",
		"tier_expert": "Expert",
		"tier_expert_desc": "The toughest 200. Undo and hints are your friends",
		"daily": "Daily Puzzle",
		"daily_streak": "%d-day streak",
		"daily_done": "Done today",
		"daily_clear": "Daily Puzzle Complete!",
		"daily_come_back": "A new puzzle opens tomorrow",
		"daily_level": "Difficulty %d / 7",
		"weekday_0": "Monday", "weekday_1": "Tuesday", "weekday_2": "Wednesday", "weekday_3": "Thursday",
		"weekday_4": "Friday", "weekday_5": "Saturday", "weekday_6": "Sunday",
		"date_fmt": "%d/%d",
		"hint_btn": "Hint",
		"hint_thinking": "Thinking...",
		"hint_ok": "Push the glowing food in the arrow's direction",
		"hint_dead": "This position can't be solved. Try Undo",
		"hint_limit": "No hint found right now. Restart and it will guide you from the start",
		"hint_used": "Hint used · max 2 stars",
		"hint_btn_count": "Hint (%d)",
		"hint_offer_title": "Unlock hints",
		"hint_offer_desc": "Once unlocked, hints stay on for this stage",
		"hint_offer_stars": "Stages cleared with hints give at most 2 stars",
		"hint_use_pass": "Use a hint pass (%d left)",
		"hint_watch_ad": "Watch an ad",
		"hint_ad_loading": "Loading ad…",
		"hint_ad_failed": "The ad didn't play. Please try again soon",
		"hint_free_note": "%d free passes every day · more from daily puzzles and achievements",
		"hint_pass_got": "Hint pass +%d",
		"hint_pass_from_daily": "Daily puzzle reward",
		"hint_pass_from_ach": "Achievement reward",
		"ad_test": "Test ad %d",
		"ad_playing": "Playing ad…",
		"privacy_options": "Ad privacy options",
		"cancel": "Cancel",
		"rules_menu": "New Rules",
		"rules_title": "New Rules",
		"rules_desc": "Rules unlock one by one. Clear %d stages to open the next chapter",
		"rule_locked": "Opens after %s: %d cleared",
		"tier_rule_color": "Matching Pairs",
		"tier_rule_color_desc": "Green squash to green spots, orange pumpkins to orange spots",
		"tier_rule_ice": "Slippery Ice",
		"tier_rule_ice_desc": "Food pushed onto ice slides until something stops it",
		"tier_rule_oneway": "One-Way Paths",
		"tier_rule_oneway_desc": "Arrow tiles can only be entered in the arrow's direction",
		"tier_rule_mix": "Mixed",
		"tier_rule_mix_desc": "Two rules in the same stage",
		"rule_color_1": "This chapter is about pairs. Green squash only fits spots with a green mark.",
		"rule_color_2": "Orange pumpkins go on orange spots. Match every color to clear!",
		"rule_ice_1": "Glowing blue tiles are ice. Food pushed onto ice slides until it is blocked.",
		"rule_ice_2": "The capybara never slides. Think about where the food will stop.",
		"rule_oneway_1": "Arrow tiles can only be entered in the arrow's direction.",
		"rule_oneway_2": "That goes for the capybara and the food alike. No going backwards.",
		"rule_mix_1": "Now two rules share a stage. Use a hint if you get stuck.",
		"achievements": "Achievements",
		"ach_count": "%d / %d unlocked",
		"ach_unlocked": "Achievement unlocked!",
		"hat_unlocked": "New hat unlocked!",
		"wardrobe": "Wardrobe",
		"wardrobe_desc": "Collect hats with stars and achievements",
		"hat_none": "No hat",
		"equipped": "Wearing",
		"req_stars": "%d stars",
		"req_ach": "Achievement: %s",
	},
}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_register_input_actions()
	load_save()
	apply_settings()
	get_window().theme = UITheme.build()   # 모든 화면에 공통 테마 적용


## 번역: 현재 언어 문자열 반환. 없으면 영어 → 없으면 키 그대로
func T(key: String) -> String:
	var table: Dictionary = STRINGS.get(settings["lang"], {})
	if table.has(key):
		return table[key]
	return STRINGS["en"].get(key, key)


## ---------- 입력 액션 ----------
## project.godot 에 직접 쓰는 대신 코드에서 등록 (읽기 쉽고 수정도 쉬움)
func _register_input_actions() -> void:
	_add_action("move_up", [KEY_W, KEY_UP], JOY_BUTTON_DPAD_UP)
	_add_action("move_down", [KEY_S, KEY_DOWN], JOY_BUTTON_DPAD_DOWN)
	_add_action("move_left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT)
	_add_action("move_right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT)
	_add_action("undo", [KEY_Z, KEY_BACKSPACE], JOY_BUTTON_X)
	_add_action("restart", [KEY_R], JOY_BUTTON_Y)
	_add_action("pause", [KEY_ESCAPE], JOY_BUTTON_START)
	_add_action("page_prev", [KEY_Q], JOY_BUTTON_LEFT_SHOULDER)
	_add_action("page_next", [KEY_E], JOY_BUTTON_RIGHT_SHOULDER)
	_add_action("hint", [KEY_H], JOY_BUTTON_B)


func _add_action(action: String, keys: Array, joy_button: int = -1) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)
	if joy_button >= 0:
		var jb := InputEventJoypadButton.new()
		jb.button_index = joy_button as JoyButton
		jb.device = -1   # any joypad, not only device 0 (Steam Input may enumerate as 1)
		InputMap.action_add_event(action, jb)


## True on phones/tablets, or with "--touch" for testing the mobile layout on desktop.
## (DisplayServer.is_touchscreen_available() is also true when touch is emulated
## from the mouse, so only the platform feature decides.)
func is_touch_device() -> bool:
	if "--touch" in OS.get_cmdline_user_args():
		return true
	return OS.has_feature("mobile")


## Screen cut-out / rounded-corner insets in logical (viewport) pixels.
## Zero on desktop. Used to keep the HUD and touch bar out of the notch.
func safe_insets() -> Dictionary:
	var zero := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	if not is_touch_device() or "--touch" in OS.get_cmdline_user_args():
		return zero
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0 or win.y <= 0:
		return zero
	var logical := get_viewport().get_visible_rect().size
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var sx := logical.x / win.x
	var sy := logical.y / win.y
	return {
		"left": max(0.0, safe.position.x) * sx,
		"top": max(0.0, safe.position.y) * sy,
		"right": max(0.0, win.x - safe.end.x) * sx,
		"bottom": max(0.0, win.y - safe.end.y) * sy,
	}


## Any button created anywhere gets hover/press feedback (see Juice.attach_button)
func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		Juice.attach_button(n)


## ---------- 설정 적용 ----------
func apply_settings() -> void:
	get_window().title = T("title")
	# Only touch the window mode when it actually changes, otherwise every
	# unrelated setting toggle would un-maximize a maximized window.
	var cur := DisplayServer.window_get_mode()
	var is_fs := cur == DisplayServer.WINDOW_MODE_FULLSCREEN or cur == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fs != bool(settings["fullscreen"]):
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)
	var vs := DisplayServer.VSYNC_ENABLED if settings["vsync"] else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != vs:
		DisplayServer.window_set_vsync_mode(vs)


func set_setting(key: String, value) -> void:
	settings[key] = value
	apply_settings()
	save()


## ---------- 저장 / 불러오기 ----------
func save() -> void:
	var data := {
		"version": SAVE_VERSION,
		"settings": settings,
		"progress": progress,
		"current_tier": current_tier,
		"current_level": current_level,
		"achievements": achievements,
		"hat": hat,
		"hats_seen": hats_seen,
		"seen_rules": seen_rules,
		"best_streak": best_streak,
		"hint_passes": hint_passes,
		"hint_pass_day": hint_pass_day,
		"hint_open": hint_open,
	}
	# Write to a temp file first and rename, so a crash mid-write cannot leave
	# a truncated save behind.
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SAVE_PATH))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		# Keep the damaged file for inspection instead of silently overwriting it
		var abs := ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.rename_absolute(abs, abs + ".corrupt")
		push_warning("save.json was unreadable; moved to save.json.corrupt")
		return
	# 저장된 값 중 존재하는 키만, 타입이 맞을 때만 덮어씀 (새 설정 항목이 추가돼도 안전)
	var s = parsed.get("settings")
	if s is Dictionary:
		for k in settings.keys():
			if s.has(k) and typeof(s[k]) == typeof(settings[k]):
				settings[k] = s[k]
	if not STRINGS.has(settings["lang"]):
		settings["lang"] = "ko"
	var p = parsed.get("progress")
	progress = p if p is Dictionary else {}
	# old saves used plain level numbers as keys; those records are dropped
	for k in progress.keys():
		if not ("/" in str(k)):
			progress.erase(k)
	current_tier = int(parsed.get("current_tier", 0))
	current_level = int(parsed.get("current_level", 0))
	var a = parsed.get("achievements")
	achievements = a if a is Dictionary else {}
	hat = str(parsed.get("hat", ""))
	var hs = parsed.get("hats_seen")
	hats_seen = hs if hs is Array else []
	var sr = parsed.get("seen_rules")
	seen_rules = sr if sr is Dictionary else {}
	best_streak = int(parsed.get("best_streak", 0))
	hint_passes = max(0, int(parsed.get("hint_passes", 0)))
	hint_pass_day = str(parsed.get("hint_pass_day", ""))
	var ho = parsed.get("hint_open")
	hint_open = ho if ho is Dictionary else {}


func reset_progress() -> void:
	progress = {}
	current_tier = 0
	current_level = 0
	achievements = {}
	hat = ""
	hats_seen = []
	seen_rules = {}
	best_streak = 0
	hint_open = {}
	save()


static func level_key(t: int, idx: int) -> String:
	return "%s/%d" % [Levels.tier_id(t), idx]


## ---------- 진행도 조회 (모두 티어 번호 + 레벨 번호) ----------
func is_completed(t: int, idx: int) -> bool:
	return progress.has(level_key(t, idx))


## 첫 스테이지는 항상 열림, 이미 깬 스테이지도 열림, 그 외에는 바로 앞 스테이지를 깨야 열림
func is_unlocked(t: int, idx: int) -> bool:
	return idx == 0 or is_completed(t, idx) or is_completed(t, idx - 1)


func stars_for(t: int, idx: int) -> int:
	return int(progress.get(level_key(t, idx), {}).get("stars", 0))


func record_for(t: int, idx: int) -> Dictionary:
	return progress.get(level_key(t, idx), {})


## 티어에서 깬 스테이지 수 / 별 합계
func tier_done(t: int) -> int:
	var n := 0
	for i in Levels.count(t):
		if is_completed(t, i):
			n += 1
	return n


func tier_stars(t: int) -> int:
	var n := 0
	for i in Levels.count(t):
		n += stars_for(t, i)
	return n


func total_done() -> int:
	var n := 0
	for t in Levels.tier_count():
		n += tier_done(t)
	return n


## 티어에서 아직 안 깬 첫 스테이지 번호. 전부 깼으면 0
func next_unfinished_level(t: int) -> int:
	for i in Levels.count(t):
		if not is_completed(t, i):
			return i
	return 0


## 클리어 결과 기록. 신기록이면 true 반환
## flags: {"hint": bool, "undo": bool} — whether hints / undo were used in this clear
func record_result(t: int, idx: int, time: float, moves: int, pushes: int, stars: int, flags := {}) -> bool:
	return _record(level_key(t, idx), time, moves, pushes, stars, flags)


func _record(key: String, time: float, moves: int, pushes: int, stars: int, flags: Dictionary) -> bool:
	var prev: Dictionary = progress.get(key, {})
	var is_new := prev.is_empty() or time < float(prev.get("time", INF)) or moves < int(prev.get("moves", 999999))
	progress[key] = {
		"time": min(time, float(prev.get("time", INF))),
		"moves": min(moves, int(prev.get("moves", 999999))),
		"pushes": min(pushes, int(prev.get("pushes", 999999))),
		"stars": max(stars, int(prev.get("stars", 0))),
		# "ever cleared without a hint / without undo" — once true, stays true
		"nohint": bool(prev.get("nohint", false)) or not bool(flags.get("hint", false)),
		"noundo": bool(prev.get("noundo", false)) or not bool(flags.get("undo", false)),
	}
	save()
	return is_new


## ---------- hint passes ----------
## Daily top-up: at most once per calendar day, back up to FREE_HINT_PASSES
func refill_hint_passes() -> void:
	var day := today()
	if hint_pass_day == day:
		return
	hint_pass_day = day
	hint_passes = max(hint_passes, FREE_HINT_PASSES)
	save()


## Rewards (daily puzzle, achievements). Only counts where passes exist (phones).
func give_hint_passes(n: int, reason: String) -> void:
	if not Ads.enabled() or n <= 0:
		return
	hint_passes += n
	save()
	Achievements.notify(reason, T("hint_pass_got") % n, "hint_pass")


func hints_unlocked(key: String) -> bool:
	return not Ads.enabled() or hint_open.has(key)


func unlock_hints(key: String, spend_pass: bool) -> void:
	if spend_pass:
		hint_passes = max(0, hint_passes - 1)
	hint_open[key] = true
	save()


## ---------- 오늘의 퍼즐 ----------
## Local calendar date "YYYY-MM-DD" (offset_days < 0 = past days)
func today(offset_days := 0) -> String:
	var bias: int = int(Time.get_time_zone_from_system()["bias"])
	var unix: float = Time.get_unix_time_from_system() + bias * 60 + offset_days * 86400
	var d := Time.get_date_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


func record_daily(date: String, time: float, moves: int, pushes: int, stars: int, flags := {}) -> bool:
	var first := not is_daily_done(date)
	var is_new := _record("daily/" + date, time, moves, pushes, stars, flags)
	if first:
		best_streak = max(best_streak, daily_streak())
		save()
		give_hint_passes(1, T("hint_pass_from_daily"))
	return is_new


func is_daily_done(date: String) -> bool:
	return progress.has("daily/" + date)


## Consecutive days ending today (or yesterday, if today's puzzle is still open)
func daily_streak() -> int:
	var start := 0 if is_daily_done(today()) else -1
	var n := 0
	while is_daily_done(today(start - n)):
		n += 1
	return n


func daily_count() -> int:
	var n := 0
	for k in progress.keys():
		if str(k).begins_with("daily/"):
			n += 1
	return n


## ---------- 유틸 ----------
## 초 단위 float → "MM:SS.ss"  (autoload 인스턴스로 호출하므로 static 아님)
func format_time(t: float) -> String:
	# Work in whole hundredths so rounding can never show 4.996 s as "04.00"
	var cs := int(floor(max(t, 0.0) * 100.0))
	var minutes := int(cs / 6000.0)
	var seconds := int(cs / 100.0) % 60
	var hundredths := cs % 100
	return "%02d:%02d.%02d" % [minutes, seconds, hundredths]


## 이동 수와 기준(par)으로 별 개수 계산: 기준 이하 3개, 기준의 1.3배+2 이하 2개, 나머지 1개
func stars_from_moves(moves: int, par: int) -> int:
	if par <= 0:
		return 3
	if moves <= par:
		return 3
	if moves <= int(par * 1.3) + 2:
		return 2
	return 1
