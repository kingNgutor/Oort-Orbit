# pause_menu.gd

""" Herein the pause screen menu may interact with the GameState 
autoload (game_state.gd) to control pause/unpause functions, 
either through the UI button press or via keyboard command. """

extends Control

#var is_paused := true

# unpause game via UI button signal 
func _on_continue_pressed() -> void:
	GameState.unpause_game()
	
	
#func _unhandled_input(event: InputEvent):
	#if event.is_action_pressed("ui_text_backspace"):
		#_on_continue_pressed()
		##GameState.toggle_pause()
		
# unpause game via keyboard input
func _process(delta: float) -> void:
	if Input.is_action_just_released("ui_select"):
		if GameState.pause_state == true:
			_on_continue_pressed()
			#GameState.unpause_game()
