extends Camera3D

var target_fov: float = 21.01
var base_fov: float = 21.01

var current_angle = 0.0
var target_angle = 0.0
var camera_radius = 8.0
var camera_height = 6.0

var in_cinematic = false

func _ready():
	var board_type = "NORMAL"
	# Check SaveManager for round board
	if Engine.has_singleton("SaveManager") or true:
		# Just access it if it's an autoload, but it might not be a direct singleton in Engine.
		# A safer way in Godot 4 for autoloads is using get_node("/root/SaveManager")
		var save_mgr = get_node_or_null("/root/SaveManager")
		if save_mgr and save_mgr.has_method("get_setting"):
			board_type = save_mgr.get_setting("selected_board")
	
	if board_type == "ROUND BOARD":
		target_fov = 32.98
	else:
		target_fov = 21.01
		
	fov = target_fov
	base_fov = target_fov
	
	_update_camera_pos()
	look_at(Vector3.ZERO, Vector3.UP)

func rotate_to_player(player_index: int):
	pass 

func start_cinematic_mode(target: Node3D):
	# Disabled to keep camera perfectly framed
	pass

func stop_cinematic_mode():
	# Disabled to keep camera perfectly framed
	pass

func _update_camera_pos():
	var cam_x = sin(current_angle) * camera_radius
	var cam_z = cos(current_angle) * camera_radius
	global_position = Vector3(cam_x, camera_height, cam_z)

func _process(delta):
	# Lock FOV
	fov = target_fov
	
	if not is_equal_approx(current_angle, target_angle):
		current_angle = lerpf(current_angle, target_angle, 5.0 * delta)
		_update_camera_pos()
		look_at(Vector3.ZERO, Vector3.UP)

func set_zoom_level(value: float):
	pass # Disabled zoom

func _unhandled_input(event):
	pass # Disabled mouse wheel zoom
