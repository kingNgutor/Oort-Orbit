#pooled_asteroid-mmi3-[Autoload-Version].gd
extends Node3D

""" Update to asteroid algorithm:
	
	Explicitly calculate an instantaneous velocity vector to the player from the asteroid spawn 
	point. Wherever the player is, calculate an angle from spawn point to player and send the asteroid 
	that way regardless of what direction the player happens to be facing, making sure that asteroids always
	appear in front of player.
	
	 """

#___________________Initialization______________________#
@onready var pool = GlobalObjectPool
#var obj_array = []
const time_interval := 3.0
var time_accumulator := 0.0
var random_time_interval := randf_range(0.1, 0.5)
var fromSignal_player_position: Vector3
var randomPos_player_offset: Vector3
#var world_root: Node3D
var custom_integrator : bool
var camera : Camera3D


#----MultiMeshInstance3D variables----#
var mm_instance: MultiMeshInstance3D
var multimesh: MultiMesh
@onready var asteroid_count : int = pool.initial_size
const HIDDEN_TRANSFORM := Transform3D(Basis(), Vector3(0, -99999, 0))    # hide inactive instances off-screen rather than writing zero-scale transforms
@onready var pool_bodies : Array[RigidBody3D] = pool._pool
@onready var pool_in_use : Array[RigidBody3D] = pool._in_use
var active_indices: Array[int] = []    # multimesh indices currently in use
var free_indices: Array[int] = []    # recycled indices ready for reuse
var body_to_index: Dictionary[int, RigidBody3D] = {}    # Rigidbody3D -> multimesh index 
var lin_vel_arr : Array[Vector3] = []    # keep a store of values to avoid constantly polling rb.linear_velocity

func _ready():
	
	#default init, call activate() from main scene 
	#set_process(false)
	#set_physics_process(false)
	#visible = false
	custom_integrator = true 
	#-----Connect signals if not already----#
	if not GlobalSignal.exited_id.is_connected(Callable(self, "despawn_specific_asteroid")):
		GlobalSignal.exited_id.connect(Callable(self, "despawn_specific_asteroid"))
	GameState.Game_Over.connect(Callable(self, "reset_pool"), CONNECT_ONE_SHOT)
	if not GlobalSignal.spaceship_position.is_connected(Callable(self, "get_random_position_near_player")):
		GlobalSignal.spaceship_position.connect(Callable(self,"get_random_position_near_player" ))
	#GlobalSignal.ready_to_recycle.connect(Callable(self, "despawn_specific_asteroid"))
	
	#----Check for Camera---#
	camera =  get_viewport().get_camera_3d()
	if camera:
		print("CAMERA! ACTION!")
	else:
		print("WARNING: No camera node found. Add a camera to the scene.")
		return # handle camera absence gracefully
	print("pooled_asteroid initialized session ObjectPool instance_id = ", pool.get_instance_id())
	
	#---- Initialize MultiMeshInstances ----#
	print("Initializing multimeshinstances...")
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = preload("res://scratchpad/elektra_rb3d-[no mesh]/e_rb3d_nm/elektra.tres")
	multimesh.instance_count = asteroid_count
	multimesh.visible_instance_count = 0    # nothing active yet
	
	mm_instance = MultiMeshInstance3D.new()
	mm_instance.multimesh = multimesh
	add_child(mm_instance)
	
	# Pre-fill the free index pool
	for i in asteroid_count:
		free_indices.append(i)
		multimesh.set_instance_transform(i, HIDDEN_TRANSFORM)
	print("free_indices prefilled to : ", free_indices)
	print("Init MMI complete!")
	print_verbose("objpool _pool array : ", pool._pool, " ", typeof(pool._pool), " ", pool._pool.size(), " ", asteroid_count)
	
	# Generate random linear velocity Vector3's 
	
	var ITERATIONS = asteroid_count
	var start = Time.get_ticks_usec()
	for i in asteroid_count:
		var min_velocity = Vector3(0,0,500)
		var max_velocity = Vector3(0,0,1000)
		var random_velocity = Vector3(
				randf_range(min_velocity.x, max_velocity.x),
				randf_range(min_velocity.y, max_velocity.y),
				randf_range(min_velocity.z, max_velocity.z)
			)
		lin_vel_arr.append(random_velocity)
	var elapsed = Time.get_ticks_usec() - start
	print_verbose(lin_vel_arr)
	print("MMI Total: %d µs" % elapsed)
	print("MMI Per call: %.4f µs" % (float(elapsed) / ITERATIONS))
	
	
	#---------------------------------- END _READY() ----------------------------------#


#____________________________Functions______________________________#

#func activate():
	#visible = true
	#set_process(true)
	#set_physics_process(true)
	#
#func deactivate():
	#set_process(false)
	#set_physics_process(false)
	#visible = false
#
#func set_world(root: Node3D) -> void:
	#world_root = root
