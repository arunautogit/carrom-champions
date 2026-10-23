extends RigidBody3D

signal striker_fired

# --- New Constants for Physics Simulation ---
const PREDICTION_STEPS: int = 120
const SIM_TIME_STEP: float = 1.0/60.0
const MIN_VELOCITY: float = 0.05
const CUSHION_RESTITUTION: float = 0.88
const COIN_RESTITUTION: float = 0.75

var is_aiming = false
var is_positioning = false
var pending_drag = false
var start_world_pos = Vector3.ZERO
var current_bounds = null
var drag_start = Vector2.ZERO
var force_multiplier = 80.0
var max_force = 120.0
var can_shoot = true
var ai_controlling = false
var ai_drag_vector = Vector3.ZERO

var power_label: Label3D

@onready var trajectory = $Trajectory

var floor_rid_to_exclude: RID

# --- UI / Visuals ---
var trajectory_container: Node3D
var striker_ribbon: MeshInstance3D
var coin_ribbon: MeshInstance3D
var ghost_striker: MeshInstance3D
var cut_cone: MeshInstance3D

const SURFACE_Y: float = 0.082
const RIBBON_WIDTH: float = 0.06

static var striker_hit_sounds: Array[AudioStream] = []
static var striker_wall_sounds: Array[AudioStream] = []
static var striker_shoot_sound: AudioStream

var sfx_striker_hit: AudioStreamPlayer3D
var sfx_striker_wall: AudioStreamPlayer3D
var sfx_striker_shoot: AudioStreamPlayer3D
var last_collision_time: float = 0.0

static func _load_striker_audio():
	if striker_hit_sounds.is_empty():
		for i in range(1, 6):
			var res = load("res://assets/audio/striker_hit_" + str(i) + ".mp3")
			if res: striker_hit_sounds.append(res)
	if striker_wall_sounds.is_empty():
		for i in range(1, 5):
			var res = load("res://assets/audio/wall_hit_" + str(i) + ".mp3")
			if res: striker_wall_sounds.append(res)
	if striker_shoot_sound == null:
		striker_shoot_sound = load("res://assets/audio/striker_shoot.mp3")

func _ready():
	_load_striker_audio()
	sfx_striker_hit = AudioStreamPlayer3D.new()
	sfx_striker_hit.unit_size = 10.0
	sfx_striker_hit.max_db = 3.0
	add_child(sfx_striker_hit)
	
	sfx_striker_wall = AudioStreamPlayer3D.new()
	sfx_striker_wall.unit_size = 10.0
	sfx_striker_wall.max_db = 3.0
	add_child(sfx_striker_wall)
	
	sfx_striker_shoot = AudioStreamPlayer3D.new()
	sfx_striker_shoot.unit_size = 10.0
	sfx_striker_shoot.stream = striker_shoot_sound
	add_child(sfx_striker_shoot)
	
	setup_visuals()
	add_to_group("striker")
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	if trajectory:
		trajectory.visible = false
		
	var board = get_parent()
	if board and board.has_node("board/FloorStaticBody"):
		var floor_body = board.get_node("board/FloorStaticBody")
		floor_rid_to_exclude = floor_body.get_rid()
		
	reload_mesh()

func reload_mesh():
	# If there is already a custom mesh, we need to clean it up before loading the new one
	# But wait, if they switch to Striker 0, we need the original cylinder back!
	# The easiest way is to let reload_mesh handle finding the node and replacing it.
	
	var selected_striker = SaveManager.get_setting("selected_striker")
	if not selected_striker:
		return
		
	var striker_num = selected_striker.replace("Striker", "")
	
	for child in get_children():
		if child.name.begins_with("MeshInstance3D"):
			child.name = "deleted_" + str(child.get_instance_id())
			child.queue_free()
		
	if striker_num == "0":
		# Re-create the default cylinder mesh dynamically if they switch back to 0
		var mesh_inst = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.125
		cyl.bottom_radius = 0.125
		cyl.height = 0.028
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = load("res://assets/3dmodel/Striker_Image_0.png")
		cyl.material = mat
		mesh_inst.mesh = cyl
		mesh_inst.position = Vector3(0, 0.0126, 0)
		mesh_inst.name = "MeshInstance3D"
		add_child(mesh_inst)
		return
		
	var target_path = "res://scenes/game/StrikerModel" + striker_num + ".tscn"
	var packed_scene = null
	if ResourceLoader.exists(target_path):
		packed_scene = load(target_path)
		
	if packed_scene:
		var model_node = packed_scene.instantiate()
		model_node.position = Vector3(0, 0.0126, 0)
		model_node.scale = Vector3(0.125, 0.125, 0.125)
		model_node.name = "MeshInstance3D"
		add_child(model_node)
		
