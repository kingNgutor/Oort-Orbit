extends ProgressBar

#@export var player: CharacterBody3D

func _ready():
	GlobalSignal.current_health.connect(update_health)
	
func update_health(current_health: int):
	value = current_health * 100 / 100
