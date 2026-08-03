extends CharacterBody3D
# Full IMU flight control (Godot 4.x, mobile sensors or external feed you pipe into the getters)
# - Complementary filter for pitch/roll (gyro + accel)
# - Yaw from gyro (angular velocity)
# - Smooth bank (roll) while turning
# - Low-pass filtering + gyro bias calibration

# ========= Tunables =========
@export_group("Filtering")
@export_range(0.0, 1.0, 0.01) var accel_lpf_alpha := 0.12          # accel low-pass (lower = smoother, more lag)
@export_range(0.0, 1.0, 0.01) var gyro_lpf_alpha  := 0.20          # gyro low-pass
@export_range(0.0, 1.0, 0.01) var comp_acc_weight := 0.04          # complementary filter accel weight (0.02–0.08)
@export var gyro_bias_calibration_frames := 60                      # frames to average gyro bias at startup

@export_group("Controls")
@export var yaw_sensitivity      := 1.6    # scales gyro.y (rad/s) → yaw
@export var pitch_sensitivity    := 1.0    # scales estimated pitch → ship pitch
@export var roll_level_strength  := 0.65   # how strongly the ship levels toward estimated roll
@export var bank_from_turn_gain  := 0.55   # extra visual bank from yaw rate
@export var max_bank_deg         := 45.0   # clamp visual bank
@export_range(0.0, 1.0, 0.01) var rot_lerp := 0.18                 # smoothing for applying rotations

@export_group("Movement")
@export var thrust := 18.0                  # forward m/s
@export var strafe := 0.0                   # optional lateral drift
@export var drag   := 0.8                   # 0..1 blend toward desired velocity

# ========= State =========
var accel_raw   : Vector3 = Vector3.ZERO
var gyro_raw    : Vector3 = Vector3.ZERO            # rad/s
var accel_filt  : Vector3 = Vector3.ZERO
var gyro_filt   : Vector3 = Vector3.ZERO
var gyro_bias   : Vector3 = Vector3.ZERO

var _bias_sum   : Vector3 = Vector3.ZERO
var _bias_count : int = 0
var _calibrated : bool = false

# Estimated attitude (radians)
var est_pitch := 0.0   # rotation around X (nose up/down)
var est_roll  := 0.0   # rotation around Z (wing up/down)
# Yaw is integrated directly into the node's rotation.y via gyro (no absolute reference)

func _ready() -> void:
	# Optional: align ship to world forward initially
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	# 1) Read sensors (replace these two lines if you feed external IMU data)
	accel_raw = Input.get_accelerometer()     # approx. m/s^2 (gravity ~ 9.81 magnitude)
	gyro_raw  = Input.get_gyroscope()         # rad/s, device axes

	# 2) Low-pass filter (exponential moving average)
	accel_filt = accel_filt * (1.0 - accel_lpf_alpha) + accel_raw * accel_lpf_alpha
	gyro_filt  = gyro_filt  * (1.0 - gyro_lpf_alpha)  + gyro_raw  * gyro_lpf_alpha

	# 3) Gyro bias calibration (collect a few frames while device is roughly still)
	if not _calibrated:
		_bias_sum += gyro_filt
		_bias_count += 1
		if _bias_count >= gyro_bias_calibration_frames:
			gyro_bias = _bias_sum / float(_bias_count)
			_calibrated = true
		return  # wait until bias done so controls are stable

	var gyro_unbiased: Vector3 = gyro_filt - gyro_bias

	# ---- Coordinate notes (Godot vs device) ----
	# Godot 3D uses: +X right, +Y up, -Z forward for Basis/transform.
	# On many phones: gyro.x≈pitch rate, gyro.y≈yaw rate, gyro.z≈roll rate — but signs can differ by device.
	# You may need to flip signs below if controls feel inverted.

	# 4) Complementary filter for pitch/roll (absolute tilt from gravity + integrated gyro)
	# Compute tilt from accelerometer (gravity dir).
	# Common formulas (stable across devices, may need sign tweaks):
	# roll_acc  = atan2(accel_y, accel_z)
	# pitch_acc = atan2(-accel_x, sqrt(accel_y^2 + accel_z^2))
	var ax := accel_filt.x
	var ay := accel_filt.y
	var az := accel_filt.z
	var roll_from_acc  := atan2(ay, az)
	var pitch_from_acc := atan2(-ax, sqrt(ay * ay + az * az))

	# Integrate gyro for smooth short-term changes
	var pitch_gyro := est_pitch + gyro_unbiased.x * delta
	var roll_gyro  := est_roll  + gyro_unbiased.z * delta

	# Fuse (small accel weight; gyro dominates short-term, accel corrects drift)
	est_pitch = lerp(pitch_gyro, pitch_from_acc, comp_acc_weight)
	est_roll  = lerp(roll_gyro,  roll_from_acc,  comp_acc_weight)

	# 5) Apply yaw from gyro (turn rate)
	rotation.y -= gyro_unbiased.y * yaw_sensitivity * delta

	# 6) Compute target visual bank:
	#    - part 1: level toward true roll (from complementary filter) so ship doesn’t stay crooked
	#    - part 2: extra bank into the turn from yaw rate (feels “plane-like”)
	var desired_bank := est_roll * roll_level_strength  +  (-gyro_unbiased.y) * bank_from_turn_gain
	var max_bank_rad := deg_to_rad(max_bank_deg)
	desired_bank = clamp(desired_bank, -max_bank_rad, max_bank_rad)

	# 7) Apply pitch & bank smoothly
	var target_pitch := est_pitch * pitch_sensitivity
	rotation.x = lerp_angle(rotation.x, target_pitch, rot_lerp)
	rotation.z = lerp_angle(rotation.z, desired_bank,  rot_lerp)

	# 8) Move: constant forward thrust (customize as needed)
	var desired_velocity := -transform.basis.z * thrust \
						  +  transform.basis.x * strafe
	# simple drag toward desired
	velocity = lerp(velocity, desired_velocity, clamp(drag * delta * 10.0, 0.0, 1.0))
	move_and_slide()

# ===== Optional helpers =====

# If your IMU is noisy, you can expose a deadzone to ignore tiny jitters:
func apply_deadzone(v: Vector3, dz: float) -> Vector3:
	if dz <= 0.0:
		return v
	return Vector3(
		0.0 if abs(v.x) < dz else v.x,
		0.0 if abs(v.y) < dz else v.y,
		0.0 if abs(v.z) < dz else v.z
	)


# To feed external IMU data (e.g., UDP from ESP32), replace the reads with your own setters:
func set_external_accel(value: Vector3) -> void:
	accel_raw = value
func set_external_gyro(value: Vector3) -> void:
	gyro_raw = value
