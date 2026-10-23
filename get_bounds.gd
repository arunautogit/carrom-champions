extends SceneTree

func _init():
	var scene = load("res://scenes/game/Board.tscn")
	var node = scene.instantiate()
	var mesh_instance = node.get_child(0).get_child(0)
	if mesh_instance is MeshInstance3D:
		var aabb = mesh_instance.get_aabb()
		print("AABB_SIZE: ", aabb.size)
		print("AABB_POS: ", aabb.position)
	else:
		print("MeshInstance3D not found")
	quit()
