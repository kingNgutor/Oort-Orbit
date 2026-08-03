#main_menu.gd
extends CenterContainer

#-----------PARAMS-----------#

#@onready var _next_scene: PackedScene = preload("res://stages/worldenv_Player_AsteroidPool/worldenv_Player_AsteroidPool.tscn")
@onready var highscore_label: Label = $PanelContainer/VBoxContainer/highscore_label
#@onready var SettingsPanel: PanelContainer = $"OverlayLayer (_Settings_Screen_)"/SettingsPanel

@onready var settingsPanel: PanelContainer = $"OverlayLayer (_Settings_Screen_)"/SettingsPanel
@onready var settingsButton: Button = $PanelContainer/VBoxContainer/Button3_settings
@onready var closeSettings: Button = $"OverlayLayer (_Settings_Screen_)"/SettingsPanel/VBoxContainer/"Button (_Close_Settings_)"
@onready var main_menu_ui: CenterContainer = $"."
@onready var music_slider: HSlider = $"OverlayLayer (_Settings_Screen_)"/SettingsPanel/VBoxContainer/Music_Volume
@onready var sfx_slider: HSlider = $"OverlayLayer (_Settings_Screen_)"/SettingsPanel/VBoxContainer/SFX_Volume
@onready var MUSIC_BUS = AudioServer.get_bus_index("Music")
@onready var SFX_BUS = AudioServer.get_bus_index("SFX")

var settings_config = ConfigFile.new()
var music_volume: float = 10.0
var sfx_volume: float = 10.0

#-----------READY-----------#
func _ready():
	#-----init highscore display-----#
	# load high score into memory
	HighScore.recover_saved_score()
	# display high score text
	highscore_label.text = str("High Score: ", HighScore.highscore)
	
	#-----init settings submenu-----#
	# hide the settings panel initially
	settingsPanel.visible = false 
	# Connect to the settings button and volume slider's signals
	closeSettings.pressed.connect(_hide_settings)
	music_slider.value_changed.connect(_music_slider)
	sfx_slider.value_changed.connect(_sfx_slider)
	# load previous settings from file
	var err = settings_config.load(GlobalScenepath.settings_savefile)
	if err == OK:
		# retrive saved values for audio settings
		music_volume = settings_config.get_value("music_volume", "volume")
		sfx_volume = settings_config.get_value("sfx_volume", "volume")
		print("init music/sfx @: ", music_volume, " ", sfx_volume)
		# set bus volumes to thus saved audio levels
		AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(music_volume))
		AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(sfx_volume))
		# visually set music/sfx volume sliders according to saved values 
		music_slider.value = music_volume
		sfx_slider.value = sfx_volume
		
#-----------------------------------------------------------------#

######################################################################
#------------------------MAIN MENU FUNCTIONS-------------------------#
######################################################################

#-----------QUIT-----------#
func _on_button_4_quit_pressed() -> void:
	print("exiting program")
	HighScore.save_score()
	get_tree().quit() #exit runtime
	
	# add a "are you sure" pop-up prompt screen 

#-----------CONTINUE-----------#
func _on_button_2_continue_pressed() -> void:
	print("transitioning to gameplay")
	GlobalLoadmanager.load_scene(GlobalScenepath.worldenv_Player_Asteroid)
	#get_tree().change_scene_to_packed(_next_scene)
	#get_tree().change_scene_to_file("res://stages/worldenv_Player_AsteroidPool/worldenv_Player_AsteroidPool.tscn")

#-----------SETTINGS-----------#
func _on_button_3_settings_pressed() -> void:
	
	# diable main menu input
	main_menu_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	
	# show the panel (but it's invisible because its scale is 0, etc.)
	
	settingsPanel.visible = true
	settingsPanel.modulate.a = 0.0
	settingsPanel.scale = Vector2(0.8,0.8) # 0.8,0.8
	
	# create a tween and animate
	var tween = create_tween()
	tween.set_parallel(true) # run animations together
	tween.tween_property(settingsPanel, "modulate:a", 1.0,0.3)
	tween.tween_property(settingsPanel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	
	pass # Replace with function body.

func _hide_settings():
	# Animate out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(settingsPanel, "modulate:a", 0.0,0.2)
	tween.tween_property(settingsPanel, "scale", Vector2(0.9,0.9), 0.2).set_ease(Tween.EASE_IN)
	
	#after animation finishes, hide panel and restore input
	tween.finished.connect(_on_settings_hidden)
	pass

func _on_settings_hidden():
	settingsPanel.visible = false
	main_menu_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(false)

func _music_slider(value: float) -> void:
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(value))
	print("music_volume: ", value)
	settings_config.set_value("music_volume", "volume", value)
	settings_config.save(GlobalScenepath.settings_savefile)
	pass

func _sfx_slider(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
	print("sfx_volume: ", value)
	settings_config.set_value("sfx_volume", "volume", value)
	settings_config.save(GlobalScenepath.settings_savefile)
	pass

func _save_settings():

	pass

func _load_settings():
	pass

#-----------NEW GAME-----------#
func _on_button_newgame_pressed() -> void:
	pass # Replace with function body.

#-----------EXIT PROGRAM-----------#
func _exit_program():
	get_tree().quit()





#-----------PROCESS-----------#
func _process(_delta) -> void:
	# display high score dynamically by putting it in func _process()
	highscore_label.text = str("High Score: ", HighScore.highscore)
	# Esc key to exit runtime
	if Input.is_action_just_pressed("ui_cancel"):
		print("exiting runtime")
		HighScore.save_score()
		call_deferred("_exit_program")
