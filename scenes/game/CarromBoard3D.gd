extends Node3D

@export_category("Coin Configuration")
@export var white_coin_scene: PackedScene
@export var black_coin_scene: PackedScene
@export var queen_coin_scene: PackedScene

@export_group("Formation Settings")
@export var coin_spacing_gap: float = 0.005 # Small gap between coins
@export var coin_radius: float = 0.091797 # Based on actual CollisionShape3D radius
@export var coin_surface_height: float = 0.078 # Physics height

@export_group("Coin Counts")
@export var white_coin_count: int = 9
@export var black_coin_count: int = 9
@export var queen_count: int = 1

var formation_center: Marker3D
var magnet_active = false
var magnet_light_ref: OmniLight3D
var magnet_blink_timer = 0.0

var coin_stone_data = {} # Object -> {"percent": int, "last_hit": int}
var stone_tex_diffuse: Texture2D
var stone_tex_normal: Texture2D
var stone_tex_rough: Texture2D
var stone_blend_shader: Shader

func _ready():
	stone_tex_diffuse = load("res://assets/textures/seaside_rock_1k/textures/seaside_rock_diff_1k.jpg")
	
	stone_blend_shader = Shader.new()
	stone_blend_shader.code = """
shader_type spatial;
uniform vec4 original_color : source_color;
uniform sampler2D stone_tex : source_color;
uniform float blend_amount : hint_range(0.0, 1.0);

void fragment() {
	vec4 s_albedo = texture(stone_tex, UV);
	ALBEDO = mix(original_color.rgb, s_albedo.rgb, blend_amount);
}
"""
	
	# Ensure the formation center exists
	formation_center = get_node_or_null("CoinFormationCenter")
	if not formation_center:
		formation_center = Marker3D.new()
		formation_center.name = "CoinFormationCenter"
		# Default center of board is assumed to be 0, y, 0 relative to CarromBoard3D
		formation_center.position = Vector3(0, coin_surface_height, 0)
		add_child(formation_center)
		
	setup_coins()
	
	var is_round = (SaveManager.get_setting("selected_board") == "ROUND BOARD")
	var board_node = get_node_or_null("board")
	var board_model = null
	
	if is_round and board_node:
		# Hide default square model and walls
		var old_model = board_node.get_node_or_null("Model")
		if old_model:
			old_model.visible = false
			old_model.queue_free()
			
		var old_walls = board_node.get_node_or_null("Node3D")
		if old_walls:
			old_walls.visible = false
			old_walls.queue_free()
			
		# Load and add round board scene
		var round_scene = load("res://scenes/game/RoundBoard.tscn")
		if round_scene:
			board_model = round_scene.instantiate()
			board_model.name = "board"
			# Add the new board node
			get_node_or_null(".").add_child(board_model)
			# Move it to the same place the old board was
			var old_board_node = board_node
			old_board_node.queue_free()
			board_node = board_model
				
			# Setup 6 pockets for round board
			var pockets_node = get_node_or_null("Pockets")
			if pockets_node:
				# Remove old pockets
				for child in pockets_node.get_children():
					child.queue_free()
				
				# Create 6 new pockets using exact unscaled coordinates from user
				var pocket_scale = 0.667
				var pocket_positions = [
					Vector3(4.556, 0, 0.098),
					Vector3(-4.556, 0, 0.098),
					Vector3(-2.306, 0, 3.914),
					Vector3(2.164, 0, 3.914),
					Vector3(2.463, 0, -3.809),
					Vector3(-2.22, 0, -3.975)
				]
				var pocket_script = load("res://scenes/game/Pocket.gd")
				
				for i in range(6):
					var p_area = Area3D.new()
					p_area.name = "PocketRound_" + str(i)
					if pocket_script:
						p_area.set_script(pocket_script)
						p_area.set("pocket_name", p_area.name)
					
					var col = CollisionShape3D.new()
					var shape = SphereShape3D.new()
					shape.radius = 0.13
					col.shape = shape
					
					# Add a visual black hole so the pocket is reflected in the scene
					var mesh_inst = MeshInstance3D.new()
					var cyl_mesh = CylinderMesh.new()
					cyl_mesh.top_radius = 0.13
					cyl_mesh.bottom_radius = 0.13
					cyl_mesh.height = 0.05
					var mat = StandardMaterial3D.new()
					mat.albedo_color = Color.BLACK
					cyl_mesh.material = mat
					mesh_inst.mesh = cyl_mesh
					mesh_inst.position.y = 0.02 # slightly above the floor
					
					p_area.position = pocket_positions[i] * pocket_scale
					
					p_area.add_child(col)
					p_area.add_child(mesh_inst)
					pockets_node.add_child(p_area)
					
				# Ensure game root connects to the new pockets immediately
				var game_root = get_parent().get_parent().get_parent() # SubViewport -> SubViewportContainer -> CarromGame
				if game_root and game_root.has_method("refresh_pockets"):
					game_root.refresh_pockets()
					
	else:
		board_model = get_node_or_null("board/Model")
		
	if board_model:
		var meshes = board_model.find_children("*", "MeshInstance3D")
		for m in meshes:
			if m.mesh:
				for i in range(m.mesh.get_surface_count()):
					var mat = m.get_active_material(i)
					if mat and mat is StandardMaterial3D:
						mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

	if GameManager.get("is_magnetic_mode"):
		magnet_light_ref = OmniLight3D.new()
		magnet_light_ref.light_color = Color(0.5, 0.0, 1.0)
		magnet_light_ref.light_energy = 0.0 # start off
		magnet_light_ref.light_size = 0.5
		magnet_light_ref.omni_range = 1.5
		magnet_light_ref.position = formation_center.position + Vector3(0, 0.01, 0)
		magnet_light_ref.visible = false
		add_child(magnet_light_ref)

