#inertial-pursuit-camera.gd

extends Node3D

#-----------------------KEY PARAMETERS-----------------------#

#----persistent angular offsets----#
# represents how far craft rotates away 
# relative to camera (not the camera's rotation itself)
var yaw_error := 0.0
var pitch_error := 0.0
var last_ship_yaw := 0.0
var last_ship_pitch := 0.0

#camera target node
var target: CharacterBody3D
@export var target_path: NodePath

#game over destruction animation sequence
@onready var explosion: Node3D = $Explosion

#-------------FUNCTIONS-------------#

func detonate_spaceship():
	print("detonating...")
	explosion.explode() # detonation
	await get_tree().create_timer(10.0).timeout # display detonation event
	print("waited 10 seconds. dispatching to game_over.tscn...") 
	get_tree().change_scene_to_file(GlobalScenepath.game_over) # advance to game over screen

#----------------------------MAIN----------------------------#

func _ready() -> void:
	
	GlobalSignal.died.connect(Callable(self, "detonate_spaceship"))
	target = get_node_or_null(target_path)

	if not target:
		push_error("CameraRig: 'target_path' is not assigned.")

func _physics_process(delta: float) -> void:
	if not target:
		await get_tree().create_timer(5.0).timeout
		return
	
	var ship_basis := target.global_transform.basis
	var ship_euler := ship_basis.get_euler()
	var ship_yaw := ship_euler.y
	var ship_pitch := ship_euler.x
	
	#var delta_ship_yaw := ship_euler.y - last_ship_yaw
	#var delta_ship_pitch := ship_euler.x - last_ship_pitch
	
	var delta_ship_yaw := ship_yaw - yaw_error
	var delta_ship_pitch := ship_pitch - pitch_error
	
	
	last_ship_yaw = ship_euler.y
	last_ship_pitch = ship_euler.x
	
	yaw_error += delta * ship_yaw
	pitch_error += delta * ship_pitch
	
	
