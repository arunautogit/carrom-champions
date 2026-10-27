extends RigidBody3D

static var coin_hit_sounds: Array[AudioStream] = []
static var wall_hit_sounds: Array[AudioStream] = []

var sfx_player: AudioStreamPlayer3D
var last_hit_time: float = 0.0

func _ready():
	contact_monitor = true
	max_contacts_reported = 3
	body_entered.connect(_on_body_entered)
	
	_load_resources()
	
	sfx_player = AudioStreamPlayer3D.new()
	sfx_player.unit_size = 8.0
	sfx_player.max_db = 2.0
	add_child(sfx_player)

static func _load_resources():
	if coin_hit_sounds.is_empty():
		for i in range(1, 6):
			var res = load("res://assets/audio/coin_hit_" + str(i) + ".mp3")
			if res:
				coin_hit_sounds.append(res)
	if wall_hit_sounds.is_empty():
		for i in range(1, 5):
			var res = load("res://assets/audio/wall_hit_" + str(i) + ".mp3")
			if res:
				wall_hit_sounds.append(res)

func _is_sound_enabled() -> bool:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("is_sound_enabled"):
		return am.is_sound_enabled()
	return true

func _on_body_entered(body: Node):
	if not _is_sound_enabled():
		return
		
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_hit_time < 0.04:
		return
		
	var speed = linear_velocity.length()
	
	if body is RigidBody3D:
		# If colliding with another coin, let only one body play the sound to avoid double phasing
		if not body.is_in_group("striker") and get_instance_id() > body.get_instance_id():
			return
		
		# Relative collision speed
		speed = (linear_velocity - body.linear_velocity).length()
		if speed < 0.15:
			return
			
		last_hit_time = current_time
		
		# Pick random coin hit sample
		if not coin_hit_sounds.is_empty():
			sfx_player.stream = coin_hit_sounds.pick_random()
			var t = clampf((speed - 0.2) / 4.5, 0.0, 1.0)
			sfx_player.volume_db = lerpf(-16.0, 1.0, t)
			sfx_player.pitch_scale = randf_range(0.95, 1.05)
			sfx_player.play()
			
	elif body is StaticBody3D:
		if speed < 0.15:
			return
			
		last_hit_time = current_time
		
		# Pick random cushion/wall bounce sample
		if not wall_hit_sounds.is_empty():
			sfx_player.stream = wall_hit_sounds.pick_random()
			var t = clampf((speed - 0.2) / 4.5, 0.0, 1.0)
			sfx_player.volume_db = lerpf(-14.0, 2.0, t)
			sfx_player.pitch_scale = randf_range(0.96, 1.04)
			sfx_player.play()
