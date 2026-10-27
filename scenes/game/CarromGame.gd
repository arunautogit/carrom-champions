extends Control


enum GameState { PLACING, MOVING, MAGNET_EVENT }
var current_state = GameState.PLACING
var rest_timer = 0.0
var turn_timer = 0.0

var magnet_timer = 180.0
var magnet_event_active = false
var magnet_ui_label: Label

var stone_mode_timer = 180.0 # 3 minutes
var active_stone_timer = 0.0
var stone_ui_label: Label

var bomber_ui_label: Label
var player_bomb_timers = {1: 120.0, 2: 120.0, 3: 120.0, 4: 120.0, 5: 120.0, 6: 120.0}
var player_bomb_penalties = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}

var tagcoins_ui_label: Label
var tagcoins_phase = 0
var tagcoins_timer = 240.0
var coin_tags = {}

var coin_breaker_ui_label: Label
var coin_breaker_phase = 0 # 0=Norm1, 1=Breaker, 2=Norm2, 3=Glue
var coin_breaker_timer = 180.0
var coins_hit_this_turn = []
var coin_breaker_player_colors = {1: "black", 2: "white", 3: "black", 4: "white", 5: "black", 6: "white"}

var player_scores = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
var current_player = 1
var scored_this_turn = false
var pending_rough_coins = []
var queen_pending = false
var pending_queen_node = null

var pocketed_white = 0
var pocketed_black = 0
var pocketed_red = 0
var stats_label: Label

var ai_state = 0
var ai_timer = 0.0
var ai_target_pos = Vector3.ZERO
var ai_target_drag = Vector3.ZERO
var ai_start_pos = Vector3.ZERO

var turn_pocketed_coins = []
var striker_fouled = false

var player_striker_bounds = {
	1: {"left": Vector3(-1.19, 0, 1.409), "right": Vector3(1.281, 0, 1.409)},
	2: {"left": Vector3(-1.38, 0, -1.21), "right": Vector3(-1.38, 0, 1.234)},
	3: {"left": Vector3(1.281, 0, -1.39), "right": Vector3(-1.22, 0, -1.39)},
	4: {"left": Vector3(1.404, 0, 1.214), "right": Vector3(1.404, 0, -1.21)}
}

var sfx_bgm: AudioStreamPlayer

func _ready():
	sfx_bgm = AudioStreamPlayer.new()
	var bgm_res = load("res://assets/audio/bgm_ambient.mp3")
	if bgm_res:
		if bgm_res is AudioStreamMP3:
			bgm_res.loop = true
		sfx_bgm.stream = bgm_res
	sfx_bgm.volume_db = -16.0
	sfx_bgm.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_bgm)
	if AudioManager.is_music_enabled():
		sfx_bgm.play()

	var num_players = GameManager.match_settings.size()
	if not GameManager.match_settings.has(1):
		num_players += 1
		
	if SaveManager.get_setting("selected_board") == "ROUND BOARD":
		# The user provided coordinates for the unscaled board.
		# Since the RoundBoard.tscn is scaled by 0.667, we apply the same scale here.
		var scale_factor = 0.667
		var spawn_points = [
			Vector3(0, 0, 3.132),
			Vector3(0, 0, -3.034),
			Vector3(2.677, 0, -1.468),
			Vector3(-2.677, 0, -1.468),
			Vector3(-2.648, 0, 1.55),
			Vector3(2.648, 0, 1.55)
		]
		
		player_striker_bounds.clear()
		for i in range(1, 7):
			var pos = spawn_points[i - 1] * scale_factor
			player_striker_bounds[i] = {"left": pos, "right": pos}
	else:
		if num_players == 2:
			player_striker_bounds[2] = {"left": Vector3(1.281, 0, -1.39), "right": Vector3(-1.22, 0, -1.39)} # Top

	var hud = $InGameMatchHUD
	var change_striker_btn = hud.change_striker_btn
	var pause_btn = hud.pause_btn
	var end_btn = hud.end_btn
	var overlay = $PauseOverlay
	
	change_striker_btn.pressed.connect(func():
		var current = SaveManager.get_setting("selected_striker")
		var num = 0
		if current:
			num = int(current.replace("Striker", ""))
		num = (num + 1) % 6
		SaveManager.set_setting("selected_striker", "Striker" + str(num))
		
		# Find the striker in the board and reload it
		var striker_node = $SubViewportContainer/SubViewport/CarromBoard3D/Striker
		if striker_node and striker_node.has_method("reload_mesh"):
			striker_node.reload_mesh()
	)
	
	var res_btn = $PauseOverlay/CenterContainer/VBoxContainer/ResumeBtn
	var rest_btn = $PauseOverlay/CenterContainer/VBoxContainer/RestartBtn
	var set_btn = $PauseOverlay/CenterContainer/VBoxContainer/SettingsBtn
	var menu_btn = $PauseOverlay/CenterContainer/VBoxContainer/MenuBtn
	var zoom_slider = hud.zoom_slider
	
	zoom_slider.value_changed.connect(func(val):
		var cam = $SubViewportContainer/SubViewport/CarromBoard3D/Camera3D
		if cam and cam.has_method("set_zoom_level"):
			cam.set_zoom_level(val)
	)
	
		
	pause_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		overlay.visible = true
	)
	
	end_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		end_match()
	)
	
	res_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		overlay.visible = false
	)
	
	rest_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/game/CarromGame.tscn")
	)
	
	set_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		# For this prototype we go to settings directly
		GameManager.goto_scene("res://scenes/settings/Settings.tscn")
	)
	
	menu_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/menu/MainMenu.tscn")
	)
	
	var striker = $SubViewportContainer/SubViewport/CarromBoard3D/Striker
	if striker:
		striker.striker_fired.connect(_on_striker_fired)
		if "current_bounds" in striker:
			striker.current_bounds = player_striker_bounds[current_player]
		
	refresh_pockets()
	
	_setup_hud()
	
	if GameManager.get("is_magnetic_mode"):
		$InGameMatchHUD.register_or_update_mode_pill("magnet", "Magnet", 180, Color(0.2, 0.6, 0.86))
		
	if GameManager.get("is_stone_mode"):
		$InGameMatchHUD.register_or_update_mode_pill("stone", "Stone in", 180, Color.WHITE)

	if GameManager.get("is_bomber_mode"):
		$InGameMatchHUD.register_or_update_mode_pill("bomber", "Bomber Active", 0, Color.ORANGE, true)

	if GameManager.get("is_tagcoins_mode"):
		$InGameMatchHUD.register_or_update_mode_pill("tagcoins", "Tagging Phase", 240, Color.CYAN)

	if GameManager.get("is_coin_breaker_mode"):
		$InGameMatchHUD.register_or_update_mode_pill("coinbreaker", "Normal Mode", 180, Color.WHITE)
				
	update_score_ui()
	update_turn_ui()
	update_stats_ui()