func trigger_magnet_event():
	magnet_active = true
	if magnet_light_ref:
		magnet_light_ref.visible = true
		
	var striker = get_node_or_null("Striker")
	if striker:
		striker.visible = false
		striker.freeze = true

func end_magnet_event():
	magnet_active = false
	if magnet_light_ref:
		magnet_light_ref.visible = false
		magnet_light_ref.light_energy = 0.0
		
	_rerack_coins()
		
	var striker = get_node_or_null("Striker")
	if striker:
		striker.visible = true
		striker.freeze = false
		# Reset position to baseline
		var bounds = GameManager.current_scene.player_striker_bounds[GameManager.current_scene.current_player]
		var mid_x = (bounds.left.x + bounds.right.x) / 2.0
		var mid_z = (bounds.left.z + bounds.right.z) / 2.0
		var reset_transform = Transform3D(Basis(), Vector3(mid_x, 0.081, mid_z))
		striker.global_transform = reset_transform

func _rerack_coins():
	var active_coins = []
	for child in get_children():
		if child is RigidBody3D and child.visible and not child.freeze:
			if child.is_in_group("white_coins") or child.is_in_group("black_coins") or child.is_in_group("red_coin"):
				active_coins.append(child)
				child.linear_velocity = Vector3.ZERO
				child.angular_velocity = Vector3.ZERO
				
	# Sort coins: Queen first, then alternate White/Black
	var red_coins = []
	var w_coins = []
	var b_coins = []
	
	for c in active_coins:
		if c.is_in_group("red_coin"): red_coins.append(c)
		elif c.is_in_group("white_coins"): w_coins.append(c)
		else: b_coins.append(c)
		
	var sorted_coins = []
	sorted_coins.append_array(red_coins)
	while w_coins.size() > 0 or b_coins.size() > 0:
		if w_coins.size() > 0: sorted_coins.append(w_coins.pop_back())
		if b_coins.size() > 0: sorted_coins.append(b_coins.pop_back())
		
	var center_pos = formation_center.global_position
	var diameter = coin_radius * 2.0
	var spacing = diameter + coin_spacing_gap
	
	var ring_capacities = [1, 6, 12, 18]
	var current_ring = 0
	var coins_placed_in_ring = 0
	
	for i in range(sorted_coins.size()):
		var coin = sorted_coins[i]
		var pos = Vector3.ZERO
		
		if current_ring == 0:
			pos = Vector3.ZERO
		else:
			var angle = deg_to_rad(coins_placed_in_ring * (360.0 / ring_capacities[current_ring]))
			var radius = 0.0
			
			if current_ring == 1:
				radius = spacing
			elif current_ring == 2:
				radius = (2.0 if coins_placed_in_ring % 2 == 0 else sqrt(3.0)) * spacing
			elif current_ring == 3:
				radius = spacing * 3.0 # Simplified for rare cases
				
			pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
			
		coins_placed_in_ring += 1
		if coins_placed_in_ring >= ring_capacities[current_ring]:
			current_ring += 1
			coins_placed_in_ring = 0
			
		var new_transform = Transform3D(Basis(), center_pos + pos)
		PhysicsServer3D.body_set_state(coin.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, new_transform)

