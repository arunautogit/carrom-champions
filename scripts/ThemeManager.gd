extends Node

func _ready():
	var theme = Theme.new()
	
	# AAA Color Palette
	var color_gold_primary = Color("#D4AF37")
	var color_gold_highlight = Color("#E8C15A")
	var color_amber = Color("#C85A17")
	var color_surface = Color(0.106, 0.071, 0.047, 0.90) # #1B120C at 90%
	var color_mahogany = Color("#704214")
	var color_birch = Color("#DEB887")
	var color_text_ivory = Color("#F5E6C8")
	var color_text_muted = Color("#A89582")
	
	# Font
	var font = null
	if FileAccess.file_exists("res://assets/fonts/Montserrat-Bold.ttf"):
		font = load("res://assets/fonts/Montserrat-Bold.ttf")
		theme.default_font = font
		theme.default_font_size = 32
	
	# Dynamic Buttons
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color("#4A2C18") # Leather brown
	btn_normal.border_color = color_gold_primary # Brass frame
	btn_normal.border_width_bottom = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.corner_radius_top_left = 16
	btn_normal.corner_radius_top_right = 16
	btn_normal.corner_radius_bottom_left = 16
	btn_normal.corner_radius_bottom_right = 16
	btn_normal.shadow_color = Color(0, 0, 0, 0.5)
	btn_normal.shadow_size = 4
	theme.set_stylebox("normal", "Button", btn_normal)
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = color_amber # Warm amber glow
	btn_hover.border_color = color_gold_highlight
	btn_hover.shadow_color = Color(color_amber.r, color_amber.g, color_amber.b, 0.6)
	btn_hover.shadow_size = 12
	theme.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color("#3A2212")
	btn_pressed.border_color = Color("#B3942F") # Dark gold bevel
	btn_pressed.shadow_size = 0
	theme.set_stylebox("pressed", "Button", btn_pressed)
	
	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color("#33221A") # Desaturated muted brown
	btn_disabled.border_color = Color("#554433")
	theme.set_stylebox("disabled", "Button", btn_disabled)
	
	# PlayButton (Large Gold Accent)
	var play_normal = btn_normal.duplicate()
	play_normal.bg_color = color_gold_primary
	play_normal.border_color = color_gold_highlight
	play_normal.border_width_bottom = 4
	play_normal.corner_radius_top_left = 40
	play_normal.corner_radius_top_right = 40
	play_normal.corner_radius_bottom_left = 40
	play_normal.corner_radius_bottom_right = 40
	play_normal.shadow_color = Color(color_gold_primary.r, color_gold_primary.g, color_gold_primary.b, 0.4)
	play_normal.shadow_size = 20
	theme.set_stylebox("normal", "PlayButton", play_normal)
	
	var play_hover = play_normal.duplicate()
	play_hover.bg_color = color_gold_highlight
	play_hover.shadow_size = 30
	theme.set_stylebox("hover", "PlayButton", play_hover)
	
	var play_pressed = play_normal.duplicate()
	play_pressed.bg_color = Color("#A38628")
	play_pressed.border_width_bottom = 2
	play_pressed.shadow_size = 10
	theme.set_stylebox("pressed", "PlayButton", play_pressed)
	
	# Circle Button (HUD)
	var circle_btn = btn_normal.duplicate()
	circle_btn.corner_radius_top_left = 100
	circle_btn.corner_radius_top_right = 100
	circle_btn.corner_radius_bottom_left = 100
	circle_btn.corner_radius_bottom_right = 100
	theme.set_stylebox("normal", "CircleButton", circle_btn)
	var circle_hover = btn_hover.duplicate()
	circle_hover.corner_radius_top_left = 100
	circle_hover.corner_radius_top_right = 100
	circle_hover.corner_radius_bottom_left = 100
	circle_hover.corner_radius_bottom_right = 100
	theme.set_stylebox("hover", "CircleButton", circle_hover)
	var circle_pressed = btn_pressed.duplicate()
	circle_pressed.corner_radius_top_left = 100
	circle_pressed.corner_radius_top_right = 100
	circle_pressed.corner_radius_bottom_left = 100
	circle_pressed.corner_radius_bottom_right = 100
	theme.set_stylebox("pressed", "CircleButton", circle_pressed)
	
	# Default Panel
	var panel = StyleBoxFlat.new()
	panel.bg_color = color_surface
	theme.set_stylebox("panel", "Panel", panel)
	
	# Card Panel (Hero Cards / HUD)
	var card = StyleBoxFlat.new()
	card.bg_color = color_surface
	card.border_color = color_gold_primary
	card.border_width_bottom = 2
	card.border_width_top = 2
	card.border_width_left = 2
	card.border_width_right = 2
	card.corner_radius_top_left = 16
	card.corner_radius_top_right = 16
	card.corner_radius_bottom_left = 16
	card.corner_radius_bottom_right = 16
	card.shadow_color = Color(0, 0, 0, 0.6)
	card.shadow_size = 15
	theme.set_stylebox("panel", "CardPanel", card)
	
	# Label Colors
	theme.set_color("font_color", "Label", color_text_ivory)
	theme.set_color("font_color", "Button", color_text_ivory)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_color", "PlayButton", color_surface)
	theme.set_color("font_hover_color", "PlayButton", color_surface)
	
	
	# ProgressBar
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = color_mahogany
	pb_bg.border_color = color_gold_primary
	pb_bg.border_width_bottom = 2
	pb_bg.border_width_top = 2
	pb_bg.border_width_left = 2
	pb_bg.border_width_right = 2
	pb_bg.corner_radius_top_left = 15
	pb_bg.corner_radius_top_right = 15
	pb_bg.corner_radius_bottom_left = 15
	pb_bg.corner_radius_bottom_right = 15
	
	var pb_fill = pb_bg.duplicate()
	pb_fill.bg_color = color_amber
	pb_fill.border_width_left = 0
	pb_fill.border_width_top = 0
	pb_fill.border_width_right = 0
	pb_fill.border_width_bottom = 0
	pb_fill.shadow_color = Color(color_amber.r, color_amber.g, color_amber.b, 0.5)
	pb_fill.shadow_size = 10
	
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	get_tree().root.set_theme(theme)

