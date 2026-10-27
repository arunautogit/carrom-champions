extends RefCounted
class_name AIPlayerMemory

const SAVE_PATH = "user://carrom_ai_memory.json"
var memory_data = {}

func _init():
	load_memory()

func load_memory():
	if not FileAccess.file_exists(SAVE_PATH):
		_create_default()
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			memory_data = json.data
			if not memory_data.has("ai_memory"):
				_create_default()
		else:
			_create_default()
	else:
		_create_default()

func _create_default():
	memory_data = {
		"player_profile": {},
		"ai_memory": {}
	}
	save_memory()

func save_memory():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(memory_data)
		file.store_string(json_string)
		file.close()

func observe_shot(ai_profile_id: String, power: float, pocket_name: String):
	if ai_profile_id == "": return
	
	if not memory_data["ai_memory"].has(ai_profile_id):
		memory_data["ai_memory"][ai_profile_id] = {
			"average_power": {"value": 0.5, "confidence": 0.0, "sample_count": 0},
			"preferred_pocket": {"value": "", "confidence": 0.0, "sample_count": 0}
		}
		
	var mem = memory_data["ai_memory"][ai_profile_id]
	
	# Update Power if specified
	if power > 0.0:
		var pow_mem = mem["average_power"]
		pow_mem["sample_count"] += 1
		var weight = 1.0 / pow_mem["sample_count"]
		pow_mem["value"] = lerp(pow_mem["value"], power, weight)
		pow_mem["confidence"] = min(1.0, pow_mem["sample_count"] / 20.0)
	
	# Update Pocket if specified
	if pocket_name != "":
		var pock_mem = mem["preferred_pocket"]
		pock_mem["sample_count"] += 1
		pock_mem["value"] = pocket_name
		pock_mem["confidence"] = min(1.0, pock_mem["sample_count"] / 10.0)
		
	save_memory()
	
func get_ai_memory(ai_profile_id: String) -> Dictionary:
	if memory_data["ai_memory"].has(ai_profile_id):
		return memory_data["ai_memory"][ai_profile_id]
	return {}
