# mmi3d.gd
extends MultiMeshInstance3D

@export var number_of_mesh : int = 1000
@export var rotation_speed : float = 0.2
var material = StandardMaterial3D.new()
@onready var camera = get_viewport().get_camera_3d()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_mesh()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#self.rotate_y(rotation_speed * delta) #rotate all multimeshinstance3d's
	set_multimesh_index_translation_transform()
	## translate multimeshinstance3d instance via index
	#for i in range(0, number_of_mesh -1):
		#reset_physics_interpolation()
		#
		#var lerp_weight = randf()
		#var trnslte = multimesh.get_instance_transform(i)
		#var og_pos = trnslte # instance initial position
		#trnslte.origin += Vector3(0,0,-1) # translation vector
		#multimesh.set_instance_transform(i, lerp(og_pos, trnslte, lerp_weight))
		
	pass
	

func generate_mesh():
	#var multimesh = get_multimesh()
	multimesh.instance_count = number_of_mesh
	var viewport_size = get_viewport().get_visible_rect().size
	print("viewport size : ", viewport_size)
	var frustum: Array[Plane] = camera.get_frustum()
	var far_plane: Plane = frustum[5]
	print("far : ",far_plane)
	print("far type: ", typeof(far_plane))
	
	for i in range(0, number_of_mesh - 1):
		#material.albedo_texture = load("res://assets/meshes/space_debris/asteroids_comets/elektra/lowpoly/Elektra-f836_Elektra Base Color.png")
		#multimesh.mesh.surface_set_material(0, material)
		var x = randf_range(-10.0, 10.0)
		var y = randf_range(-10.0, 10.0)
		var z = randf_range(-200.0, 0.0)
		var temp = Transform3D(Basis.IDENTITY, Vector3(x, y, z))
		multimesh.set_instance_transform(i, temp)
		
func brownian_motion():
	for i in range(0, number_of_mesh -1):
		var x = randf_range(-1.0, 1.0)
		var y = randf_range(-1.0, 1.0)
		var z = randf_range(-1.0, 1.0)
		var lerp_weight = randf()
		var trnslte = multimesh.get_instance_transform(i)
		var og_pos = trnslte # instance initial position
		trnslte.origin += Vector3(x,y,z) # translation vector
		multimesh.set_instance_transform(i, lerp(og_pos, trnslte, lerp_weight))
		
func set_multimesh_index_translation_transform():
	# Sets different transform based on index number i.e. if divisibe by 3, 5, or 7, respectively
	
	for i in range(0, number_of_mesh -1):
		var translation = multimesh.get_instance_transform(i)
		var original_position = translation
		if i % 3 == 0:
			translation.origin -= Vector3(0, 0, -10)
			multimesh.set_instance_transform(i, lerp(original_position, translation, 0.1))
			pass
		
		if i % 5 == 0:
			translation.origin -= Vector3(0, -5, 0)
			multimesh.set_instance_transform(i, lerp(original_position, translation, 0.1))

			pass
		
		if i % 7 == 0:
			translation.origin -= Vector3(10, 0, 0)
			multimesh.set_instance_transform(i, lerp(original_position, translation, 0.1))
		
		translation.origin -= Vector3(-1, 0, 0)
		#multimesh.set_instance_transform(i, lerp(original_position, translation, 0.2))
