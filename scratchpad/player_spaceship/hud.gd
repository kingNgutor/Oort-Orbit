extends CanvasLayer
#@onready var player: CharacterBody3D = $"."
#@onready var label: Label = $HUD/Control/Label
#@onready var healthbar: ProgressBar = $HUD/Control/ProgressBar
#
#func _process(delta: float) -> void:
	#label.text = str(player.current_health) + "/" + str(100)
	#healthbar.value = player.current_health
