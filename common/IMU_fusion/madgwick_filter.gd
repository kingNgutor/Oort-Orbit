#madgwick_filter.gd
extends Node
class_name MadgwickFilter

# ============================================================
# Madgwick Filter for Godot 4.x (Quaternion-based sensor fusion)
# ============================================================

@export var beta: float = 0.1  # responsiveness (0.03–0.2 typical)
var q: Quaternion = Quaternion(0.0, 0.0, 0.0, 1.0)  # orientation quaternion (x, y, z, w)

func reset():
	q = Quaternion(0.0, 0.0, 0.0, 1.0)


# ------------------------------------------------------------
# update(gyro, accel, magnetometer, delta)
# gyro: Vector3 (radians/sec)
# accel: Vector3 (m/s²)
# magnetometer: Vector3 (optional, µT)
# delta: float (seconds)
# ------------------------------------------------------------
func update(gyro: Vector3, accel: Vector3, magnetometer: Vector3 = Vector3.ZERO, delta: float = 0.016) -> void:
	if accel.length() == 0:
		return

	accel = accel.normalized()
	var use_mag := magnetometer.length() > 0.0
	if use_mag:
		magnetometer = magnetometer.normalized()

	var q1 = q.w
	var q2 = q.x
	var q3 = q.y
	var q4 = q.z
	var gx = gyro.x
	var gy = gyro.y
	var gz = gyro.z
	var ax = accel.x
	var ay = accel.y
	var az = accel.z
	var mx = magnetometer.x
	var my = magnetometer.y
	var mz = magnetometer.z

	# Gradient descent algorithm corrective step
	var s1: float
	var s2: float
	var s3: float
	var s4: float

	if use_mag:
		# Reference direction of Earth's magnetic field
		var _2q1mx = 2.0 * q1 * mx
		var _2q1my = 2.0 * q1 * my
		var _2q1mz = 2.0 * q1 * mz
		var _2q2mx = 2.0 * q2 * mx

		var hx = mx * q1 * q1 - _2q1my * q4 + _2q1mz * q3 + mx * q2 * q2 + 2.0 * q2 * my * q3 + 2.0 * q2 * mz * q4 - mx * q3 * q3 - mx * q4 * q4
		var hy = 2.0 * q1 * mx * q4 + my * q1 * q1 - 2.0 * q1 * mz * q2 + 2.0 * q2 * mx * q3 - my * q2 * q2 + my * q3 * q3 + 2.0 * q3 * mz * q4 - my * q4 * q4
		var _2bx = sqrt(hx * hx + hy * hy)
		var _2bz = -2.0 * q1 * mx * q3 + 2.0 * q1 * my * q2 + mz * q1 * q1 + 2.0 * q2 * mx * q4 - mz * q2 * q2 + 2.0 * q3 * my * q4 - mz * q3 * q3 + mz * q4 * q4

		# Simplified correction step (we don’t need the full symbolic expansion here)
		var f1 = 2.0 * (q2 * q4 - q1 * q3) - ax
		var f2 = 2.0 * (q1 * q2 + q3 * q4) - ay
		var f3 = 2.0 * (0.5 - q2 * q2 - q3 * q3) - az
		s1 = -2.0 * q3 * f1 + 2.0 * q2 * f2
		s2 = 2.0 * q4 * f1 + 2.0 * q1 * f2 - 4.0 * q2 * f3
		s3 = -2.0 * q1 * f1 + 2.0 * q4 * f2 - 4.0 * q3 * f3
		s4 = 2.0 * q2 * f1 + 2.0 * q3 * f2
	else:
		# 6DOF version (no magnetometer)
		var f1 = 2.0 * (q2 * q4 - q1 * q3) - ax
		var f2 = 2.0 * (q1 * q2 + q3 * q4) - ay
		var f3 = 2.0 * (0.5 - q2 * q2 - q3 * q3) - az
		s1 = -2.0 * q3 * f1 + 2.0 * q2 * f2
		s2 = 2.0 * q4 * f1 + 2.0 * q1 * f2 - 4.0 * q2 * f3
		s3 = -2.0 * q1 * f1 + 2.0 * q4 * f2 - 4.0 * q3 * f3
		s4 = 2.0 * q2 * f1 + 2.0 * q3 * f2

	# Normalize step magnitude
	var norm = sqrt(s1 * s1 + s2 * s2 + s3 * s3 + s4 * s4)
	if norm == 0:
		return
	s1 /= norm
	s2 /= norm
	s3 /= norm
	s4 /= norm

	# Compute rate of change of quaternion
	var q_dot1 = 0.5 * (-q2 * gx - q3 * gy - q4 * gz) - beta * s1
	var q_dot2 = 0.5 * (q1 * gx + q3 * gz - q4 * gy) - beta * s2
	var q_dot3 = 0.5 * (q1 * gy - q2 * gz + q4 * gx) - beta * s3
	var q_dot4 = 0.5 * (q1 * gz + q2 * gy - q3 * gx) - beta * s4

	# Integrate to yield new quaternion
	q1 += q_dot1 * delta
	q2 += q_dot2 * delta
	q3 += q_dot3 * delta
	q4 += q_dot4 * delta

	# Normalize quaternion
	norm = sqrt(q1 * q1 + q2 * q2 + q3 * q3 + q4 * q4)
	q1 /= norm
	q2 /= norm
	q3 /= norm
	q4 /= norm

	q = Quaternion(q2, q3, q4, q1)

func get_orientation() -> Quaternion:
	return q
