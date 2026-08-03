# game_over.gd



extends Control

@onready var current_score_label: Label = $CanvasLayer/VBoxContainer/current_score_label
@onready var high_score_label: Label = $CanvasLayer/VBoxContainer/high_score_label

func _ready():
	#HighScore.recover_saved_score()
	current_score_label.text = str("Current Score: ", HighScore.current_score)
	high_score_label.text = str("High Score: ", HighScore.highscore)
	GameState.set_game_over_music_level()
	

func _reset_game():
	RenderingServer.force_sync()
	print("forced sync on RenderingServer. is it work?")
	GameState.reset()

func _on_retry_pressed() -> void:
	HighScore.save_score()
	call_deferred("_reset_game")
	

func _return_to_main_menu():
	get_tree().change_scene_to_file(GlobalScenepath.main_menu)

# "res://config/highscore_savefile.cfg"
func _on_quit_pressed() -> void:
	HighScore.save_score()
	call_deferred("_return_to_main_menu")
