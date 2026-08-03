extends CharacterBody3D

# ---------------------------------------------------------------------------
# SHIP
#
# This is a completely ordinary CharacterBody3D: real velocity, real
# move_and_slide(), a real chase camera as a child. It has no idea it's
# flying through curved space.
#
# The only non-Euclidean-aware code here is _maybe_rebase(): once the ship
# has drifted more than `rebase_threshold` from the local patch's origin,
# it hands that displacement to the World (Main.gd) to fold into the
# authoritative curved-space position, then recenters itself back near
# zero. Keeping `rebase_threshold` small relative to `world.radius` keeps
# the flat-patch approximation error negligible (it scales roughly like
# (threshold / radius)^2).
# ---------------------------------------------------------------------------

@export var max_speed: float = 14.0
@export var acceleration: float = 6.0
@export var yaw_speed: float = 1.8
@export var pitch_speed: float = 1.3
@export var mouse_sensitivity: float = 0.0025
@export var rebase_threshold: float = 628.3

var world: Node3D
var mouse_captured := true
var pitch := 0.0


func _ready() -> void:
	world = get_parent()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_object_local(Vector3.UP, -event.relative.x * mouse_sensitivity)
		var new_pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.3, 1.3)
		rotate_object_local(Vector3.RIGHT, new_pitch - pitch)
		pitch = new_pitch
		orthonormalize()

	if event.is_action_pressed("toggle_mouse"):
		mouse_captured = not mouse_captured
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	# Standard local-frame thrust input (forward is -Z in Godot).
	var thrust_local := Vector3(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_down", "move_up"),
		Input.get_axis("move_forward", "move_back")
	)

	var target_velocity := Vector3.ZERO
	if thrust_local.length() > 0.001:
		target_velocity = global_transform.basis * thrust_local.normalized() * max_speed

	velocity = velocity.lerp(target_velocity, clamp(acceleration * delta, 0.0, 1.0))
	print("ship position : ", global_position)
	move_and_slide()

	_maybe_rebase()
	world.update_markers()


func _maybe_rebase() -> void:
	# `position` is local to the parent (World), which never itself moves,
	# so this is exactly the ship's displacement from the patch center.
	if position.length() > rebase_threshold:
		var offset := position
		world.fold_displacement(offset)
		position -= offset  # recenter to (approximately) zero
