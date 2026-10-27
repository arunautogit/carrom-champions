extends Control

@onready var grid = $MarginContainer/ScrollContainer/GridContainer
@onready var back_btn = $MarginContainer/TopBar/BackButton

func _ready():
	$MarginContainer.move_child($MarginContainer/TopBar, -1)
	back_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/mode/GameMode.tscn")
	)
	
	_populate_grid()

func _populate_grid():
	# Clear grid
	for child in grid.get_children():
		child.queue_free()
		
	var AIProfileData = load("res://scripts/ui/ai_profile_data.gd")
	var profiles = AIProfileData.PROFILES
	
	var highest_unlocked = GameManager.highest_unlocked_ai_level
	
	for profile in profiles:
		var card = PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		card.custom_minimum_size = Vector2(300, 450)
		
		# Inner Margin
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		card.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 15)
		margin.add_child(vbox)
		
		# Avatar
		var avatar = TextureRect.new()
		avatar.custom_minimum_size = Vector2(150, 150)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if profile.has("avatar_path") and ResourceLoader.exists(profile["avatar_path"]):
			avatar.texture = load(profile["avatar_path"])
		vbox.add_child(avatar)
		
		# Name
		var name_lbl = Label.new()
		name_lbl.text = profile["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 32)
		vbox.add_child(name_lbl)
		
		# Tier
		var tier_lbl = Label.new()
		tier_lbl.text = profile["tier_name"]
		tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_lbl.add_theme_font_size_override("font_size", 24)
		tier_lbl.add_theme_color_override("font_color", Color(profile["tier_color"]))
		vbox.add_child(tier_lbl)
		
		var is_unlocked = profile["default_unlocked"] or profile["level"] <= highest_unlocked
		
		if not is_unlocked:
			card.modulate = Color(0.5, 0.5, 0.5, 0.8)
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒 LEVEL " + str(profile["level"]) + " REQ"
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			vbox.add_child(lock_lbl)
		else:
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			card.gui_input.connect(_on_card_input.bind(card, profile))
			
			card.mouse_entered.connect(func():
				AudioManager.play_hover_sound()
				var t = create_tween()
				t.tween_property(card, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_SINE)
			)
			card.mouse_exited.connect(func():
				var t = create_tween()
				t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
			)
			card.pivot_offset = card.custom_minimum_size / 2.0
		
		grid.add_child(card)

func _on_card_input(event: InputEvent, card: Control, profile: Dictionary):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		AudioManager.play_button_sound()
		_open_detail_modal(profile)

func _open_detail_modal(profile: Dictionary):
	var modal_scene = load("res://scenes/ui/AICharacterDetailModal.tscn")
	var modal = modal_scene.instantiate()
	modal.setup(profile)
	add_child(modal)
