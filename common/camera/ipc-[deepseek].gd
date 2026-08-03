# ipc-[deepseek].gd (Inertial Pursuit Camera)
extends Node3D

@export var target: Marker3D
@export var position_offset: Vector3 = Vector3(0, 2, -10)
@export var rotation_speed: float = 4.0
@export var position_speed: float = 6.0
@export var max_rotation_offset: Vector2 = Vector2(30.0, 30.0)  # x = pitch, y = yaw in degrees
@export var rotation_damping: float = 8.0
@export var fov_base: float = 75.0
@export var fov_boost: float = 10.0

# Camera reference
@onready var _camera: Camera3D = $Camera3D

# Inertial tracking variables
var _current_offset: Vector3 = position_offset
var _target_rotation: Vector3 = Vector3.ZERO
var _current_rotation: Vector3 = Vector3.ZERO
var _position_velocity: Vector3 = Vector3.ZERO
var _rotation_velocity: Vector3 = Vector3.ZERO
var _base_fov: float = fov_base
var _target_fov: float = fov_base

func _ready():
	if not _camera:
		# Try to find any Camera3D child
		for child in get_children():
			if child is Camera3D:
				_camera = child
				break
	
	if not _camera:
		push_error("No Camera3D child found!")
		return
	
	_base_fov = fov_base
	_target_fov = fov_base
	
	if target:
		# Start directly behind target in global space
		var target_transform = target.global_transform
		global_position = target_transform.origin
		
		# Position camera relative to this node
		_camera.position = position_offset
		
		# Look at target from starting position
		look_at_target()
		
		# Initialize rotations
		_current_rotation = global_rotation
		_target_rotation = target.global_rotation

func _physics_process(delta):
	if not target or not _camera:
		return
	
	# Get target's current transform
	var target_transform = target.global_transform
	var target_global_rotation = target.global_rotation
	
	# Update target rotation for camera to chase (XY only - pitch and yaw)
	_target_rotation.x = target_global_rotation.x  # Pitch
	_target_rotation.y = target_global_rotation.y  # Yaw
	# Don't track roll (z) for horizon stability
	
	# Calculate rotation difference with proper angle wrapping
	var rotation_delta = _calculate_rotation_delta(_current_rotation, _target_rotation)
	
	# Apply limits to keep ship in frame during turns
	rotation_delta.x = clamp(rotation_delta.x, -deg_to_rad(max_rotation_offset.x), deg_to_rad(max_rotation_offset.x))
	rotation_delta.y = clamp(rotation_delta.y, -deg_to_rad(max_rotation_offset.y), deg_to_rad(max_rotation_offset.y))
	
	# Apply inertial damping to rotation tracking
	_rotation_velocity = _rotation_velocity.lerp(rotation_delta * rotation_speed, rotation_damping * delta)
	_current_rotation += _rotation_velocity * delta
	
	# Update this node's rotation (the pivot)
	global_rotation = _current_rotation
	
	# Calculate desired position (behind target in target's forward direction)
	# Get target's forward vector (negative Z in Godot)
	var target_forward = -target_transform.basis.z.normalized()
	var desired_position = target_transform.origin + target_forward * position_offset.z
	
	# Apply vertical offset in world up direction
	desired_position.y += position_offset.y
	
	# Apply horizontal offset in target's right direction
	var target_right = target_transform.basis.x.normalized()
	desired_position += target_right * position_offset.x
	
	# Smooth position with spring physics
	var current_position = global_position
	var position_error = desired_position - current_position
	
	_position_velocity = _position_velocity.lerp(position_error * position_speed, delta * 4.0)
	current_position += _position_velocity * delta
	
	# Update position
	global_position = current_position
	
	# Optional: Adjust FOV based on speed for dynamic feel
	_update_fov_based_on_speed(delta)
	
	# Ensure camera is looking at target (with slight offset for better framing)
	look_at_target()

func look_at_target():
	if not target or not _camera:
		return
	
	# Make camera look at target with a slight lead for better framing
	var look_target = target.global_position
	_camera.look_at(look_target, Vector3.UP)