func stone_pulse():
	for child in get_children():
		if child is RigidBody3D and child.visible and not child.freeze:
			if child.is_in_group("white_coins") or child.is_in_group("black_coins") or child.is_in_group("red_coin"):
				if not coin_stone_data.has(child):
					coin_stone_data[child] = {"percent": 0, "last_hit": 0}
					
				var data = coin_stone_data[child]
				data["percent"] = min(100, data["percent"] + 5)
				_apply_stone_physics(child, data["percent"])
				
func _apply_stone_physics(coin: RigidBody3D, percent: int):
	if percent >= 100:
		coin.freeze = true
	else:
		coin.freeze = false
		coin.mass = lerp(0.5, 50.0, percent / 100.0)
		
	var mesh = null
	var meshes = coin.find_children("*", "MeshInstance3D")
	if meshes.size() > 0:
		mesh = meshes[0]
		
	if mesh:
		var mat = mesh.get_active_material(0)
		if mat == null or not (mat is ShaderMaterial):
			mat = ShaderMaterial.new()
			mat.shader = stone_blend_shader
			if stone_tex_diffuse:
				mat.set_shader_parameter("stone_tex", stone_tex_diffuse)
			mesh.set_surface_override_material(0, mat)
		
		if mat is ShaderMaterial:
			var original_color = Color.WHITE
			if coin.is_in_group("black_coins"):
				original_color = Color(0.1, 0.1, 0.1)
			elif coin.is_in_group("red_coin"):
				original_color = Color(0.9, 0.2, 0.2)
			else:
				original_color = Color(0.9, 0.9, 0.8)
			
			mat.set_shader_parameter("original_color", original_color)
			mat.set_shader_parameter("blend_amount", float(percent) / 100.0)

	var label = coin.get_node_or_null("StoneLabel")
	if percent > 0:
		if not label:
			label = Label3D.new()
			label.name = "StoneLabel"
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.pixel_size = 0.001
			label.font_size = 64
			label.position = Vector3(0, 0.04, 0)
			label.modulate = Color.WHITE
			label.outline_modulate = Color.BLACK
			label.outline_size = 4
			coin.add_child(label)
		
		label.text = "%d%%" % percent
		label.visible = true
	else:
		if label:
			label.visible = false

func _physics_process(delta):
	if magnet_active:
		magnet_blink_timer += delta
		if magnet_light_ref:
			magnet_light_ref.light_energy = 4.0 if int(magnet_blink_timer * 8) % 2 == 0 else 0.5
			
		var center_pos = formation_center.global_position
		var magnetic_strength = 200.0 # Very strong pull!
		
		for child in get_children():
			if child is RigidBody3D and child.visible and not child.freeze:
				if child.is_in_group("white_coins") or child.is_in_group("black_coins") or child.is_in_group("red_coin"):
					var dir = (center_pos - child.global_position)
					dir.y = 0
					var dist = dir.length()
					if dist > 0.05:
						child.apply_central_force(dir.normalized() * magnetic_strength)

