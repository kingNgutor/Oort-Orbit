# Main_rigid.gd
extends Node3D

#___________________Initialization______________________#
@onready var pool: ObjectPool = $objectPool
@onready var ast_pool: ObjectPool = $asteroid_objPool
#@onready var frustum_tracker = $'res://rigid_body_asteroids.tscn/RgidBody3D/VisibleOnScreenNotifier3D'
var obj_array = []
var ast_array = []

#____________________________Functions______________________________#
func spawn(count: int):
	for i in range(count):
		#___________generate random spawning position__________#
		#spawn random location within this box
		var min_bound = Vector3(-5, 0, -5)
		var max_bound = Vector3(5, 5, 5)
		var random_pos = Vector3(
		randf_range(min_bound.x, max_bound.x),
		randf_range(min_bound.y, max_bound.y),
		randf_range(min_bound.z, max_bound.z)
		)
		#________generate random spawning orientation_________#
		# Generate a random axis vector and normalize it
		var random_axis = Vector3(randf(), randf(), randf()).normalized()
		# Generate a random angle in radians (0 to 2*PI)
		var random_angle = randf_range(0.0, TAU)  # TAU = 2 * PI
		# Rotate the object around the random axis by the random angle
		#rotate(random_axis, random_angle)
		#_________________generate random initial velocity____________#
		var min_velocity = Vector3(-10,-10,-10)
		var max_velocity = Vector3(10,10,10)
		var random_velocity = Vector3(
			randf_range(min_velocity.x, max_velocity.x),
			randf_range(min_velocity.y, max_velocity.y),
			randf_range(min_velocity.z, max_velocity.z)
		)
		#_____________activate instantiated pool object_____________#
		var obj = pool.get_instance()
		obj.global_position = random_pos
		obj.scale = Vector3(0.5, 0.5, 0.5)
		obj.rotate(random_axis, random_angle)
		obj.linear_velocity = random_velocity
		#obj.global_position = global_transform.origin
		obj_array += [obj]
		print("Creating new object(s): ", obj, " at ", random_pos)
		print("Object Set Array = ", obj_array)
		#$StateChart.send_event("spawn") #send signal to State Chart
		#print(typeof(obj_array[0]))
		
func spawn_astroid(count: int):
	
	for i in range(count):
		#___________generate random spawning position__________#
		#spawn random location within this box
		var min_bound = Vector3(-5, 0, -5)
		var max_bound = Vector3(5, 5, 5)
		var random_pos = Vector3(
		randf_range(min_bound.x, max_bound.x),
		randf_range(min_bound.y, max_bound.y),
		randf_range(min_bound.z, max_bound.z)
		)
		#________generate random spawning orientation_________#
		# Generate a random axis vector and normalize it
		var random_axis = Vector3(randf(), randf(), randf()).normalized()
		# Generate a random angle in radians (0 to 2*PI)
		var random_angle = randf_range(0.0, TAU)  # TAU = 2 * PI
		# Rotate the object around the random axis by the random angle
		#rotate(random_axis, random_angle)
		#_________________generate random initial velocity____________#
		var min_velocity = Vector3(-100,-100,-100)
		var max_velocity = Vector3(100,100,100)
		var random_velocity = Vector3(
			randf_range(min_velocity.x, max_velocity.x),
			randf_range(min_velocity.y, max_velocity.y),
			randf_range(min_velocity.z, max_velocity.z)
		)
		#_____________activate instantiated pool object_____________#
		var ast = ast_pool.get_instance()
		ast.global_position = random_pos
		ast.scale = Vector3(0.5, 0.5, 0.5)
		ast.rotate(random_axis, random_angle)
		ast.linear_velocity = random_velocity
		#obj.global_position = global_transform.origin
		ast_array += [ast]
		#print("Creating new object(s): ", ast, " at ", random_pos)
		print("Object Set Array = ", ast_array)
		#print(type_string(typeof(ast_array[0])))
		#print(type_string(typeof(/root/mainRigid/asteroid_objPool/@RigidBody3D@19)))
		
		#$StateChart.send_event("spawn") #send signal to State Chart
		#print(typeof(obj_array[0]))
	
#func clear_all_bullets():
	#for bullet in pool._in_use.duplicate():
		#if bullet is Bullet:
			#bullet.despawn()

func despawn_all():
	
	for i in range(obj_array.size() - 1, -1, -1):
		pool.return_instance(obj_array[i])
		#obj_array.remove_at(i)
		#$StateChart.send_event("despawn")
	
	for i in range(ast_array.size() - 1, -1, -1):
		ast_pool.return_instance(ast_array[i])
	print("objects cleared!")

func despawn_LIFO():
	if obj_array.size() > 0:
		var obj = obj_array.pop_back()
		print("Removing: ", obj)
		pool.return_instance(obj)
	elif ast_array.size() > 0:
		var ast = ast_array.pop_back()
		print("Removing asteroid: ", ast)
		ast_pool.return_instance(ast)

func despawn_FIFO():
	if obj_array.size() > 0:
		var obj = obj_array.pop_front()
		print("Removing comet: ", obj)
		pool.return_instance(obj)
	elif ast_array.size() > 0:
		var ast = ast_array.pop_front()
		print("Removing asteroid: ", ast)
		ast_pool.return_instance(ast)
		#$StateChart.send_event("despawn") #send signal to State Chart
		
func time_despawn(secs: int):
	pass
	
func despawn_specific_asteroid(instance: RigidBody3D):
	ast_pool.return_instance(instance)
	print("removing offscreen asteroid!", instance)
	#var tick = 1
	#while tick > 0: 
		#ast_pool.return_instance(instance)
		#print("removing offscreen asteroid!", instance)
		#tick -= 1
	#pool.return_instance(instance)
	#print("removing offscreen comet!", instance)



#______________________________Main: Game Loop_______________________________#
func _physics_process(_delta):
	
	if Input.is_action_just_pressed("ui_accept"):
		#spawn(1)
		spawn_astroid(1)
		
		#print("in use: ", ast_pool.in_use())
		#$'res://rigid_body_asteroids.tscn'.connect("exited_id", despawn_all())
		
		#var arr = ast_pool.in_use()
		#for i in range(arr[i]):
			#if arr[i] == 
	#if frustum_tracker == null:
		#pass
	#else:
		##pass
		#print(frustum_tracker.get_instance_id())
	
	#var startDespawnTimer = Time.get_ticks_usec()
	#var asteroid = null
	#for i in ast_array.size() -1:
		#asteroid = ast_array[i]
		#if not $Camera3D.is_position_in_frustum(asteroid.global_position):
			#
			##despawn_all()
			#despawn_specific_asteroid(asteroid)
			#ast_array.remove_at(i)
			#asteroid = null
			#print("should be null...(?): ", asteroid)
			#print("updated Array = ", ast_array)
			#var endDespawnTimer = Time.get_ticks_usec()
			#print("Despawn Time: ", endDespawnTimer - startDespawnTimer, " microseconds")
		
	if Input.is_action_just_pressed("ui_text_backspace"):
		#despawn_all()
		despawn_FIFO()