func refresh_pockets():
	var pockets = $SubViewportContainer/SubViewport/CarromBoard3D/Pockets
	if pockets:
		for pocket in pockets.get_children():
			if pocket is Area3D:
				if not pocket.coin_pocketed.is_connected(_on_coin_pocketed):
					pocket.coin_pocketed.connect(_on_coin_pocketed)

func _setup_hud():
	var active_players = [1]
	for k in GameManager.match_settings.keys():
		active_players.append(k)
	
	for p_id in active_players:
		var is_ai = GameManager.match_settings.has(p_id) and GameManager.match_settings[p_id]["type"] == "ai"
		
		if is_ai and p_id == 2:
			var ai_profile_id = GameManager.match_settings[p_id].get("ai_profile_id", "ravi")
			var AIProfileData = load("res://scripts/ui/ai_profile_data.gd")
			var profile = {}
			if AIProfileData:
				for p in AIProfileData.PROFILES:
					if p["id"] == ai_profile_id:
						profile = p
						break
			$InGameMatchHUD.setup_p2(profile)




func update_score_ui():
	var active_ids = [1]
	for k in GameManager.match_settings.keys():
		active_ids.append(k)
		
	for p_id in active_ids:
		if $InGameMatchHUD.has_method("update_score"):
			$InGameMatchHUD.update_score(p_id, player_scores.get(p_id, 0))

func get_player_display_name(p_id: int) -> String:
	if p_id == 1:
		return PlayerProfileManager.player_name
	if GameManager.match_settings.has(p_id) and GameManager.match_settings[p_id]["type"] == "ai":
		var ai_id = GameManager.match_settings[p_id].get("ai_profile_id", "")
		if ai_id != "":
			var p = AIProfiles.get_profile(ai_id)
			if not p.is_empty():
				return p["name"]
	return "PLAYER " + str(p_id)

func update_turn_ui():
	var p_name = get_player_display_name(current_player)
	var is_ai = GameManager.match_settings.has(current_player) and GameManager.match_settings[current_player]["type"] == "ai"
	if $InGameMatchHUD.has_method("update_turn_indicator"):
		$InGameMatchHUD.update_turn_indicator(p_name, is_ai)

func update_stats_ui():
	# Removed stats container references since it's not in the new HUD
	pass
func _on_striker_fired():
	current_state = GameState.MOVING
	var striker = $SubViewportContainer/SubViewport/CarromBoard3D/Striker
	
	if striker:
		striker.can_shoot = false
		
		# Record human shot for AI learning
		if GameManager.match_settings.has(current_player) and GameManager.match_settings[current_player]["type"] == "human":
			var power = min(1.0, striker.linear_velocity.length() / 20.0) # Approx max velocity
			var memory = AIPlayerMemory.new()
			# All AIs in this match observe the human
			for p_id in GameManager.match_settings:
				var config = GameManager.match_settings[p_id]
				if config["type"] == "ai" and config.has("ai_profile_id"):
					memory.observe_shot(config["ai_profile_id"], power, "")
			
	rest_timer = 0.0
	turn_timer = 0.0
	scored_this_turn = false
	striker_fouled = false
	turn_pocketed_coins.clear()
	coins_hit_this_turn.clear()
	
	# Check if we should activate cinematic mode
	var active_coins = 0
	var white_coins = get_tree().get_nodes_in_group("white_coins")
	var black_coins = get_tree().get_nodes_in_group("black_coins")
	var red_coin = get_tree().get_nodes_in_group("red_coin")
	
	var all_coins = []
	all_coins.append_array(white_coins)
	all_coins.append_array(black_coins)
	all_coins.append_array(red_coin)
	
	for c in all_coins:
		if c.visible and not pending_rough_coins.has(c) and not turn_pocketed_coins.has(c):
			active_coins += 1
			
	if active_coins == 1:
		var cam = $SubViewportContainer/SubViewport/CarromBoard3D/Camera3D
		if cam and cam.has_method("start_cinematic_mode"):
			cam.start_cinematic_mode(striker)

