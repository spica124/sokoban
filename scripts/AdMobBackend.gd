## AdMobBackend.gd — the only script that talks to the AdMob plugin (addons/admob).
## Created by Ads.gd on Android only.
##
## Start-up order (Google's required flow):
##   consent info update → consent form if the user must answer → SDK init → load ad
## One rewarded ad is kept loaded; after it is shown the next one loads.
## Failed loads retry with a growing delay (10 s, 20 s, ... up to 2 min).
extends RefCounted

signal ready_changed(is_ready: bool)

var _unit := ""
var _ad: RewardedAd = null
var _loading := false
var _started_sdk := false
var _retries := 0


func start(unit_id: String) -> void:
	_unit = unit_id
	UserMessagingPlatform.consent_information.update(
		ConsentRequestParameters.new(), _on_consent_info, func(_e: FormError): _start_sdk())


func is_ready() -> bool:
	return _ad != null


func privacy_options_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_e: FormError): pass)


func _on_consent_info() -> void:
	var info := UserMessagingPlatform.consent_information
	if info.get_is_consent_form_available() \
			and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm): form.show(func(_e: FormError): _start_sdk()),
			func(_e: FormError): _start_sdk())
	else:
		_start_sdk()


func _start_sdk() -> void:
	if _started_sdk:
		return
	_started_sdk = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus): load_ad()
	MobileAds.initialize(listener)


func load_ad() -> void:
	if _ad != null or _loading:
		return
	_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd):
		_loading = false
		_retries = 0
		_ad = ad
		ready_changed.emit(true)
	callback.on_ad_failed_to_load = func(_e: LoadAdError):
		_loading = false
		_retries += 1
		var tree := Engine.get_main_loop() as SceneTree
		tree.create_timer(minf(10.0 * _retries, 120.0)).timeout.connect(load_ad)
	RewardedAdLoader.new().load(_unit, AdRequest.new(), callback)


## Shows the loaded ad; `finish(rewarded)` runs after it closes.
func show(finish: Callable) -> void:
	if _ad == null:
		finish.call(false)
		load_ad()
		return
	var ad := _ad
	_ad = null
	ready_changed.emit(false)
	var earned := [false]          # array so the lambdas share one flag
	var closed := func():
		ad.destroy()
		# the reward event can land just after the close event; give it a moment
		var tree := Engine.get_main_loop() as SceneTree
		await tree.create_timer(0.3).timeout
		finish.call(earned[0])
		load_ad()
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_dismissed_full_screen_content = closed
	callbacks.on_ad_failed_to_show_full_screen_content = func(_e: AdError): closed.call()
	ad.full_screen_content_callback = callbacks
	var reward := OnUserEarnedRewardListener.new()
	reward.on_user_earned_reward = func(_item: RewardedItem): earned[0] = true
	ad.show(reward)
