extends RefCounted
class_name AIShotEvaluator

const COIN_RADIUS = 0.09179
const STRIKER_RADIUS = 0.125
const BOARD_HALF = 0.74

func evaluate(game: Node, profile: Dictionary, memory: RefCounted) -> Dictionary:
	var current_player = game.current_player
	var board = game.get_node("SubViewportContainer/SubViewport/CarromBoard3D")
	if not board: return {}
	
	var pockets = board.get_node("Pockets").get_children()
	
	var is_queen_pending = false
	if "queen_pending" in game and game.queen_pending:
		is_queen_pending = true
	
	var target_group = "white_coins" if current_player % 2 != 0 else "black_coins"
	if is_queen_pending:
		# When queen is pocketed, we must pocket one of our own to cover it
		target_group = "white_coins" if current_player % 2 != 0 else "black_coins"
	
	var my_coins = []
	var all_coins = game.get_tree().get_nodes_in_group(target_group)
	for c in all_coins:
		if c.visible and not game.pending_rough_coins.has(c):
			my_coins.append(c)
			
	var queen = null
	var red_coins = game.get_tree().get_nodes_in_group("red_coin")
	if not red_coins.is_empty() and red_coins[0].visible:
		queen = red_coins[0]
		
	var valid_coins = []
	if is_queen_pending:
		valid_coins = my_coins
	elif queen != null:
		# Can target queen or own coins
		valid_coins = [queen]
		valid_coins.append_array(my_coins)
	else:
		valid_coins = my_coins
		
	if valid_coins.is_empty():
		return {}
		
	var bounds = game.player_striker_bounds[current_player]
	var baseline_dir = (bounds.right - bounds.left).normalized()
	var baseline_len = bounds.left.distance_to(bounds.right)
	
	var best_candidate = null
	var best_score = -99999.0
	
	var mem_data = {}
	if memory and memory.has_method("get_ai_memory"):
		mem_data = memory.get_ai_memory(profile["id"])
		
	for coin in valid_coins:
		for p in pockets:
			var coin_pos = coin.global_position
			var pocket_pos = p.global_position
			var pocket_name = p.name
			
			# 1. DIRECT SHOT CANDIDATE
			var dir_to_pocket = (pocket_pos - coin_pos).normalized()
			var impact_pos = coin_pos - dir_to_pocket * (COIN_RADIUS + STRIKER_RADIUS)
			
			var v = impact_pos - bounds.left
			var d = v.dot(baseline_dir)
			
			if d >= 0.0 and d <= baseline_len:
				var placement = bounds.left + baseline_dir * d
				placement.y = 0.081
				var dist = placement.distance_to(impact_pos) + coin_pos.distance_to(pocket_pos)
				
				var score = 100.0 - (dist * 10.0) # Base closeness score
				score += (profile.get("straight_shot_skill", 50) / 100.0) * 30.0
				
				if coin == queen:
					score += (profile.get("queen_strategy", 50) / 100.0) * 40.0
					
				# Adaptability / Memory: Slightly prioritize human's preferred pocket (if we want to block it, or if it seems to be an easier pocket)
				if mem_data.has("preferred_pocket"):
					var pp = mem_data["preferred_pocket"]
					if pp["value"] == pocket_name:
						# E.g., The human likes this pocket, maybe we score there too because it's open, or defend it.
						score += (profile.get("adaptability", 50) / 100.0) * pp["confidence"] * 5.0
						
				score += randf_range(-5.0, 5.0) * (1.0 - (profile.get("decision_quality", 50)/100.0))
				
				if score > best_score:
					best_score = score
					best_candidate = {
						"pos": placement,
						"drag": (impact_pos - placement).normalized(),
						"power": clamp(dist * 0.4, 0.5, 1.5),
						"type": "DIRECT"
					}
					
			# 2. BANK SHOT CANDIDATE (Simple approximation off left/right walls)
			for wall_x in [-BOARD_HALF, BOARD_HALF]:
				var reflected_pocket = pocket_pos
				reflected_pocket.x = wall_x + (wall_x - pocket_pos.x)
				
				var b_dir_to_pocket = (reflected_pocket - coin_pos).normalized()
				var b_impact_pos = coin_pos - b_dir_to_pocket * (COIN_RADIUS + STRIKER_RADIUS)
				
				var bv = b_impact_pos - bounds.left
				var bd = bv.dot(baseline_dir)
				
				if bd >= 0.0 and bd <= baseline_len:
					var placement = bounds.left + baseline_dir * bd
					placement.y = 0.081
					var dist = placement.distance_to(b_impact_pos) + coin_pos.distance_to(reflected_pocket)
					
					var score = 60.0 - (dist * 8.0) # Lower base score for banks
					score += (profile.get("bank_shot_skill", 50) / 100.0) * 40.0
					
					if coin == queen:
						score += (profile.get("queen_strategy", 50) / 100.0) * 20.0
						
					score += randf_range(-10.0, 10.0) * (1.0 - (profile.get("decision_quality", 50)/100.0))
					
					if score > best_score:
						best_score = score
						best_candidate = {
							"pos": placement,
							"drag": (b_impact_pos - placement).normalized(),
							"power": clamp(dist * 0.6, 0.7, 1.5),
							"type": "BANK"
						}
						
			# 3. DEFENSIVE CANDIDATE (Pushing coin towards center)
			if profile.get("defensive_skill", 50) > 30:
				var def_dir = (Vector3.ZERO - coin_pos).normalized()
				var def_impact = coin_pos - def_dir * (COIN_RADIUS + STRIKER_RADIUS)
				
				var dv = def_impact - bounds.left
				var dd = dv.dot(baseline_dir)
				
				if dd >= 0.0 and dd <= baseline_len:
					var placement = bounds.left + baseline_dir * dd
					placement.y = 0.081
					var dist = placement.distance_to(def_impact)
					
					var score = 40.0 - (dist * 5.0)
					score += (profile.get("defensive_skill", 50) / 100.0) * 30.0
					
					# Memory adaptation: if human uses high power, play more defensive
					if mem_data.has("average_power"):
						var ap = mem_data["average_power"]
						if ap["value"] > 0.8 and ap["confidence"] > 0.4:
							score += (profile.get("adaptability", 50) / 100.0) * 15.0
							
					score += randf_range(-5.0, 5.0) * (1.0 - (profile.get("decision_quality", 50)/100.0))
					
					if score > best_score:
						best_score = score
						best_candidate = {
							"pos": placement,
							"drag": (def_impact - placement).normalized(),
							"power": clamp(dist * 0.3, 0.4, 0.8),
							"type": "DEFENSIVE"
						}
						
	if best_candidate != null:
		# Controlled Error Model
		var error_magnitude = 1.0 - (profile.get("accuracy", 50) / 100.0)
		var max_angle_dev = 0.5 + (error_magnitude * 6.0) # Varies from ~0.5 to ~6.5 degrees max
		
		# Shot difficulty modifier
		if best_candidate["type"] == "BANK":
			max_angle_dev *= 1.5
		elif best_candidate["type"] == "DEFENSIVE":
			max_angle_dev *= 1.2
			
		# Risk modifier
		var risk_mod = profile.get("risk_tolerance", 50) / 100.0
		if best_candidate["type"] == "BANK":
			max_angle_dev *= (1.0 + (risk_mod * 0.5)) # High risk takers have more variance on banks
			
		var inaccuracy_rad = deg_to_rad(randf_range(-max_angle_dev, max_angle_dev))
		var final_drag = best_candidate["drag"].rotated(Vector3.UP, inaccuracy_rad)
		
		# Power Control Error
		var p_err_mag = 1.0 - (profile.get("power_control", 50) / 100.0)
		var power_mod = randf_range(1.0 - (p_err_mag * 0.25), 1.0 + (p_err_mag * 0.25))
		
		var final_power = best_candidate["power"] * power_mod
		
		return {
			"pos": best_candidate["pos"],
			"drag": final_drag * final_power
		}
		
	return {}