func _on_coin_pocketed(body, _pocket_name):
	if body.is_in_group("striker"):
		striker_fouled = true
	elif body.is_in_group("white_coins") or body.is_in_group("black_coins") or body.is_in_group("queen") or body.is_in_group("red_coin"):
		turn_pocketed_coins.append(body)
		body.visible = false
		body.freeze = true
		
		if GameManager.match_settings.has(current_player) and GameManager.match_settings[current_player]["type"] == "human":
			var memory = AIPlayerMemory.new()
			for p_id in GameManager.match_settings:
				var config = GameManager.match_settings[p_id]
				if config["type"] == "ai" and config.has("ai_profile_id"):
					memory.observe_shot(config["ai_profile_id"], 0.0, _pocket_name)
		
	# Delay score updating until turn ends to handle fouls correctly

func start_magnet_event():
	current_state = GameState.MAGNET_EVENT
	magnet_event_active = true
	magnet_timer = 20.0
	
	if magnet_ui_label:
		magnet_ui_label.text = "MAGNETIC MODE ACTIVATED!"
		magnet_ui_label.add_theme_color_override("font_color", Color.RED)
		
	var board = $SubViewportContainer/SubViewport/CarromBoard3D
	if board and board.has_method("trigger_magnet_event"):
		board.trigger_magnet_event()

func end_magnet_event():
	magnet_event_active = false
	magnet_timer = 120.0
	
	if magnet_ui_label:
		magnet_ui_label.add_theme_color_override("font_color", Color.WHITE)
		
	var board = $SubViewportContainer/SubViewport/CarromBoard3D
	if board and board.has_method("end_magnet_event"):
		board.end_magnet_event()
		
	_reset_turn()

