#player_spaceship.gd
extends CharacterBody3D

#_______________________________Initialization_________________________________#
#accl/vel
@export var MAXIMUM_SPEED := 80.0
@export var MINIMUM_SPEED := 20.0
@export var acceleration := 15.5
@export var deceleration := 10.5
@export var current_speed := 30.0

#orientation
@export var yaw_speed := 45.0
@export var pitch_speed := 45.0
@export var roll_speed := 45.0
var bank_angle := 0.0
@export var bank_speed : float = 20.0

#var local_forward : Vector3
#var world_forward : Vector3
var counter := 0
var elapsed : float = 0.0
@export var duration : float = 0.5

var vanishing_direction: Vector3
var far_point: Vector3

#model ref
@onready var spaceship = $"lightfighter_yflip"


var turn_input = Vector2()
##############################################
#Health Variables
@onready var game_manager: Node = $"../GameManager"
#@export var max_health: int = 100
var current_health = GameState.player_health

#Collision Variables
@export var damage_cooldown := 3.0 #secs
var damage_timer := 0.0
var damaged_colliders: = {}

# Spaceship Position
var player_position : Vector3

@onready var camera =  get_viewport().get_camera_3d()

########################____Ready()____#########################

func _ready() -> void:
	
	GlobalWorldOrigin.register(self)    # floating-origin
	
	yaw_speed = deg_to_rad(yaw_speed)
	pitch_speed = deg_to_rad(pitch_speed)
	roll_speed = deg_to_rad(roll_speed)
	#current_health = max_health
	GlobalSignal.collision_detected.connect(Callable(self, "_handle_collision"))
	GlobalSignal.current_health.connect(Callable(self, "init_health"))
	GameState.Game_Over.connect(Callable(self, "die" ), CONNECT_ONE_SHOT)
	#PooledAsteroid.activate()
	#print("pooledAsteroid id = ", PooledAsteroid.pool.get_instance_id())
	
	######## Quaternion Rotation to vanishing point ############
	# this is to keep ship pointing toward horizon vanishing point
	if camera:
		print("Camera found...assigning camera variables...")
		# Direction the camera is looking (toward the vanishing point)
		vanishing_direction = -camera.global_basis.z
		# A point very far in that direction
		far_point = camera.global_position + vanishing_direction * camera.far
		print("Camera varialbes assigned.")
		
	if not camera:
		#print("Warning: Camera not found.")
		push_error("Missing Camera node. Make sure there is an active camera in scene.")
		print("Error. See Stack Trace. Halting program execution...")
		breakpoint # graceful preemptive failure if no camera is present

	######## /Quaternion Rotation to vanishing point/ ############
	
#____________________________Transformation Functions___________________________#
func apply_rotation(vector,delta):
	
	pass
	
	#rotate(basis.z, vector.z * roll_speed * delta)
	rotate(basis.x, vector.x * pitch_speed * 3.0 * delta)
	rotate(basis.y, vector.y * yaw_speed * 1.5 * delta)
	##lean mesh
	#if vector.y < 0:
		#spaceship.rotation.z = lerp_angle(spaceship.rotation.z, deg_to_rad(-45) * vector.y, delta)
	#elif vector.y > 0:
		#spaceship.rotation.z = lerp_angle(spaceship.rotation.z, deg_to_rad(45) * -vector.y, delta)
	#else:
		#spaceship.rotation.z = lerp_angle(spaceship.rotation.z, 0, delta)
	


##takes the x,y values for the analog stick input and turn them into a Vector2 normalized to the unit circle.
func map_turn_input(delta):
	var x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var combined_xy_axes = Vector2(x, y).normalized()
	#turn_input = -combined_xy_axes #inverted axes (up is down, down is up)
	turn_input = combined_xy_axes
	
	#------------------------------------------------------------#
	# Roll Banking Subsystem
	#------------------------------------------------------------#
	'''The ship rotates around Z-axis relative to the camera's vanishing point.
	Quaternion spherical interpolation is applied to the vectors banking around 
	and facing toward the vanishing point resulting in a net rotation which is 
	applied to the ships basis rotation matrix.'''
	
	vanishing_direction = -camera.global_basis.z # Vector3.FORWARD # camera's forward-facing direction 
	far_point = camera.global_position + vanishing_direction * camera.far # camera perspective vanishing point
	var current_rotation = Quaternion(basis.orthonormalized()) # this node's (i.e. ship's) current rotation quaternion matrix
	
	var forward_dir = (far_point - global_position).normalized()
	
	#-------------------------------------------------------------------#
	#---- fix for polar degenerate singularity chaoticness ----#
	# How close is forward_dir to the world y axis (1.0 = exactly parallel = singularity)
	var up_dot = abs(forward_dir.dot(Vector3.UP))
	
	# Ship's own current up, as a fallback reference that's guaranteed
	# roughly perpendicular to forward_dir (since it's continuous frame-to-frame)
	var current_up = current_rotation * Vector3.UP
	
	# Blend from world UP to current_up as we approach th pole. Away from the
	# pole this is pure Vector3.UP (identical to our original behavior);
	# near the pole it smoothly hands off to a non-degenerate reference.
	var blend = smoothstep(0.9, 0.995, up_dot) # tune these two thresholds to taste
	var reference_up = Vector3.UP.lerp(current_up, blend).normalized()
	#-------------------------------------------------------------------#
	
	# 1. Base look-at quaternion
	var look_basis = Basis.looking_at(far_point - global_position, Vector3.UP)
	var look_quat = look_basis.get_rotation_quaternion()
	
	# 2. Compute target bank angle from input, reset when input stops
	var target_bank = x * deg_to_rad(90)
	bank_angle = lerp(bank_angle, target_bank, bank_speed * delta)
	
	# 3. Bank rotation is ALWAYS around the ship's local z (forward)
	var bank_quat = Quaternion(Vector3.FORWARD, bank_angle)
	
	# 4. Compose: look first, then bank in local space
	var target_quat = look_quat * bank_quat
	
	# 5. Spherically interpolate the whole thing at once
	current_rotation = current_rotation.slerp(target_quat, 3.0 * delta)
	global_transform.basis = Basis(current_rotation) # apply interpolated rotation to node3d
	if x != 0:
		pass
		#global_translate(Vector3(0,-3,-4))
		#global_translate(lerp(Vector3.ZERO, Vector3(0,-3,0), bank_speed * delta))
	#------------------------------------------------------------#
	# Roll Banking Subsystem ---- END ---- #
	#------------------------------------------------------------#

