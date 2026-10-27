extends Control

var progress = 0.0
var target_scene = "res://scenes/menu/MainMenu.tscn"
@onready var progress_bar = $CenterContainer/VBoxContainer/LoadingBox/ProgressBar
@onready var diamond = $CenterContainer/VBoxContainer/LoadingBox/DiamondContainer/Diamond

func _ready():
	_animate_diamond()
	if has_node("/root/YouTubePlayablesBridge"):
		get_node("/root/YouTubePlayablesBridge").notify_first_frame_ready()

func _process(delta):
	progress += delta * 0.4
	if progress_bar:
		progress_bar.value = progress
	if progress >= 1.0:
		set_process(false)
		if GameManager.has_method("goto_scene"):
			GameManager.goto_scene(target_scene)
		else:
			get_tree().change_scene_to_file(target_scene)

func _animate_diamond():
	var tween = create_tween().set_loops()
	tween.tween_property(diamond, "rotation", PI/2, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(diamond, "rotation", PI, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(diamond, "rotation", PI*1.5, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(diamond, "rotation", PI*2, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	var scale_tween = create_tween().set_loops()
	scale_tween.tween_property(diamond, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(diamond, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