func _process(delta):
	if GameManager.get("is_magnetic_mode"):
		magnet_timer -= delta
		if not magnet_event_active:
			$InGameMatchHUD.register_or_update_mode_pill("magnet", "Magnet", max(0, int(magnet_timer)), Color(0.2, 0.6, 0.86))
			
		if magnet_timer <= 0.0:
			if not magnet_event_active:
				start_magnet_event()
			else:
				end_magnet_event()
				
	if GameManager.get("is_stone_mode"):
		if stone_mode_timer > 0.0:
			stone_mode_timer -= delta
			$InGameMatchHUD.register_or_update_mode_pill("stone", "Stone in", max(0, int(stone_mode_timer)), Color.WHITE)
				
		if stone_mode_timer <= 0.0:
			active_stone_timer += delta
			if active_stone_timer >= 15.0:
				active_stone_timer = 0.0
				var board = $SubViewportContainer/SubViewport/CarromBoard3D
				if board and board.has_method("stone_pulse"):
					board.stone_pulse()
					
			$InGameMatchHUD.register_or_update_mode_pill("stone", "Stone", 0, Color.GRAY, true)

	if GameManager.get("is_bomber_mode"):
		var active_players = [1]
		for p in GameManager.match_settings.keys():
			active_players.append(p)
			
		for p in active_players:
			if player_bomb_penalties[p] == 0:
				player_bomb_timers[p] -= delta
				if player_bomb_timers[p] <= 0.0:
					player_bomb_timers[p] = 90.0
					player_bomb_penalties[p] = 10
					
					var board = $SubViewportContainer/SubViewport/CarromBoard3D
					if board:
						var bounds = player_striker_bounds[p]
						var spawn_pos = (bounds.left + bounds.right) / 2.0
						spawn_pos.y = 0.08
						
						var bomb_scene = load("res://assets/3dmodel/bombblast.glb")
						if bomb_scene:
							var bomb_inst = bomb_scene.instantiate()
							bomb_inst.global_position = spawn_pos
							# Scale up slightly if it's too small? 
							# bomb_inst.scale = Vector3(2, 2, 2)
							board.add_child(bomb_inst)
							
							var anim_player = null
							for child in bomb_inst.get_children():
								if child is AnimationPlayer:
									anim_player = child
									break
									
							if anim_player:
								var anim_list = anim_player.get_animation_list()
								if anim_list.size() > 0:
									anim_player.play(anim_list[0])
									anim_player.animation_finished.connect(func(_anim_name):
										if is_instance_valid(bomb_inst):
											bomb_inst.queue_free()
									)
								else:
									var t = get_tree().create_timer(2.0)
									t.timeout.connect(func(): if is_instance_valid(bomb_inst): bomb_inst.queue_free())
							else:
								var t = get_tree().create_timer(2.0)
								t.timeout.connect(func(): if is_instance_valid(bomb_inst): bomb_inst.queue_free())
								
						if board.has_method("_trigger_bomb_explosion"):
							board._trigger_bomb_explosion(spawn_pos)
						
		if bomber_ui_label and current_state != GameState.MOVING:
			var txt = ""
			for p in active_players:
				if player_bomb_penalties[p] > 0:
					txt += "P%d: Penalty(%d)  " % [p, player_bomb_penalties[p]]
				else:
					txt += "P%d Bomb: %ds  " % [p, int(player_bomb_timers[p])]
			bomber_ui_label.text = txt
			
		var all_penalized = true
		for p in active_players:
			if player_bomb_penalties[p] <= 0:
				all_penalized = false
				break
				
		if all_penalized:
			if not get_meta("game_over_triggered", false):
				set_meta("game_over_triggered", true)
				if bomber_ui_label:
					bomber_ui_label.text = "GAME OVER! NO PLAYERS REMAIN!"
					bomber_ui_label.add_theme_color_override("font_color", Color.RED)
				
				var t = get_tree().create_timer(2.5)
				t.timeout.connect(func():
					if is_inside_tree():
						GameManager.last_level_unlocked_msg = "GAME OVER! NO STRIKERS LEFT!"
						end_match()
				)
			return
			
	if GameManager.get("is_tagcoins_mode"):
		tagcoins_timer -= delta
		if tagcoins_timer <= 0:
			tagcoins_timer = 240.0
			tagcoins_phase = 1 if tagcoins_phase == 0 else 0
			
		if tagcoins_ui_label:
			var phase_str = "TAGGING PHASE" if tagcoins_phase == 0 else "POCKETING PHASE"
			tagcoins_ui_label.text = "%s: %ds" % [phase_str, int(tagcoins_timer)]
			if tagcoins_phase == 0:
				tagcoins_ui_label.add_theme_color_override("font_color", Color.CYAN)
			else:
				tagcoins_ui_label.add_theme_color_override("font_color", Color.ORANGE)

	if GameManager.get("is_coin_breaker_mode"):
		coin_breaker_timer -= delta
		if coin_breaker_timer <= 0:
			coin_breaker_phase = (coin_breaker_phase + 1) % 4
			if coin_breaker_phase == 0 or coin_breaker_phase == 2:
				coin_breaker_timer = 120.0 # Normal mode subsequent times
			elif coin_breaker_phase == 1:
				coin_breaker_timer = 60.0 # Breaker mode
			elif coin_breaker_phase == 3:
				coin_breaker_timer = 60.0 # Glue mode
		
		if coin_breaker_ui_label:
			if coin_breaker_phase == 0 or coin_breaker_phase == 2:
				coin_breaker_ui_label.text = "NORMAL MODE: %ds" % int(coin_breaker_timer)
				coin_breaker_ui_label.add_theme_color_override("font_color", Color.WHITE)
			elif coin_breaker_phase == 1:
				coin_breaker_ui_label.text = "BREAKER MODE: %ds" % int(coin_breaker_timer)
				coin_breaker_ui_label.add_theme_color_override("font_color", Color.RED)
			elif coin_breaker_phase == 3:
				coin_breaker_ui_label.text = "GLUE MODE: %ds" % int(coin_breaker_timer)
				coin_breaker_ui_label.add_theme_color_override("font_color", Color.GREEN)
				
		if coin_breaker_phase == 3 and coins_hit_this_turn.size() >= 2:
			var halves = []
			var normals = []
			for c in coins_hit_this_turn:
				if is_instance_valid(c):
					if c.is_in_group("half_coins"):
						halves.append(c)
					elif not c.is_in_group("glued_coins") and not c.is_in_group("queen"):
						normals.append(c)
			var glued_halves = []
			for h1 in halves:
				for h2 in halves:
					if h1 != h2 and not glued_halves.has(h1) and not glued_halves.has(h2):
						if (h1.is_in_group("black_coins") and h2.is_in_group("black_coins")) or (h1.is_in_group("white_coins") and h2.is_in_group("white_coins")):
							glue_coins(h1, h2)
							glued_halves.append(h1)
							glued_halves.append(h2)
							break
			var glued_normals = []
			for n1 in normals:
				for n2 in normals:
					if n1 != n2 and not glued_normals.has(n1) and not glued_normals.has(n2):
						glue_coins(n1, n2)
						glued_normals.append(n1)
						glued_normals.append(n2)
						break
			for c in glued_halves: coins_hit_this_turn.erase(c)
			for c in glued_normals: coins_hit_this_turn.erase(c)
				
	if current_state == GameState.MAGNET_EVENT:
		return
		
	if current_state == GameState.PLACING:
		if GameManager.match_settings.has(current_player) and GameManager.match_settings[current_player]["type"] == "ai":
			_process_ai(delta)
			
	elif current_state == GameState.MOVING:
		turn_timer += delta
		if turn_timer > 7.0:
			_reset_turn()
			return
			
		if _are_all_pieces_resting():
			rest_timer += delta
			if rest_timer > 0.5:
				_reset_turn()
		else:
			rest_timer = 0.0

