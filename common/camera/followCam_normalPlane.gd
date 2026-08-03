# followCam.gd

extends Node3D
#__________________________first iteration_____________________________#
#@export var target_path: NodePath
#@export var follow_distance := -15.0
#@export var follow_height := 5.0
#@export var position_lerp_speed := 5.0
#@export var rotation_lerp_speed := 5.0
#
#var target: Node3D
#
#
#func _ready() -> void:
	#target = get_node_or_null(target_path)
	#if not target:
		#push_error("CameraRig: Target not assigned or missing.")
#
#
#func _process(delta: float) -> void:
	#if not target:
		#return
#
	## Desired position is behind the target
	#var target_transform = target.global_transform
	#var back_vector = -target_transform.basis.z.normalized()
	#var desired_position = target_transform.origin + back_vector * follow_distance
	#desired_position.y += follow_height
#
	## Smoothly move camera rig to the desired position
	#global_transform.origin = global_transform.origin.lerp(desired_position, delta * position_lerp_speed)
#
	## Smoothly rotate to look at the target
	#var desired_rotation = (target.global_transform.origin - global_transform.origin).normalized()
	#var desired_basis = Basis().looking_at(desired_rotation, Vector3.UP)
	#global_transform.basis = global_transform.basis.slerp(desired_basis, delta * rotation_lerp_speed)

#_________________________second iteration (using spring arm)____________________#

#@export var target_path: NodePath
#@export var look_at_target_path: NodePath
#@export var follow_offset: Vector3 = Vector3(0, 3, 10) # Local offset: behind and above
#@export var position_lerp_speed: float = 5.0
#
#var target: Node3D
#var look_at_target: Node3D
#
#func _ready() -> void:
	#target = get_node_or_null(target_path)
	#look_at_target = get_node_or_null(look_at_target_path)
#
	#if not target:
		#push_error("CameraRig: 'target_path' is not assigned.")
	#if not look_at_target:
		#push_error("CameraRig: 'look_at_target_path' is not assigned.")
#
#
#func _process(delta: float) -> void:
	#if not target or not look_at_target:
		#return
#
	## Calculate desired position relative to the target's local space
	#var desired_global_position = target.global_transform.origin \
		#+ target.global_transform.basis * follow_offset
#
	## Smoothly move the camera rig to the desired position
	#global_transform.origin = global_transform.origin.lerp(desired_global_position, delta * position_lerp_speed)
#
	## Always look at the look_at_target (e.g. back of the ship)
	#look_at(look_at_target.global_transform.origin, Vector3.UP)
###########################################################################################


#_____________________third iteration (spring arm and rotational orientation)_____________#

@export var target_path: NodePath
@export var look_at_target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0, 1, 20) # Local space offset from the target
@export var follow_speed: float = 5.0
@export var rotation_lerp_speed: float = 5.0

var target: Node3D
var look_at_target: Node3D

@onready var explosion: Node3D = $Explosion
func _ready() -> void:
	
	GlobalSignal.died.connect(Callable(self, "detonate_spaceship"))
	target = get_node_or_null(target_path)
	look_at_target = get_node_or_null(look_at_target_path)

	if not target:
		push_error("CameraRig: 'target_path' is not assigned.")
	if not look_at_target:
		push_error("CameraRig: 'look_at_target_path' is not assigned.")


func _process(delta: float) -> void:
	if not target or not look_at_target:
		return

	# 1. Calculate desired global position based on local offset from target
	var target_transform = target.global_transform
	# 1 #
	var desired_position = target_transform.origin + target_transform.basis * follow_offset
	
	# 2. Smoothly move toward that position
	
	#global_transform.origin = global_transform.origin.lerp(desired_position, delta * follow_speed)
	
	#--__--__--__----__--__-_-_-_--_NORMAL PLANE CONSTRAINT_--__--__--____--__-----____---#
	
	# Constrain this position to a plane perpendicular to the target's forward
	
	var target_forward = -target_transform.basis.z.normalized() # -Z is forward
	var current_position = global_transform.origin
	var target_up = target_transform.basis.y.normalized()
	
	
	# Vector from target to current camera rig
	var to_camera = current_position - target_transform.origin
	
	# Remove the component along the forward vector -> stays on the chase plane
	var forward_distance = to_camera.dot(target_forward)
	var lateral_offset = to_camera - target_forward * forward_distance
	var constrained_position = desired_position + lateral_offset
	#var constrained_position = current_position - target_forward *forward_distance
	
	# Smoothly move the rig toward the constrained desired position
	#var final_position = constrained_position.lerp(desired_position, delta * follow_speed)
	#global_transform.origin = final_position
	global_transform.origin = global_transform.origin.lerp(constrained_position, delta * follow_speed)
	
	#--__--__--__----__--__-_-_-_--__--__--__--____--__-----____---#
	# 3. Calculate direction toward look_at_target
	var to_look_at = (look_at_target.global_transform.origin - global_transform.origin).normalized()
	var desired_basis = Basis.looking_at(to_look_at, target_up)
	#var desired_basis = Basis.looking_at(to_look_at, target_transform.basis.y) # Use target's up

	# 4. Smoothly rotate toward that orientation
	#global_transform.basis = global_transform.basis.slerp(desired_basis, delta * rotation_lerp_speed)
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var desired_quat = desired_basis.get_rotation_quaternion()
	var slerped_quat = current_quat.slerp(desired_quat, delta * rotation_lerp_speed)
	global_transform.basis = Basis(slerped_quat)
	
	# 5. Compute the plane perpendicular to craft's forward
	

	
func detonate_spaceship():
	print("detonating...")
	explosion.explode() # detonation
	await get_tree().create_timer(10.0).timeout # display detonation event
	print("waited 10 seconds. dispatching to game_over.tscn...") 
	get_tree().change_scene_to_file(GlobalScenepath.game_over) # advance to game over screen
	
	
