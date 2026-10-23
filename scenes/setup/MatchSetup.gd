extends Control


var player_count = 4
var unlocked_level = 1
var panels_hbox: HBoxContainer
var _card_style: StyleBoxFlat
var _focus_card_style: StyleBoxFlat

func _ready():
	_init_styles()
	
	for child in get_children():
		child.queue_free()
		
	var bg = ColorRect.new()
	bg.color = Color(0.067, 0.071, 0.082) # Deep Slate #111215
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 30)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "MATCH SETUP"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	unlocked_level = GameManager.highest_unlocked_ai_level
	var info = Label.new()
	info.text = "Highest AI Level Unlocked: " + str(unlocked_level) + " / 5"
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color(0, 1, 0.8)) # Cyan #00ffcc
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)
	
	var count_hbox = HBoxContainer.new()
	count_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	count_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(count_hbox)
	
	var count_label = Label.new()
	count_label.text = "Number of Players:"
	count_label.add_theme_font_size_override("font_size", 32)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1))
	count_hbox.add_child(count_label)
	
	var count_btn = OptionButton.new()
	count_btn.add_item("2 Players")
	count_btn.add_item("3 Players")
	count_btn.add_item("4 Players")
	
	var max_players = 4
	if SaveManager.get_setting("selected_board") == "ROUND BOARD":
		count_btn.add_item("5 Players")
		count_btn.add_item("6 Players")
		max_players = 6
		
	count_btn.custom_minimum_size = Vector2(200, 50)
	
	var num_opponents = GameManager.match_settings.size()
	player_count = clamp(num_opponents, 2, max_players)
	var dropdown_idx = player_count - 2
	count_btn.select(dropdown_idx)
		
	count_btn.item_selected.connect(func(idx):
		player_count = idx + 2
		_update_panels()
	)
	count_hbox.add_child(count_btn)
	
	if GameManager.is_ai_levels_mode:
		count_hbox.visible = false
		player_count = 2
	
	panels_hbox = HBoxContainer.new()
	panels_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panels_hbox.add_theme_constant_override("separation", 50)
	vbox.add_child(panels_hbox)
	
	_update_panels()
	
	var start_btn = Button.new()
	start_btn.text = "START MATCH"
	start_btn.custom_minimum_size = Vector2(300, 80)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.add_theme_font_size_override("font_size", 32)
	_setup_button_style(start_btn)
	start_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/game/CarromGame.tscn")
	)
	vbox.add_child(start_btn)
	
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(200, 60)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 24)
	_setup_button_style(back_btn)
	back_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/mode/GameMode.tscn")
	)
	vbox.add_child(back_btn)

func _init_styles():
	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color(0.067, 0.071, 0.082, 0.85)
	_card_style.border_color = Color(0, 1, 0.8, 0.5)
	_card_style.set_border_width_all(2)
	_card_style.set_corner_radius_all(12)
	
	_focus_card_style = _card_style.duplicate()
	_focus_card_style.border_color = Color(1, 0.8, 0, 1) # Gold
	_focus_card_style.shadow_color = Color(1, 0.8, 0, 0.3)
	_focus_card_style.shadow_size = 15

func _setup_button_style(btn: Button):
	btn.add_theme_stylebox_override("normal", _card_style)
	btn.add_theme_stylebox_override("hover", _focus_card_style)
	btn.add_theme_stylebox_override("focus", _focus_card_style)
	btn.add_theme_stylebox_override("pressed", _focus_card_style)
	
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)

func _update_panels():
	for child in panels_hbox.get_children():
		child.queue_free()
		
	var active_ids = []
	for i in range(2, player_count + 1):
		active_ids.append(i)
		
	var old_settings = GameManager.match_settings.duplicate()
	GameManager.match_settings.clear()
	
	for id in active_ids:
		if old_settings.has(id):
			GameManager.match_settings[id] = old_settings[id]
		else:
			GameManager.match_settings[id] = {"type": "ai", "level": 1}
			
		var panel = _create_player_panel(id, unlocked_level)
		panels_hbox.add_child(panel)