var tick := 0
var idx_lin_vel_arr := 0
func spawn(count: int, _delta):
	
	#---- NOTE: This timer is meant to give some sporadicity to the spawn cycle ----#
	tick += 1
	if tick > 5:
		await get_tree().create_timer(2.0).timeout # yields, here resumes for-loop next physics tick
		tick = 0
	if GlobalObjectPool._pool != null:

		for i in range(count):
			if i > active_indices.size():
				i = active_indices.size() - 1
			#___________generate random spawning position___________#
			#spawn random location within this box
			#var min_bound = Vector3(-5, 0, -5)
			#var max_bound = Vector3(5, 5, 5)
			#var random_pos = Vector3(
			#randf_range(min_bound.x, max_bound.x),
			#randf_range(min_bound.y, max_bound.y),
			#randf_range(min_bound.z, max_bound.z)
			#)
			#_______player-relative spawn position volumetric_______# 
			var random_pos = randomPos_player_offset
			
			#________generate random spawning orientation________#
			# Generate a random axis vector and normalize it
			var random_axis = Vector3(randf(), randf(), randf()).normalized()
			# Generate a random angle in radians (0 to 2*PI)
			var random_angle = randf_range(0.0, TAU)  # TAU = 2 * PI
			# Rotate the object around the random axis by the random angle
			#rotate(random_axis, random_angle)
			#____________generate random initial velocity____________#
			#var min_velocity = Vector3(0,0,500)
			#var max_velocity = Vector3(0,0,1000)
			#var random_velocity = Vector3(
				#randf_range(min_velocity.x, max_velocity.x),
				#randf_range(min_velocity.y, max_velocity.y),
				#randf_range(min_velocity.z, max_velocity.z)
			#)
			#
			#lin_vel_arr.append(random_velocity)
			
			#_____________ activate instantiated pool object and mirror mesh transform to rigidbody3d _____________#
			var start_timer = Time.get_ticks_usec()
			var obj = await pool.get_instance()
			var elapsed_time = Time.get_ticks_usec() - start_timer
			print_verbose("pooled-asteroid-mmi3.get_instance ", obj, " time : ", elapsed_time, " µs")
			free_indices.pop_back()
			active_indices.append(asteroid_count - free_indices.size() - 1)
			print("i : ", i)
			body_to_index.set(active_indices[i], obj) # hashmap active_indices array index to rigidbody3d id, match linear_velocity transform per obj to set_instance_transform
			#print_verbose("Dict body_to_index : ",body_to_index)
			#print_verbose("body_to_index key type : ", body_to_index.get_typed_key_builtin())
			#world_root.add_child(obj)
			#obj.reset_physics_interpolation
			if obj == null:
				var eleonora = $"../Eleonora"
				obj = eleonora
			obj.global_position = random_pos
			#print_verbose('poolobj ', obj, ' instance global transform : ', obj.global_transform)
			obj.scale = Vector3(1,1,1) #(0.5, 0.5, 0.5)
			obj.rotate(random_axis.normalized(), random_angle)
			
			var st_timer_spawn_linear_velocity = Time.get_ticks_usec()
			if i > lin_vel_arr.size():
				idx_lin_vel_arr = 0
			obj.linear_velocity = lin_vel_arr[i]
			idx_lin_vel_arr += 1
			var elapsed_linear_velocity = Time.get_ticks_usec() - st_timer_spawn_linear_velocity
			print_verbose("linear velocity from spawn: ", elapsed_linear_velocity, " microseconds")
			
			#print_verbose("obj.linear_velocity = ", obj.linear_velocity, ' ' , obj)
			
			multimesh.set_instance_transform(i, obj.global_transform)    # make meshinstance follow rigidbody global transform
			var mesh_translation_vector = multimesh.get_instance_transform(i)
			var mesh_original_position = mesh_translation_vector
			mesh_translation_vector.origin -= obj.linear_velocity
			multimesh.set_instance_transform(i, lerp(mesh_original_position, mesh_translation_vector, 1.0))
			
			#print('obj: ', obj, 'linear_velocity = ', obj.linear_velocity)
			
			#----multimeshinstance3d modifications----#
			#for j in pool.in_use():
			#var new_pos = obj.global_position + obj.linear_velocity * delta
			#var new_basis = obj.global_transform.basis.rotated(random_axis, random_angle * delta)
			#var new_transform = Transform3D(new_basis, new_pos)
			
			#var idx = pool._asteroid_to_index[obj]
			#pool.multimesh.set_instance_transform(idx, obj.global_transform)
			#print("Spawn func pool.multimesh type : ",typeof(pool.multimesh_instance))
			
			#obj.global_transform = new_transform
			#print("obj", obj, "global_transform = ", obj.global_transform)
			#----multimeshinstance3d modifications----#
			
			
			#obj.global_position = global_transform.origin
			#obj_array += [obj]
			#print("Creating new object(s): ", obj, " at ", random_pos)
			#print("Object Set Array = ", obj_array)
			#$StateChart.send_event("spawn") #send signal to State Chart
			#print(typeof(obj_array[0]))
	else:
		push_warning("ObjectPool empty. Temporarily waiting for objects to repopulate.")
		await get_tree().create_timer(10.0).timeout
		print("Spawn timeout complete!")

