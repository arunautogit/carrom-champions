extends Control

var board_group: ButtonGroup
var striker_group: ButtonGroup

@onready var tab_container = $MarginContainer/VBoxContainer/ContentSplit/TabContainer
@onready var model_pivot = $MarginContainer/VBoxContainer/ContentSplit/HeroDisplay/SubViewport/ModelPivot
@onready var camera = $MarginContainer/VBoxContainer/ContentSplit/HeroDisplay/SubViewport/Camera3D

func _ready():
	var top_bar = $MarginContainer/TopBar
	$MarginContainer.move_child(top_bar, -1)
	
	$MarginContainer/TopBar/BackButton.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/menu/MainMenu.tscn")
	)
	
	$MarginContainer/TopBar/PlayButton.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/mode/GameMode.tscn")
	)
	
	board_group = ButtonGroup.new()
	striker_group = ButtonGroup.new()
	
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Boards
	var board1 = $MarginContainer/VBoxContainer/ContentSplit/TabContainer/Boards/ScrollContainer/VBoxContainer/Board1
	var board2 = $MarginContainer/VBoxContainer/ContentSplit/TabContainer/Boards/ScrollContainer/VBoxContainer/Board2
	
	board1.toggle_mode = true
	board2.toggle_mode = true
	board1.button_group = board_group
	board2.button_group = board_group
	
	var current_board = SaveManager.get_setting("selected_board")
	if current_board == "ROUND BOARD":
		board2.button_pressed = true
	else:
		board1.button_pressed = true
		
	board1.toggled.connect(func(is_pressed):
		if is_pressed:
			AudioManager.play_button_sound()
			SaveManager.set_setting("selected_board", "NORMAL BOARD")
			update_board_texts()
			_update_hero_display()
	)
	board2.toggled.connect(func(is_pressed):
		if is_pressed:
			AudioManager.play_button_sound()
			SaveManager.set_setting("selected_board", "ROUND BOARD")
			update_board_texts()
			_update_hero_display()
	)
	update_board_texts()

	# Strikers
	var grid = $MarginContainer/VBoxContainer/ContentSplit/TabContainer/Strikers/ScrollContainer/GridContainer
	var current_striker = SaveManager.get_setting("selected_striker")
	if not current_striker:
		current_striker = "Striker0"
		SaveManager.set_setting("selected_striker", current_striker)
		
	for i in range(6):
		var striker_name = "Striker" + str(i)
		var btn = grid.get_node(striker_name)
		btn.toggle_mode = true
		btn.button_group = striker_group
		
		if current_striker == striker_name:
			btn.button_pressed = true
			
		btn.toggled.connect(func(is_pressed):
			if is_pressed:
				AudioManager.play_button_sound()
				SaveManager.set_setting("selected_striker", striker_name)
				update_striker_texts()
				_update_hero_display()
		)
	update_striker_texts()
	
	_update_hero_display()

func _on_tab_changed(tab_idx):
	_update_hero_display()

func update_board_texts():
	var board1 = $MarginContainer/VBoxContainer/ContentSplit/TabContainer/Boards/ScrollContainer/VBoxContainer/Board1
	var board2 = $MarginContainer/VBoxContainer/ContentSplit/TabContainer/Boards/ScrollContainer/VBoxContainer/Board2
	board1.text = ("(✔) " if board1.button_pressed else "") + "NORMAL BOARD\n(Unlocked)"
	board2.text = ("(✔) " if board2.button_pressed else "") + "ROUND BOARD\n(Unlocked)"

func update_striker_texts():
	var grid = $MarginContainer/VBoxContainer/ContentSplit/TabContainer/Strikers/ScrollContainer/GridContainer
	for i in range(6):
		var striker_name = "Striker" + str(i)
		var btn = grid.get_node(striker_name)
		btn.text = ("(✔) " if btn.button_pressed else "") + "Striker " + str(i)

func _update_hero_display():
	for child in model_pivot.get_children():
		child.queue_free()
		
	var active_tab = tab_container.current_tab
	var model_path = ""
	var is_board = (active_tab == 0)
	
	if is_board:
		var current_board = SaveManager.get_setting("selected_board")
		if current_board == "ROUND BOARD":
			model_path = "res://scenes/game/RoundBoard.tscn"
		else:
			model_path = "res://assets/3dmodel/board.glb"
		
		camera.position = Vector3(0, 4, 3.5)
		camera.rotation_degrees = Vector3(-45, 0, 0)
	else:
		var current_striker = SaveManager.get_setting("selected_striker")
		if current_striker:
			var striker_num = current_striker.replace("Striker", "")
			var model_path_attempt = "res://scenes/game/StrikerModel" + striker_num + ".tscn"
			
			if striker_num != "0" and ResourceLoader.exists(model_path_attempt):
				model_path = model_path_attempt
			else:
				var mesh_inst = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.5
				cyl.bottom_radius = 0.5
				cyl.height = 0.1
				
				var mat = StandardMaterial3D.new()
				var tex_path1 = "res://assets/3dmodel/Strikers/Striker" + striker_num + "_Image_0.png"
				var tex_path2 = "res://assets/3dmodel/Striker_Image_0.png"
				
				if ResourceLoader.exists(tex_path1):
					mat.albedo_texture = load(tex_path1)
				elif ResourceLoader.exists(tex_path2):
					mat.albedo_texture = load(tex_path2)
					
				cyl.material = mat
				mesh_inst.mesh = cyl
				model_pivot.add_child(mesh_inst)
				
			camera.position = Vector3(0, 2.5, 3.0)
			if striker_num == "3" or striker_num == "5":
				camera.position = Vector3(0, 4.0, 4.5)
				
			camera.rotation_degrees = Vector3(-35, 0, 0)
				
	if model_path != "":
		if ResourceLoader.exists(model_path):
			var scene = load(model_path)
			if scene:
				var inst = scene.instantiate()
				
				if is_board and "RoundBoard" in model_path:
					inst.scale = Vector3(0.667, 0.667, 0.667)
					
				if not is_board:
					inst.scale = Vector3(2.5, 2.5, 2.5)
					
				model_pivot.add_child(inst)

func _process(delta):
	if model_pivot:
		model_pivot.rotate_y(delta * 0.5)
