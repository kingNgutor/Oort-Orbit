# original ObjectPool.gd

# ObjectPool.gd
extends Node
class_name ObjectPool

@export var scene: PackedScene
@export var scene_1: PackedScene
@export var initial_size: int = 100
#@export var scene_1_size: int = 100
#@onready var instID_str : String

#var _pool = GlobalAutoload._pool
#var _in_use = GlobalAutoload._in_use
var _pool: Array[RigidBody3D] = []
var _in_use: Array[RigidBody3D] = []
var _initialized := false
var _pool_stocked_counter: int = 0

var gi_isWaiting := false

signal recycle_instance(obj: Node)

func _ready():
	
	recycle_instance.connect(Callable(self,"respawn_recycled_instance()"))
	#confirm scene var contains a PackedScene
	if not scene:
		push_error("ObjectPool requires a PackedScene to function.")
		return
	
	# Set _initialized bool to true for current play session
	if _initialized:
		return
	_initialized = true
	
	# Pre-instantiate objects
	var startimer = Time.get_ticks_usec()
	for i in initial_size:
		var obj = scene.instantiate()
		
		obj.visible = false
		obj.set_physics_process(false)
		
		add_child(obj) #if this line causes trouble here reverse with below...
		_pool.append(obj)
		
	#for i in scene_1_size:
		#var obj = scene_1.instantiate()
		#obj.visible = false
		#obj.set_physics_process(false)
		#add_child(obj)
		#_pool.append(obj)
		
	var instantiation_duration = Time.get_ticks_usec() - startimer
	print("ObjectPool pre-instantiate took ", instantiation_duration, " µs")
		
	print("ObjectPool initialized with instance_id = ", get_instance_id())
	print("ObjectPool _ready() _pool : ", _pool)
	print(recycle_instance.get_connections())
	
	
	
	
	
#------------------Class (ObjectPool) Methods------------------#

func get_instance() -> Node:
	
	""" (This first if block contains a logical error. It should not just check if the pool is currently empty
	#but also how many times it has been emptied, or rather only populate upon program initialization or first 
	#call, and subsequently return push_warning("get_instance() exhaustion. ObjectPool depleted.") and 
	#otherwise fail gracefully or to that effect. This logical bug is what is causing the program to generate 
	#tens of thousands of remote asteroids even though pool var initial_size := 100. When rigidbody3d
	#count exceeds ~10,000 the engine struggles to render them without jitter/stutter.) """
	
	var obj: Node
	obj = _pool.pop_back()
	
	#-----------------moderate flow rate below 50% used----------------------#
	if _pool.size() < initial_size / 2:
		var prior_waiting = _pool.size()
		gi_isWaiting = true
		if gi_isWaiting:
			await get_tree().create_timer(0.01).timeout
			var _pool_delta_waiting = _pool.size() - prior_waiting
			gi_isWaiting = false
			print_verbose("waited 10 msec because _pool.size() is less than half... ", abs(_pool_delta_waiting))
	#------------------------------------------------------------------------#
	
	# null instance case
	if obj == null:
		#-------------------------------------------#
		obj = await recycle_instance
		print("await recycle_instance result = ", obj)
		
		#-------------------------------------------#
	
	_in_use.append(obj)
	#print("_in_use : ", _in_use)
	obj.visible = true
	obj.set_physics_process(true)
	print("get_instance() _pool size : ", _pool.size())
	return obj
	

func return_instance(obj: Node) -> void:
	if not _in_use.has(obj):
		push_warning("Returned object was not in use by this pool.")
		return
	
	#var transient_wait := true
	#if transient_wait:
		#await get_tree().create_timer(1.0).timeout
		#print("return waited 1.0s before signal emission")
		#transient_wait = false
	
	_in_use.erase(obj)
	obj.visible = false
	obj.set_physics_process(false)
	_pool.append(obj)
	recycle_instance.emit(obj)
	
	print("return_instance(obj) : ", obj, " returned to GlobalObjectPool._pool")
	print("return_instance() _pool size: ", _pool.size())

func free_all():
	# destruct all instances in memory on game over
	for obj in _in_use:
		if is_instance_valid(obj):
			obj.queue_free()
	for obj in _pool:
		if is_instance_valid(obj):
			obj.queue_free()
	
	_in_use.clear()
	_pool.clear()
	_pool_stocked_counter = 0
	await get_tree().process_frame
	print("free_all() success")
	print("_in_use.is_empty() = ", _in_use.is_empty())
	print("_pool.is_empty() = ", _pool.is_empty())

func in_use() -> Array:
	#print(_in_use)
	return _in_use

func reset():
	#call reset() on game over instead of free_all()
	for obj in _in_use:
		obj.visible = false
		obj.set_physics_process(false)
		_pool.append(obj)
	_in_use.clear()
	_pool_stocked_counter = 0
