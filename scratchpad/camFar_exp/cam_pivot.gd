#extends Node3D
#
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#
	#global_translate(-basis.z * 1)
	#print("position : ", global_transform.origin)
	#pass

# camFar_exp.tscn
# cam_pivot.gd

""" The objective herein is to use a fixed plane at camera far to generate multimesh instances
and then calculate the vector from that plane to the camera, and send an asteroid toward the camera whilst 
staying with the frustum. The script checks first to verify that the path is in view before moving the multimesh instance. 
At least it should... """

extends Node3D

@export var camera: Camera3D
@export var spawn_plane: MeshInstance3D
@export var multi_mesh_instance: MultiMeshInstance3D #= $"camPivot/asteroids"

@export var asteroid_count: int = 200
@export var asteroid_speed_min: float = 5.0
@export var asteroid_speed_max: float = 20.0
@export var plane_half_extents: Vector2 = Vector2(10.0, 10.0)  # set in Inspector

# Stored per-instance for _process updates
var velocities: Array[Vector3] = []



func _ready() -> void:
	_spawn_asteroids()

func _spawn_asteroids() -> void:
	var mm: MultiMesh = multi_mesh_instance.multimesh
	mm.instance_count = asteroid_count
	velocities.resize(asteroid_count)

	var plane_transform: Transform3D = spawn_plane.global_transform
	# Plane local axes in world space
	# The plane mesh sits orthogonal to camera forward,
	# so its local X and Z span the visible surface
	var plane_right:   Vector3 = plane_transform.basis.x   # world-space U axis
	var plane_up:	  Vector3 = plane_transform.basis.y   # world-space V axis
	var plane_origin:  Vector3 = plane_transform.origin

	# Half-extents of the plane mesh (assuming PlaneMesh default size 2x2, adjust to yours)
	#var plane_mesh := spawn_plane.mesh as PlaneMesh
	#var half_w: float = plane_mesh.size.x * 0.5
	#var half_h: float = plane_mesh.size.y * 0.5
	
	var fp := _get_far_plane_basis()
	var to_camera: Vector3 = -camera.global_transform.basis.z  # asteroids fly along -forward

	for i in asteroid_count:
		var spawn_pos: Vector3 = _sample_far_plane(fp)
		var asteroid_basis: Basis = _basis_facing(to_camera)
		mm.set_instance_transform(i, Transform3D(asteroid_basis, spawn_pos))
		velocities[i] = to_camera * randf_range(asteroid_speed_min, asteroid_speed_max)
		
	#var half_w: float = plane_half_extents.x
	#var half_h: float = plane_half_extents.y
	#
	## Direction from plane toward camera (asteroids fly this way)
	#var to_camera: Vector3 = (camera.global_position - plane_origin).normalized()
#
	#for i in asteroid_count:
		#var spawn_pos: Vector3 = _frustum_clamped_position(
			#plane_origin, plane_right, plane_up,
			#half_w, half_h
		#)
#
		## Orient each asteroid: Z- faces toward camera
		#var asteroid_basis: Basis = _basis_facing(to_camera)
		#var t := Transform3D(asteroid_basis, spawn_pos)
		#mm.set_instance_transform(i, t)
		#
#
		## Randomise speed along the to_camera direction
		#var speed := randf_range(asteroid_speed_min, asteroid_speed_max)
		#velocities[i] = to_camera * speed
		#

#func _spawn_asteroids() -> void:
	#var mm: MultiMesh = multi_mesh_instance.multimesh
	#mm.instance_count = asteroid_count
	#velocities.resize(asteroid_count)
#
	#var fp := _get_far_plane_basis()
	#var to_camera: Vector3 = -camera.global_transform.basis.z  # asteroids fly along -forward
#
	#for i in asteroid_count:
		#var spawn_pos: Vector3 = _sample_far_plane(fp)
		#var asteroid_basis: Basis = _basis_facing(to_camera)
		#mm.set_instance_transform(i, Transform3D(asteroid_basis, spawn_pos))
		#velocities[i] = to_camera * randf_range(asteroid_speed_min, asteroid_speed_max)

func _sample_far_plane(fp: Dictionary) -> Vector3:
	var u := randf_range(-fp.half_w, fp.half_w)
	var v := randf_range(-fp.half_h, fp.half_h)
	return fp.origin + fp.right * u + fp.up * v