func _create_player_panel(player_id: int, unlocked_level: int) -> Control:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var label = Label.new()
	label.text = "PLAYER " + str(player_id)
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0, 1, 0.8)) # Cyan
	vbox.add_child(label)
	
	var type_btn = OptionButton.new()
	type_btn.add_item("Human")
	type_btn.add_item("AI")
	type_btn.custom_minimum_size = Vector2(240, 50)
	
	if GameManager.is_ai_levels_mode:
		GameManager.match_settings[player_id]["type"] = "ai"
		type_btn.select(1)
		type_btn.visible = false
	elif GameManager.match_settings[player_id]["type"] == "ai":
		type_btn.select(1)
	else:
		type_btn.select(0)
		
	vbox.add_child(type_btn)
	
	var ai_profile_btn = OptionButton.new()
	var career = AICareerProgress.new()
	var all_profiles = AIProfiles.get_all_profiles()
	
	for i in range(all_profiles.size()):
		var p = all_profiles[i]
		var txt = p["name"] + " (Lvl " + str(p["level"]) + ")"
		ai_profile_btn.add_item(txt)
		if not career.is_unlocked(p["id"]):
			ai_profile_btn.set_item_disabled(i, true)
			
	if not GameManager.match_settings[player_id].has("ai_profile_id"):
		GameManager.match_settings[player_id]["ai_profile_id"] = "ravi"
		
	var curr_profile = GameManager.match_settings[player_id]["ai_profile_id"]
	var p_idx = 0
	for i in range(all_profiles.size()):
		if all_profiles[i]["id"] == curr_profile:
			p_idx = i
			break
	ai_profile_btn.select(p_idx)
	ai_profile_btn.custom_minimum_size = Vector2(240, 50)
	vbox.add_child(ai_profile_btn)
	
	# HBox for Versus layout
	var vs_hbox = HBoxContainer.new()
	vs_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(vs_hbox)
	
	# Left: Avatar
	var avatar_bg = ColorRect.new()
	avatar_bg.custom_minimum_size = Vector2(100, 100)
	avatar_bg.color = Color(1, 0.8, 0, 1) # Gold
	
	var avatar_tex = TextureRect.new()
	avatar_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_bg.add_child(avatar_tex)
	vs_hbox.add_child(avatar_bg)
	
	# Right: Stats Box
	var stats_vbox = VBoxContainer.new()
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vs_hbox.add_child(stats_vbox)
	
	var ai_info_label = RichTextLabel.new()
	ai_info_label.custom_minimum_size = Vector2(200, 50)
	ai_info_label.bbcode_enabled = true
	ai_info_label.fit_content = true
	stats_vbox.add_child(ai_info_label)
	
	var power_lbl = Label.new()
	power_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	var accuracy_lbl = Label.new()
	accuracy_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	var rebound_lbl = Label.new()
	rebound_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	stats_vbox.add_child(power_lbl)
	stats_vbox.add_child(accuracy_lbl)
	stats_vbox.add_child(rebound_lbl)
	
	var update_ai_info = func():
		var sel_idx = ai_profile_btn.selected
		if sel_idx >= 0 and sel_idx < all_profiles.size():
			var p = all_profiles[sel_idx]
			ai_info_label.text = "[color=#00ffcc][b]" + p["nickname"] + "[/b][/color]\n[color=gray]" + p["specialty"] + "[/color]"
			# Procedurally generate stat bars based on level/params
			var lvl = p["level"]
			var pwr = clamp(50 + (lvl * 10) + (hash(p["id"]+"p") % 20), 0, 100)
			var acc = clamp(40 + (lvl * 12) + (hash(p["id"]+"a") % 20), 0, 100)
			var reb = clamp(30 + (lvl * 15) + (hash(p["id"]+"r") % 20), 0, 100)
			
			power_lbl.text = "Power: " + str(pwr) + "%"
			accuracy_lbl.text = "Accuracy: " + str(acc) + "%"
			rebound_lbl.text = "Rebound: " + str(reb) + "%"
			
			if p.has("avatar_path") and ResourceLoader.exists(p["avatar_path"]):
				avatar_tex.texture = load(p["avatar_path"])
			else:
				avatar_tex.texture = null
	
	update_ai_info.call()
	
	var update_visibility = func(idx):
		var is_ai = (idx == 1)
		ai_profile_btn.visible = is_ai
		vs_hbox.visible = is_ai
		GameManager.match_settings[player_id]["type"] = "ai" if is_ai else "human"
		
	type_btn.item_selected.connect(update_visibility)
	update_visibility.call(type_btn.selected)
	
	ai_profile_btn.item_selected.connect(func(idx):
		var p_id = all_profiles[idx]["id"]
		var p_lvl = all_profiles[idx]["level"]
		GameManager.match_settings[player_id]["ai_profile_id"] = p_id
		GameManager.match_settings[player_id]["level"] = p_lvl
		update_ai_info.call()
	)
	
	return card
