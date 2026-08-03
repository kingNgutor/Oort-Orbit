# normal_planar_quaternion_followCam.gd
extends Camera3D


@export var follow_distance: float = 10.0
@export var rotation_lerp_speed: float = 5.0
@export var position_lerp_speed: float = 5.0

func _process(delta):
	var craft = $CharacterBody3D  # adjust path as needed
	var craft_transform = craft.global_transform

	# Get camera basis & desired rotation
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var desired_quat = craft_transform.basis.get_rotation_quaternion()
	var new_quat = current_quat.slerp(desired_quat, delta * rotation_lerp_speed)
	var new_basis = Basis(new_quat)

	# Compute the plane perpendicular to craft's forward
	var craft_forward = -craft_transform.basis.z.normalized()
	var craft_position = craft_transform.origin

	# Project current camera position onto the chase plane
	var to_camera = global_transform.origin - craft_position
	var distance_along_forward = to_camera.dot(craft_forward)
	var projected_pos = global_transform.origin - (craft_forward * distance_along_forward)

	# Compute desired position: behind craft at fixed distance, constrained to plane
	var desired_pos = craft_position - (craft_forward * follow_distance)
	desired_pos = desired_pos.linear_interpolate(projected_pos, delta * position_lerp_speed)

	# Apply new transform
	global_transform.origin = desired_pos
	global_transform.basis = new_basis
