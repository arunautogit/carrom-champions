extends CanvasLayer

var transition_rect: ColorRect

func _ready():
	layer = 100 # Keep it on top
	transition_rect = ColorRect.new()
	transition_rect.color = Color(0, 0, 0, 0)
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition_rect)

func transition_to_scene(path: String):
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	AudioManager.play_screen_transition()
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(Callable(self, "_on_fade_out_complete").bind(path))

func _on_fade_out_complete(path: String):
	GameManager.call_deferred("_deferred_goto_scene", path)
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 0.0, 0.3)
	tween.tween_callback(func(): transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)
