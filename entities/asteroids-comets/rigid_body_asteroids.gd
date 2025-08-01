extends RigidBody3D
@onready var is_in_frustum = $VisibleOnScreenNotifier3D
#@onready var instance_ID_str : String
signal exited_id(instID_str : Object)

func return_screen_exited_instance_id(string: String) -> String:
	
	return(string)

func _on_visible_on_screen_notifier_3d_screen_exited():
	#screen_exited() signal
	print("asteroid offscreen [SIGNAL]")
	#var instID = self.get_instance_id()
	#var instID_str = "<RigidBody3D#" + str(instID) + ">"
	#print(instID_str, type_string(typeof(instID_str)))
	print("Object = ", self)
	#print("self is of typeObject: ", type_string(typeof(self)))
	#return_screen_exited_instance_id(instID_str)
	emit_signal("exited_id", self)
	print("get_object(): ", exited_id.get_object())
	#exited_id.emit(instID_str)
	
	#print(type_string(typeof($".")))
	#instance_ID.emit("instance_ID", instID)
