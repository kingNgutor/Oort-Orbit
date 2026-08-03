#eleonora.gd
extends RigidBody3D
#__________________________Initialization___________________________#

@export var recycle_distance: float = 200.0
@export var offscreen_time_limit: float = 10.0
var spawn_origin: Vector3
var offscreen_timer: float = 0.0
var asteroid_is_visible: bool = true

func _ready():
	spawn_origin = global_transform.origin
	#var notifier = $VisibleOnScreenNotifier3D
	#notifier.connect("screen_entered", Callable(self, "_on_screen_entered"))
	#notifier.connect("screen_exited", Callable(self, "_on_screen_exited"))

#___________________________Signal Functions_____________________________#
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	asteroid_is_visible = false
	print("[Node:VisibleOnScreenNotifier3D] --> [Script:eleonora.gd] Object: ", self, " exited offscreen...")
	GlobalSignal.exited_id.emit(self)

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	asteroid_is_visible = true
	print("...another asteroid is visible...")

#___________________________Process()/Physics_Process()__________________#
func _physics_process(delta: float):
	var dist = global_transform.origin.distance_to(spawn_origin)
	if not is_visible:
		offscreen_timer += delta
	else:
		offscreen_timer = 0.0
	if dist >= recycle_distance and not is_visible and offscreen_timer >= offscreen_time_limit:
		GlobalSignal.ready_to_recycle.emit(self)
		#emit_signal("ready_to_recycle", self)
