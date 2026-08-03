# game_state.gd

""" Herein the game may exist in some XOR state: 
	play, pause or game over. During game over, 
	handle_game_over_state() will loop infinitely; however 
	unintentional this errant behavoir is, it is rather used  
	to poll keyboard input and fascilitate immediate advancement to 
	next scene: game_over.tscn. """

#-------------------------Declarations-------------------------#

extends Node
var player_health: int = 100
signal Game_Over()
signal pause
signal unpause

var pause_state: bool = false
var game_over_state: bool = false

# Bus_name_ID (Audio) - use for func fade_bus 
@onready var SFX_BUS_ID = AudioServer.get_bus_index("SFX")
@onready var MUSIC_BUS_ID = AudioServer.get_bus_index("Music")

#---------------------Functions---------------------#

func reset(): # Reset Game
	player_health = 100
	HighScore.current_score = 0
	game_over_state = false
	fade_bus(MUSIC_BUS_ID, 0.0, 0.1)
	get_tree().change_scene_to_file(GlobalScenepath.worldenv_Player_Asteroid)
	#get_tree().change_scene_to_packed(GlobalScenepath.worldenv_Player_Asteroid)
	
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_text_backspace"):
		#toggle_pause()
#
#func toggle_pause():
	#pause_state = !pause_state
	#get_tree().paused = pause_state

func pause_game():
	if pause_state == false:
		pause_state = true
		get_tree().paused = true
		pause.emit()
		print("game paused normally, ", pause_state)
	else:
		print("game is already paused")

func unpause_game():
	if pause_state == true:
		pause_state = false
		get_tree().paused = false
		unpause.emit()
		print("game unpaused normally, ", pause_state)
	else:
		print("game is already unpaused")

func handle_game_over_state():
	Game_Over.emit()
	game_over_state = true
	# fade out over 2 secs
	fade_bus(MUSIC_BUS_ID, -80.0, 2.0)
	print("handle_game_over_state() event to player...Emitting Game_over signal")

func fade_bus(bus_name_ID: int, tartget_db: float, duration: float) -> void:
	
	var tween = create_tween()
	tween.tween_method(
		func(db): AudioServer.set_bus_volume_db(bus_name_ID, db),
		AudioServer.get_bus_volume_db(bus_name_ID),
		tartget_db,
		duration
	)
func set_game_over_music_level():
	fade_bus(MUSIC_BUS_ID, 0.0, 0.1)

#-------------------------------PROCESS-------------------------------#

func _process(delta):
	
	if game_over_state == true:
		# press space to skip to game over screen
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene_to_file(GlobalScenepath.game_over)
