extends Control

@onready var play_btn = $DashboardMargin/HBoxContainer/PlayBtnContainer/PlayNowBtn
@onready var boards_btn = $DashboardMargin/HBoxContainer/VBoxContainer/BoardsBtnContainer/BoardsBtn
@onready var exit_btn = $DashboardMargin/HBoxContainer/VBoxContainer/ExitBtnContainer/ExitBtn

func _ready():
	if not PlayerProfileManager.is_created:
		var modal = load("res://scenes/ui/ProfileCreationModal.tscn").instantiate()
		add_child(modal)
		# Wait a frame for onready
		await get_tree().process_frame
		modal.open_modal()
		
	_setup_button(play_btn)
	_setup_button(boards_btn)
	_setup_button(exit_btn)
	
	play_btn.pressed.connect(_on_play_pressed)
	boards_btn.pressed.connect(_on_boards_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	play_btn.focus_neighbor_right = boards_btn.get_path()
	boards_btn.focus_neighbor_left = play_btn.get_path()
	boards_btn.focus_neighbor_bottom = exit_btn.get_path()
	exit_btn.focus_neighbor_left = play_btn.get_path()
	exit_btn.focus_neighbor_top = boards_btn.get_path()
	play_btn.grab_focus()

	if has_node("/root/YouTubePlayablesBridge"):
		get_node("/root/YouTubePlayablesBridge").notify_game_ready()

func _setup_button(btn: Button):
	btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
	btn.focus_entered.connect(_on_btn_hover.bind(btn, true))
	btn.focus_exited.connect(_on_btn_hover.bind(btn, false))

func _on_btn_hover(btn: Button, is_hovered: bool):
	var style = btn.get_theme_stylebox("normal").duplicate()
	var target_scale = Vector2(1.05, 1.05) if is_hovered else Vector2(1.0, 1.0)
	var target_color = Color("#ffcc00") if is_hovered else Color("#00ffcc")
	
	style.border_color = target_color
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("focus", style)
	
	var tween = create_tween()
	tween.tween_property(btn, "scale", target_scale, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_play_pressed():
	AudioManager.play_button_sound()
	GameManager.goto_scene("res://scenes/mode/GameMode.tscn")

func _on_boards_pressed():
	AudioManager.play_button_sound()
	GameManager.goto_scene("res://scenes/boards/BoardSelection.tscn")

func _on_exit_pressed():
	AudioManager.play_button_sound()
	get_tree().quit()
