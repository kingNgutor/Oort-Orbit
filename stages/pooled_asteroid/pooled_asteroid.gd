extends Node3D

#___________________Initialization______________________#
@onready var pool: ObjectPool = $objectPool
var obj_array = []

func _ready():
	GlobalSignal.exited_id.connect(Callable(self, "despawn_specific_asteroid"))
	pass

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
		var min_velocity = Vector3(-100,-100,-100)
		var max_velocity = Vector3(100,100,100)
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

func despawn_LIFO():
	if obj_array.size() > 0:
		var obj = obj_array.pop_back()
		print("Removing: ", obj)
		pool.return_instance(obj)
		
func despawn_FIFO():
	if obj_array.size() > 0:
		var obj = obj_array.pop_front()
		print("Removing comet: ", obj)
		pool.return_instance(obj)
		
func despawn_specific_asteroid(offscreen_instance: RigidBody3D):
	print("[Script:elektra.gd] --> [Script:pooled_asteroid.gd]. Removing offscreen asteroid: ", offscreen_instance)
	pool.return_instance(offscreen_instance)
	var in_use_now = GlobalAutoload._in_use
	print("current in_use_now objs: ", in_use_now)
	
	
	
#______________________________Main: Game Loop_______________________________#
func _physics_process(_delta):
	
	if Input.is_action_just_pressed("ui_accept"):
		spawn(1)

	#if Input.is_action_just_pressed("ui_text_backspace"):
		#despawn_FIFO()
