extends MarginContainer

@onready var avatar_btn = $GlassBackground/MarginContainer/HBoxContainer/AvatarButton
@onready var player_name_lbl = $GlassBackground/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var level_lbl = $GlassBackground/MarginContainer/HBoxContainer/VBoxContainer/LevelLabel

func _ready() -> void:
	PlayerProfileManager.profile_updated.connect(_on_profile_updated)
	_update_ui()
	
	avatar_btn.pressed.connect(_open_avatar_modal)
	avatar_btn.pivot_offset = avatar_btn.custom_minimum_size / 2.0
	
	# Add hover scaling for AvatarButton
	avatar_btn.mouse_entered.connect(func():
		create_tween().tween_property(avatar_btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
	)
	avatar_btn.mouse_exited.connect(func():
		create_tween().tween_property(avatar_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	)

func _update_ui() -> void:
	player_name_lbl.text = PlayerProfileManager.player_name
	if level_lbl:
		level_lbl.text = PlayerProfileManager.expertise_area.to_upper()
		
	if ResourceLoader.exists(PlayerProfileManager.active_avatar_path):
		avatar_btn.texture_normal = load(PlayerProfileManager.active_avatar_path)
	else:
		avatar_btn.texture_normal = null

func _on_profile_updated(path: String, p_name: String) -> void:
	_update_ui()

func _open_avatar_modal() -> void:
	AudioManager.play_button_sound()
	var modal_scene = load("res://scenes/ui/AvatarSelectionModal.tscn")
	if modal_scene:
		var modal = modal_scene.instantiate()
		get_tree().root.add_child(modal)
		# Allow a frame to pass so onready variables inside modal populate
		await get_tree().process_frame
		if modal.has_method("open_modal"):
			modal.open_modal()
