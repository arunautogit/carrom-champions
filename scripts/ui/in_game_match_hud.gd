extends Control

@onready var p1_score_lbl = $SafeMarginContainer/TopLeftBanner/HBox/VBox/P1_ScoreLabel
@onready var p2_score_lbl = $SafeMarginContainer/TopRightBanner/HBox/VBox/P2_ScoreLabel
@onready var ai_status_lbl = $SafeMarginContainer/TopRightBanner/HBox/VBox/AI_StateHBox/StatusLabel
@onready var ai_learning_dot = $SafeMarginContainer/TopRightBanner/HBox/VBox/AI_StateHBox/LearningIndicator
@onready var turn_banner = $SafeMarginContainer/CenterFieldZone/TurnTransitionBanner
@onready var turn_label = $SafeMarginContainer/CenterFieldZone/TurnTransitionBanner/Label
@onready var modes_container = $SafeMarginContainer/TopCenterTimerBar/ActiveModesStack
@onready var striker_slider = get_node_or_null("SafeMarginContainer/BottomDashboard/DashHBox/StrikerSlider")
@onready var zoom_slider = $SafeMarginContainer/LeftControlZone/ZoomSliderContainer/VSlider
@onready var change_striker_btn = $SafeMarginContainer/BottomDashboard/DashHBox/ChangeStrikerButton
@onready var pause_btn = $SafeMarginContainer/BottomDashboard/DashHBox/PauseButton
@onready var end_btn = $SafeMarginContainer/BottomDashboard/DashHBox/EndMatchButton
@onready var p1_name_lbl = $SafeMarginContainer/TopLeftBanner/HBox/VBox/P1_NameLabel
@onready var p1_avatar = $SafeMarginContainer/TopLeftBanner/HBox/AvatarWrapper/AvatarIcon
@onready var p2_name_lbl = $SafeMarginContainer/TopRightBanner/HBox/VBox/P2_NameLabel
@onready var p2_avatar = $SafeMarginContainer/TopRightBanner/HBox/AvatarWrapper/AvatarIcon

var active_mode_pills: Dictionary = {}
var banner_tween: Tween
var player_scores = {1: 0, 2: 0}
var extra_score_labels = {}

func _ready() -> void:
	turn_banner.modulate.a = 0.0
	turn_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_p1_avatar()
	PlayerProfileManager.profile_updated.connect(func(_p, _n): _update_p1_avatar())
	
	zoom_slider.max_value = 1.0
	zoom_slider.step = 0.01
	
	# Navigation Matrix
	pause_btn.focus_neighbor_right = end_btn.get_path()
	end_btn.focus_neighbor_left = pause_btn.get_path()

func _update_p1_avatar() -> void:
	if ResourceLoader.exists(PlayerProfileManager.active_avatar_path) and p1_avatar:
		p1_avatar.texture = load(PlayerProfileManager.active_avatar_path)
	if p1_name_lbl:
		p1_name_lbl.text = PlayerProfileManager.player_name.to_upper()

func setup_p2(profile: Dictionary):
	if profile.has("name") and p2_name_lbl:
		p2_name_lbl.text = profile["name"].to_upper() + " (AI)"
		var color = Color(profile.get("tier_color", "#FFFFFF"))
		p2_name_lbl.add_theme_color_override("font_color", color)
	elif p2_name_lbl:
		p2_name_lbl.text = "PLAYER 2 (AI)"
	if profile.has("avatar_path") and ResourceLoader.exists(profile["avatar_path"]) and p2_avatar:
		p2_avatar.texture = load(profile["avatar_path"])
	elif p2_avatar:
		p2_avatar.texture = null


