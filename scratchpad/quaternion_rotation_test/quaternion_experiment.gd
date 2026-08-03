# quaternion_experiment.gd
extends Node3D

# Spaceship 3D model asset
@onready var ship = $"lightfighter_yflip"


var local_forward : Vector3 # spaceship forward
var world_forward : Vector3 # global forward
var counter := 0 # program cycle counter
var elapsed : float # timer
var duration : float = 1.0 # rotation vector interpolation duration 

# Camera Vectors
var vanishing_direction: Vector3 # camera -z-axis basis
var far_point: Vector3 # effective distal vanishing point (x,y,z)
var camera: Camera3D

# ------------------------------------------------------------------
# CONFIGURATION (tweak these in the editor or script)
# ------------------------------------------------------------------
var offset : Vector3 = Vector3(0,1.5,-5) #Vector3.ZERO          # extra offset from the player
var followSpeed : float = 1.0             # lerp factor (0‑1). Faster = snappier
@export var smoothLerp : bool = true        # if false we snap instantly



func camera_motion():
	var current_cam_quaternion = Quaternion(camera.basis.orthonormalized())
	var cam_look_at = Basis.looking_at(ship.global_position, Vector3.UP)
	var cam_rotation_quaternion = cam_look_at.get_rotation_quaternion()
	camera.basis = Basis(cam_rotation_quaternion)

#-------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------
func orient_node_toward_camera_far_point_via_quaternion_interpolation(delta: float):
	
	var quat_rot = Quaternion(ship.basis.orthonormalized()) # current local orientation
	var world_quat = Quaternion(global_basis.orthonormalized()) # current global space orientation 
	var far_quat = Quaternion.from_euler(far_point) # camera vanishing point 
	counter += 1
	elapsed = 0.0
	#if counter > 256:
	print("slerping quaternions...")
	elapsed += delta
	var t = clampf(elapsed / duration, 0.0, 1.0) # rotation time duration
	#var resultant_quat = quat_rot.slerp(far_quat, t)
	var resultant_quat = Basis.looking_at(far_point).get_rotation_quaternion() # new facing direction
	var bank_to = Basis.looking_at(far_point, -Vector3.FORWARD).get_rotation_quaternion()
	bank_to = bank_to.get_euler()
	resultant_quat = resultant_quat.get_euler()
	#ship.rotation = resultant_quat
	ship.rotation = lerp(quat_rot.get_euler(),resultant_quat, t) # update facing direction
	#ship.rotation = lerp(quat_rot.get_euler(), bank_to, t)
	
	print("slerp complete")



#-------------------------------------------------------------------
# READY INIT
#-------------------------------------------------------------------
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	camera =  get_viewport().get_camera_3d()
	if camera:
		print("CAMERA! ACTION!")
	else:
		print("WARNING: No camera node found. Add a camera to the scene.")
		return # handle camera absence gracefully
	
# Direction the camera is looking (toward the vanishing point)
	vanishing_direction = -camera.global_basis.z
# A point very far in that direction
	far_point = camera.global_position + vanishing_direction * camera.far

#-------------------------------------------------------------------
# MAIN LOOP
#-------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	vanishing_direction = -camera.global_basis.z
	# A point very far in that direction
	far_point = camera.global_position + vanishing_direction * camera.far
	#orient_node_toward_camera_far_point_via_quaternion_interpolation(delta)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	#camera.global_translate(-camera.basis.z * 1)
	#var local_forward = -ship.basis.z
	#var world_forward = Vector3.FORWARD
#
	#
	#var quat_rot = Quaternion(ship.basis.orthonormalized())
	#var world_quat = Quaternion(global_basis.orthonormalized())
	#
	#var angle = local_forward.signed_angle_to(world_forward, Vector3.UP)
	#var angle_deg = rad_to_deg(angle)
	#print("local-z to global-z : ", angle_deg, " degrees")
	#
	#var quat_angle = quat_rot.angle_to(world_quat)
	#var quat_angle_deg = rad_to_deg(quat_angle)
	#print("quaternion angle delta : ", quat_angle)
	#quat_angle = 0.0
	#ship.rotate_z(quat_angle)
	
	
	#counter += 1
	#if counter == 256:
		#print("slerping quaternions...")
		#var resultant_quat = quat_rot.slerp(world_quat, 1.0)
		#resultant_quat = resultant_quat.get_euler()
		#ship.rotation = resultant_quat
		#print("slerp complete")
	
	""" NOTE: It appears there is a discrepancy between these two methods of measuring angles of about 5.092 deg.
	Is this due to floating point error (this is rather large, no?)? """
	
	#---------------------
	# FOLLOW CAMERA
	#---------------------
	# If the script runs on 3D, you’ll want vec3 math – but we keep it simple:
	if not smoothLerp:
		camera.position = ship.global_position + offset   # snap instantly
	else:
		camera.global_position = lerp(camera.global_position,
							ship.global_position + offset,
							followSpeed * delta)
		print("camera.position = ", camera.position)
		print("camera.global_position = ", camera.global_position)
		print("camera.global_basis = ", camera.global_basis)
		
	#if Input.is_action_just_pressed("ui_right"):
		##camera.global_translate(Vector3(1,0,0))
		##camera.global_rotate(Vector3.UP, deg_to_rad(15))
		#ship.global_position = lerp(ship.global_position, ship.global_position + Vector3(1.0, 0.0, 0.0), 10.0 * delta)
	#if Input.is_action_just_pressed("ui_left"):
		##camera.global_translate(Vector3(-1,0,0))
		##camera.global_rotate(Vector3.UP, deg_to_rad(-15))
		#ship.global_position = lerp(ship.global_position, ship.global_position + Vector3(-1.0, 0.0, 0.0), 10.0 * delta)
	#if Input.is_action_just_pressed("ui_up"):
		##camera.global_translate(Vector3(0,1,0))
		##camera.global_rotate(Vector3.RIGHT, deg_to_rad(-15))
		#ship.global_position = lerp(ship.global_position, ship.global_position + Vector3(0.0, 1.0, 0.0), 10.0 * delta)
	#if Input.is_action_just_pressed("ui_down"):
		##camera.global_translate(Vector3(0,-1,0))
		##camera.global_rotate(Vector3.RIGHT, deg_to_rad(15))
		#ship.global_position = lerp(ship.global_position, ship.global_position + Vector3(0.0, -1.0, 0.0), 10.0 * delta)
		
	pass
