# ObjectPool.gd
extends Node
class_name ObjectPool

@export var scene: PackedScene
@export var initial_size: int = 10
#@onready var instID_str : String

var _pool = GlobalAutoload._pool
var _in_use = GlobalAutoload._in_use
#var _pool: Array = []
#var _in_use: Array = []

#signal current_pool_usage(new_value: Array)

func _ready():
	if not scene:
		push_error("ObjectPool requires a PackedScene to function.")
		return

	# Pre-instantiate objects
	for i in initial_size:
		var obj = scene.instantiate()
		obj.visible = false
		obj.set_physics_process(false)
		_pool.append(obj)
		add_child(obj)

func get_instance() -> Node:
	var obj: Node
	if _pool.is_empty():
		obj = scene.instantiate()
		add_child(obj)
		#obj.connect("exited_id", _on_exited_id)
#		obj.exited_id.connect(Callable(self, "_on_exited_id"))
	else:
		obj = _pool.pop_back()

	_in_use.append(obj)
	obj.visible = true
	obj.set_physics_process(true)
	# Add to the scene root to ensure visibility
	#get_tree().current_scene.add_child(obj)
	#add_child(obj)
	return obj

func return_instance(obj: Node) -> void:
	if not _in_use.has(obj):
		push_warning("Returned object was not in use by this pool.")
		return

	_in_use.erase(obj)
	#current_pool_usage.emit(_in_use) #alert other parts of program how many pool objs are now active hence
	obj.visible = false
	obj.set_physics_process(false)
	_pool.append(obj)

#func _on_exited_id():
	#
	#print("exited_id signal received in ObjectPool: ", _on_exited_id().self)
	#_in_use.erase(self)
	#return self
	
	

func in_use() -> Array:
	#print(_in_use)
	return _in_use
#func in_use() -> Dictionary:
	#var dict = {}
	#for i in range(_in_use.size()):
		#
		
