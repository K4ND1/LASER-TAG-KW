class_name MainScene
extends Node2D

@onready var player: CharacterBody2D = $Player ## Reference to the player scene
@onready var death_menu: CanvasLayer = $DeathMenu ## Reference to the death menu
@onready var healthbar: TextureProgressBar = $HUD/Healthbar

var kills_count: int = 0 ## Counter for how many enemies has player killed
var survival_time: float = 0.0 ## Updated with delta time of survival of the player in a game
var is_game_over: bool = false ## A simple flag that controlls if time is supposed to measured 

func _ready() -> void:
	if player:
		# Attaching the player emmited signal through the reference
		player.player_died.connect(_on_player_died)
		player.health_changed.connect(change_health_bar)

func _process(delta: float) -> void:
	# In process we count time, that's it
	if not is_game_over:
		survival_time += delta

func change_health_bar(health: int):
	healthbar.value = health

# Function that is being called in enemies upon when they die
func add_kill() -> void:
	kills_count += 1
	#print("Current Kills: ", kills_count) ##[DEBUG]

# Simple function that returns the final score, kind of just a getter
func calculate_final_score() -> int:
	return kills_count * int(survival_time)

# When player dies stop measuring survival_time and call death_menu
func _on_player_died() -> void:
	is_game_over = true
	#print("Game Over triggered in Main Scene!") ##[DEBUG]
	
	# We are calling the death menu while passing along stats as paramaters
	death_menu.display_game_over(kills_count, survival_time)
