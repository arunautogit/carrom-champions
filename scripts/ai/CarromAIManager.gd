extends Node
class_name CarromAIManager


static func calculate_shot(game: Node, ai_profile_id: String) -> Dictionary:
	var profile = AIProfiles.get_profile(ai_profile_id)
	if profile.is_empty():
		return {}
		
	var evaluator = AIShotEvaluator.new()
	var memory = AIPlayerMemory.new()
	var result = evaluator.evaluate(game, profile, memory)
	return result