func _dump_visual_heights():
	print("\n=== FINAL CARROM HEIGHT VALIDATION ===\n")
	
	# Board Detailed Diagnostic
	print("BOARD VISUAL MESH BOUNDS:")
	var board_mesh = get_node_or_null("board/Model")
	if board_mesh:
		var meshes = board_mesh.find_children("*", "MeshInstance3D")
		for m in meshes:
			var aabb = m.get_aabb()
			var global_bottom = (m.global_transform * Vector3(0, aabb.position.y, 0)).y
			var global_top = (m.global_transform * Vector3(0, aabb.position.y + aabb.size.y, 0)).y
			print("  ", m.name, " -> Bottom Y: ", global_bottom, " | Top Y: ", global_top)
	else:
		print("  board/Model NOT FOUND")
	print("\nBOARD PHYSICS SURFACE:\nY = 0.078404\n")
	
	# Coin
	var coin_tested = false
	for child in get_children():
		if child.is_in_group("white_coins"):
			print("COIN:")
			print("RigidBody Y = ", child.global_position.y)
			var col = child.get_node_or_null("CollisionShape3D")
			if col:
				var shape = col.shape
				var local_y = col.position.y
				var global_y = col.global_position.y
				var half_height = shape.height / 2.0
				print("Collider global Y = ", global_y)
				print("Collider bottom = ", global_y - half_height)
				print("Collider top = ", global_y + half_height)
			var meshes = child.find_children("*", "MeshInstance3D")
			if meshes.size() > 0:
				var m = meshes[0]
				var aabb = m.get_aabb()
				var global_bottom = (m.global_transform * Vector3(0, aabb.position.y, 0)).y
				var global_top = (m.global_transform * Vector3(0, aabb.position.y + aabb.size.y, 0)).y
				print("Visual mesh bottom = ", global_bottom)
				print("Visual mesh top = ", global_top)
			print("")
			coin_tested = true
			break
			
	if not coin_tested:
		print("COIN: NOT FOUND\n")
		
	# Striker
	var striker = get_node_or_null("Striker")
	if striker:
		print("STRIKER:")
		print("RigidBody Y = ", striker.global_position.y)
		var col = striker.get_node_or_null("CollisionShape3D")
		if col:
			var shape = col.shape
			var local_y = col.position.y
			var global_y = col.global_position.y
			var half_height = shape.height / 2.0
			print("Collider global Y = ", global_y)
			print("Collider bottom = ", global_y - half_height)
			print("Collider top = ", global_y + half_height)
		var meshes = striker.find_children("*", "MeshInstance3D")
		for m in meshes:
			if m.name == "Trajectory": continue
			var aabb = m.get_aabb()
			var global_bottom = (m.global_transform * Vector3(0, aabb.position.y, 0)).y
			var global_top = (m.global_transform * Vector3(0, aabb.position.y + aabb.size.y, 0)).y
			print("Visual mesh bottom = ", global_bottom)
			print("Visual mesh top = ", global_top)
		print("")
	else:
		print("STRIKER: NOT FOUND\n")
		
	# Pocket
	var pocket = get_node_or_null("Pockets/PocketTopLeft")
	if pocket:
		var col = pocket.get_node_or_null("CollisionShape3D")
		if col:
			var shape = col.shape as SphereShape3D
			var global_y = col.global_position.y
			print("POCKET:")
			print("Center Y = ", global_y)
			if shape:
				print("Bottom Y = ", global_y - shape.radius)
				print("Top Y = ", global_y + shape.radius)
			else:
				print("Bottom Y = UNKNOWN\nTop Y = UNKNOWN")
	else:
		print("POCKET: NOT FOUND")
		
	# Striker Diagnostic
	print("\n=== STRIKER VISIBILITY DIAGNOSTIC ===")
	striker = get_node_or_null("Striker")
	if striker:
		var real_mesh = striker.get_node_or_null("MeshInstance3D")
		if real_mesh:
			print("STRIKER VISUAL NODE:")
			print("NodePath: ", real_mesh.get_path())
			print("Name: ", real_mesh.name)
			print("Visible: ", real_mesh.visible)
			print("Visible in tree: ", real_mesh.is_visible_in_tree())
			print("Position: ", real_mesh.position)
			print("Global position: ", real_mesh.global_position)
			print("Scale: ", real_mesh.scale)
			print("Global scale: ", real_mesh.global_scale)
			print("Mesh: ", real_mesh.mesh)
			
			var surface_count = 0
			if real_mesh.mesh:
				surface_count = real_mesh.mesh.get_surface_count()
				print("Mesh surface count: ", surface_count)
				print("Mesh AABB size: ", real_mesh.mesh.get_aabb().size)
				
				var mat = real_mesh.get_active_material(0)
				print("Active Material 0: ", mat)
				if mat is StandardMaterial3D:
					print("  Transparency: ", mat.transparency)
					print("  Albedo Color: ", mat.albedo_color)
					print("  Albedo Texture: ", mat.albedo_texture)
					print("  Cull Mode: ", mat.cull_mode)
					print("  Depth Draw: ", mat.depth_draw_mode)
					
			print("Visibility Layer: ", real_mesh.layers)
			var camera = get_node_or_null("Camera3D")
			if camera:
				print("Camera cull_mask: ", camera.cull_mask)
				print("Camera cull_mask & layers: ", camera.cull_mask & real_mesh.layers)
			
			var parent = real_mesh.get_parent()
			while parent:
				print("Parent [", parent.name, "] -> visible: ", ("visible" in parent and parent.visible), ", scale: ", parent.scale if "scale" in parent else "N/A")
				parent = parent.get_parent()
		else:
			print("Striker MeshInstance3D NOT FOUND")
	else:
		print("Striker NOT FOUND")
		
	# Camera Diagnostic
	print("\n=== CAMERA RENDERING DIAGNOSTIC ===")
	var root_node = get_tree().root
	var all_cameras = []
	var nodes_to_check = [root_node]
	
	while nodes_to_check.size() > 0:
		var current = nodes_to_check.pop_back()
		if current is Camera3D:
			all_cameras.append(current)
		for c in current.get_children():
			nodes_to_check.append(c)
			
	for c in all_cameras:
		print("CAMERA:")
		print("Path: ", c.get_path())
		print("Name: ", c.name)
		print("Current: ", c.current)
		print("Global position: ", c.global_position)
		print("Global rotation: ", c.global_rotation)
		print("Near: ", c.near)
		print("Far: ", c.far)
		print("Projection: ", c.projection)
		print("Cull mask: ", c.cull_mask)
		print("---")
		
	var main_cam = get_node_or_null("Camera3D")
	if main_cam:
		print("Forcefully calling make_current() on CarromBoard3D/Camera3D")
		main_cam.make_current()
	else:
		print("CarromBoard3D/Camera3D NOT FOUND!")
		
	print("\n======================================\n")

