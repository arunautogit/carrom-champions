extends RefCounted
class_name AICareerProgress

const SAVE_PATH = "user://carrom_ai_progress.json"

static var career_order = [
	"ravi", "karthik", "arjun",
	"vikram", "nikhil", "surya",
	"dev", "ajay", "manoj",
	"raj", "vishal", "aditya",
	"aryan", "kabir", "veer"
]

var data = {}

func _init():
	load_progress()

func load_progress():
	if not FileAccess.file_exists(SAVE_PATH):
		_create_default()
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			data = json.data
			if not data.has("highest_unlocked_index"):
				data["highest_unlocked_index"] = 0
			else:
				data["highest_unlocked_index"] = int(data["highest_unlocked_index"])
			if not data.has("completed_ai_ids"):
				data["completed_ai_ids"] = []
		else:
			_create_default()
		file.close()
	else:
		_create_default()

func _create_default():
	data = {
		"highest_unlocked_index": 0,
		"completed_ai_ids": []
	}
	save_progress()

func save_progress():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func complete_ai(ai_id: String):
	if not data["completed_ai_ids"].has(ai_id):
		data["completed_ai_ids"].append(ai_id)
		
	var idx = career_order.find(ai_id)
	if idx >= 0 and idx == data["highest_unlocked_index"]:
		if idx + 1 < career_order.size():
			data["highest_unlocked_index"] = idx + 1
			GameManager.highest_unlocked_ai_level = AIProfiles.get_profile(career_order[idx + 1])["level"]
			
	save_progress()

func get_next_career_opponent() -> String:
	var idx = data["highest_unlocked_index"]
	if idx < career_order.size():
		return career_order[idx]
	return career_order[career_order.size() - 1]

func is_unlocked(ai_id: String) -> bool:
	var idx = career_order.find(ai_id)
	return idx <= data["highest_unlocked_index"]