func _is_sound_enabled() -> bool:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("is_sound_enabled"):
		return am.is_sound_enabled()
	return true

func _on_body_entered(body: Node):
	if _is_sound_enabled():
		var current_time = Time.get_ticks_msec() / 1000.0
		var speed = linear_velocity.length()
		
		if body is RigidBody3D and (body.is_in_group("white_coins") or body.is_in_group("black_coins") or body.is_in_group("red_coin")):
			var rel_speed = (linear_velocity - body.linear_velocity).length()
			if rel_speed >= 0.15 and current_time - last_collision_time > 0.03:
				last_collision_time = current_time
				if not striker_hit_sounds.is_empty():
					sfx_striker_hit.stream = striker_hit_sounds.pick_random()
					var t = clampf((rel_speed - 0.2) / 5.0, 0.0, 1.0)
					sfx_striker_hit.volume_db = lerpf(-14.0, 2.5, t)
					sfx_striker_hit.pitch_scale = randf_range(0.95, 1.05)
					sfx_striker_hit.play()
			
			var board = get_parent()
			if board and board.has_method("_on_coin_body_entered"):
				board._on_coin_body_entered(self, body)
		elif body is StaticBody3D:
			if speed >= 0.15 and current_time - last_collision_time > 0.03:
				last_collision_time = current_time
				if not striker_wall_sounds.is_empty():
					sfx_striker_wall.stream = striker_wall_sounds.pick_random()
					var t = clampf((speed - 0.2) / 5.0, 0.0, 1.0)
					sfx_striker_wall.volume_db = lerpf(-12.0, 2.5, t)
					sfx_striker_wall.pitch_scale = randf_range(0.96, 1.04)
					sfx_striker_wall.play()

func play_shoot_sound(power_ratio: float = 1.0):
	if not _is_sound_enabled() or sfx_striker_shoot == null:
		return
	var t = clampf(power_ratio, 0.0, 1.0)
	sfx_striker_shoot.volume_db = lerpf(-10.0, 1.0, t)
	sfx_striker_shoot.pitch_scale = randf_range(0.96, 1.04)
	sfx_striker_shoot.play()

func setup_visuals():
	power_label = Label3D.new()
	power_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	power_label.position = Vector3(0, 0.2, 0)
	power_label.text = ""
	power_label.font_size = 32
	power_label.modulate = Color(1, 0.9, 0)
	power_label.outline_render_priority = 0
	power_label.outline_size = 8
	power_label.no_depth_test = true
	add_child(power_label)
	
	trajectory_container = Node3D.new()
	trajectory_container.top_level = true
	add_child(trajectory_container)
	
	striker_ribbon = MeshInstance3D.new()
	var mat_striker = ShaderMaterial.new()
	mat_striker.shader = load("res://shaders/trajectory_dots.gdshader")
	if mat_striker.shader:
		mat_striker.set_shader_parameter("dot_color", Color(1.0, 1.0, 1.0, 1.0))
	striker_ribbon.material_override = mat_striker
	trajectory_container.add_child(striker_ribbon)
	
	coin_ribbon = MeshInstance3D.new()
	var mat_coin = ShaderMaterial.new()
	mat_coin.shader = load("res://shaders/trajectory_dots.gdshader")
	if mat_coin.shader:
		mat_coin.set_shader_parameter("dot_color", Color(1.0, 0.7, 0.2, 1.0))
	coin_ribbon.material_override = mat_coin
	trajectory_container.add_child(coin_ribbon)
	
	ghost_striker = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.125
	cyl.bottom_radius = 0.125
	cyl.height = 0.02
	ghost_striker.mesh = cyl
	var g_mat = StandardMaterial3D.new()
	g_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.3)
	g_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_striker.material_override = g_mat
	trajectory_container.add_child(ghost_striker)
	
	cut_cone = MeshInstance3D.new()
	var c_mat = StandardMaterial3D.new()
	c_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	c_mat.albedo_color = Color(0.2, 0.8, 1.0, 0.4)
	c_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cut_cone.material_override = c_mat
	trajectory_container.add_child(cut_cone)
	
	hide_visuals()

