extends Control

func _ready():
	var spinner = $CenterContainer/VBoxContainer/Spinner
	spinner.pivot_offset = spinner.custom_minimum_size / 2.0
	var progress = $CenterContainer/VBoxContainer/ProgressBar
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(spinner, "rotation", TAU, 1.5).from(0.0).set_trans(Tween.TRANS_LINEAR)
	
	var p_tween = create_tween()
	p_tween.tween_property(progress, "value", 100.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	GameManager.goto_scene("res://scenes/menu/MainMenu.tscn")
