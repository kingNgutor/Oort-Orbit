#IMU_spaceshipController.gd
#IMU-sc-corrected-sensor-input.gd
#IMU-sc-corrected-sensor-input-quaternion.gd

"""Herein: an IMU control implementation with quaternion sensor fusion
and corrections for Godot/Android Z-axis (forward) direction mismatch."""

extends CharacterBody3D

#################################################################
	#------------------------INIT------------------------#
#################################################################

#______________IMU Config______________#

var imu_gyro
var imu_accel
var imu_mag
var imu_grav

var imu_ready = false
var imu_timer = 0.0

@onready var madgwick := preload("res://common/IMU_fusion/madgwick_filter.gd").new()

@export var rotation_speed := 1.5
@export var thrust_power := 10.0
@export var vertical_thrust_power := 5.0
@export var boost_multiplier := 2.0
@export var brake_damping := 5.0
@export var max_speed := 100.0
@export var roll_amout := 20.0 #max degrees roll angle
@export var alpha := 0.1
@export var bank_deadzone := 0.2

@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/4
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4

var filtered_gyro: Vector3 = Vector3.ZERO
var filtered_accelerometer: Vector3 = Vector3.ZERO
var gravity_smoothed = Vector3.UP


#__________________Spaceship Mesh Parameters___________________#

#var vel: Vector3 = Vector3.ZERO
@onready var mesh = $"USS_Prometheus_NX-59650"
@onready var exhaust = $jet_GPUParticles3D
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

#################################################################
	#-------------------------FUNCTIONS-------------------------#
#################################################################

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

func get_corrected_sensor_input(raw_input: Vector3) -> Vector3:
	
	'''Herein is a more comprehensive way of resolving the axes mismatch 
	between Godot and Android. Previously negating (or otherwise 
	trying to flip) Z-axis vector was causing issues to the application
	of basis rotation matrix, resulting in move_and_slide() unresponsiveness
	and worst of all, not explicit warning or errors. This new implementation
	fixes this by rotating the vector rather than negating, and improves on the 
	former function by rotating the reference frame based on Android screen
	orientation.'''

#-------------rectify sensor input-------------#
	
	# 1. Get raw sensor data
	# var raw_input = Input.get_gyroscope()
	# 2. Remap Android axes to Godot world space axes
	# Android: x=right, y=up, z=towards user
	# Godot: x=right, y=up, z=back (away from user)
	# However, if the game is LANDSCAPE, the device axes rotate!
	# We must consult the DisplayServer for screen orientation.
	
	var orientation = DisplayServer.screen_get_orientation()
	var corrected = Vector3.ZERO
	print("corrected assigned zero vector = " , corrected)
	
	match orientation:
		DisplayServer.SCREEN_LANDSCAPE:
			# Device is rotated 90 deg. Device Y becomes World -X or +X
			corrected.x = raw_input.y
			corrected.y = raw_input.x
			corrected.z = raw_input.z
		DisplayServer.SCREEN_PORTRAIT:
			corrected.x = raw_input.x
			corrected.y = raw_input.y
			corrected.z = raw_input.z
		# add other cases as needed (e.g. REVERSE_LANDSCAPE)
		_:
			corrected = raw_input
			print("corrected should be non-zero vector", corrected)
			
	# 3. Fix the "backwards" issue by rotating, not negating.
	# Rotate the vector 180 degrees around the y-axis (up)
	# This flips z and x appropriately without breaking the right-hand rule.
	
	corrected = corrected.rotated(Vector3.UP, PI)
	return corrected
	
#------------------func end------------------#

"""[See func below]: One cannot simply invert z-component because 
it will create an invalid basis (rotation matrix), 
i.e. its determinant will become negative or zero, "breaking" 
the physics engine, thus move_and_slide()."""

#func invert_Z(v: Vector3) -> Vector3:
	#return Vector3(v.x, v.y, -v.z)

#func move_and_slide():
	#velocity = move_and_slide(velocity)

#################################################################
	#-------------------------MAIN CODE-------------------------#
#################################################################

func _ready():
	GlobalSignal.collision_detected.connect(Callable(self, "_handle_collision"))
	GlobalSignal.current_health.connect(Callable(self, "init_health"))
	GameState.Game_Over.connect(Callable(self, "die"), CONNECT_ONE_SHOT)
	

#--------------------physics_process()--------------------#

func _physics_process(delta: float):
	
	#get IMU sensors and perform input corrections
	
	imu_gyro = Input.get_gyroscope()
	imu_gyro = get_corrected_sensor_input(imu_gyro)
	imu_accel = Input.get_accelerometer()
	imu_accel = get_corrected_sensor_input(imu_accel) 
	imu_mag = Input.get_magnetometer()
	imu_mag = get_corrected_sensor_input(imu_mag)
	imu_grav = Input.get_gravity()
	imu_grav = get_corrected_sensor_input(imu_grav)
	
	madgwick.update(imu_gyro, imu_accel, imu_mag, delta)
	var fused_quaternion: Quaternion = madgwick.get_orientation()
	#var basis := Basis(fused_quaternion)
	
	#---------Accelerometer Kalman filtering setup---------#
	
	filtered_accelerometer = imu_accel
	filtered_accelerometer = filtered_accelerometer * (1.0 - alpha) + imu_accel * alpha
	
	#____________attempting to clamp rotation for camera stability_______#
	rotation.x  -= imu_gyro.x * rotation_speed * delta
	rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)
	rotation.y -= imu_gyro.y *rotation_speed * delta
	rotation.y = clamp(rotation.y, min_vertical_angle, max_vertical_angle)

	#---------------------Roll Banking---------------------#
	
	var yaw_input = filtered_accelerometer.x
	#rotation.y -= yaw_input * rotation_speed * delta 
	
	var target_roll = deg_to_rad(clamp(-yaw_input * roll_amout, -roll_amout, roll_amout))
	if abs(target_roll) < bank_deadzone:
		target_roll = 0.0
	rotation.z = lerp_angle(rotation.z, target_roll, alpha)
	
	var bank := Vector3(0.0, 0.0, rotation.z)
	var q_bank = Quaternion.from_euler(bank)
	var q_final = fused_quaternion * q_bank
	var basis := Basis(q_final)
	
	
	#---------------------END (Roll Banking)---------------------#
	
	if imu_accel.z < -0.2:
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
	print("IMU_acceleration = ", imu_accel)
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

#-------------------------process()-------------------------#

func _process(delta):
	#print("det = ", transform.basis.determinant())
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

#----------------------------END-----------------------------#