func _process_ai(delta):
	var striker = $SubViewportContainer/SubViewport/CarromBoard3D/Striker
	if not striker or not is_instance_valid(striker): return
	
	if ai_state == 0: # WAITING
		ai_timer += delta
		if ai_timer > 0.5:
			ai_state = 1
			ai_timer = 0.0
			$InGameMatchHUD.set_ai_status("Calculating...", true)
			
	elif ai_state == 1: # DECIDING
		ai_timer += delta
		var think_time = 0.5
		if GameManager.match_settings.has(current_player):
			think_time = 0.5 + (GameManager.match_settings[current_player].get("level", 1) * 0.2)
			
		if ai_timer > think_time:
			_calculate_ai_shot()
			ai_state = 2
			ai_timer = 0.0
			ai_start_pos = striker.global_position
			update_turn_ui() # Reset text back to normal
			
			$InGameMatchHUD.set_ai_status("Positioning...", false)
		
	elif ai_state == 2: # POSITIONING
		ai_timer += delta
		var t = clamp(ai_timer / 0.5, 0.0, 1.0)
		striker.global_position = ai_start_pos.lerp(ai_target_pos, t)
		if t >= 1.0:
			ai_state = 3
			ai_timer = 0.0
			striker.is_aiming = true
			striker.ai_controlling = true
			
			$InGameMatchHUD.set_ai_status("Aiming...", false)
			
	elif ai_state == 3: # AIMING
		ai_timer += delta
		var t = clamp(ai_timer / 1.0, 0.0, 1.0)
		striker.ai_drag_vector = Vector3.ZERO.lerp(ai_target_drag, t)
		if t >= 1.0:
			ai_state = 0
			striker.execute_ai_shot()
			
			$InGameMatchHUD.set_ai_status("Waiting...", false)

func _calculate_ai_shot():
	# If player settings have ai_profile_id, use the new system
	if GameManager.match_settings.has(current_player):
		var player_config = GameManager.match_settings[current_player]
		if player_config.has("ai_profile_id") and player_config["ai_profile_id"] != "":
			var result = CarromAIManager.calculate_shot(self, player_config["ai_profile_id"])
			if result != null and not result.is_empty():
				ai_target_pos = result["pos"]
				ai_target_drag = result["drag"]
				return
				
	# Fallback if no profile ID, or if evaluator returns empty/fails
	_calculate_ai_shot_fallback()

func _calculate_ai_shot_fallback():
	var level = GameManager.match_settings[current_player]["level"]
	var max_angle_dev = 10.0 # Level 1
	if level == 2: max_angle_dev = 8.0
	if level == 3: max_angle_dev = 6.0
	if level == 4: max_angle_dev = 4.0
	if level == 5: max_angle_dev = 2.0
	
	var board = $SubViewportContainer/SubViewport/CarromBoard3D
	var pockets = board.get_node("Pockets").get_children()
	
	var target_group = "white_coins" if current_player % 2 != 0 else "black_coins"
	if GameManager.get("is_coin_breaker_mode"):
		target_group = "black_coins" if current_player % 2 != 0 else "white_coins"
		
	var all_coins = get_tree().get_nodes_in_group(target_group)
	var valid_coins = []
	for c in all_coins:
		if c.visible and not pending_rough_coins.has(c):
			valid_coins.append(c)
			
	if valid_coins.is_empty():
		valid_coins = get_tree().get_nodes_in_group("red_coin")
		
	if valid_coins.is_empty():
		var bounds = player_striker_bounds[current_player]
		var mid = (bounds.left + bounds.right) / 2.0
		mid.y = 0.081
		ai_target_pos = mid
		ai_target_drag = Vector3(0, 0, 1) * 1.5
		return
		
	var best_coin = null
	var best_pocket = null
	var min_dist = 999.0
	
	for coin in valid_coins:
		for p in pockets:
			var d = coin.global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				best_coin = coin
				best_pocket = p
				
	var coin_pos = best_coin.global_position
	var pocket_pos = best_pocket.global_position
	var dir_to_pocket = (pocket_pos - coin_pos).normalized()
	
	var impact_pos = coin_pos - dir_to_pocket * (0.09179 + 0.125)
	
	var bounds = player_striker_bounds[current_player]
	var baseline_dir = (bounds.right - bounds.left).normalized()
	var baseline_len = bounds.left.distance_to(bounds.right)
	
	var v = impact_pos - bounds.left
	var d = v.dot(baseline_dir)
	d = clamp(d, 0.0, baseline_len)
	var placement = bounds.left + baseline_dir * d
	placement.y = 0.081
	
	ai_target_pos = placement
	
	var shot_dir = (impact_pos - placement).normalized()
	var inaccuracy_rad = deg_to_rad(randf_range(-max_angle_dev, max_angle_dev))
	shot_dir = shot_dir.rotated(Vector3.UP, inaccuracy_rad)
	
	# Force multiplier is 80, max force is 120, so drag length 1.5 max
	var dist_to_impact = placement.distance_to(impact_pos)
	var power_needed = clamp(dist_to_impact * 0.5, 0.5, 1.5)
	ai_target_drag = shot_dir * power_needed

