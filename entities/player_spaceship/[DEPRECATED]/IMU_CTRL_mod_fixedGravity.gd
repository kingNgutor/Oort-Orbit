extends CharacterBody3D

@export_group("Filtering")
@export_range(0.0, 1.0, 0.01) var accel_lpf_alpha := 0.12
@export_range(0.0, 1.0, 0.01) var gyro_lpf_alpha  := 0.20
@export_range(0.0, 1.0, 0.01) var comp_acc_weight := 0.04
@export var gyro_bias_calibration_frames := 60

@export_group("Controls")
@export var yaw_sensitivity      := 1.6
@export var pitch_sensitivity    := 1.0
@export var roll_level_strength  := 0.65
@export var bank_from_turn_gain  := 0.55
@export var max_bank_deg         := 45.0
@export_range(0.0, 1.0, 0.01) var rot_lerp := 0.18

@export_group("Movement")
@export var thrust := 18.0
@export var strafe := 0.0
@export var drag   := 0.8

var accel_raw   : Vector3 = Vector3.ZERO
var gyro_raw    : Vector3 = Vector3.ZERO
var accel_filt  : Vector3 = Vector3.ZERO
var gyro_filt   : Vector3 = Vector3.ZERO
var gyro_bias   : Vector3 = Vector3.ZERO

var _bias_sum   : Vector3 = Vector3.ZERO
var _bias_count : int = 0
var _calibrated : bool = false

var est_pitch := 0.0
var est_roll  := 0.0

func _ready() -> void:
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	# 1) Read sensors (gravity removed)
	accel_raw = Input.get_accelerometer() - Input.get_gravity()  # linear acceleration, no gravity
	gyro_raw  = Input.get_gyroscope()           # angular velocity (rad/s)

	# 2) Low-pass filter
	accel_filt = accel_filt * (1.0 - accel_lpf_alpha) + accel_raw * accel_lpf_alpha
	gyro_filt  = gyro_filt  * (1.0 - gyro_lpf_alpha)  + gyro_raw  * gyro_lpf_alpha

	# 3) Gyro bias calibration
	if not _calibrated:
		_bias_sum += gyro_filt
		_bias_count += 1
		if _bias_count >= gyro_bias_calibration_frames:
			gyro_bias = _bias_sum / float(_bias_count)
			_calibrated = true
		return

	var gyro_unbiased: Vector3 = gyro_filt - gyro_bias

	# 4) Complementary filter for pitch/roll
	var ax := accel_filt.x
	var ay := accel_filt.y
	var az := accel_filt.z

	# These formulas only make sense if you still want tilt influence
	var roll_from_acc  := atan2(ay, az)
	var pitch_from_acc := atan2(-ax, sqrt(ay * ay + az * az))

	var pitch_gyro := est_pitch + gyro_unbiased.x * delta
	var roll_gyro  := est_roll  + gyro_unbiased.z * delta

	est_pitch = lerp(pitch_gyro, pitch_from_acc, comp_acc_weight)
	est_roll  = lerp(roll_gyro,  roll_from_acc,  comp_acc_weight)

	# 5) Apply yaw from gyro
	rotation.y -= gyro_unbiased.y * yaw_sensitivity * delta

	# 6) Compute bank
	var desired_bank := est_roll * roll_level_strength + (-gyro_unbiased.y) * bank_from_turn_gain
	var max_bank_rad := deg_to_rad(max_bank_deg)
	desired_bank = clamp(desired_bank, -max_bank_rad, max_bank_rad)

	# 7) Apply pitch & bank
	var target_pitch := est_pitch * pitch_sensitivity
	rotation.x = lerp_angle(rotation.x, target_pitch, rot_lerp)
	rotation.z = lerp_angle(rotation.z, desired_bank,  rot_lerp)

	# 8) Movement
	var desired_velocity := -transform.basis.z * thrust + transform.basis.x * strafe
	velocity = lerp(velocity, desired_velocity, clamp(drag * delta * 10.0, 0.0, 1.0))
	move_and_slide()

# ===== Optional deadzone =====
func apply_deadzone(v: Vector3, dz: float) -> Vector3:
	if dz <= 0.0:
		return v
	return Vector3(
		0.0 if abs(v.x) < dz else v.x,
		0.0 if abs(v.y) < dz else v.y,
		0.0 if abs(v.z) < dz else v.z
	)
