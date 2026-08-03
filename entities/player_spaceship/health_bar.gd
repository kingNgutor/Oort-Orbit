#health_bar.gd on player_spaceship
extends ProgressBar


func _ready() -> void:
	
	GlobalSignal.current_health.connect(Callable(self, "update_health"))
	
func update_health(health: int):
	
	value -= health
	
	
