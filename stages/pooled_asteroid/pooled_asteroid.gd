#pooled_asteroid.gd
extends Node3D

#___________________Initialization______________________#
@onready var pool: ObjectPool = $objectPool
#var obj_array = []
const time_interval := 3.0
var time_accumulator := 0.0
var random_time_interval := randf_range(2, 3)
var fromSignal_player_position: Vector3
var randomPos_player_offset: Vector3
#var world_root: Node3D

func _ready():
	
	#default init, call activate() from main scene 
	#set_process(false)
	#set_physics_process(false)
	#visible = false
	
	# connect signals if not already
	if not GlobalSignal.exited_id.is_connected(Callable(self, "despawn_specific_asteroid")):
		GlobalSignal.exited_id.connect(Callable(self, "despawn_specific_asteroid"))
	GameState.Game_Over.connect(Callable(self, "reset_pool"), CONNECT_ONE_SHOT)
	if not GlobalSignal.spaceship_position.is_connected(Callable(self, "get_random_position_near_player")):
		GlobalSignal.spaceship_position.connect(Callable(self,"get_random_position_near_player" ))
	
	#GlobalSignal.ready_to_recycle.connect(Callable(self, "despawn_specific_asteroid"))
	
	print("pooled_asteroid initialized session ObjectPool instance_id = ", pool.get_instance_id())


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

func spawn(count: int):
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
		var min_velocity = Vector3(0,0,500)
		var max_velocity = Vector3(0,0,1000)
		var random_velocity = Vector3(
			randf_range(min_velocity.x, max_velocity.x),
			randf_range(min_velocity.y, max_velocity.y),
			randf_range(min_velocity.z, max_velocity.z)
		)
		#_____________activate instantiated pool object_____________#
		var obj = pool.get_instance()
		#world_root.add_child(obj)
		obj.global_position = random_pos
		obj.scale = Vector3(0.5, 0.5, 0.5)
		obj.rotate(random_axis, random_angle)
		obj.linear_velocity = random_velocity
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
	print("Despawn ", offscreen_instance, elapsed_time, " microsecs")
	#var in_use_now = GlobalAutoload._in_use
	#print("current in_use_now objs: ", in_use_now)

func get_random_position_near_player(player_position: Vector3, radius: float = 250.0) -> Vector3:
	var offset = Vector3(
		randf_range(player_position.x + radius, player_position.x - radius ), #x
		randf_range(player_position.y - radius , player_position.y + radius ), #y
		randf_range(player_position.z - 10000, -3000)  #z
	)
	#print("player_position signal received: ", player_position)
	#print("plus offset: ", player_position + offset)
	fromSignal_player_position = player_position
	randomPos_player_offset = player_position + offset
	return randomPos_player_offset

func _exit_tree():
	
	if GlobalSignal.exited_id.is_connected(Callable(self, "despawn_specific_asteroid")):
		GlobalSignal.exited_id.disconnect(Callable(self, "despawn_specific_asteroid"))
	if GlobalSignal.spaceship_position.is_connected(Callable(self, "get_random_position_near_player")):
		GlobalSignal.spaceship_position.disconnect(Callable(self, "get_random_position_near_player"))

#________________________physics_process()________________________#

func _physics_process(delta):
	
	#variable rate asteroid spawn
	time_accumulator += delta
	if time_accumulator >= random_time_interval:
		time_accumulator -= random_time_interval
		spawn(10)
	
	#constant rate asteroid spawn
	#time_accumulator += delta
	#if time_accumulator >= time_interval:
		#time_accumulator -= time_interval
		#spawn(1)
