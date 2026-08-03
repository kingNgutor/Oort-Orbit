#spaceshipController.gd
extends CharacterBody3D
#________________________________Initialization________________________________#
@export var rotation_speed := 1.5
@export var thrust_power := 10.0
@export var vertical_thrust_power := 5.0
@export var boost_multiplier := 2.0
@export var brake_damping := 5.0
@export var max_speed := 100.0
@export var max_health: int = 100
var current_health: int = max_health

#var vel: Vector3 = Vector3.ZERO
@onready var mesh = $"USS_Prometheus_NX-59650"
#@onready var exhaust = $ExhaustTrail

func _ready():
	current_health = max_health

#___________________________Process()/Physics_Process()________________________#
func _physics_process(delta: float) -> void:
	handle_rotation(delta)
	handle_thrust(delta)
	handle_misc(delta)
	
	move_and_slide()
	var player_position := global_transform.origin
	GlobalSignal.spaceship_position.emit(player_position)
	#if velocity.length() > 0.1:
		##point exhaust opposite to movement direction
		#exhaust.look_at(global_transform.origin - velocity.normalized(), Vector3.UP)
	
#func _process(delta):
	#var fps = Engine.get_frames_per_second()
	#var lerp_interval = velocity / fps
	#var lerp_position = global_transform.origin + lerp_interval
	#
	#if fps > 60:
		#mesh.top_level = true
		#mesh.global_transform.origin = mesh.global_transform.origin.lerp(lerp_position, 40 * delta)
	#else:
		#mesh.global_transform = global_transform
		#mesh.top_level = false

#_________________________Geometric Transform Functions_______________________#
func handle_rotation(delta: float) -> void:
	#var yaw_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	#var pitch_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	#var roll_input = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")

	# Alternatively, read from joystick directly for analog control
	var yaw_input = Input.get_joy_axis(0, JOY_AXIS_LEFT_X) # DS4 Left Stick X
	var pitch_input = -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) # DS4 Left Stick Y
	var roll_input = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) # DS4 Right Stick X

	# Apply rotation
	rotate_object_local(Vector3.UP, yaw_input * rotation_speed * delta)
	rotate_object_local(Vector3.RIGHT, pitch_input * rotation_speed * delta)
	rotate_object_local(Vector3.BACK, roll_input * rotation_speed * delta)

#______________________#
func handle_thrust(delta: float) -> void:
	var forward_thrust = -Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) # Right Stick Y (up is negative)
	var up_thrust = 0.0

	if Input.is_action_pressed("thrust_up"):
		up_thrust += 1.0
	if Input.is_action_pressed("thrust_down"):
		up_thrust -= 1.0

	var local_thrust = Vector3(0, up_thrust * vertical_thrust_power, forward_thrust * thrust_power)

	if Input.is_action_pressed("ui_cross"):
		local_thrust *= boost_multiplier

	# Convert local to global direction
	var global_thrust = global_transform.basis * local_thrust * delta

	velocity += global_thrust

	# Clamp to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

#_____________________#
func handle_misc(delta: float) -> void:
	if Input.is_action_pressed("ui_circle"):
		velocity = velocity.move_toward(Vector3.ZERO, brake_damping * delta)

#_____________________#
#func move_and_slide():
	#velocity = move_and_slide(velocity)

#___________________________Health Functions____________________________#
func _handle_collision(collision: KinematicCollision3D):
	var collider = collision.get_collider()
	
	if collider.has_method("get_damage"):
		apply_damage(collider.get_damage())

func apply_damage(amount: int):
	current_health -= amount
	print("HP: ", current_health, "/100")
	if current_health <= 0:
		die()

func die():
	print("you died")
	queue_free() #or trigger a respawn, gameover etc.
