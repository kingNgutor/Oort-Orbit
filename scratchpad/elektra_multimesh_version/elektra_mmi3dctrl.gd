# elektra_mmi3dctrl.gd

""" refactoring elektra asteroid logic for use with multimeshinstance3d, and potential bypass of 
object pool logic, if computationally expedient, otherwise it will need to be made to work with 
it. """

extends MultiMeshInstance3D

#----------------INIT--------------#
@export var number_of_mesh : int = 10
@onready var camera = get_viewport().get_camera_3d()
var viewport_size : Vector2
var temp
var world_space_point_from_camera_projection

@onready var elektra = $"."

func populate_mmi3d_via_frustum():
	#var multimesh = get_multimesh()
	multimesh.instance_count = number_of_mesh
	
	for i in range(0, number_of_mesh - 1):
		#material.albedo_texture = load("res://assets/meshes/space_debris/asteroids_comets/elektra/lowpoly/Elektra-f836_Elektra Base Color.png")
		#multimesh.mesh.surface_set_material(0, material)
		
		# generate random location to place mesh
		var z = -camera.basis.z * -10.0 # randf_range(-200.0, 0.0) # try something like (camera.basis.z - 1000)
		
		var y = randf_range(0.0, viewport_size.y)
		var x = randf_range(0.0, viewport_size.x)
		var screen_point = Vector2(x,y)
		world_space_point_from_camera_projection = camera.project_position(screen_point, z.z)
		print("worldspace projection = ", world_space_point_from_camera_projection)
		print(typeof(world_space_point_from_camera_projection))
		print("is projected position in frustum : ", camera.is_position_in_frustum(world_space_point_from_camera_projection))
		
		# generate random rotation axes and angle for mesh
		var r_x = randf_range(-10.0, 10.0)
		var r_y = randf_range(-17.0, 42.0)
		var r_z = randf_range(-19.0, 29.0)
		var r_ang = deg_to_rad(randf_range(0.0,360.0))
		
		#var temp = Transform3D(Basis.IDENTITY, Vector3(x, y, z))
		#var temp = Transform3D(Basis.IDENTITY, world_space_point_from_camera_projection)
		temp = Transform3D(Basis(Vector3(r_x,r_y,r_z).normalized(),r_ang), world_space_point_from_camera_projection)
		multimesh.set_instance_transform(i, temp)
		print("multimesh = ", multimesh)
		print("multimesh.mesh = ", multimesh.mesh)
		print("transform format = ", multimesh.transform_format)
		#print(multimesh.mesh.visible)
		#print(multimesh.mesh.global_transform)


func translate_instances():
	
	for i in range(0, number_of_mesh -1):
		var translation = multimesh.get_instance_transform(i)
		var original_position = translation
		if i % 3 == 0:
			translation.origin -= Vector3(0, 0, -10)
			multimesh.set_instance_transform(i, lerp(original_position, translation, 0.1))
			pass
		if i % 2 ==0:
			translation.origin -= Vector3(-1,0,-15)
			multimesh.set_instance_transform(i, lerp(original_position, translation, 0.1))
		else:
			translation.origin -= Vector3(-10,5,-5)
			multimesh.set_instance_transform(i, lerp(original_position, translation, 0.1))

#-----------------------MAIN-------------------------#
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	if camera:
		viewport_size = get_viewport().get_visible_rect().size
		populate_mmi3d_via_frustum()
		print("_ready() rigidbody3d transform : ", elektra.global_transform)
	else:
		print("WARNING: There is no Camera3D present in this scene.")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#print("rigidbody3d transform : ", elektra.global_transform)
	#print("idx[0] mmi transform = ", multimesh.get_instance_transform(0))
	#temp = Transform3D(Basis.IDENTITY, world_space_point_from_camera_projection)
	#multimesh.set_instance_transform(0, temp)
	translate_instances()
	
func _physics_process(delta: float) -> void:
	pass
	#print("rigidbody3d transform : ", elektra.global_transform)
	
	
	
