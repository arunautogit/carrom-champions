extends Node3D

func _ready():
	# _generate_collisions(self)
	# Trimesh collision is completely disabled because it generates buggy invisible edges 
	# inside the playing area. The board now relies 100% on the 4 manual StaticBody3D 
	# border walls and the 4 pocket Area3Ds, keeping the inner surface perfectly clear.
	var model = get_node_or_null("Model")
	if model:
		_apply_matte_material(model)

func _apply_matte_material(node: Node):
	if node is MeshInstance3D:
		var mesh = node.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var mat = mesh.surface_get_material(i)
				if not mat:
					mat = node.get_active_material(i)
				
				var new_mat = StandardMaterial3D.new()
				if mat and mat is StandardMaterial3D:
					new_mat.albedo_color = Color(0.78, 0.58, 0.35, 1.0)
					new_mat.albedo_texture = mat.albedo_texture
					
				new_mat.roughness = 0.82
				new_mat.metallic = 0.0
				new_mat.specular = 0.15
				
				node.set_surface_override_material(i, new_mat)
				
	for child in node.get_children():
		_apply_matte_material(child)