func update_score(p_id: int, score: int):
	player_scores[p_id] = score
	var txt = "%02d" % score
	if p_id == 1:
		if p1_score_lbl: p1_score_lbl.text = txt
	elif p_id == 2:
		if p2_score_lbl: p2_score_lbl.text = txt
	else:
		# Double check that this player is actually in the match!
		if p_id != 1 and not GameManager.match_settings.has(p_id):
			return
			
		# For extra players (3-6), duplicate the banners and stack them downward
		if not extra_score_labels.has(p_id):
			var is_left = (p_id % 2 != 0) # P3, P5 go left. P4, P6 go right
			var source_banner
			if is_left:
				source_banner = $SafeMarginContainer/TopLeftBanner
			else:
				source_banner = $SafeMarginContainer/TopRightBanner
				
			if source_banner:
				var new_banner = source_banner.duplicate()
				$SafeMarginContainer.add_child(new_banner)
				
				# Calculate vertical offset based on player index (P3/P4 -> offset 1, P5/P6 -> offset 2)
				var offset_idx = (p_id - 1) / 2
				new_banner.position.y += 100 * offset_idx
				
				# Create a MarginContainer to safely position the new banner over the UI
				var margin_container = MarginContainer.new()
				margin_container.add_theme_constant_override("margin_top", 100 * offset_idx)
				if is_left:
					margin_container.add_theme_constant_override("margin_left", 0)
					margin_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				else:
					margin_container.add_theme_constant_override("margin_right", 0)
					margin_container.size_flags_horizontal = Control.SIZE_SHRINK_END
				margin_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				
				$SafeMarginContainer.add_child(margin_container)
				
				var panel = Panel.new()
				panel.custom_minimum_size = Vector2(250, 70)
				var style = source_banner.get_node("TrapezoidBg").get("theme_override_styles/panel").duplicate()
				panel.add_theme_stylebox_override("panel", style)
				margin_container.add_child(panel)
				
				var hbox = HBoxContainer.new()
				hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
				hbox.alignment = BoxContainer.ALIGNMENT_CENTER
				panel.add_child(hbox)
				
				var vbox = VBoxContainer.new()
				vbox.alignment = BoxContainer.ALIGNMENT_CENTER
				hbox.add_child(vbox)
				
				var name_lbl = Label.new()
				name_lbl.text = "PLAYER " + str(p_id)
				name_lbl.add_theme_font_size_override("font_size", 16)
				vbox.add_child(name_lbl)
				
				var score_lbl = Label.new()
				score_lbl.text = txt
				score_lbl.add_theme_font_size_override("font_size", 24)
				if is_left:
					score_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
				else:
					score_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.0))
				vbox.add_child(score_lbl)
				
				extra_score_labels[p_id] = score_lbl
		else:
			if extra_score_labels[p_id]:
				extra_score_labels[p_id].text = txt

func update_turn_indicator(player_name: String, is_ai: bool) -> void:
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()

	var display_name = player_name.to_upper()
	if turn_label:
		if is_ai:
			turn_label.text = "%s IS CALCULATING..." % display_name
		else:
			turn_label.text = "%s'S TURN" % display_name
	
	banner_tween = create_tween().set_parallel(false)
	banner_tween.tween_property(turn_banner, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	banner_tween.tween_interval(0.6)
	banner_tween.tween_property(turn_banner, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func register_or_update_mode_pill(mode_id: String, display_title: String, remaining_seconds: int, color_theme: Color, is_active_state: bool = false) -> void:
	var pill: HBoxContainer
	if not active_mode_pills.has(mode_id):
		pill = _create_mode_pill_node(mode_id)
		modes_container.add_child(pill)
		active_mode_pills[mode_id] = pill
	else:
		pill = active_mode_pills[mode_id]

	var title_lbl: Label = pill.get_node_or_null("TitleLabel")
	var time_lbl: Label = pill.get_node_or_null("TimeLabel")
	
	if title_lbl:
		title_lbl.text = display_title.to_upper()
	
	if time_lbl:
		if remaining_seconds > 0:
			time_lbl.text = str(remaining_seconds) + "s"
		else:
			time_lbl.text = "ON"
		
		time_lbl.add_theme_color_override("font_color", color_theme)
		time_lbl.add_theme_color_override("font_shadow_color", Color(color_theme, 0.4))

func remove_mode_pill(mode_id: String) -> void:
	if active_mode_pills.has(mode_id):
		var pill = active_mode_pills[mode_id]
		active_mode_pills.erase(mode_id)
		pill.queue_free()

func _create_mode_pill_node(mode_id: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.name = "Pill_" + mode_id
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	
	var title = Label.new()
	title.name = "TitleLabel"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	var timer = Label.new()
	timer.name = "TimeLabel"
	timer.add_theme_font_size_override("font_size", 32)
	timer.add_theme_constant_override("shadow_outline_size", 10)
	
	hbox.add_child(title)
	hbox.add_child(timer)
	return hbox

func set_ai_status(txt: String, learning: bool = false):
	if ai_status_lbl:
		ai_status_lbl.visible = true
		ai_status_lbl.text = txt
	if ai_learning_dot:
		ai_learning_dot.visible = learning
