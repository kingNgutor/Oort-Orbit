extends Node3D

# ---------------------------------------------------------------------------
# S3 WORLD  (floating-origin flight on a 3-sphere)
#
# The ship (a normal CharacterBody3D) flies through an ordinary flat local
# patch using real Godot physics -- velocity, move_and_slide, collisions,
# a normal chase camera. Nothing about that motion is special.
#
# Separately, this node tracks the AUTHORITATIVE state of where that flat
# patch sits on the curved 3-sphere:
#   Q : unit quaternion, the patch center's true position on S3
#   F : unit quaternion, the patch's orientation frame (maps the local
#       flat patch's fixed XYZ axes to tangent directions at Q)
#
# Whenever the ship drifts more than `rebase_threshold` from the patch
# center, Ship.gd calls fold_displacement(offset): that displacement gets
# folded into Q via the exponential map (the same update rule used for
# plain movement), and the ship is recentered near the origin. Because
# every marker's rendered position is recomputed from Q/F every frame via
# the logarithmic map, nothing visually pops when this happens -- the
# world just continuously re-centers itself under the ship.
# ---------------------------------------------------------------------------

@export var radius: float = 100.0          # size of the universe
@export var marker_count: int = 40

var Q := Quaternion.IDENTITY   # patch center position on S3
var F := Quaternion.IDENTITY   # patch orientation frame

var distance_traveled := 0.0

var markers: Array = []   # each entry: {node: MeshInstance3D, q: Quaternion, name: String}

@onready var world: Node3D = $World
@onready var ship: CharacterBody3D = $Ship
@onready var label: Label = $HUD/Label


func _ready() -> void:
	_spawn_markers()
	update_markers()


func _spawn_markers() -> void:
	# Big bright "home" marker sitting right where the ship starts.
	_add_marker(Quaternion.IDENTITY, Color(1.0, 0.85, 0.1), 1.0, "HOME")

	# A ring of markers along one great circle, so you can clearly watch
	# yourself fly all the way around the sphere and come back to HOME.
	var ring_axis := Vector3(0, 1, 0).normalized()
	var ring_steps := 16
	for i in range(ring_steps):
		var t := (float(i) / float(ring_steps)) * TAU
		var q := Quaternion(sin(t / 2.0) * ring_axis.x,
							sin(t / 2.0) * ring_axis.y,
							sin(t / 2.0) * ring_axis.z,
							cos(t / 2.0))
		if i != 0:
			_add_marker(q, Color(0.2, 0.6, 1.0), 0.4, "ring_%d" % i)

	# A scatter of random markers across the whole sphere for spatial reference.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(marker_count):
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if v.length() < 0.001:
			continue
		v = v.normalized()
		var theta := rng.randf_range(0.15, PI - 0.15)  # avoid the antipode singularity
		var q := Quaternion(sin(theta / 2.0) * v.x, sin(theta / 2.0) * v.y,
							sin(theta / 2.0) * v.z, cos(theta / 2.0))
		var hue := rng.randf()
		_add_marker(q, Color.from_hsv(hue, 0.6, 0.9), rng.randf_range(0.3, 0.8), "star_%d" % i)


func _add_marker(q: Quaternion, color: Color, size: float, marker_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mesh_instance.material_override = mat
	mesh_instance.name = marker_name
	world.add_child(mesh_instance)
	markers.append({"node": mesh_instance, "q": q.normalized(), "name": marker_name})


# Called by Ship.gd whenever it has drifted too far from the patch center.
# `local_offset` is the ship's accumulated displacement in the flat patch's
# fixed Godot coordinates (NOT the ship's own rotating body frame).
func fold_displacement(local_offset: Vector3) -> void:
	var dist := local_offset.length()
	if dist < 0.000001:
		return
	var dir := local_offset / dist
	var t := dist / radius  # geodesic angle covered by this displacement

	# Convert the flat local direction into the ambient tangent direction at Q.
	var v := F * Quaternion(dir.x, dir.y, dir.z, 0.0) * F.inverse()
	var step := Quaternion(sin(t) * v.x, sin(t) * v.y, sin(t) * v.z, cos(t))

	Q = (Q * step).normalized()
	F = (F * step).normalized()
	distance_traveled += dist


# Logarithmic map: converts another point's global quaternion position into
# an ordinary Vector3 in the flat patch's fixed local coordinates (the same
# coordinates the ship and camera live in), with true geodesic distance
# preserved as the vector's length.
func local_position_of(other_q: Quaternion) -> Vector3:
	var delta := Q.inverse() * other_q
	var w = clamp(delta.w, -1.0, 1.0)
	var d := acos(w)  # geodesic distance on the unit sphere, in [0, PI]
	var s := sin(d)
	var dir: Vector3
	if s < 0.0001:
		dir = Vector3.ZERO
	else:
		dir = Vector3(delta.x, delta.y, delta.z) / s
	var local_dir_q := F.inverse() * Quaternion(dir.x, dir.y, dir.z, 0.0) * F
	var local_dir := Vector3(local_dir_q.x, local_dir_q.y, local_dir_q.z)
	return local_dir * d * radius


func update_markers() -> void:
	for m in markers:
		m.node.position = local_position_of(m.q)
	_update_hud()


func _update_hud() -> void:
	var circumference := TAU * radius
	label.text = "S3 SHIP — flying through a 3-sphere with a real CharacterBody3D\n" \
		+ "W/S: thrust fwd/back   A/D: strafe   Space/Shift: up/down   Mouse: steer   Esc: cursor\n" \
		+ "World radius R = %.1f   |   great-circle circumference = %.1f\n" % [radius, circumference] \
		+ "Distance traveled: %.1f  (fly %.1f in a straight line to fully loop around)\n" % [distance_traveled, circumference] \
		+ "Yellow sphere = your starting point (HOME). Fly straight long enough and you'll return to it."
