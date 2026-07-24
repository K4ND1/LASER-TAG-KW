extends CanvasLayer

# Reference to the different editable elements of the menu and a restart button
@onready var stats_label: Label = $Control/MenuPanel/MarginContainer/VBoxContainer/StatsLabel
@onready var highscores_list_label: Label = $Control/MenuPanel/MarginContainer/VBoxContainer/HighscoresListLabel
@onready var restart_button: TextureButton = $Control/MenuPanel/MarginContainer/VBoxContainer/RestartButton
@onready var score_label: Label = $Control/MenuPanel/MarginContainer/VBoxContainer/ScoreLabel
@onready var menu_panel: NinePatchRect = $Control/MenuPanel



func _ready() -> void:
	# At the begginging we are setting the right listener to the button and 
	# hiding the menu
	restart_button.pressed.connect(_on_restart_button_pressed)
	hide()

#func display_game_over(kills: int, time_survived: float) -> void:
	## We are calculating the score and we showing it in the right text boxes
	#var final_score = kills * int(time_survived)
	#stats_label.text = "KILLS: %d  |  TIME: %d" % [kills, int(time_survived)]
	#score_label.text = "YOUR SCORE: %d" % final_score
	#
	## We are saving the current score to the high score list in our autoplay
	## script, as well as getting the reference to that list
	#var top_scores = ScoreManager.save_new_score(final_score)
	#
	## Itarating through the highscore list and formating it
	#var scores_text = ""
	#for i in range(top_scores.size()):
		#scores_text += "%d:   %d POINTS" % [i + 1, top_scores[i]]
		#if i != top_scores.size()-1:
			#scores_text += "\n"
	#highscores_list_label.text = scores_text
	#
	## Displaying the menu as well as pausing the game in the background
	#show()
	#get_tree().paused = true

func display_game_over(kills: int, time_survived: float) -> void:
	# We are calculating the score and we showing it in the right text boxes
	var final_score = kills * int(time_survived) 
	stats_label.text = "KILLS: %d  |  TIME: %d" % [kills, int(time_survived)]
	score_label.text = "YOUR SCORE: %d" % final_score
	
	# We are saving the current score to the high score list in our autoplay
	# script, as well as getting the reference to that list
	var top_scores = ScoreManager.save_new_score(final_score)
	
	# Itarating through the highscore list and formating it
	var scores_text = ""
	for i in range(top_scores.size()):
		scores_text += "%d:   %d POINTS" % [i + 1, top_scores[i]]
		if i != top_scores.size()-1:
			scores_text += "\n"
	highscores_list_label.text = scores_text
	
	# Displaying the menu as well as pausing the game in the background
	show()
	get_tree().paused = true
	
	# 2. Przygotowanie panelu do animacji
	# Ustawiamy punkt obrotu/skalowania na sam środek okienka
	menu_panel.pivot_offset = menu_panel.size / 2.0
	
	# Zmniejszamy okienko do zera (niewidoczne na starcie)
	menu_panel.scale = Vector2.ZERO
	
	# 3. Pokazujemy menu i pauzujemy grę
	show()
	get_tree().paused = true

	# 4. Tworzymy animację (TWEEN)
	# .set_pause_mode(...) gwarantuje, że animacja zadziała na pauzie!
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Płynne powiększenie z rozmiarem 0 do 1 w czasie 0.4 sekundy
	tween.tween_property(menu_panel, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_restart_button_pressed() -> void:
	# Takes of the pause from the game and reloads the main scene
	get_tree().paused = false
	get_tree().reload_current_scene()
