#IMU_spaceshipController.gd

extends CharacterBody3D

#_____________________________IMU Config_________________________#
@export var rotation_speed := 1.5
@export var thrust_power := 10.0
@export var vertical_thrust_power := 5.0
@export var boost_multiplier := 2.0
@export var brake_damping := 5.0
@export var max_speed := 100.0
@export var roll_amout := 20.0 #max degrees roll angle
@export var alpha := 0.1

@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/4
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4

var filtered_gyro: Vector3 = Vector3.ZERO
var filtered_accelerometer: Vector3 = Vector3.ZERO
var gravity_smoothed = Vector3.UP

#__________________Spaceship Mesh Parameters___________________#

#var vel: Vector3 = Vector3.ZERO
@onready var mesh = $"USS_Prometheus_NX-59650"
@onready var exhaust = $ExhaustTrail
var player_position : Vector3

#________________________Health and Collision_____________________#

#Health Variables
@onready var game_manager: Node = $"../GameManager"
#@export var max_health: int = 100
var current_health = GameState.player_health

#Collision Variables
@export var damage_cooldown := 3.0 #secs
var damage_timer := 0.0
var damaged_colliders: = {}

#________________________Damage Functions_________________________#

func _handle_collision(collision: KinematicCollision3D):
	var collider = collision.get_collider()
	
	#if collider.has_method("get_damage"):
		#apply_damage(collider.get_damage())
	if collider is RigidBody3D:
		print("collided with rigidbody3d: ", collider.name)
		#apply_damage(10)
		game_manager.update_health(-100)
		#GlobalSignal.current_health.emit(current_health)
		damaged_colliders[collider] = true
		damage_timer = damage_cooldown

func is_colliding_with(collider: Node) -> bool:
	# Returns true if we're still colliding with this collider
	for i in range(get_slide_collision_count()):
		if get_slide_collision(i).get_collider() == collider:
			return true
	return false

func apply_damage(amount: int):
	current_health -= amount
	GlobalSignal.current_health.emit(current_health)
	#HealthBar.change_value(current_health)
	#HUD_healthbar.health = current_health
	#childed_healthbar.set_value_no_signal(current_health)
	print("HP: ", current_health, "/100")
	if current_health <= 0:
		die()

func die():
	#explosion.explode()
	GlobalSignal.died.emit()
	print("died. queue_free()-ing")
	#disconnect("Game_Over", Callable(GameState, "handle_game_over_state" ))
	call_deferred("queue_free")
	#queue_free() #or trigger a respawn, gameover etc.
	#get_tree().change_scene_to_file(GlobalScenepath.game_over)

func init_health():
	current_health

#________________________IMU Transform Functions_____________________#
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


func handle_misc(delta: float) -> void:
	if Input.is_action_pressed("ui_circle"):
		velocity = velocity.move_toward(Vector3.ZERO, brake_damping * delta)


#func move_and_slide():
	#velocity = move_and_slide(velocity)

#________________________Realtime Process()________________________#

func _ready():
	GlobalSignal.collision_detected.connect(Callable(self, "_handle_collision"))
	GlobalSignal.current_health.connect(Callable(self, "init_health"))
	GameState.Game_Over.connect(Callable(self, "die" ))
	var grav = Input.get_gravity()
	
	

func _physics_process(delta: float):
	#IMU control configuration
	var imu_gyro = Input.get_gyroscope()
	var imu_accelerometer = Input.get_accelerometer()
	#var magnetometer = Input.get_magnetometer()
	#GlobalSignal.magnetic_field_vector.emit(magnetometer)
	
	var filtered_accelerometer = filtered_accelerometer * (1.0 - alpha) + imu_accelerometer * alpha
	
	#____________attempting to clamp rotation for camera stability_______#
	rotation.x  -= imu_gyro.x * rotation_speed * delta
	#rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)
	rotation.y -= imu_gyro.y *rotation_speed * delta
	#rotation.y = clamp(rotation.y, min_vertical_angle, max_vertical_angle)
	
	
	var yaw_input = filtered_accelerometer.x
	rotation.y -= yaw_input * rotation_speed * delta
	
	var target_roll = deg_to_rad(clamp(-yaw_input * roll_amout, -roll_amout, roll_amout))
	rotation.z = lerp_angle(rotation.z, target_roll, 0.1)
	
	if imu_accelerometer.z < -0.2:
		velocity += transform.basis.z * thrust_power * delta
	
	#handle_rotation(delta)
	handle_thrust(delta)
	handle_misc(delta)
	player_position = global_transform.origin
	GlobalSignal.spaceship_position.emit(player_position)
	
	move_and_slide()
	if velocity.length() > 0.1:
		#point exhaust opposite to movement direction
		exhaust.look_at(global_transform.origin - velocity.normalized(), Vector3.UP)
	print("rotation.x = ", rotation.x)
	print("rotation.y = ", rotation.y)
	print("IMU_acceleration = ", imu_accelerometer)
	# damage control process
	if damage_timer > 0:
		damage_timer -= delta
	var collision = move_and_collide(velocity * delta)
	if collision and damage_timer <= 0:
		_handle_collision(collision)
	 # Clean up colliders no longer in contact
	for c in damaged_colliders.keys():
		if not is_colliding_with(c):
			damaged_colliders.erase(c)




func _process(delta):
	var fps = Engine.get_frames_per_second()
	var lerp_interval = velocity / fps
	var lerp_position = global_transform.origin + lerp_interval
	
	if fps > 60:
		mesh.top_level = true
		mesh.global_transform.origin = mesh.global_transform.origin.lerp(lerp_position, 40 * delta)
	else:
		mesh.global_transform = global_transform
		mesh.top_level = false
	# emit player position via signal
	var player_position := global_transform.origin
	GlobalSignal.spaceship_position.emit(player_position)
	
	if Input.is_action_just_released("ui_text_backspace"):
	
		if GameState.pause_state == false:
			GameState.pause_game()
	
	#___________________Gravitational Orientaion________________#

	# Gravity vector in world space
	#var g = Input.get_gravity().normalized()
	#gravity_smoothed = gravity_smoothed.lerp(g, 0.1)
#
	## Desired "up" direction = opposite of gravity
	#var desired_up = -g
#
	## Current forward direction (we keep this stable or define it)
	#var current_forward = -transform.basis.z
#
	## Make sure forward and up are orthogonal
	#var right = desired_up.cross(current_forward).normalized()
	#var forward = right.cross(desired_up).normalized()
#
	## Build a new orientation basis
	#var new_basis = Basis(right, desired_up, -forward)
#
	#transform.basis = new_basis.orthonormalized()
	
	#_________________________end block (grav)____________________#
	

#func handle_rotation(delta: float) -> void:
	#var yaw_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	#var pitch_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	#var roll_input = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	#
	## Alternatively, read from joystick directly for analog control
	#yaw_input = Input.get_joy_axis(0, JOY_AXIS_LEFT_X) # DS4 Left Stick X
	#pitch_input = -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) # DS4 Left Stick Y
	#roll_input = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) # DS4 Right Stick X
#
	## Apply rotation
	#rotate_object_local(Vector3.UP, yaw_input * rotation_speed * delta)
	#rotate_object_local(Vector3.RIGHT, pitch_input * rotation_speed * delta)
	#rotate_object_local(Vector3.BACK, roll_input * rotation_speed * delta)