func _are_all_pieces_resting() -> bool:
	var board_node = $SubViewportContainer/SubViewport/CarromBoard3D
	if not board_node: return true
	for child in board_node.get_children():
		if child is RigidBody3D:
			if child.freeze or not is_instance_valid(child) or child.is_queued_for_deletion():
				continue
				
			# Check if the piece fell completely off the board geometry
			# Check if the piece fell off the board geometry
			var is_out_of_bounds = child.global_position.y < -0.2
			if abs(child.global_position.x) > 2.2 or abs(child.global_position.z) > 2.2:
				is_out_of_bounds = true
				
			if is_out_of_bounds:
				child.linear_velocity = Vector3.ZERO
				child.angular_velocity = Vector3.ZERO
				
				if child.is_in_group("striker"):
					child.freeze = true
					_on_coin_pocketed(child, "out_of_bounds")
				else:
					child.freeze = true
					child.visible = false
					if not pending_rough_coins.has(child):
						pending_rough_coins.append(child)
						update_stats_ui()
				continue
				
			if child.linear_velocity.length() > 0.05 or child.angular_velocity.length() > 0.05:
				return false
	return true

func _reset_turn():
	current_state = GameState.PLACING
	
	var cam = $SubViewportContainer/SubViewport/CarromBoard3D/Camera3D
	if cam and cam.has_method("stop_cinematic_mode"):
		cam.stop_cinematic_mode()
	
	if striker_fouled:
		player_scores[current_player] = max(0, player_scores[current_player] - 10)
		if queen_pending:
			queen_pending = false
			if is_instance_valid(pending_queen_node):
				if not pending_rough_coins.has(pending_queen_node):
					pending_rough_coins.append(pending_queen_node)
			pending_queen_node = null
			
		for coin in turn_pocketed_coins:
			if not pending_rough_coins.has(coin):
				pending_rough_coins.append(coin)
		turn_pocketed_coins.clear()
		scored_this_turn = false
	else:
		for coin in turn_pocketed_coins:
			var reject_coin = false
			if GameManager.get("is_tagcoins_mode"):
				if tagcoins_phase == 0:
					reject_coin = true
				else:
					if coin_tags.get(coin) != current_player:
						reject_coin = true
						
			if GameManager.get("is_coin_breaker_mode"):
				if coin.is_in_group("half_coins") or coin.is_in_group("glued_coins"):
					reject_coin = true
						
			if reject_coin:
				if not pending_rough_coins.has(coin):
					pending_rough_coins.append(coin)
				if coin.is_in_group("queen") or coin.is_in_group("red_coin"):
					if pending_queen_node == coin:
						queen_pending = false
						pending_queen_node = null
				continue
				
			if coin.is_in_group("black_coins") or coin.is_in_group("white_coins"):
				player_scores[current_player] += 10
				if coin.is_in_group("black_coins"):
					pocketed_black += 1
				else:
					pocketed_white += 1
					
				if queen_pending:
					queen_pending = false
					player_scores[current_player] += 50
					pocketed_red += 1
					if is_instance_valid(pending_queen_node):
						pending_queen_node.queue_free()
					pending_queen_node = null
				
				scored_this_turn = true
				if is_instance_valid(coin):
					coin.queue_free()
			elif coin.is_in_group("queen") or coin.is_in_group("red_coin"):
				queen_pending = true
				pending_queen_node = coin
				scored_this_turn = true
		turn_pocketed_coins.clear()
		
	update_score_ui()
	update_stats_ui()
	
	if pocketed_white + pocketed_black + pocketed_red == 19:
		end_match()
		return
		
	if GameManager.get("is_coin_breaker_mode"):
		if pocketed_black == 9:
			# Player 1 / 3 wins
			player_scores[1] += 1000 # ensure they win
			if GameManager.match_settings.has(3):
				player_scores[3] += 1000
			end_match()
			return
		elif pocketed_white == 9:
			# Player 2 / 4 wins
			if GameManager.match_settings.has(2):
				player_scores[2] += 1000
			if GameManager.match_settings.has(4):
				player_scores[4] += 1000
			end_match()
			return
	
	if not scored_this_turn:
		if queen_pending:
			queen_pending = false
			if is_instance_valid(pending_queen_node):
				if not pending_rough_coins.has(pending_queen_node):
					pending_rough_coins.append(pending_queen_node)
			pending_queen_node = null
			
		_advance_to_next_valid_player()
	else:
		scored_this_turn = false
		if GameManager.get("is_bomber_mode"):
			player_bomb_timers[current_player] = 90.0
		
	var board_node = $SubViewportContainer/SubViewport/CarromBoard3D
	var center_pos = Vector3(0, 0.000548, 0)
	if board_node and board_node.has_node("CoinFormationCenter"):
		center_pos = board_node.get_node("CoinFormationCenter").global_position
		
	for coin in pending_rough_coins:
		if is_instance_valid(coin):
			var new_transform = Transform3D(Basis(), center_pos + Vector3(0, 0, 0))
			PhysicsServer3D.body_set_state(coin.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, new_transform)
			coin.freeze = false
			coin.sleeping = false
			coin.visible = true
	pending_rough_coins.clear()
	update_stats_ui()
		
	var striker = $SubViewportContainer/SubViewport/CarromBoard3D/Striker
	
	ai_state = 0
	ai_timer = 0.0
	
	if striker:
		striker.freeze = false
		striker.visible = true
		striker.scale = Vector3.ONE
		
		striker.linear_velocity = Vector3.ZERO
		striker.angular_velocity = Vector3.ZERO
		
		var bounds = player_striker_bounds[current_player]
		var y = striker.global_position.y
		if y < 0.01:
			y = 0.081
		var mid_x = (bounds.left.x + bounds.right.x) / 2.0
		var mid_z = (bounds.left.z + bounds.right.z) / 2.0
		var reset_transform = Transform3D(Basis(), Vector3(mid_x, y, mid_z))
		striker.global_transform = reset_transform
		striker.can_shoot = true
		if "current_bounds" in striker:
			striker.current_bounds = bounds
			
	var pockets = $SubViewportContainer/SubViewport/CarromBoard3D/Pockets
	if pockets:
		for pocket in pockets.get_children():
			if pocket.has_method("reset_pocket"):
				pocket.reset_pocket()
				
	cam = $SubViewportContainer/SubViewport/CarromBoard3D/Camera3D
	if cam and cam.has_method("rotate_to_player"):
		cam.rotate_to_player(current_player)
		
	update_turn_ui()

