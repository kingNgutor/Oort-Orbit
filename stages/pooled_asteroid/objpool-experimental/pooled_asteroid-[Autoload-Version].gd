#pooled_asteroid-[Autoload-Version].gd
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
var random_time_interval := randf_range(0.017, 0.272)
var fromSignal_player_position: Vector3
var randomPos_player_offset: Vector3
#var world_root: Node3D
var custom_integrator : bool
var camera : Camera3D
@onready var comet = $"../comet"
var player : CharacterBody3D
var spawn_nullwatch_isWaiting := false
var sp_poolwait_isWaiting := false
var spawn_radius : float = 2000.0
var player_xy_spread : float = 100.0

func _ready():
	
	#GlobalWorldOrigin.register(self) # my hypothesis is that rebasing is not necessary for asteroids since they exist within frustrum and are constrained to player's position. Is this true?
	
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
		print("pooled_asteroid detected present camera node...")
	else:
		print("WARNING: No camera node found. Add a camera to the scene.")
		return # handle camera absence gracefully
	print("pooled_asteroid initialized session ObjectPool instance_id = ", pool.get_instance_id())
	
	#----Check for Player----#
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Player not found. Make sure 'player' is set in Groups and active with the current scene.")
		print("Error. See stack trace for details. Halting program execution...")
		breakpoint
		
	if player:
		print("player node found in scene...", player)
		



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
func spawn(count: int, delta):
	for i in range(count):
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
		#var min_velocity = Vector3(100,100,10000)
		#var max_velocity = Vector3(100,100,70000)
		#var random_velocity = Vector3(
			#randf_range(min_velocity.x, max_velocity.x),
			#randf_range(min_velocity.y, max_velocity.y),
			#randf_range(min_velocity.z, max_velocity.z)
		#)
		
		#----------------- Velocity vector towards player -----------------#
		
		var player_basis := player.global_transform.basis
		
		# pick a random point on the player's local xy-plane (offset from the player's origin)
		var rand_x := randf_range(-player_xy_spread, player_xy_spread)
		var rand_y := randf_range(-player_xy_spread, player_xy_spread)
		var target_point : Vector3 = player.global_transform.origin + basis.x * rand_x + basis.y * rand_y
		
		
		#------------------------------------------------------------------#
		
		#_____________activate instantiated pool object_____________#
		
		var obj = await pool.get_instance()
			
		
		#world_root.add_child(obj)
		#if obj != null:
			##push_warning("attempted to spawn null obj in func spawn()...")
			
		print_verbose("obj received from ObjectPool: ", obj)
		obj.global_position = random_pos
		obj.scale = Vector3(1,1,1) #(0.5, 0.5, 0.5)
		obj.rotate(random_axis, random_angle)
		
		var direction : Vector3 = (target_point - obj.global_transform.origin).normalized()
		#obj.linear_velocity += random_velocity
		var speed : float = randf_range(10, 100)
		obj.linear_velocity += direction * speed
		
		#obj.apply_central_force(Vector3.FORWARD * 1000 * 1.0)
		#var new_pos = obj.global_position + obj.linear_velocity * delta
		#var new_basis = obj.global_transform.basis.rotated(random_axis, random_angle * delta)
		#var new_transform = Transform3D(new_basis, new_pos)
		#obj.global_transform = new_transform
		print_verbose("obj was transformed... ", obj.global_position)
			
		#-------///////////////////////////////////////////-----------#
		#push_warning("NULL CODEPATH. INSTANTIATING COMET SUBSTITUTE.")
		#if comet == null:
			#pass
		#else:
		##obj = comet
			#comet.global_position = random_pos
			#comet.scale = Vector3(1,1,1) #(0.5, 0.5, 0.5)
			#comet.rotate(random_axis, random_angle)
			#comet.global_position += random_velocity
			#break
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
	var start_timer = Time.get_ticks_usec()
	print("Removing offscreen asteroid: ", offscreen_instance)
	
	#await get_tree().create_timer(10.0).timeout #remove object after countdown
	pool.return_instance(offscreen_instance)
	
	var end_timer := Time.get_ticks_usec()
	var elapsed_time = end_timer - start_timer
	#print("Despawn ", offscreen_instance, " ", elapsed_time, " microsecs")
	#var in_use_now = GlobalAutoload._in_use
	#print("current in_use_now objs: ", in_use_now)

func get_random_position_near_player(player_position: Vector3, radius: float = 250.0) -> Vector3:
	
	#var vanishing_direction = -camera.global_basis.z # camera's forward-facing direction 
	#var far_point = camera.global_position + vanishing_direction * camera.far # camera perspective vanishing point
	
	#----- Get orientation relative to player ------#
	#fromSignal_player_position = player_position
	var player_FORWARD = -player.global_transform.basis.z
	var player_RIGHT = player.global_transform.basis.x
	var player_UP = player.global_transform.basis.y
	
	# center of orthogonal plane ahead of ship (from which to eventually spawn)
	var orthoplane_center := player.global_position + player_FORWARD.normalized() * camera.far
	
	var angle := randf() * TAU
	var r := sqrt(randf()) * spawn_radius
	var offset = (player_RIGHT * cos(angle) + player_UP * sin(angle)) * r 
	var spawn_pos = orthoplane_center + offset
	
	#var offset = Vector3(
		#randf_range(player_position.x + radius, player_position.x - radius ), #x
		#randf_range(player_position.y - radius , player_position.y + radius ), #y
		#randf_range(player_position.z - 2000, player_position.z - 4000)  #z
	#)
	#var offset = far_point * 0.5 # This updated offset uses the camera facing far point as the spawn origin 
	
	#print("player_position signal received: ", player_position)
	#print("plus offset: ", player_position + offset)
	
	#randomPos_player_offset = player_position + offset
	randomPos_player_offset = spawn_pos
	#print("pp = ", fromSignal_player_position)
	#print("randomPos_player_offset = ", randomPos_player_offset)
	return randomPos_player_offset
	#return fromSignal_player_position

func _exit_tree():
	
	if GlobalSignal.exited_id.is_connected(Callable(self, "despawn_specific_asteroid")):
		GlobalSignal.exited_id.disconnect(Callable(self, "despawn_specific_asteroid"))
	if GlobalSignal.spaceship_position.is_connected(Callable(self, "get_random_position_near_player")):
		GlobalSignal.spaceship_position.disconnect(Callable(self, "get_random_position_near_player"))
	
	#GlobalWorldOrigin.unregister(self)

#________________________physics_process()________________________#

func _physics_process(delta):
	
	#generate a random spawn position
	
	#variable rate asteroid spawn
	time_accumulator += delta
	if time_accumulator >= random_time_interval:
		time_accumulator -= random_time_interval
		spawn(10, delta)
	
	print("player transform forward : ", player.transform.basis.z)
	
	#constant rate asteroid spawn
	#time_accumulator += delta
	#if time_accumulator >= time_interval:
		#time_accumulator -= time_interval
		#spawn(1)
func _process(delta):
	pass
	#if not pool.multimesh:
		#push_warning("ObjectPoolManager: multimesh not ready yet.")
		#return
		
