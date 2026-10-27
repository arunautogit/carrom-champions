extends Area3D

signal coin_pocketed(coin, pocket_name)

@export var pocket_name: String = "unknown_pocket"
var processed_bodies: Dictionary = {}
var active_tweens: Dictionary = {}

static var pocket_sounds: Array[AudioStream] = []
var sfx_pocket: AudioStreamPlayer3D

func _ready():
	_load_pocket_audio()
	sfx_pocket = AudioStreamPlayer3D.new()
	sfx_pocket.unit_size = 10.0
	sfx_pocket.max_db = 2.0
	add_child(sfx_pocket)
	body_entered.connect(_on_body_entered)

static func _load_pocket_audio():
	if pocket_sounds.is_empty():
		for i in range(1, 4):
			var res = load("res://assets/audio/pocket_drop_" + str(i) + ".mp3")
			if res:
				pocket_sounds.append(res)
		if pocket_sounds.is_empty():
			var fallback = load("res://assets/audio/pocket_drop.wav")
			if fallback: pocket_sounds.append(fallback)

func _on_body_entered(body: Node3D):
	# Ignore if not a RigidBody3D or already processed
	if not body is RigidBody3D:
		return
	if processed_bodies.has(body):
		return
		
	# Check if the body belongs to a valid group
	if body.is_in_group("black_coins") or body.is_in_group("white_coins") or body.is_in_group("red_coin") or body.is_in_group("striker"):
		processed_bodies[body] = true
		
		# Stop physics
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.freeze = true
		
		# Emit signal for game logic
		coin_pocketed.emit(body, pocket_name)
		
		# Play contextual audio feedback
		var am = get_node_or_null("/root/AudioManager")
		var sound_on = true
		if am and am.has_method("is_sound_enabled"):
			sound_on = am.is_sound_enabled()
			
		if sound_on:
			if body.is_in_group("red_coin") and am and am.has_method("play_reward"):
				am.play_reward()
			elif body.is_in_group("striker") and am and am.has_method("play_foul"):
				am.play_foul()
			else:
				if not pocket_sounds.is_empty():
					sfx_pocket.stream = pocket_sounds.pick_random()
					sfx_pocket.volume_db = 0.0
					sfx_pocket.pitch_scale = randf_range(0.96, 1.04)
					sfx_pocket.play()
		
		# Smoothly scale down and hide
		var tween = create_tween()
		active_tweens[body] = tween
		tween.tween_property(body, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): 
			active_tweens.erase(body)
			if is_instance_valid(body):
				body.visible = false
		)

func reset_pocket():
	for body in active_tweens:
		if active_tweens[body] and active_tweens[body].is_valid():
			active_tweens[body].kill()
	active_tweens.clear()
	processed_bodies.clear()