func _advance_to_next_valid_player():
	while true:
		current_player += 1
		var max_p = 1
		for k in GameManager.match_settings.keys():
			if k > max_p: max_p = k
		if current_player > max_p:
			current_player = 1
		
		# Skip inactive players
		if current_player != 1 and not GameManager.match_settings.has(current_player):
			continue
			
		if GameManager.get("is_bomber_mode"):
			if player_bomb_penalties[current_player] > 0:
				player_bomb_penalties[current_player] -= 1
				continue # Skip this player's turn
				
		break

func end_match():
	var winner = 1
	var max_score = player_scores[1]
	for i in range(2, 7):
		if GameManager.match_settings.has(i) and player_scores[i] > max_score:
			max_score = player_scores[i]
			winner = i
			
	var winner_name = "PLAYER 1"
	GameManager.last_level_unlocked_msg = ""
	
	GameManager.last_match_scores = player_scores.duplicate()
	GameManager.last_match_players.clear()
	
	for i in range(1, 5):
		if i == 1 or GameManager.match_settings.has(i):
			GameManager.last_match_players[i] = get_player_display_name(i)
			
	if winner == 1:
		winner_name = GameManager.last_match_players[1]
		# If Player 1 wins, check if we played against an AI and update level
		if GameManager.get("is_career_mode"):
			var opp_id = GameManager.match_settings[2]["ai_profile_id"]
			var career = AICareerProgress.new()
			career.complete_ai(opp_id)
			GameManager.last_level_unlocked_msg = "Career Victory! Next AI unlocked!"
		else:
			var max_ai_level = 0
			var career = AICareerProgress.new()
			for i in range(2, 5):
				if GameManager.match_settings.has(i) and GameManager.match_settings[i]["type"] == "ai":
					max_ai_level = max(max_ai_level, GameManager.match_settings[i].get("level", 1))
					var opp_id = GameManager.match_settings[i].get("ai_profile_id", "")
					if opp_id != "":
						career.complete_ai(opp_id)
			if max_ai_level > 0:
				GameManager.unlock_next_level(max_ai_level)
				if GameManager.highest_unlocked_ai_level > max_ai_level and max_ai_level < 5:
					GameManager.last_level_unlocked_msg = "You unlocked AI Level " + str(max_ai_level + 1) + "!"
	else:
		winner_name = GameManager.last_match_players[winner]
		
	GameManager.last_match_winner_name = winner_name
	GameManager.last_match_winner_score = max_score
	GameManager.goto_scene("res://scenes/result/ResultScreen.tscn")

func tag_coin(coin, player_id):
	if coin_tags.has(coin):
		var old_p = coin_tags[coin]
		if old_p == player_id:
			return # already tagged by this player
			
	coin_tags[coin] = player_id
	
	var existing_tag = coin.get_node_or_null("TagVisual")
	if existing_tag:
		existing_tag.queue_free()
		
	var tag_scene = load("res://assets/3dmodel/tag.glb")
	if tag_scene:
		var tag_inst = tag_scene.instantiate()
		tag_inst.name = "TagVisual"
		tag_inst.position = Vector3(0, 0.08, 0) # Explicitly lifted higher
		tag_inst.scale = Vector3(0.033, 0.033, 0.033)
		coin.add_child(tag_inst)
		
		var colors = { 1: Color.RED, 2: Color.GREEN, 3: Color.YELLOW, 4: Color.CYAN }
		var mat = StandardMaterial3D.new()
		mat.albedo_color = colors.get(player_id, Color.RED)
		
		var meshes = tag_inst.find_children("*", "MeshInstance3D")
		for m in meshes:
			m.set_surface_override_material(0, mat)
			var aabb = m.get_aabb()
			var center = aabb.get_center()
			m.position = Vector3(m.position.x - center.x, m.position.y, m.position.z - center.z)

