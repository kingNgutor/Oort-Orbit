# global_autoload.gd
extends Node

#____________ObjectPool.gd______________#
#var _pool: Array = []
#var _in_use: Array = []

#func clear_arrays_on_game_over():
#	_pool.clear()
#	_in_use.clear()
#	print("is _in_use empty: ",_in_use.is_empty())
#	print("is _pool empty: ", _pool.is_empty())

#______________player_spaceship.gd____________#
#var current_speed := 30.0
var velocity = Vector3.ZERO



func _ready():
	# connect to game over signal (to remove_instance() _in_use)
	#GameState.Game_Over.connect(Callable(self, "clear_arrays_on_game_over"))
	pass
