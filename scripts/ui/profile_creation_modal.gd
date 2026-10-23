extends Control

@onready var name_input = $ModalFrame/Margin/VBox/HBox/FormVBox/NameInput
@onready var expertise_dropdown = $ModalFrame/Margin/VBox/HBox/FormVBox/ExpertiseDropdown
@onready var avatar_grid = $ModalFrame/Margin/VBox/HBox/FormVBox/AvatarScroll/AvatarGrid
@onready var preview_rect = $ModalFrame/Margin/VBox/HBox/PreviewVBox/PreviewRect
@onready var save_btn = $ModalFrame/Margin/VBox/SaveBtn

var avatar_catalog: Array[Dictionary] = []

var selected_avatar_data: Dictionary

func _ready() -> void:
	save_btn.pressed.connect(_on_save_pressed)
	
	var all_ai = AIProfiles.get_all_profiles()
	for p in all_ai:
		avatar_catalog.append({
			"id": p["id"],
			"name": p["name"],
			"path": "res://assets/avatars/level" + str(p.get("level", 1)) + "_" + p["id"] + ".png"
		})
		
	populate_grid()
	
	name_input.text = PlayerProfileManager.player_name
	
	# Select expertise
	for i in range(expertise_dropdown.item_count):
		if expertise_dropdown.get_item_text(i) == PlayerProfileManager.expertise_area:
			expertise_dropdown.select(i)
			break

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
			break

func _on_save_pressed() -> void:
	AudioManager.play_button_sound()
	
	var txt = name_input.text.strip_edges()
	if txt != "":
		PlayerProfileManager.player_name = txt
		
	PlayerProfileManager.expertise_area = expertise_dropdown.get_item_text(expertise_dropdown.selected)
	
	if not selected_avatar_data.is_empty():
		PlayerProfileManager.active_avatar_id = selected_avatar_data["id"]
		PlayerProfileManager.active_avatar_path = selected_avatar_data["path"]
		
	PlayerProfileManager.is_created = true
	PlayerProfileManager.save_profile()
	PlayerProfileManager.profile_updated.emit(PlayerProfileManager.active_avatar_path, PlayerProfileManager.player_name)
	
	hide()
	queue_free()
