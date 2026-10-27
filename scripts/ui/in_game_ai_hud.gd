extends PanelContainer

@onready var name_lbl = $MarginContainer/HBoxContainer/VBoxContainer/NameLbl
@onready var score_lbl = $MarginContainer/HBoxContainer/VBoxContainer/ScoreLbl
@onready var state_lbl = $MarginContainer/HBoxContainer/VBoxContainer/StateHBox/StateLbl
@onready var learning_indicator = $MarginContainer/HBoxContainer/VBoxContainer/StateHBox/LearningIndicator

var _setup_p_id: int = 0
var _setup_profile: Dictionary = {}
var _is_ready: bool = false

func _ready():
	theme_type_variation = "CardPanel"
	_is_ready = true
	_apply_setup()

func setup(p_id: int, profile: Dictionary):
	_setup_p_id = p_id
	_setup_profile = profile
	if _is_ready:
		_apply_setup()

func _apply_setup():
	if _setup_profile.has("avatar_path") and ResourceLoader.exists(_setup_profile["avatar_path"]):
		var avatar = $MarginContainer/HBoxContainer/Avatar
		avatar.texture = load(_setup_profile["avatar_path"])

	if _setup_profile.has("name"):
		name_lbl.text = _setup_profile["name"] + " (AI)"
		var color = Color(_setup_profile.get("tier_color", "#FFFFFF"))
		name_lbl.add_theme_color_override("font_color", color)
	else:
		name_lbl.text = "PLAYER " + str(_setup_p_id) + " (AI)"
	score_lbl.text = "Score: 0"
	state_lbl.text = "Waiting..."
	learning_indicator.modulate.a = 0.2

func update_score(score: int):
	if _is_ready:
		score_lbl.text = "Score: " + str(score)

func update_state(state: String):
	if _is_ready:
		state_lbl.text = state

func flash_learning_indicator():
	if _is_ready:
		var t = create_tween()
		t.tween_property(learning_indicator, "modulate:a", 1.0, 0.2)
		t.tween_property(learning_indicator, "modulate:a", 0.2, 0.5)
