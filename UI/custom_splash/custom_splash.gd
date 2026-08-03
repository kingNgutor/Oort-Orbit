#custom_splash.gd
extends CanvasLayer

@onready var _next_scene: PackedScene = preload(GlobalScenepath.title_screen)

func _on_animation_player_animation_finished(custom_splash_animation) -> void:
	print("changing scene to title screen...")
	get_tree().change_scene_to_packed(_next_scene)
