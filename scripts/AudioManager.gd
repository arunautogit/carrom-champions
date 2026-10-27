extends Node

var music_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var sfx_button: AudioStream
var sfx_win: AudioStream
var sfx_lose: AudioStream
var sfx_foul: AudioStream
var sfx_reward: AudioStream
var bgm_stream: AudioStream

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "Master"
	add_child(ui_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	_load_streams()

func _load_streams():
	sfx_button = load("res://assets/audio/button_click.mp3")
	sfx_win = load("res://assets/audio/win.mp3")
	sfx_lose = load("res://assets/audio/lose.mp3")
	sfx_foul = load("res://assets/audio/foul.mp3")
	sfx_reward = load("res://assets/audio/reward.mp3")
	bgm_stream = load("res://assets/audio/bgm_ambient.mp3")

static func is_sound_enabled() -> bool:
	var root = Engine.get_main_loop() as SceneTree
	if root and root.root.has_node("SaveManager"):
		var sm = root.root.get_node("SaveManager")
		if sm and sm.has_method("get_setting"):
			var setting = sm.get_setting("sound_enabled")
			return setting == null or setting == true
	return true

static func is_music_enabled() -> bool:
	var root = Engine.get_main_loop() as SceneTree
	if root and root.root.has_node("SaveManager"):
		var sm = root.root.get_node("SaveManager")
		if sm and sm.has_method("get_setting"):
			var setting = sm.get_setting("music_enabled")
			return setting == null or setting == true
	return true

func play_button_sound():
	if not is_sound_enabled() or sfx_button == null:
		return
	if not ui_player: return
	ui_player.stream = sfx_button
	ui_player.volume_db = -4.0
	ui_player.pitch_scale = randf_range(0.97, 1.03)
	ui_player.play()

func play_hover_sound():
	if not is_sound_enabled() or sfx_button == null:
		return
	if not ui_player: return
	ui_player.stream = sfx_button
	ui_player.volume_db = -12.0
	ui_player.pitch_scale = randf_range(1.15, 1.25)
	ui_player.play()

func play_screen_transition():
	if not is_sound_enabled() or sfx_button == null:
		return
	if not ui_player: return
	ui_player.stream = sfx_button
	ui_player.volume_db = -6.0
	ui_player.pitch_scale = 1.1
	ui_player.play()

func play_coin_placeholder():
	pass

func play_win():
	if not is_sound_enabled() or sfx_win == null:
		return
	if not sfx_player: return
	sfx_player.stream = sfx_win
	sfx_player.volume_db = -2.0
	sfx_player.pitch_scale = 1.0
	sfx_player.play()

func play_lose():
	if not is_sound_enabled() or sfx_lose == null:
		return
	if not sfx_player: return
	sfx_player.stream = sfx_lose
	sfx_player.volume_db = -2.0
	sfx_player.pitch_scale = 1.0
	sfx_player.play()

func play_foul():
	if not is_sound_enabled() or sfx_foul == null:
		return
	if not sfx_player: return
	sfx_player.stream = sfx_foul
	sfx_player.volume_db = -2.0
	sfx_player.pitch_scale = 1.0
	sfx_player.play()

func play_reward():
	if not is_sound_enabled() or sfx_reward == null:
		return
	if not sfx_player: return
	sfx_player.stream = sfx_reward
	sfx_player.volume_db = -2.0
	sfx_player.pitch_scale = 1.0
	sfx_player.play()

func play_sfx_oneshot(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if not is_sound_enabled() or stream == null:
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
