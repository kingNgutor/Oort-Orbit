#IMU_Relative_Orientation_Control.gd
extends CharacterBody3D

@export var yaw_sensitivity   := 1.5
@export var pitch_sensitivity := 1.5
@export var roll_sensitivity  := 1.0
@export var thrust := 18.0

var gyro_filt := Vector3.ZERO
@export var gyro_lpf_alpha := 0.2

func _physics_process(delta: float) -> void:
	# Read gyro
	var gyro_raw = Input.get_gyroscope()
	
	# Low-pass filter
	gyro_filt = gyro_filt * (1.0 - gyro_lpf_alpha) + gyro_raw * gyro_lpf_alpha

	# Apply rotation (rate control)
	rotation.x -= gyro_filt.x * pitch_sensitivity * delta  # Pitch
	rotation.y -= gyro_filt.y * yaw_sensitivity   * delta  # Yaw
	rotation.z -= gyro_filt.z * roll_sensitivity  * delta  # Roll

	# Constant forward thrust
	velocity = -transform.basis.z * thrust
	move_and_slide()
