extends Node3D

@onready var egeria = $Egeria
@onready var elektra = $Elektra

func _ready() -> void:
	GlobalSignal.collision_detected.connect(Callable(self, "something_Hit_Me"))
	pass

func something_Hit_Me():
	print("collision detected from Elektra signal")

func _physics_process(delta: float) -> void:
	egeria.linear_velocity = Vector3(0,0,1)
	elektra.linear_velocity = Vector3(0,0,-1)
	 
