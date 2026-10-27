extends Control

@onready var back_btn = $MarginContainer/TopBar/BackButton
@onready var sound_btn = $MarginContainer/CenterContainer/VBoxContainer/SoundPanel/Margin/HBox/SoundBtn
@onready var music_btn = $MarginContainer/CenterContainer/VBoxContainer/MusicPanel/Margin/HBox/MusicBtn
@onready var aim_btn = $MarginContainer/CenterContainer/VBoxContainer/AimPanel/Margin/HBox/AimBtn
@onready var vib_btn = $MarginContainer/CenterContainer/VBoxContainer/VibrationPanel/Margin/HBox/VibrationBtn

@onready var sound_panel = $MarginContainer/CenterContainer/VBoxContainer/SoundPanel
@onready var music_panel = $MarginContainer/CenterContainer/VBoxContainer/MusicPanel
@onready var aim_panel = $MarginContainer/CenterContainer/VBoxContainer/AimPanel
@onready var vib_panel = $MarginContainer/CenterContainer/VBoxContainer/VibrationPanel

func _ready():
	_setup_button_style(back_btn)
	
	_setup_hover(sound_panel)
	_setup_hover(music_panel)
	_setup_hover(aim_panel)
	_setup_hover(vib_panel)
	
	back_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/menu/MainMenu.tscn")
	)
	
	sound_btn.button_pressed = SaveManager.get_setting("sound_enabled")
	music_btn.button_pressed = SaveManager.get_setting("music_enabled")
	aim_btn.button_pressed = SaveManager.get_setting("aim_guide_enabled")
	vib_btn.button_pressed = SaveManager.get_setting("vibration_enabled")
	
	sound_btn.toggled.connect(func(pressed): SaveManager.set_setting("sound_enabled", pressed))
	music_btn.toggled.connect(func(pressed): SaveManager.set_setting("music_enabled", pressed))
	aim_btn.toggled.connect(func(pressed): SaveManager.set_setting("aim_guide_enabled", pressed))
	vib_btn.toggled.connect(func(pressed): SaveManager.set_setting("vibration_enabled", pressed))

func _setup_button_style(btn: Button):
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		create_tween().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)

func _setup_hover(panel: PanelContainer):
	panel.mouse_entered.connect(func():
		panel.pivot_offset = panel.size / 2.0
		create_tween().tween_property(panel, "scale", Vector2(1.02, 1.02), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Change stylebox to focus
		var style = panel.get_theme_stylebox("panel")
		if style:
			var new_style = style.duplicate()
			new_style.border_color = Color(1, 0.8, 0, 1) # Gold
			new_style.shadow_color = Color(1, 0.8, 0, 0.3)
			new_style.shadow_size = 15
			panel.add_theme_stylebox_override("panel", new_style)
	)
	
	panel.mouse_exited.connect(func():
		create_tween().tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		var style = panel.get_theme_stylebox("panel")
		if style:
			var new_style = style.duplicate()
			new_style.border_color = Color(0, 1, 0.8, 0.5) # Cyan
			new_style.shadow_size = 0
			panel.add_theme_stylebox_override("panel", new_style)
	)