func _process(_delta):
	if pending_drag:
		var current_mouse = get_viewport().get_mouse_position()
		var world_current = get_world_mouse_pos(current_mouse)
		var drag_vec = world_current - start_world_pos
		
		if drag_vec.length() > 0.05:
			if current_bounds and SaveManager.get_setting("selected_board") != "ROUND BOARD":
				var line_dir = (current_bounds.right - current_bounds.left).normalized()
				var dot = abs(drag_vec.normalized().dot(line_dir))
				if dot > 0.707:
					is_positioning = true
				else:
					is_aiming = true
			else:
				is_aiming = true
			pending_drag = false
			
	if is_aiming:
		var drag_vector = Vector3.ZERO
		
		if ai_controlling:
			drag_vector = ai_drag_vector
		else:
			var current_mouse = get_viewport().get_mouse_position()
			var world_start = get_world_mouse_pos(drag_start)
			var world_current = get_world_mouse_pos(current_mouse)
			drag_vector = world_start - world_current
			
		var force = drag_vector * force_multiplier
		
		if force.length() > max_force:
			force = force.normalized() * max_force
			
		var power_percent = clamp(int((force.length() / max_force) * 100.0), 0, 100)
		if power_label:
			power_label.text = str(power_percent) + "%"
			
		if force.length() > 0.1:
			var aim_dir = force.normalized()
			var initial_vel = aim_dir * (force.length())
			
			var sim_results = simulate_striker_path(global_position, initial_vel)
			
			var visual_y = global_position.y
			if has_node("MeshInstance3D"):
				visual_y = $MeshInstance3D.global_position.y
				
			# 2. Build Ribbon Mesh
			striker_ribbon.visible = true
			generate_ribbon_mesh(striker_ribbon, sim_results.points)
			
			# 3. Target Coin & Ghost Striker Visuals
			if sim_results.coin_hit.hit:
				ghost_striker.visible = true
				ghost_striker.global_position = Vector3(sim_results.coin_hit.collision_point.x, SURFACE_Y, sim_results.coin_hit.collision_point.z)
				
				# Coin exit path
				var target_pos = sim_results.coin_hit.collision_point + sim_results.coin_hit.coin_velocity.normalized() * 0.125
				var coin_points: Array = [
					target_pos,
					target_pos + sim_results.coin_hit.coin_velocity.normalized() * 1.5
				]
				coin_ribbon.visible = true
				generate_ribbon_mesh(coin_ribbon, coin_points)
				
				# Wedge / Cut Angle Indicator
				cut_cone.visible = true
				update_cut_wedge(sim_results.coin_hit.collision_point, aim_dir, sim_results.coin_hit.coin_velocity.normalized())
			else:
				ghost_striker.visible = false
				coin_ribbon.visible = false
				cut_cone.visible = false
				
		else:
			if power_label: power_label.text = ""
			hide_visuals()
	elif is_positioning and current_bounds:
		hide_visuals()
		
		var camera = get_viewport().get_camera_3d()
		if not camera:
			camera = get_parent().get_node_or_null("Camera3D")
			
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var dir = camera.project_ray_normal(mouse_pos)
			
			if dir.y != 0:
				var t = (global_position.y - from.y) / dir.y
				var intersect_pos = from + dir * t
				
				var left = current_bounds.left
				var right = current_bounds.right
				
				var line_dir = (right - left).normalized()
				var line_len = left.distance_to(right)
				var v = intersect_pos - left
				var d = v.dot(line_dir)
				d = clamp(d, 0.0, line_len)
				
				var new_pos = left + line_dir * d
				new_pos.y = global_position.y
				
				var space_state = get_world_3d().direct_space_state
				var shape_query = PhysicsShapeQueryParameters3D.new()
				if has_node("CollisionShape3D"):
					shape_query.shape = $CollisionShape3D.shape
					shape_query.transform = Transform3D(global_basis, new_pos)
					shape_query.exclude = [self.get_rid()]
					var collisions = space_state.intersect_shape(shape_query, 10)
					var has_overlap = false
					for col in collisions:
						var collider = col.collider
						if collider and (collider.is_in_group("white_coins") or collider.is_in_group("black_coins") or collider.is_in_group("red_coin")):
							has_overlap = true
							break
					
					if not has_overlap:
						global_position = new_pos
				else:
					global_position = new_pos
	else:
		hide_visuals()