func destruct_pool():
	pool.free_all()
	print("object pool destructed")

func reset_pool():
	set_process(false)
	set_physics_process(false)
	#visible = false
	pool.reset()
	print("object pool has been reset. verifying...")
	print("instance_id = ", pool.get_instance_id())

#func despawn_LIFO():
	#if obj_array.size() > 0:
		#var obj = obj_array.pop_back()
		#print("Removing: ", obj)
		#pool.return_instance(obj)
		
#func despawn_FIFO():
	#if obj_array.size() > 0:
		#var obj = obj_array.pop_front()
		#print("Removing comet: ", obj)
		#pool.return_instance(obj)

func despawn_specific_asteroid(offscreen_instance: RigidBody3D):
	var idx = free_indices.size() - 1
	print_verbose("despawned ", offscreen_instance, ", free_indices idx: ", idx)
	var start_timer = Time.get_ticks_usec()
	#print_verbose("Removing offscreen asteroid: ", offscreen_instance)
	
	#await get_tree().create_timer(10.0).timeout #remove object after countdown
	pool.return_instance(offscreen_instance)
	active_indices.pop_back()
	if free_indices.size() < asteroid_count:
		free_indices.append(idx + 1)
	
	var end_timer := Time.get_ticks_usec()
	var elapsed_time = end_timer - start_timer
	#print_verbose("Despawn ", offscreen_instance, " ", elapsed_time, " microsecs")
	#var in_use_now = GlobalAutoload._in_use
	#print_verbose("current in_use_now objs: ", in_use_now)

func get_random_position_near_player(player_position: Vector3, radius: float = 250.0) -> Vector3:
	
	var vanishing_direction = -camera.global_basis.z # camera's forward-facing direction 
	var far_point = camera.global_position + vanishing_direction * camera.far # camera perspective vanishing point
	#print("func get_random_position_near_player far_point : ", far_point)
	#var offset = Vector3(
		#randf_range(player_position.x + radius, player_position.x - radius ), #x
		#randf_range(player_position.y - radius , player_position.y + radius ), #y
		#randf_range(player_position.z - 3000, -3000)  #z
	#)
	var offset = far_point * 0.5 # This updated offset uses the camera facing far point as the spawn origin 
	
	#print("player_position signal received: ", player_position)
	#print("plus offset: ", player_position + offset)
	fromSignal_player_position = player_position
	#randomPos_player_offset = player_position + offset
	randomPos_player_offset = offset
	#print("pp = ", fromSignal_player_position)
	#print("randomPos_player_offset = ", randomPos_player_offset)
	return randomPos_player_offset
	return fromSignal_player_position

func _exit_tree():
	
	if GlobalSignal.exited_id.is_connected(Callable(self, "despawn_specific_asteroid")):
		GlobalSignal.exited_id.disconnect(Callable(self, "despawn_specific_asteroid"))
	if GlobalSignal.spaceship_position.is_connected(Callable(self, "get_random_position_near_player")):
		GlobalSignal.spaceship_position.disconnect(Callable(self, "get_random_position_near_player"))
		

func update_asteroid_transform():
	pass
	
	#for i in pool_in_use.size():
		#multimesh.set_instance_transform(i, pool_in_use[i].global_transform)
	
	# var translation = multimesh.get_instance_transform(i)
	#	var original_position = translation
	
	if body_to_index.is_empty() == false:
		for i in body_to_index:
			var rb3d = body_to_index.get(i)
			var rb3d_translation = rb3d.global_transform
			var rb3d_init_pos = rb3d_translation
			rb3d_translation.origin -= rb3d.linear_velocity
			#print(rb3d, " linear velocity = ", rb3d.linear_velocity)
			#print(body_to_index.get(0), " linear velocity = ", body_to_index.get(0).linear_velocity)
			rb3d.reset_physics_interpolation
			multimesh.set_instance_transform(i, lerp(rb3d_init_pos, rb3d_translation, 0.1))
		

#________________________physics_process()________________________#

func _physics_process(delta):
	
	#generate a random spawn position

	var st = Time.get_ticks_usec()
	#variable rate asteroid spawn
	time_accumulator += delta
	if time_accumulator >= random_time_interval:
		time_accumulator -= random_time_interval
		spawn(100, delta)
		
		#update_asteroid_transform()
	var elapsed = Time.get_ticks_usec() - st
	print_verbose("poolastmmi3 physproc : ", elapsed)
	
	# BELOW: success accessing rigidbody3d instance via array index mapped to dictionary key with rb3d as value
	#if body_to_index.is_empty() == false:
		#var dict_ast = body_to_index.get(0)
		#print("dict_ast vel = ",dict_ast.linear_velocity)
	
	#constant rate asteroid spawn
	#time_accumulator += delta
	#if time_accumulator >= time_interval:
		#time_accumulator -= time_interval
		#spawn(1)
func _process(_delta):
	
	multimesh.visible_instance_count = -1
	pass
	#if not pool.multimesh:
		#push_warning("ObjectPoolManager: multimesh not ready yet.")
		#return
		