func setup_coins():
	if white_coin_count != 9 or black_coin_count != 9 or queen_count != 1:
		printerr("ERROR: Invalid carrom coin counts! Must be exactly 9 White, 9 Black, and 1 Queen.")
		# Force standard values just in case
		white_coin_count = 9
		black_coin_count = 9
		queen_count = 1
	
	if not white_coin_scene or not black_coin_scene or not queen_coin_scene:
		printerr("ERROR: Coin scenes are not assigned in CarromBoard3D!")
		return
		
	# 1. Clear existing coins from the board
	for child in get_children():
		if child.is_in_group("white_coins") or child.is_in_group("black_coins") or child.is_in_group("red_coin"):
			child.queue_free()
		
	var center_pos = formation_center.position
		
	# 2. Place Queen at the exact center (Ring 0)
	var queen = queen_coin_scene.instantiate()
	queen.position = center_pos
	add_child(queen)
	queen.add_to_group("red_coin")
	
	# The distance between centers of two touching coins is 2 * coin_radius
	var diameter = coin_radius * 2.0
	var spacing = diameter + coin_spacing_gap
	
	# Keep track of how many we've placed
	var placed_white = 0
	var placed_black = 0
	
	# 3. Ring 1: 6 coins
	for i in range(6):
		var angle = deg_to_rad(i * 60.0)
		var pos = Vector3(cos(angle) * spacing, 0, sin(angle) * spacing)
		
		var coin = null
		if i % 2 == 0:
			coin = white_coin_scene.instantiate()
			coin.add_to_group("white_coins")
			placed_white += 1
		else:
			coin = black_coin_scene.instantiate()
			coin.add_to_group("black_coins")
			placed_black += 1
			
		coin.position = center_pos + pos
		add_child(coin)

	# 4. Ring 2: 12 coins
	for i in range(12):
		var angle = deg_to_rad(i * 30.0)
		
		var radius = 0.0
		if i % 2 == 0:
			radius = 2.0 * spacing
		else:
			radius = sqrt(3.0) * spacing
			
		var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		
		var coin = null
		if i % 2 == 0:
			coin = white_coin_scene.instantiate()
			coin.add_to_group("white_coins")
			placed_white += 1
		else:
			coin = black_coin_scene.instantiate()
			coin.add_to_group("black_coins")
			placed_black += 1
			
		coin.position = center_pos + pos
		add_child(coin)
		
	print("\n--- CARROM FORMATION VALIDATION ---")
	print("White Coins: ", placed_white)
	print("Black Coins: ", placed_black)
	print("Queen: ", queen_count)
	print("Total: ", placed_white + placed_black + queen_count)
	print("Coin Radius: 0.0917")
	print("Coin Height: 0.0311")
	print("-----------------------------------\n")
	
	# Enable contact monitors for Stone Mode collisions
	for child in get_children():
		if child is RigidBody3D and (child.is_in_group("white_coins") or child.is_in_group("black_coins") or child.is_in_group("red_coin")):
			child.contact_monitor = true
			child.max_contacts_reported = 4
			if not child.body_entered.is_connected(_on_coin_body_entered):
				child.body_entered.connect(_on_coin_body_entered.bind(child))

