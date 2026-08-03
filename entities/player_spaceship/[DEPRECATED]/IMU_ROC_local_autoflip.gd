#IMU_ROC_local_autoflip.gd
extends CharacterBody3D

@export var ship_mesh_path: NodePath
@export var camera_path: NodePath

@export var yaw_sensitivity   := 1.5
@export var pitch_sensitivity := 1.5
@export var roll_sensitivity  := 1.0
@export var thrust := 18.0

@export var upright_lerp_speed := 4.0
@export var auto_flip_threshold := 90.0

var gyro_filt := Vector3.ZERO
@export var gyro_lpf_alpha := 0.2

var target_roll_state := 1  # 1 = upright, -1 = inverted
var ship_mesh: Node3D
var camera: Camera3D

func _ready() -> void:
	ship_mesh = get_node(ship_mesh_path) as Node3D
	camera = get_node(camera_path) as Camera3D

func _physics_process(delta: float) -> void:
	# 1) Read and smooth gyro
	var gyro_raw = Input.get_gyroscope()
	gyro_filt = gyro_filt * (1.0 - gyro_lpf_alpha) + gyro_raw * gyro_lpf_alpha

	# 2) Apply rate-based pitch, yaw, roll to ship (body motion)
	rotation.x -= gyro_filt.x * pitch_sensitivity * delta
	rotation.y -= gyro_filt.y * yaw_sensitivity   * delta
	rotation.z -= gyro_filt.z * roll_sensitivity  * delta

	# 3) Calculate ship roll RELATIVE TO CAMERA
	var ship_in_cam_space = camera.global_transform.basis.inverse() * global_transform.basis
	var roll_deg = wrapf(rad_to_deg(ship_in_cam_space.get_euler().z), -180.0, 180.0)

	# 4) Decide upright/inverted based on roll threshold
	if roll_deg > auto_flip_threshold:
		target_roll_state = -1
	elif roll_deg < -auto_flip_threshold:
		target_roll_state = 1

	# 5) Smoothly adjust mesh roll locally
	var target_roll_angle = 0.0 if target_roll_state == 1 else 180.0
	var current_mesh_rot = ship_mesh.rotation
	current_mesh_rot.z = lerp_angle(current_mesh_rot.z, deg_to_rad(target_roll_angle), delta * upright_lerp_speed)
	ship_mesh.rotation = current_mesh_rot

	# 6) Move ship forward
	velocity = -transform.basis.z * thrust
	move_and_slide()

# Utility for float wrapping
func wrapf(value: float, min_value: float, max_value: float) -> float:
	var range = max_value - min_value
	return min_value + (value - min_value) - floor((value - min_value) / range) * range