func _unhandled_input(event):
	if not can_shoot:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var camera = get_viewport().get_camera_3d()
			if not camera:
				camera = get_parent().get_node_or_null("Camera3D")
			
			if camera:
				var from = camera.project_ray_origin(event.position)
				var to = from + camera.project_ray_normal(event.position) * 1000.0
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.create(from, to)
				var result = space_state.intersect_ray(query)
				
				if result and result.collider == self:
					pending_drag = true
					drag_start = event.position
					start_world_pos = get_world_mouse_pos(drag_start)
				else:
					is_aiming = true
					drag_start = event.position
		else:
			if pending_drag:
				pending_drag = false
			elif is_positioning:
				is_positioning = false
			elif is_aiming:
				is_aiming = false
				if power_label:
					power_label.text = ""
					
				var world_start = get_world_mouse_pos(drag_start)
				var world_current = get_world_mouse_pos(event.position)
				var drag_vector = world_start - world_current
				var force = drag_vector * force_multiplier
				
				if force.length() > max_force:
					force = force.normalized() * max_force
					
				if force.length() > 0.1:
					play_shoot_sound(force.length() / max_force)
					apply_central_impulse(force)
					emit_signal("striker_fired")

func execute_ai_shot():
	ai_controlling = false
	is_aiming = false
	if power_label: power_label.text = ""
	
	var force = ai_drag_vector * force_multiplier
	if force.length() > max_force:
		force = force.normalized() * max_force
		
	if force.length() > 0.1:
		play_shoot_sound(force.length() / max_force)
		apply_central_impulse(force)
		emit_signal("striker_fired")

func get_world_mouse_pos(screen_pos: Vector2) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		camera = get_parent().get_node_or_null("Camera3D")
	if not camera:
		return Vector3.ZERO
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	if dir.y == 0: return Vector3.ZERO
	var t = (global_position.y - from.y) / dir.y
	var world_pos = from + dir * t
	world_pos.y = global_position.y
	return world_pos

