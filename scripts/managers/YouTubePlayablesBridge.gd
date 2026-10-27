extends Node

signal cloud_data_loaded(data: Dictionary)
signal audio_state_changed(is_enabled: bool)

var is_web: bool = false
var yt_game_ready: bool = false
var _pause_callback
var _resume_callback
var _audio_callback
var _load_callback

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_web = OS.has_feature("web")
	
	if is_web:
		_setup_yt_playables_listeners()

func _setup_yt_playables_listeners():
	# Define JavaScript bridge hooks
	var js_setup = """
	if (typeof window.ytgame !== 'undefined' && window.ytgame.system) {
		console.log('[YouTubePlayables] SDK detected. Attaching system listeners.');
		window.ytgame.system.onPause(() => {
			console.log('[YouTubePlayables] onPause received from YouTube.');
			if (window._godot_on_pause) window._godot_on_pause();
		});
		window.ytgame.system.onResume(() => {
			console.log('[YouTubePlayables] onResume received from YouTube.');
			if (window._godot_on_resume) window._godot_on_resume();
		});
		window.ytgame.system.onAudioEnabledChange((enabled) => {
			console.log('[YouTubePlayables] onAudioEnabledChange received: ' + enabled);
			if (window._godot_on_audio_change) window._godot_on_audio_change(enabled);
		});
	} else {
		console.log('[YouTubePlayables] Running outside YouTube sandbox or SDK mock enabled.');
	}
	"""
	JavaScriptBridge.eval(js_setup)
	
	_pause_callback = JavaScriptBridge.create_callback(_on_yt_pause)
	_resume_callback = JavaScriptBridge.create_callback(_on_yt_resume)
	_audio_callback = JavaScriptBridge.create_callback(_on_yt_audio_change)
	
	var window = JavaScriptBridge.get_interface("window")
	if window:
		window._godot_on_pause = _pause_callback
		window._godot_on_resume = _resume_callback
		window._godot_on_audio_change = _audio_callback

func notify_first_frame_ready():
	if not is_web:
		return
	var js = """
	if (typeof window.ytgame !== 'undefined' && window.ytgame.game && window.ytgame.game.firstFrameReady) {
		window.ytgame.game.firstFrameReady();
		console.log('[YouTubePlayables] ytgame.game.firstFrameReady() sent successfully.');
	}
	"""
	JavaScriptBridge.eval(js)

func notify_game_ready():
	if not is_web or yt_game_ready:
		return
	yt_game_ready = true
	var js = """
	if (typeof window.ytgame !== 'undefined' && window.ytgame.game && window.ytgame.game.gameReady) {
		window.ytgame.game.gameReady();
		console.log('[YouTubePlayables] ytgame.game.gameReady() sent successfully.');
	}
	"""
	JavaScriptBridge.eval(js)

func _on_yt_pause(_args):
	get_tree().paused = true
	_set_master_mute(true)

func _on_yt_resume(_args):
	get_tree().paused = false
	var should_unmute = true
	if is_web:
		var check_audio_js = "(typeof window.ytgame !== 'undefined' && window.ytgame.system && window.ytgame.system.isAudioEnabled) ? (window.ytgame.system.isAudioEnabled() ? 1 : 0) : 1"
		var res = JavaScriptBridge.eval(check_audio_js)
		if res == 0:
			should_unmute = false
	_set_master_mute(!should_unmute)

func _on_yt_audio_change(args):
	if args.size() > 0:
		var enabled = bool(args[0])
		_set_master_mute(!enabled)
		audio_state_changed.emit(enabled)

func _set_master_mute(is_muted: bool):
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, is_muted)

func save_cloud_data(json_str: String):
	if not is_web:
		return
	var sanitized_str = json_str.replace("`", "\\`")
	var js = """
	(function() {
		if (typeof window.ytgame !== 'undefined' && window.ytgame.game && window.ytgame.game.saveData) {
			const data = `%s`;
			window.ytgame.game.saveData(data).then(() => {
				console.log('[YouTubePlayables] Cloud saveData successful.');
			}).catch((err) => {
				console.warn('[YouTubePlayables] Cloud saveData error:', err);
			});
		}
	})();
	""" % sanitized_str
	JavaScriptBridge.eval(js)

func load_cloud_data():
	if not is_web:
		return
	_load_callback = JavaScriptBridge.create_callback(_on_cloud_data_received)
	var window = JavaScriptBridge.get_interface("window")
	if window:
		window._godot_on_cloud_data = _load_callback
	
	var js = """
	(function() {
		if (typeof window.ytgame !== 'undefined' && window.ytgame.game && window.ytgame.game.loadData) {
			window.ytgame.game.loadData().then((data) => {
				console.log('[YouTubePlayables] Cloud loadData successful.');
				if (window._godot_on_cloud_data) window._godot_on_cloud_data(data || '');
			}).catch((err) => {
				console.warn('[YouTubePlayables] Cloud loadData error:', err);
				if (window._godot_on_cloud_data) window._godot_on_cloud_data('');
			});
		}
	})();
	"""
	JavaScriptBridge.eval(js)

func _on_cloud_data_received(args):
	if args.size() > 0 and args[0] != null and str(args[0]).length() > 0:
		var raw_str = str(args[0])
		var json = JSON.new()
		if json.parse(raw_str) == OK and typeof(json.data) == TYPE_DICTIONARY:
			cloud_data_loaded.emit(json.data)
