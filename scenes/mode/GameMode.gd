extends Control

@onready var scroll = $SafeMargin/ScrollContainer
@onready var hbox = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer
@onready var btn_player = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer/BtnPlayerMatch
@onready var btn_ai = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer/BtnAILevels
@onready var btn_fun = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer/BtnFunMode
@onready var back_btn = $BackBtn

var scroll_tween: Tween

func _ready():
	_setup_card(btn_player)
	_setup_card(btn_ai)
	_setup_card(btn_fun)
	
	btn_player.pressed.connect(_on_player_match_pressed)
	btn_ai.pressed.connect(_on_ai_levels_pressed)
	btn_fun.pressed.connect(_on_fun_mode_pressed)
	back_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/menu/MainMenu.tscn")
	)
	
	# Navigation linking
	btn_player.focus_neighbor_right = btn_ai.get_path()
	btn_ai.focus_neighbor_left = btn_player.get_path()
	btn_ai.focus_neighbor_right = btn_fun.get_path()
	btn_fun.focus_neighbor_left = btn_ai.get_path()
	
	btn_player.focus_neighbor_top = back_btn.get_path()
	btn_ai.focus_neighbor_top = back_btn.get_path()
	btn_fun.focus_neighbor_top = back_btn.get_path()
	back_btn.focus_neighbor_bottom = btn_player.get_path()
	
	btn_player.grab_focus()

func _setup_card(btn: Button):
	btn.focus_entered.connect(_on_card_focus.bind(btn))
	btn.mouse_entered.connect(func(): btn.grab_focus())
	
func _on_card_focus(btn: Button):
	var target_scale = Vector2(1.05, 1.05)
	
	# Reset others
	for child in hbox.get_children():
		if child is Button:
			if child != btn:
				create_tween().tween_property(child, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC)
	
	# Scale focused
	create_tween().tween_property(btn, "scale", target_scale, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Scroll LERP
	if scroll_tween and scroll_tween.is_valid():
		scroll_tween.kill()
		
	# Calculate target scroll value to center the button
	var btn_center_x = btn.position.x + btn.size.x / 2.0
	var scroll_target = btn_center_x - (scroll.size.x / 2.0)
	scroll_target = clamp(scroll_target, 0, max(0, hbox.size.x - scroll.size.x))
	
	scroll_tween = create_tween()
	scroll_tween.tween_property(scroll, "scroll_horizontal", scroll_target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_player_match_pressed():
	AudioManager.play_button_sound()
	# Set 2 players
	GameManager.match_settings = {
		1: {"type": "human"},
		2: {"type": "human"}
	}
	GameManager.set("is_magnetic_mode", false)
	GameManager.set("is_stone_mode", false)
	GameManager.set("is_bomber_mode", false)
	GameManager.set("is_tagcoins_mode", false)
	GameManager.set("is_coin_breaker_mode", false)
	GameManager.goto_scene("res://scenes/setup/MatchSetup.tscn")

func _on_ai_levels_pressed():
	AudioManager.play_button_sound()
	GameManager.goto_scene("res://scenes/ui/AIChallengerSelect.tscn")

func _on_fun_mode_pressed():
	AudioManager.play_button_sound()
	GameManager.goto_scene("res://scenes/mode/FunMode.tscn")
