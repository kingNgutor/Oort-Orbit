#flycam.gd
extends Node3D

@export var target: Node3D

#var assigned_velocity = GlobalAutoload.velocity
func _ready():
	GlobalSignal.spaceship_velocity.connect(_on_signaled_spaceship_velocity)
	
func _on_signaled_spaceship_velocity(velocity: Vector3):
	#var move_here = velocity
	print("signaled velocity from spaceship: ", velocity)

func _process(delta: float) -> void:
	
	position = lerp(position, target.position * 0.95, 20 * delta)
	rotation.x = lerp_angle(rotation.x, target.rotation.x, 1 * delta)
	rotation.y = lerp_angle(rotation.y, target.rotation.y, 2 * delta)
	rotation.z = lerp_angle(rotation.z, target.rotation.z, 2 * delta)
	
	print("cameraPosition: ", global_transform.origin)
	