#___________________________Damage Functions____________________________#
func _handle_collision(collision: KinematicCollision3D):
	var collider = collision.get_collider()
	var collision_position = collision.get_position()
	var collision_RID = collision.get_collider_rid()
	
	#if collider.has_method("get_damage"):
		#apply_damage(collider.get_damage())
	if collider is RigidBody3D:
		print("collided with rigidbody3d: ", collider.name, " " , collision_RID, " " , collision_position)
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
	#RenderingServer.force_sync()
	#queue_free() #or trigger a respawn, gameover etc.
	#get_tree().change_scene_to_file(GlobalScenepath.game_over)
	

func gain_health():
	
	# gain health
	GameState.player_health += 5 
	current_health = GameState.player_health

func _exit_tree() -> void:
	pass
	GlobalWorldOrigin.unregister(self)

#_________________proc/phys_proc_________________#

func _physics_process(delta: float) -> void:

	#---------------------------------------------------------------------------------------------#	
	# reset player global position if x, y, or, z exceeds 100,000 units (or perhaps 95,000 conservatively)
	
	#if player_position.x > 95000:
		#pass    # transform player position to origin (will it break move_and_slide()?)
	#if player_position.y > 95000:
		#pass    # transform player position to origin (will it break move_and_slide()?)
	#if player_position.z > 95000:
		#pass    # transform player position to origin (will it break move_and_slide()?)
		
	#---------------------------------------------------------------------------------------------#
	
	#vanishing_direction = -camera.global_basis.z
	# A point very far in that direction
	#far_point = camera.global_position + vanishing_direction * camera.far
	#print("far point: ", far_point)
	
	#var input = Input.get_vector("ui_up","ui_down","ui_left","ui_right")
	var x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var roll = Input.get_axis("left_trigger","right_trigger")
	
	velocity = -basis.z * current_speed * acceleration + basis.y * 3.0
	if x != 0:
		velocity += -basis.x * current_speed + basis.y * current_speed * 3.0 
	#acceleration += 2.0
	#assigned_velocity = velocity
	GlobalSignal.spaceship_velocity.emit(velocity) #inform the rest of the program player velocity
	
	# if no input, rotate up (+y) by some amount to offset rebase pitch error
	#if not x or roll:
		#global_rotation_degrees = Vector3(0,20,0)
	#----Apply transformations and movement----#
	
	move_and_slide()
	
	#--------COLLISION HANDLING--------#
	if damage_timer > 0:
		damage_timer -= delta
	var collision = move_and_collide(velocity * delta)
	if collision and damage_timer <= 0:
		_handle_collision(collision)
	 # Clean up colliders no longer in contact
	for c in damaged_colliders.keys():
		if not is_colliding_with(c):
			damaged_colliders.erase(c)
	#for i in range(get_slide_collision_count()):
		#var collision = get_slide_collision(i)
		#if collision.get_collider() is RigidBody3D:
			#print("Hit RigidBody3D: ", collision.get_collider().name)
			#apply_damage(10)

	var turn_dir  = Vector3(-turn_input.y, -turn_input.x, -roll * 0)
	apply_rotation(turn_dir, delta)
	
	player_position = global_transform.origin
	turn_input = Vector2()
	map_turn_input(delta)
	GlobalSignal.spaceship_position.emit(player_position)
	print("spaceshipPosition: ", player_position)
	if abs(player_position.z) > 250000.0:
		print("player_position exceeded 100,000.0. IS FP JITTER???")
	#print("velocity: ", velocity)
	
	
	
	
func _process(_delta: float) -> void:
	
	
	#print("Forward: ", global_transform.basis.z)
	#print("Up: ", global_transform.basis.y)
	#print("Right: ", global_transform.basis.x)
	
	#local_forward = -global_basis.z.normalized()
	#world_forward = Vector3.FORWARD
	## var angle = local_forward.angle_to(world_forward)
	#var angle = local_forward.signed_angle_to(world_forward, Vector3.UP)
	#var angle_deg = rad_to_deg(angle)
	#print("delta local/global Z-axes : ", angle_deg)
	
	
	# Esc -> exit runtime
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	# Backspace -> pause_game event chain starts here
	if Input.is_action_just_released("ui_text_backspace"):
	
		if GameState.pause_state == false:
			GameState.pause_game()
