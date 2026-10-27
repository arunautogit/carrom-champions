extends Node

signal profile_updated(avatar_path: String, player_name: String)

const SAVE_PATH = "user://player_profile.json"

var player_name: String = "Player 1"
var expertise_area: String = "Balanced"
var is_created: bool = false
var active_avatar_id: String = "ravi"
var active_avatar_path: String = "res://assets/avatars/level1_ravi.png"
var unlocked_avatars: Array = ["human_01", "human_02", "human_03", "human_04", "human_05", "human_06"]

func _ready() -> void:
	load_profile()

func set_avatar(avatar_id: String, path: String) -> void:
	active_avatar_id = avatar_id
	active_avatar_path = path
	save_profile()
	profile_updated.emit(active_avatar_path, player_name)

func save_profile() -> void:
	var data = {
		"player_name": player_name,
		"expertise_area": expertise_area,
		"is_created": is_created,
		"active_avatar_id": active_avatar_id,
		"active_avatar_path": active_avatar_path,
		"unlocked_avatars": unlocked_avatars
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			player_name = parsed.get("player_name", player_name)
			expertise_area = parsed.get("expertise_area", expertise_area)
			is_created = parsed.get("is_created", is_created)
			active_avatar_id = parsed.get("active_avatar_id", active_avatar_id)
			active_avatar_path = parsed.get("active_avatar_path", active_avatar_path)
			unlocked_avatars = parsed.get("unlocked_avatars", unlocked_avatars)
		file.close()
