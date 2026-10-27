extends Control

func _ready():
	var play_btn = $CenterContainer/VBoxContainer/Buttons/PlayAgainBtn
	var menu_btn = $CenterContainer/VBoxContainer/Buttons/MenuBtn
	
	_setup_button_style(play_btn)
	_setup_button_style(menu_btn)
	
	if GameManager.get("is_career_mode"):
		if GameManager.last_level_unlocked_msg != "":
			play_btn.text = "Next Match"
			play_btn.pressed.connect(func():
				AudioManager.play_button_sound()
				var career = AICareerProgress.new()
				var next_ai = career.get_next_career_opponent()
				var p = AIProfiles.get_profile(next_ai)
				GameManager.match_settings.clear()
				GameManager.match_settings[2] = {"type": "ai", "level": p["level"], "ai_profile_id": next_ai}
				GameManager.goto_scene("res://scenes/game/CarromGame.tscn")
			)
		else:
			play_btn.text = "Try Again"
			play_btn.pressed.connect(func():
				AudioManager.play_button_sound()
				GameManager.goto_scene("res://scenes/game/CarromGame.tscn")
			)
	else:
		play_btn.pressed.connect(func():
			AudioManager.play_button_sound()
			GameManager.goto_scene("res://scenes/setup/MatchSetup.tscn")
		)
	
	menu_btn.pressed.connect(func():
		AudioManager.play_button_sound()
		GameManager.goto_scene("res://scenes/menu/MainMenu.tscn")
	)
	
	var result_text = $CenterContainer/VBoxContainer/ResultText
	var player_name = SaveManager.get_setting("player_name")
	var is_player_winner = false
	if GameManager.last_match_winner_name == "" or GameManager.last_match_winner_name.to_upper() == "YOU" or (player_name and GameManager.last_match_winner_name.to_upper() == str(player_name).to_upper()):
		is_player_winner = true
		
	if GameManager.last_match_winner_name != "":
		result_text.text = GameManager.last_match_winner_name.to_upper() + " WINS!"
	else:
		result_text.text = "YOU WIN!"

	if is_player_winner:
		AudioManager.play_win()
	else:
		AudioManager.play_lose()

func _setup_button_style(btn: Button):
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		create_tween().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
