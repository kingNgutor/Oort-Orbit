#IMU_ROC_autoflip.gd
extends CharacterBody3D

@export var yaw_sensitivity   := 1.5
@export var pitch_sensitivity := 1.5
@export var roll_sensitivity  := 1.0
@export var thrust := 18.0

@export var upright_lerp_speed := 4.0  # How quickly to return upright after flip
@export var auto_flip_threshold := 90.0  # Degrees roll before triggering flip

var gyro_filt := Vector3.ZERO
@export var gyro_lpf_alpha := 0.2

var target_roll_state := 1  # 1 = upright, -1 = inverted

func _physics_process(delta: float) -> void:
	# 1) Read and smooth gyro
	var gyro_raw = Input.get_gyroscope()
	gyro_filt = gyro_filt * (1.0 - gyro_lpf_alpha) + gyro_raw * gyro_lpf_alpha

	# 2) Apply rate-based pitch, yaw, roll
	rotation.x -= gyro_filt.x * pitch_sensitivity * delta  # Pitch
	rotation.y -= gyro_filt.y * yaw_sensitivity   * delta  # Yaw
	rotation.z -= gyro_filt.z * roll_sensitivity  * delta  # Roll

	# 3) Normalize roll to -180..180 degrees WITHOUT using '%' on floats
	var roll_deg := rad_to_deg(rotation.z)
	# float modulo: subtract full 360-degree turns
	roll_deg = roll_deg - floor(roll_deg / 360.0) * 360.0
	if roll_deg > 180.0:
		roll_deg -= 360.0

	# 4) Check for flip threshold crossing
	if roll_deg > auto_flip_threshold:
		target_roll_state = -1  # inverted
	elif roll_deg < -auto_flip_threshold:
		target_roll_state = 1   # upright

	# 5) Smooth roll correction toward desired state (0° upright or 180° inverted)
	var target_roll_angle := 0.0 if target_roll_state == 1 else 180.0
	rotation.z = lerp_angle(rotation.z, deg_to_rad(target_roll_angle), delta * upright_lerp_speed)

	# 6) Move ship forward
	velocity = -transform.basis.z * thrust
	move_and_slide()
