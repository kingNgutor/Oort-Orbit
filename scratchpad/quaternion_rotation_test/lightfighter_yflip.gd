# lightfighter_yflip.gd
extends Node3D

#Spaceship Position
var player_position : Vector3

var turn_input = Vector2() # init turn director to (0, 0)
@onready var cam = get_viewport().get_camera_3d()
var bank_angle : float = 0.0
@export var bank_speed : float = 20.0

func map_turn_input(delta):
	# poll input 
	var x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var combined_xy_axes = Vector2(x, y).normalized()
	# turn_input = -combined_xy_axes #inverted axes (up is down, down is up)
	turn_input = combined_xy_axes
	
	#if x < 0:
		#cam.set_h_offset(2.0)
		##cam.set_perspective(100.0, 0.05, 4000)
	#if x > 0:
		#cam.set_h_offset(-2.0)
		##cam.set_perspective(100.0, 0.05, 4000)
	#if y < 0:
		#cam.set_v_offset(2.0)
	#if y > 0:
		#cam.set_v_offset(-2.0)
	
	var translation_vector := Vector3(turn_input.x, turn_input.y, 0) # convert 2D input to logical Vector3 to satisfy global_translate internal representation
	var current_rotation = Quaternion(basis.orthonormalized()) # this node's (i.e. ship's) current rotation quaternion matrix
	global_translate(translation_vector * 121 * delta) # apply translation vector to move node3d (ship)
	#------------------------------------------------------------#
	# Roll Banking Subsystem
	#------------------------------------------------------------#
	'''The ship rotates around Z-axis relative to the camera's vanishing point.
	Quaternion spherical interpolation is applied to the vectors banking around 
	and facing toward the vanishing point resulting in a net rotation which is 
	applied to the ships basis rotation matrix.'''
	var vanishing_direction = -cam.global_basis.z # Vector3.FORWARD # camera's forward-facing direction 
	var far_point = cam.global_position + vanishing_direction * cam.far # camera perspective vanishing point
	
	
	
	# 1. Base look-at quaternion
	var look_basis = Basis.looking_at(far_point - global_position, Vector3.UP)
	var look_quat = look_basis.get_rotation_quaternion()
	
	# 2. Compute target bank angle from input, reset when input stops
	var target_bank = -x * deg_to_rad(45)
	bank_angle = lerp(bank_angle, target_bank, bank_speed * delta)
	
	# 3. Bank rotation is ALWAYS around the ship's local z (forward)
	var bank_quat = Quaternion(Vector3.FORWARD, bank_angle)
	
	# 4. Compose: look first, then bank in local space
	var target_quat = look_quat * bank_quat
	
	# 5. Spherically interpolate the whole thing at once
	current_rotation = current_rotation.slerp(target_quat, 2.0 * delta)
	global_transform.basis = Basis(current_rotation) # apply interpolated rotation to node3d
	
	#------------------------------------------------------------#
	# Roll Banking Subsystem ---- END ---- #
	#------------------------------------------------------------#
	
	
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	global_translate(-basis.z * 1)
	var turn_input = Vector2() # reset turn_input for subsequent polling
	map_turn_input(delta)
	print("ship.global_position = ",global_position)
	player_position = global_transform.origin
	GlobalSignal.spaceship_position.emit(player_position)
	