func break_coin(coin: RigidBody3D):
	if coin.is_in_group("half_coins"):
		return
		
	var is_black = coin.is_in_group("black_coins")
	var is_white = coin.is_in_group("white_coins")
	if not is_black and not is_white:
		return
		
	var is_glued = coin.is_in_group("glued_coins")
		
	var pos = coin.global_position
	var mat = load("res://assets/material/black.tres") if is_black else load("res://assets/material/white.tres")
	
	coin.queue_free()
	
	var board = get_node_or_null("SubViewportContainer/SubViewport/CarromBoard3D")
	if not board: return
	
	var half_scene = load("res://assets/3dmodel/halfcoin.glb") if not is_glued else (load("res://assets/3dmodel/Black.glb") if is_black else load("res://assets/3dmodel/white.glb"))
	
	for i in range(2):
		var half = RigidBody3D.new()
		half.mass = 0.5 if not is_glued else 1.0
		half.physics_material_override = load("res://assets/material/CarromCoinPhysicsMaterial.tres")
		half.linear_damp = 1.0
		half.angular_damp = 1.0
		half.contact_monitor = true
		half.max_contacts_reported = 4
		half.axis_lock_linear_y = true
		half.axis_lock_angular_x = true
		half.axis_lock_angular_z = true
		half.continuous_cd = true
		
		var col = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = (0.0917 * 0.7) / 5.0 if not is_glued else 0.0917
		cyl.height = 0.0311 / 5.0 if not is_glued else 0.0311
		col.shape = cyl
		col.position.y = 0.01503
		half.add_child(col)
		
		if half_scene:
			var visual = half_scene.instantiate()
			visual.position.y = -0.079855
			# Apply material only for halves since glued to normal already has material
			if not is_glued:
				visual.scale = Vector3(0.2, 0.2, 0.2)
				var meshes = visual.find_children("*", "MeshInstance3D")
				for m in meshes:
					m.set_surface_override_material(0, mat)
			half.add_child(visual)
			
		half.add_to_group("black_coins" if is_black else "white_coins")
		if not is_glued:
			half.add_to_group("half_coins")
		
		var dist = 0.06 if not is_glued else 0.12
		var offset = Vector3(dist if i == 0 else -dist, 0, 0)
		half.global_position = pos + offset
		
		board.add_child(half)
		if not half.body_entered.is_connected(board._on_coin_body_entered):
			half.body_entered.connect(board._on_coin_body_entered.bind(half))
			
		half.apply_central_impulse(offset.normalized() * 3.0)

func glue_coins(coin1: RigidBody3D, coin2: RigidBody3D):
	if not is_instance_valid(coin1) or not is_instance_valid(coin2): return
	
	var is_black = coin1.is_in_group("black_coins")
	var is_white = coin1.is_in_group("white_coins")
	var pos = (coin1.global_position + coin2.global_position) / 2.0
	
	var is_halves = coin1.is_in_group("half_coins") and coin2.is_in_group("half_coins")
	
	coin1.queue_free()
	coin2.queue_free()
	
	var board = get_node_or_null("SubViewportContainer/SubViewport/CarromBoard3D")
	if not board: return
	
	var merged = RigidBody3D.new()
	merged.physics_material_override = load("res://assets/material/CarromCoinPhysicsMaterial.tres")
	merged.linear_damp = 1.0
	merged.angular_damp = 1.0
	merged.contact_monitor = true
	merged.max_contacts_reported = 4
	merged.axis_lock_linear_y = true
	merged.axis_lock_angular_x = true
	merged.axis_lock_angular_z = true
	merged.continuous_cd = true
	
	if is_halves:
		# Glue halves back to normal coin
		merged.mass = 1.0
		var col = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = 0.0917
		cyl.height = 0.0311
		col.shape = cyl
		col.position.y = 0.01503
		merged.add_child(col)
		
		var visual_scene = load("res://assets/3dmodel/Black.glb") if is_black else load("res://assets/3dmodel/white.glb")
		if visual_scene:
			var visual = visual_scene.instantiate()
			visual.position.y = -0.079855
			merged.add_child(visual)
	else:
		# Glue two normal coins side-by-side using a fixed constraint... 
		# Wait, physically tying them is complex dynamically in script due to Godot Joint3D quirks. 
		# Proposal B requested: "physically attached side-by-side using a fixed joint"
		# Actually, spawning a single RigidBody3D with two collision shapes and two meshes side-by-side acts identically to a fixed joint!
		merged.mass = 2.0
		merged.add_to_group("glued_coins")
		var visual_scene = load("res://assets/3dmodel/Black.glb") if is_black else load("res://assets/3dmodel/white.glb")
		
		for i in range(2):
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.0917
			cyl.height = 0.0311
			col.shape = cyl
			col.position = Vector3(0.0917 if i == 0 else -0.0917, 0.01503, 0)
			merged.add_child(col)
			
			if visual_scene:
				var visual = visual_scene.instantiate()
				visual.position = Vector3(0.0917 if i == 0 else -0.0917, -0.079855, 0)
				merged.add_child(visual)
	
	if is_black:
		merged.add_to_group("black_coins")
	if is_white:
		merged.add_to_group("white_coins")
		
	merged.global_position = pos
	board.add_child(merged)
	
	if not merged.body_entered.is_connected(board._on_coin_body_entered):
		merged.body_entered.connect(board._on_coin_body_entered.bind(merged))
