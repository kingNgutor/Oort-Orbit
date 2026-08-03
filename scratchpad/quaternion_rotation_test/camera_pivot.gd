# camera_pivot.gd
extends Node3D

#------------------INIT CONFIG ---------------------#
@onready var ship = $"../lightfighter_yflip"
@onready var camera = get_viewport().get_camera_3d()
var cam_offset_angles: Vector2 = Vector2.ZERO

const MAX_CAM_YAW = 0.15
const MAX_CAM_PITCH = 0.10
const CAM_SPEED = 3.0
const CAM_RESET = 2.0


#-----------------FUNCTIONS-------------------------#
func get_ship_screen_offset() -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	print("viewport_size = ",viewport_size)
	print(typeof(viewport_size))
	var screen_center = viewport_size * 0.5
	var ship_screen_pos = camera.unproject_position(ship.global_position)
	var normalized_ship_screen_pos =  (ship_screen_pos - screen_center) / screen_center
	return normalized_ship_screen_pos # normalized -1...1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	var offset = get_ship_screen_offset() # Vector2, normalized
	#
	## Dead zone - i.e. don't jitter when ship is newar center
	#var deadzone = 0.15
	#offset.x = 0.0 if abs(offset.x) < deadzone else offset.x
	#offset.y = 0.0 if abs(offset.y) < deadzone else offset.y
	#
	#var target_angles = Vector2(
		#offset.x * MAX_CAM_YAW,
		#-offset.y * MAX_CAM_PITCH # invert Y: ship high -> camera tilts up
	#)
	#
	#var speed = CAM_SPEED if offset.length() > deadzone else CAM_RESET
	#cam_offset_angles = cam_offset_angles.lerp(target_angles, speed * delta)
	#
	## Apply as a local rotation on the camera rig, NOT  the ship
	#transform.basis = Basis.from_euler(Vector3(cam_offset_angles.y, cam_offset_angles.x, 0.0)) # y for pitch, x for yaw
	
	
