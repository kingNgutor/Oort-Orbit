#title_screen.gd
extends CanvasLayer

@onready var _next_scene: PackedScene = preload(GlobalScenepath.main_menu)

func _on_start_button_pressed() -> void:
	print("transitioning to main menu...")
	get_tree().change_scene_to_packed(_next_scene)
	

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		print("exiting application")
		get_tree().quit()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("options"):
		print("transitioning to main menu...")
		get_tree().change_scene_to_packed(_next_scene)