func _on_coin_body_entered(body: Node, coin: RigidBody3D):
	if GameManager.get("is_coin_breaker_mode") and body.is_in_group("striker"):
		if GameManager.current_scene and "coin_breaker_phase" in GameManager.current_scene:
			var phase = GameManager.current_scene.coin_breaker_phase
			var p_id = GameManager.current_scene.current_player
			var p_color = "black" if p_id % 2 != 0 else "white"
			
			if phase == 1: # Breaker Phase
				if (p_color == "black" and coin.is_in_group("white_coins")) or (p_color == "white" and coin.is_in_group("black_coins")):
					if body is RigidBody3D and body.linear_velocity.length() > 3.5: # "Full power" ~3.5
						GameManager.current_scene.break_coin(coin)
			
			elif phase == 3: # Glue Phase
				var hit_list = GameManager.current_scene.coins_hit_this_turn
				if not hit_list.has(coin):
					hit_list.append(coin)

	if GameManager.get("is_tagcoins_mode") and body.is_in_group("striker"):
		if GameManager.current_scene and "tagcoins_phase" in GameManager.current_scene:
			if GameManager.current_scene.tagcoins_phase == 0:
				var current_p = GameManager.current_scene.current_player
				GameManager.current_scene.tag_coin(coin, current_p)

	if GameManager.get("is_stone_mode") and body.is_in_group("striker"):
		if coin_stone_data.has(coin):
			var data = coin_stone_data[coin]
			if data["percent"] >= 100:
				var current_p = 0
				if GameManager.current_scene and "current_player" in GameManager.current_scene:
					current_p = GameManager.current_scene.current_player
					
				if data["last_hit"] != 0 and data["last_hit"] != current_p:
					# Consecutive hit by different players! Reduce to 50%
					data["percent"] = 50
					_apply_stone_physics(coin, 50)
					print("Stone reduced by consecutive hit!")
				data["last_hit"] = current_p

	if body.name.begins_with("StaticBody3D"):
		var parent = body.get_parent()
		var wall_name = parent.name if parent else "UnknownTrimesh"
		if wall_name.begins_with("MeshInstance3D"):
			print("[COLLISION DIAGNOSTIC] ", coin.name, " hit MANUAL WALL: ", wall_name, " | Coin Pos: ", coin.global_position)
		else:
			print("[COLLISION DIAGNOSTIC] ", coin.name, " hit TRIMESH: ", wall_name, " | Coin Pos: ", coin.global_position)

func _trigger_bomb_explosion(pos: Vector3):
	var bomb_strength = 40.0 # impulse force
	for child in get_children():
		if child is RigidBody3D and child.visible and not child.freeze:
			if child.is_in_group("white_coins") or child.is_in_group("black_coins") or child.is_in_group("red_coin") or child.is_in_group("striker"):
				var dist = child.global_position.distance_to(pos)
				if dist < 1.5 and dist > 0.01:
					var dir = (child.global_position - pos).normalized()
					dir.y = 0
					child.apply_central_impulse(dir * (bomb_strength * (1.0 - (dist / 1.5))))
