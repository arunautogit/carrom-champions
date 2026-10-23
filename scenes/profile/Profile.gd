extends Control

@onready var back_btn = $MarginContainer/TopBar/BackButton
@onready var name_lbl = $MarginContainer/VBoxContainer/Header/VBoxContainer/Name
@onready var avatar_icon = $MarginContainer/VBoxContainer/Header/Avatar/Icon
@onready var matches_lbl = $MarginContainer/VBoxContainer/StatsGrid/MatchesPanel/VBox/Value
@onready var wins_lbl = $MarginContainer/VBoxContainer/StatsGrid/WinsPanel/VBox/Value

func _ready():
	_setup_button_style(back_btn)
	back_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/menu/MainMenu.tscn")
	)
	_update_ui()
	
func _update_ui():
	name_lbl.text = PlayerProfileManager.player_name.to_upper()
	if ResourceLoader.exists(PlayerProfileManager.active_avatar_path):
		avatar_icon.texture = load(PlayerProfileManager.active_avatar_path)
	else:
		avatar_icon.texture = null
		
	# Placeholder for stats until persistence is implemented
	matches_lbl.text = "0"
	wins_lbl.text = "0"

func _setup_button_style(btn: Button):
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		create_tween().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
