extends Node

var current_scene = null

var last_match_winner_name = ""
var last_match_winner_score = 0
var last_match_scores = {}
var last_match_players = {}
var last_level_unlocked_msg = ""

var highest_unlocked_ai_level = 1
var match_settings = {
	2: {"type": "ai", "level": 1, "ai_profile_id": "ravi"},
	3: {"type": "human", "level": 1},
	4: {"type": "human", "level": 1}
}

var is_career_mode = false
var is_ai_levels_mode = false
var is_magnetic_mode = false
var is_stone_mode = false
var is_bomber_mode = false
var is_tagcoins_mode = false
var is_coin_breaker_mode = false

const SAVE_PATH = "user://carrom_save.json"

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	load_progression()

func save_progression():
	var save_data = {
		"highest_unlocked_ai_level": highest_unlocked_ai_level
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_progression():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data_string = file.get_as_text()
			var json = JSON.new()
			if json.parse(data_string) == OK:
				var data = json.get_data()
				if typeof(data) == TYPE_DICTIONARY and data.has("highest_unlocked_ai_level"):
					highest_unlocked_ai_level = data["highest_unlocked_ai_level"]
			file.close()

func unlock_next_level(current_beaten_level: int):
	if current_beaten_level >= highest_unlocked_ai_level and highest_unlocked_ai_level < 5:
		highest_unlocked_ai_level = current_beaten_level + 1
		save_progression()

func goto_scene(path: String):
	UIManager.transition_to_scene(path)

func _deferred_goto_scene(path: String):
	current_scene.free()
	var s = ResourceLoader.load(path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
