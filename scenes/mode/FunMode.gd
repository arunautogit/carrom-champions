extends Control

@onready var scroll = $SafeMargin/ScrollContainer
@onready var hbox = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer
@onready var btn_magnet = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer/BtnMagnet
@onready var btn_stone = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer/BtnStone
@onready var btn_bomber = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer/BtnBomber
@onready var btn_tag = $SafeMargin/ScrollContainer/CenterWrapper/HBoxContainer/BtnTagCoins
@onready var back_btn = $BackBtn

var scroll_tween: Tween

func _ready():
	var cards = [btn_magnet, btn_stone, btn_bomber, btn_tag]
	
	for i in range(cards.size()):
		_setup_card(cards[i])
		if i > 0:
			cards[i].focus_neighbor_left = cards[i-1].get_path()
		if i < cards.size() - 1:
			cards[i].focus_neighbor_right = cards[i+1].get_path()
		cards[i].focus_neighbor_top = back_btn.get_path()
		
	back_btn.focus_neighbor_bottom = btn_magnet.get_path()
	
	btn_magnet.pressed.connect(_on_mode_selected.bind("magnet"))
	btn_stone.pressed.connect(_on_mode_selected.bind("stone"))
	btn_bomber.pressed.connect(_on_mode_selected.bind("bomber"))
	btn_tag.pressed.connect(_on_mode_selected.bind("tagcoins"))
	
	back_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/mode/GameMode.tscn")
	)
	
	btn_magnet.grab_focus()

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
		
	# Calculate target scroll value
	var btn_center_x = btn.position.x + btn.size.x / 2.0
	var scroll_target = btn_center_x - (scroll.size.x / 2.0)
	scroll_target = clamp(scroll_target, 0, max(0, hbox.size.x - scroll.size.x))
	
	scroll_tween = create_tween()
	scroll_tween.tween_property(scroll, "scroll_horizontal", scroll_target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_mode_selected(mode: String):
	AudioManager.play_button_sound()
	GameManager.match_settings = {
		1: {"type": "human"},
		2: {"type": "human"}
	}
	GameManager.set("is_magnetic_mode", mode == "magnet")
	GameManager.set("is_stone_mode", mode == "stone")
	GameManager.set("is_bomber_mode", mode == "bomber")
	GameManager.set("is_tagcoins_mode", mode == "tagcoins")
	GameManager.set("is_coin_breaker_mode", mode == "coin_breaker")
	
	GameManager.goto_scene("res://scenes/setup/MatchSetup.tscn")
