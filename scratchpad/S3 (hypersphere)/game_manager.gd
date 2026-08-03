#game_manager.gd
extends Node

@onready var health_bar_control_node: Control = $"../CanvasLayer/Control/HBoxContainer/HealthBar_Control_Node/HealthBar"
@onready var explosion: Node3D = $"../flycam/Explosion" # $"../WorldPivot/flycam/Explosion"
@onready var current_score_label: Control = $"../CanvasLayer/Control2/VBoxContainer/highscore_hud_control/VBoxContainer/current_score_display"
@onready var high_score_label: Control = $"../CanvasLayer/Control2/VBoxContainer/highscore_hud_control/VBoxContainer/highscore_display"
@onready var counter := 0

func _ready():
	print("init health = ", GameState.player_health)
	health_bar_control_node.value = GameState.player_health
	GameState.pause.connect(Callable(self, "show_pause_menu"))
	GameState.unpause.connect(Callable(self, "hide_pause_menu"))

func update_health(amount: int):
	GameState.player_health += amount
	print("health = ", GameState.player_health)
	health_bar_control_node.value = GameState.player_health

func game_over():
	GameState.handle_game_over_state()

func show_pause_menu():
	$pause_menu.show()

func hide_pause_menu():
	$pause_menu.hide()

func _process(delta):
	# update scores
	current_score_label.text = str("Score: ", HighScore.current_score)
	high_score_label.text = str("High Score: ", HighScore.highscore)
	
	#Game Over process chain starts here
	if counter < 1:
		if GameState.player_health <= 0:
			print("initializing game over subroutines...")
			game_over()
			counter += 1