# ==============================================================================
# --- CORE: Iterative Physics Prediction ---
# ==============================================================================
func simulate_striker_path(start_pos: Vector3, start_vel: Vector3) -> Dictionary:
	var results = {
		"points": [start_pos],
		"coin_hit": {
			"hit": false,
			"collider_rid": null,
			"collision_point": Vector3.ZERO,
			"coin_velocity": Vector3.ZERO
		}
	}

	var space_state = PhysicsServer3D.space_get_direct_state(get_world_3d().space)
	var test_params = PhysicsTestMotionParameters3D.new()
	var test_result = PhysicsTestMotionResult3D.new()
	
	var current_pos = start_pos
	var current_vel = start_vel
	
	var excludes = [get_rid()]
	if floor_rid_to_exclude.is_valid():
		excludes.append(floor_rid_to_exclude)
		
	test_params.exclude_bodies = excludes
	test_params.exclude_objects = [get_instance_id()]
	test_params.margin = 0.005 # Slight margin to prevent stickiness

	for step in range(PREDICTION_STEPS):
		if current_vel.length_squared() < MIN_VELOCITY:
			if results.points.size() > 0 and not results.points[-1].is_equal_approx(current_pos):
				results.points.append(current_pos)
			break
			
		# Apply damping
		current_vel *= (1.0 - 0.5 * SIM_TIME_STEP)
		var motion = current_vel * SIM_TIME_STEP
		
		test_params.from = Transform3D(Basis(), current_pos)
		test_params.motion = motion
		
		if PhysicsServer3D.body_test_motion(get_rid(), test_params, test_result):
			var collider_rid = test_result.get_collider_rid()
			var collider_obj = instance_from_id(test_result.get_collider_id())
			current_pos = test_result.get_collision_point()
			
			if results.points.size() == 0 or not results.points[-1].is_equal_approx(current_pos):
				results.points.append(current_pos)
			
			if collider_obj and (collider_obj.is_in_group("white_coins") or collider_obj.is_in_group("black_coins") or collider_obj.is_in_group("red_coin")):
				results.coin_hit.hit = true
				results.coin_hit.collider_rid = collider_rid
				results.coin_hit.collision_point = current_pos
				results.coin_hit.coin_velocity = calculate_elastic_deflection(test_result, current_vel)
				break
			else:
				var normal = test_result.get_collision_normal()
				current_vel = current_vel.bounce(normal) * CUSHION_RESTITUTION
				current_pos += current_vel.normalized() * 0.01 
		else:
			current_pos += motion
			if step == PREDICTION_STEPS - 1:
				results.points.append(current_pos)
			
	return results

func calculate_elastic_deflection(result: PhysicsTestMotionResult3D, striker_vel: Vector3) -> Vector3:
	var n = result.get_collision_normal()
	n = Vector3(n.x, 0, n.z).normalized()
	var impulse = (striker_vel.dot(n)) * n
	return -impulse * COIN_RESTITUTION

func generate_ribbon_mesh(mesh_inst: MeshInstance3D, points: Array) -> void:
	if points.size() < 2:
		return
		
	var imm = ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var total_len: float = 0.0
	for i in range(points.size() - 1):
		total_len += points[i].distance_to(points[i + 1])
		
	var current_len: float = 0.0
	for i in range(points.size()):
		var p = points[i]
		var dir = Vector3.FORWARD
		if i < points.size() - 1:
			dir = (points[i + 1] - p).normalized()
		else:
			dir = (p - points[i - 1]).normalized()
			
		var normal = Vector3(0, 1, 0).cross(dir).normalized() * (RIBBON_WIDTH * 0.5)
		var u = current_len / max(total_len, 0.001)
		
		imm.surface_set_uv(Vector2(u, 0.0))
		imm.surface_add_vertex(Vector3(p.x - normal.x, SURFACE_Y, p.z - normal.z))
		
		imm.surface_set_uv(Vector2(u, 1.0))
		imm.surface_add_vertex(Vector3(p.x + normal.x, SURFACE_Y, p.z + normal.z))
		
		if i < points.size() - 1:
			current_len += p.distance_to(points[i + 1])
			
	imm.surface_end()
	mesh_inst.mesh = imm

func update_cut_wedge(contact_pos: Vector3, in_dir: Vector3, out_dir: Vector3) -> void:
	var imm = ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var base_pos = Vector3(contact_pos.x, SURFACE_Y, contact_pos.z)
	var p1 = base_pos - in_dir * 0.4
	var p2 = base_pos + out_dir * 0.4
	
	imm.surface_set_color(Color(0.2, 0.8, 1.0, 0.4))
	imm.surface_add_vertex(base_pos)
	imm.surface_add_vertex(p1)
	imm.surface_add_vertex(p2)
	
	imm.surface_end()
	cut_cone.mesh = imm

func hide_visuals() -> void:
	if striker_ribbon: striker_ribbon.visible = false
	if coin_ribbon: coin_ribbon.visible = false
	if ghost_striker: ghost_striker.visible = false
	if cut_cone: cut_cone.visible = false
