extends Control

var current_profile: Dictionary
var _is_ready: bool = false

@onready var panel = $CenterContainer/PanelContainer
@onready var close_btn = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseBtn
@onready var challenge_btn = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ChallengeBtn

func _ready():
	_is_ready = true
	modulate.a = 0
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.2)
	
	close_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		queue_free()
	)
	
	challenge_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.match_settings.clear()
		GameManager.match_settings[2] = {"type": "ai", "level": current_profile["level"], "ai_profile_id": current_profile["id"]}
		GameManager.is_career_mode = false
		GameManager.is_ai_levels_mode = true
		GameManager.is_magnetic_mode = false
		GameManager.is_stone_mode = false
		GameManager.is_bomber_mode = false
		GameManager.is_tagcoins_mode = false
		GameManager.is_coin_breaker_mode = false
		GameManager.goto_scene("res://scenes/setup/MatchSetup.tscn")
	)
	
	_apply_setup()

func setup(profile: Dictionary):
	current_profile = profile
	if _is_ready:
		_apply_setup()

func _apply_setup():
	if current_profile.is_empty(): return
	
	if current_profile.has("avatar_path") and ResourceLoader.exists(current_profile["avatar_path"]):
		var avatar = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Avatar
		avatar.texture = load(current_profile["avatar_path"])
		
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NameLbl.text = current_profile["name"] + " \"" + current_profile["nickname"] + "\""
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TierLbl.text = current_profile["tier_name"]
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TierLbl.add_theme_color_override("font_color", Color(current_profile["tier_color"]))
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SpecLbl.text = "Specialty: " + current_profile["specialty"]
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DescLbl.text = current_profile["description"]
