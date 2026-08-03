# highscore.gd 
# [This script must be a global autoload to function properly]


extends Node


var highscore: int = 0
var current_score: int = 0
var config = ConfigFile.new()
var highscore_from_file: int

# use the following as an encyrption key for save_encrypted():
# var key = OS.get_unique_id().sha256_buffer()

func _ready():
	# read high score from disk
	var err = config.load("res://config/highscore_savefile.cfg")
	if err == OK:
		highscore = config.get_value("highscore", "value")
	# connect to game over signal
	

func save_score():
	config.set_value("highscore", "value", highscore)
	if current_score > highscore:
		highscore = current_score
	config.save("res://config/highscore_savefile.cfg")

func recover_saved_score():
	var err = config.load("res://config/highscore_savefile.cfg")
	if err == OK:
		highscore_from_file = config.get_value("highscore", "value")
