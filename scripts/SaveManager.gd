extends Node

const SAVE_PATH = "user://save_data.json"

var save_data = {
	"player_name": "ARUN",
	"selected_board": "NORMAL BOARD",
	"sound_enabled": true,
	"music_enabled": true,
	"vibration_enabled": true,
	"aim_guide_enabled": true,
	"auto_zoom_enabled": false,
	"graphics_quality": "HIGH",
	"stats": {
		"games": 25,
		"wins": 18,
		"losses": 7,
		"win_rate": 72
	},
	"achievements": ["FIRST VICTORY", "PERFECT SHOT", "QUEEN MASTER"]
}

func _ready():
	load_game()
	_init_cloud_save_sync()

func _init_cloud_save_sync():
	if has_node("/root/YouTubePlayablesBridge"):
		var bridge = get_node("/root/YouTubePlayablesBridge")
		bridge.cloud_data_loaded.connect(_on_cloud_data_loaded)
		bridge.load_cloud_data()

func _on_cloud_data_loaded(cloud_dict: Dictionary):
	for key in cloud_dict.keys():
		save_data[key] = cloud_dict[key]
	# Persist merged cloud data to local storage
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func save_game():
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		
	# Synchronize with YouTube Playables cloud storage
	if has_node("/root/YouTubePlayablesBridge"):
		get_node("/root/YouTubePlayablesBridge").save_cloud_data(json_string)

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK and typeof(json.data) == TYPE_DICTIONARY:
				var loaded_data = json.data
				# Merge loaded data with default keys in case of update
				for key in loaded_data.keys():
					save_data[key] = loaded_data[key]
			file.close()
	else:
		save_game() # create default file

func get_setting(key: String):
	if save_data.has(key):
		return save_data[key]
	return null

func set_setting(key: String, value):
	save_data[key] = value
	save_game()
