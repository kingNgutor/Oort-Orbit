extends Node3D

#@onready var elektrasteroid = $Elektra
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	#elektrasteroid.set_global_position(Vector3(0,0,-10))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#print("this scene elektra's global transform : ", elektrasteroid.global_transform)
	#print("position elektra = ",elektrasteroid.global_position)
	#elektrasteroid.set_global_position(Vector3(0,0,-10))
	
