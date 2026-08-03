#flycam-inertial-follow-oort.gd
extends Node3D

#----------------Key Parameters----------------#
# Reference to the target (your spaceship)
@export var target: Marker3D
@export var camera: Camera3D

var velocity_history: Array = []
var previous_target_position: Vector3

#-------------------Main-------------------#
func _ready():
	
	if not target:
		push_error("Camera script needs a target (spaceship) assigned!")
		return
	
	if not camera:
		camera = get_node_or_null("Camera3D")
		if not camera:
			push_error("Camera3D not found as child!")
			return
	
	previous_target_position = target.global_position
	velocity_history = []

func _physics_process(delta: float) -> void:
	pass
