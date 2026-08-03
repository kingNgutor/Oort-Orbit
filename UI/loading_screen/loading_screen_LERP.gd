#loading_screen_LERP.gd
extends CanvasLayer

signal loading_screen_has_full_coverage
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
@onready var progressBar : ProgressBar = $Panel/ProgressBar


var update: float = 0.0

func _update_progress_bar(new_value: float) -> void:
	progressBar.set_value_no_signal(new_value * 100)
	
func _signaled_progress_flux():
	GlobalLoadmanager.progress_changed.connect(Callable(self, "_smooth_loading"))
	
func _smooth_loading(progress):
	if progress[0] > update:
		update = progress[0]
	
	if progressBar.value < update:
		progressBar.value = lerp(progressBar.value, update, get_process_delta_time())
	progressBar.value += get_process_delta_time() * 0.2 * \
	 (0.5 if update >= 1.0 else clamp(0.9 - progressBar.value, 0.0, 1.0)) 
	#Note: '\' newline char treats subsequent as contiguous with previous (readability)
	
	pass

func _start_outro_animation() -> void:
	await Signal(animationPlayer, "animation_finished")
	animationPlayer.play("end_load")
	await Signal(animationPlayer, "animation_finished")
	self.queue_free()
	
	
func _process(_delta):
	pass
	
		
