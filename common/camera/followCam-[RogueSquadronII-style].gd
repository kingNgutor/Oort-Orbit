# followCam-[RogueSquadronII-style].gd
extends Node3D

#------------Key Parameters------------#

@export var distance := -18.0
@export var height := 5.0
@export var lateral_offset := 0.0

@export var position_lag := 6.0
@export var rotation_lag := 5.0
@export var roll_influence := 0.35 # 0 = horizon locked, 1 = full ship roll

var target: CharacterBody3D
@export var target_path: NodePath

@onready var explosion: Node3D = $Explosion
func detonate_spaceship():
	print("detonating...")
	explosion.explode() # detonation
	await get_tree().create_timer(10.0).timeout # display detonation event
	print("waited 10 seconds. dispatching to game_over.tscn...") 
	get_tree().change_scene_to_file(GlobalScenepath.game_over) # advance to game over screen

#-----------------------MAIN-----------------------#

func _ready() -> void:
	
	GlobalSignal.died.connect(Callable(self, "detonate_spaceship"))
	target = get_node_or_null(target_path)

	if not target:
		push_error("CameraRig: 'target_path' is not assigned.")


func _physics_process(delta: float) -> void:
	
	if not target:
		await get_tree().create_timer(5.0).timeout
		return
	#------------Ship-Relative Camera Position------------#
	
	var ship_basis = target.global_transform.basis
	var ship_origin = target.global_transform.origin
	
	var local_offset = -ship_basis.z * distance + ship_basis.y * height + ship_basis.x * lateral_offset
	var desired_position = ship_origin + local_offset
	global_position = global_position.lerp(desired_position, delta * position_lag)
	#global_transform.origin = global_transform.origin.lerp(desired_position, delta * position_lag)
	
	#------------Rotation (damped roll)------------#
	
	var ship_quat = ship_basis.get_rotation_quaternion()
	
	var euler = ship_quat.get_euler()
	euler.z *= roll_influence
	var damped_quat = Quaternion.from_euler(euler)
	
	var current = global_basis.get_rotation_quaternion()
	var blended = current.slerp(damped_quat, delta * rotation_lag)
	global_basis = Basis(blended)
	
	#--------------Velocity-Weighted Lag (highly authentic)--------------#
	
	var speed = target.velocity.length()
	var lag_scale = clamp(speed / 100.0, 0.5, 1.5)
	
	global_position = global_position.lerp(desired_position, delta * position_lag / lag_scale)
	
	
	
