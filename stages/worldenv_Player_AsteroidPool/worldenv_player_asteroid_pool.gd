# worldenv_player_asteroid_pool.gd

""" Herein are rudimentary sections of code to 
free the loading screen from memory before gameplay. """

extends Node3D

func _ready():
	
	# get_viewport().size = DisplayServer.screen_get_size() #scale to screen resolution
	var loading_screen = get_tree().get_root().find_child("Panel", true, false)
	if loading_screen:
		print("Last-resort queue_free() for loading screen...")
		loading_screen.queue_free()