#func _process(delta: float) -> void:
	#var mm: MultiMesh = multi_mesh_instance.multimesh
	#var fp := _get_far_plane_basis()  # recalculate each frame if camera pivot moves
#
	#for i in asteroid_count:
		#var t: Transform3D = mm.get_instance_transform(i)
		#t.origin += velocities[i] * delta
#
		#if _is_behind_camera(t.origin):
			#t.origin = _sample_far_plane(fp)
#
		#mm.set_instance_transform(i, t)


func _frustum_clamped_position(
	origin: Vector3,
	right: Vector3,
	up: Vector3,
	half_w: float,
	half_h: float
) -> Vector3:
	# Keep sampling until the point projects inside the camera viewport
	# Typically hits on the first try because the plane IS the frustum cross-section
	for _attempt in 8:
		var u := randf_range(-half_w, half_w)
		var v := randf_range(-half_h, half_h)
		var world_pos := origin + right * u + up * v

		# Reject if outside NDC [-1,1] in both axes
		var ndc: Vector2 = camera.unproject_position(world_pos)
		var vp_size: Vector2 = camera.get_viewport().get_visible_rect().size
		var uv := ndc / vp_size			  # 0..1 space
		if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
			return world_pos

	# Fallback: plane centre (should rarely trigger)
	return origin

func _basis_facing(direction: Vector3) -> Basis:
	# Constructs a Basis whose -Z faces `direction`
	var forward := -direction
	var ref_up := Vector3.UP
	if abs(forward.dot(ref_up)) > 0.99:
		ref_up = Vector3.RIGHT
	var right := forward.cross(ref_up).normalized()
	var up	:= right.cross(forward).normalized()
	return Basis(right, up, forward)

func _process(delta: float) -> void:
	var mm: MultiMesh = multi_mesh_instance.multimesh
	#for i in asteroid_count:
		#var t: Transform3D = mm.get_instance_transform(i)
		#t.origin += velocities[i] * delta
	
	var fp := _get_far_plane_basis()  # recalculate each frame if camera pivot moves

	for i in asteroid_count:
		var t: Transform3D = mm.get_instance_transform(i)
		t.origin += velocities[i] * delta

		if _is_behind_camera(t.origin):
			t.origin = _sample_far_plane(fp)

		#mm.set_instance_transform(i, t)
		# Recycle: if past the camera, teleport back to the spawn plane
		if _is_behind_camera(t.origin):
			t.origin = _frustum_clamped_position(
				spawn_plane.global_transform.origin,
				spawn_plane.global_transform.basis.x,
				spawn_plane.global_transform.basis.y,
				plane_half_extents.x,
				plane_half_extents.y
			)

		mm.set_instance_transform(i, t)
		#spawn_plane.global_translate(-basis.z * 0.01)
		#print("campivot_pos = ",global_transform.origin)
		#print("plane_pos = ", spawn_plane.global_transform.origin)
		


func _is_behind_camera(world_pos: Vector3) -> bool:
	
	
	# Positive depth means in front of camera in Godot's right-hand system
	var local_pos: Vector3 = camera.global_transform.affine_inverse() * world_pos
	return local_pos.z > 0.5   # small positive threshold = just passed the camera

func _get_far_plane_basis() -> Dictionary:
	# get_frustum() returns Array[Plane] in order:
	# 0: left, 1: right, 2: top (or bottom), 3: bottom (or top), 4: near, 5: far
	var frustum: Array[Plane] = camera.get_frustum()
	var far_plane: Plane = frustum[5]

	# Far plane center: walk from camera along -Z by far distance
	var cam_forward: Vector3 = -camera.global_transform.basis.z
	var far_center: Vector3 = camera.global_position + cam_forward * camera.far

	# Reconstruct world-space right and up on the far plane
	var cam_right: Vector3 = camera.global_transform.basis.x
	var cam_up: Vector3	= camera.global_transform.basis.y

	# Far plane half-extents derived from fov and aspect
	var vp_size: Vector2   = camera.get_viewport().get_visible_rect().size
	var aspect: float	  = vp_size.x / vp_size.y
	var half_h: float	  = tan(deg_to_rad(camera.fov * 0.5)) * camera.far
	var half_w: float	  = half_h * aspect

	return {
		"origin": far_center,
		"right":  cam_right,
		"up":	 cam_up,
		"half_w": half_w,
		"half_h": half_h,
	}
