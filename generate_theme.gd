extends SceneTree

func _init():
	print("Generating theme...")
	var theme = Theme.new()
	
	# Colors
	var color_dark_wood = Color("#241711")
	var color_wood = Color("#5A3521")
	var color_gold = Color("#D6A84F")
	var color_cream = Color("#F7EED8")
	var color_deep_red = Color("#8E2525")
	var color_light_wood = Color("#8A5735")
	
	# Font
	var font = load("res://assets/fonts/Montserrat-Bold.ttf")
	theme.default_font = font
	theme.default_font_size = 32
	
	# Button Normal
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = color_wood
	btn_normal.border_color = color_gold
	btn_normal.border_width_bottom = 4
	btn_normal.border_width_top = 2
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.corner_radius_top_left = 16
	btn_normal.corner_radius_top_right = 16
	btn_normal.corner_radius_bottom_left = 16
	btn_normal.corner_radius_bottom_right = 16
	btn_normal.shadow_color = Color(0, 0, 0, 0.5)
	btn_normal.shadow_size = 4
	btn_normal.shadow_offset = Vector2(0, 4)
	theme.set_stylebox("normal", "Button", btn_normal)
	
	# Button Hover
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = color_light_wood
	theme.set_stylebox("hover", "Button", btn_hover)
	
	# Button Pressed
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = color_dark_wood
	btn_pressed.border_width_bottom = 2
	btn_pressed.shadow_offset = Vector2(0, 2)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	
	# Panel (Wooden Background)
	var panel = StyleBoxFlat.new()
	panel.bg_color = color_dark_wood
	theme.set_stylebox("panel", "Panel", panel)
	
	# Card Panel
	var card = StyleBoxFlat.new()
	card.bg_color = color_wood
	card.border_color = color_gold
	card.border_width_bottom = 2
	card.border_width_top = 2
	card.border_width_left = 2
	card.border_width_right = 2
	card.corner_radius_top_left = 24
	card.corner_radius_top_right = 24
	card.corner_radius_bottom_left = 24
	card.corner_radius_bottom_right = 24
	theme.set_stylebox("panel", "CardPanel", card)
	
	# Label Colors
	theme.set_color("font_color", "Label", color_cream)
	theme.set_color("font_color", "Button", color_cream)
	
	ResourceSaver.save(theme, "res://project_theme.tres")
	print("Theme saved to res://project_theme.tres")
	quit()
