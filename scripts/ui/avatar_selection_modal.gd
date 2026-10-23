extends Control

var avatar_catalog: Array[Dictionary] = []

@onready var avatar_grid = $ModalFrame/MarginContainer/VBoxContainer/ContentSplit/ScrollContainer/AvatarGrid
@onready var preview_rect = $ModalFrame/MarginContainer/VBoxContainer/ContentSplit/PreviewSection/BigAvatarPreview
@onready var avatar_title = $ModalFrame/MarginContainer/VBoxContainer/ContentSplit/PreviewSection/SelectedAvatarTitle
@onready var equip_btn = $ModalFrame/MarginContainer/VBoxContainer/ContentSplit/PreviewSection/EquipButton
@onready var close_btn = $ModalFrame/MarginContainer/VBoxContainer/CloseModalBtn

var selected_avatar_data: Dictionary

func _ready() -> void:
	close_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		hide()
		queue_free()
	)
	equip_btn.pressed.connect(_on_equip_pressed)
	
	var all_ai = AIProfiles.get_all_profiles()
	for p in all_ai:
		avatar_catalog.append({
			"id": p["id"],
			"name": p["name"],
			"path": "res://assets/avatars/level" + str(p.get("level", 1)) + "_" + p["id"] + ".png"
		})
	
	populate_grid()

func open_modal() -> void:
	show()
	_select_avatar(PlayerProfileManager.active_avatar_id)

func populate_grid() -> void:
	for child in avatar_grid.get_children():
		child.queue_free()

	for item in avatar_catalog:
		var btn = TextureButton.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		if ResourceLoader.exists(item["path"]):
			btn.texture_normal = load(item["path"])
		else:
			# Fallback if image is missing
			var placeholder = ColorRect.new()
			placeholder.color = Color(0.3, 0.3, 0.3)
			placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
			placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(placeholder)
		
		btn.pressed.connect(func():
			AudioManager.play_button_sound()
			_select_avatar(item["id"])
		)
		avatar_grid.add_child(btn)

func _select_avatar(avatar_id: String) -> void:
	for item in avatar_catalog:
		if item["id"] == avatar_id:
			selected_avatar_data = item
			if ResourceLoader.exists(item["path"]):
				preview_rect.texture = load(item["path"])
			else:
				preview_rect.texture = null
			avatar_title.text = item["name"]
			equip_btn.disabled = (item["id"] == PlayerProfileManager.active_avatar_id)
			equip_btn.text = "EQUIPPED" if equip_btn.disabled else "EQUIP AVATAR"
			break

func _on_equip_pressed() -> void:
	AudioManager.play_button_sound()
	if selected_avatar_data.is_empty():
		return
	PlayerProfileManager.set_avatar(selected_avatar_data["id"], selected_avatar_data["path"])
	_select_avatar(selected_avatar_data["id"])
	hide()
	queue_free()