func _update_fov_based_on_speed(delta):
	# Optional: Add speed-based FOV effects
	if target.has_method("get_velocity"):
		var target_velocity = target.get_velocity()
		var speed_factor = clamp(target_velocity.length() / 50.0, 0.0, 1.0)
		_target_fov = _base_fov + (fov_boost * speed_factor)
		
		# Smooth FOV transition
		_camera.fov = lerp(_camera.fov, _target_fov, delta * 8.0)

func _calculate_rotation_delta(current: Vector3, target_rot: Vector3) -> Vector3:
	var delta = Vector3.ZERO
	
	# Calculate smallest angle difference for each axis
	# Pitch (X)
	delta.x = _normalize_angle(target_rot.x - current.x)
	
	# Yaw (Y)
	delta.y = _normalize_angle(target_rot.y - current.y)
	
	# No Z (roll) tracking for arcade stability
	delta.z = 0
	
	return delta

func _normalize_angle(angle: float) -> float:
	# Normalize angle to [-PI, PI] range
	while angle > PI:
		angle -= 2.0 * PI
	while angle < -PI:
		angle += 2.0 * PI
	return angle

# Utility function to set target dynamically
func set_camera_target(new_target: Node3D):
	target = new_target
	if target:
		# Reset tracking state for new target
		_current_rotation = global_rotation
		_target_rotation = target.global_rotation
		_position_velocity = Vector3.ZERO
		_rotation_velocity = Vector3.ZERO

# Debug function to visualize camera behavior
func _draw_debug():
	if not target:
		return
	
	# Visualize camera's desired position
	var target_forward = -target.global_transform.basis.z.normalized()
	var desired_pos = target.global_position + target_forward * position_offset.z
	desired_pos.y += position_offset.y
	
	#DebugDraw3D.draw_line(global_position, desired_pos, Color.GREEN, 0.1)
	#DebugDraw3D.draw_line(global_position, target.global_position, Color.YELLOW, 0.1)

func get_corrected_orientation(raw_input: Vector3) -> Vector3:
	
	'''Herein is a more comprehensive way of resolving the axes mismatch 
	between Godot and Android. Previously negating (or otherwise 
	trying to flip) Z-axis vector was causing issues to the application
	of basis rotation matrix, resulting in move_and_slide() unresponsiveness
	and worst of all, not explicit warning or errors. This new implementation
	fixes this by rotating the vector rather than negating, and improves on the 
	former function by rotating the reference frame based on Android screen
	orientation.'''

#-------------rectify sensor input-------------#
	
	# 1. Get raw sensor data
	# var raw_input = Input.get_gyroscope()
	# 2. Remap Android axes to Godot world space axes
	# Android: x=right, y=up, z=towards user
	# Godot: x=right, y=up, z=back (away from user)
	# However, if the game is LANDSCAPE, the device axes rotate!
	# We must consult the DisplayServer for screen orientation.
	
	var orientation = DisplayServer.screen_get_orientation()
	var corrected = Vector3.ZERO
	print("corrected assigned zero vector = " , corrected)
	
	match orientation:
		DisplayServer.SCREEN_LANDSCAPE:
			# Device is rotated 90 deg. Device Y becomes World -X or +X
			corrected.x = raw_input.y
			corrected.y = raw_input.x
			corrected.z = raw_input.z
		DisplayServer.SCREEN_PORTRAIT:
			corrected.x = raw_input.x
			corrected.y = raw_input.y
			corrected.z = raw_input.z
		# add other cases as needed (e.g. REVERSE_LANDSCAPE)
		_:
			corrected = raw_input
			print("corrected should be non-zero vector", corrected)
			
	# 3. Fix the "backwards" issue by rotating, not negating.
	# Rotate the vector 180 degrees around the y-axis (up)
	# This flips z and x appropriately without breaking the right-hand rule.
	
	corrected = corrected.rotated(Vector3.UP, PI)
	return corrected
