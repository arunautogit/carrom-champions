extends Node3D

func _ready():
	var board_model = get_node_or_null("Model")
	if board_model:
		for child in board_model.find_children("*", "MeshInstance3D"):
			child.create_trimesh_collision()

