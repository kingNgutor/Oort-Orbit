# rogue_squadron_camera_[CLAUDE.AI]

extends Node3D

# Reference to the target (your spaceship)
@export var target: Node3D
@export var camera: Camera3D

# Camera positioning
@export var follow_distance: float = 8.0
@export var follow_height: float = 2.8 # for whatever reason, deviating from a value of ~1.25 in either direction interacts with the worldOrigin rebasing logic to induce player rotation around x-axis...
@export var look_ahead_distance: float = 8.0

# Camera smoothing
@export var position_smoothing: float = 4.0
@export var rotation_smoothing: float = 3.0
@export var look_at_smoothing: float = 5.0

# Banking behavior (the key to Rogue Squadron feel)
@export var bank_amount: float = 25.0  # Degrees of camera roll
@export var bank_smoothing: float = 4.0
@export var lateral_offset_amount: float = 2.5  # Camera shifts left/right during turns
@export var lateral_offset_smoothing: float = 2.0

# Pitch response
@export var pitch_influence: float = 0.3  # How much pitch affects camera height
@export var pitch_smoothing: float = 8.0

# Internal state
var current_bank: float = 0.0
var current_lateral_offset: float = 0.0
var current_pitch_offset: float = 0.0
var velocity_history: Array = []
var previous_target_position: Vector3

# Game Over Explosion trigger sequence

@onready var explosion: Node3D = $Explosion


func detonate_spaceship():
	print("detonating...")
	explosion.explode() # detonation
	await get_tree().create_timer(10.0).timeout # display detonation event
	print("waited 10 seconds. dispatching to game_over.tscn...") 
	get_tree().change_scene_to_file(GlobalScenepath.game_over) # advance to game over screen

#---------------------------------Main Code---------------------------------#

func _ready():
	GlobalSignal.died.connect(Callable(self, "detonate_spaceship"))
	GlobalWorldOrigin.register(self)
	if not target:
		push_error("Camera script needs a target (spaceship) assigned!")
		return
	
	if not camera:
		camera = get_node_or_null("Camera3D")
		if not camera:
			push_error("Camera3D not found as child!")
			return
	
	previous_target_position = target.global_position
	velocity_history = []

func _physics_process(delta: float):
	if not target or not camera:
		return
	
	# Calculate target velocity
	var current_velocity = (target.global_position - previous_target_position) / delta
	previous_target_position = target.global_position
	
	# Store velocity history for smoothing
	velocity_history.append(current_velocity)
	if velocity_history.size() > 5:
		velocity_history.pop_front()
	
	# Calculate average velocity for smoother response
	var avg_velocity = Vector3.ZERO
	for vel in velocity_history:
		avg_velocity += vel
	if velocity_history.size() > 0:
		avg_velocity /= velocity_history.size()
	
	# Get target's local movement direction
	var target_basis = target.global_transform.basis
	var local_velocity = target_basis.inverse() * avg_velocity
	
	# Calculate banking based on lateral movement
	var target_bank = -local_velocity.x * bank_amount / 10.0  # Negative for correct direction
	target_bank = clamp(target_bank, -bank_amount, bank_amount)
	current_bank = lerp(current_bank, target_bank, bank_smoothing * delta)
	
	# Calculate lateral offset (camera shifts in turn direction)
	var target_lateral = local_velocity.x * lateral_offset_amount / 10.0
	target_lateral = clamp(target_lateral, -lateral_offset_amount, lateral_offset_amount)
	current_lateral_offset = lerp(current_lateral_offset, target_lateral, lateral_offset_smoothing * delta)
	
	# Calculate pitch offset (camera adjusts height during pitch maneuvers)
	var target_pitch_offset = -local_velocity.y * pitch_influence
	current_pitch_offset = lerp(current_pitch_offset, target_pitch_offset, pitch_smoothing * delta)
	
	# Calculate ideal camera position behind the ship
	var target_forward = -target_basis.z  # Ship's forward direction
	var target_right = target_basis.x
	var target_up = target_basis.y
	
	# Base position behind and above the ship
	var ideal_position = target.global_position
	ideal_position -= target_forward * follow_distance  # Behind
	ideal_position += target_up * (follow_height + current_pitch_offset)  # Above (with pitch adjustment)
	ideal_position += target_right * current_lateral_offset  # Lateral offset during turns
	
	# Smooth camera position
	global_position = global_position.lerp(ideal_position, (position_smoothing + 10) * delta)
	
	# Calculate look-at point (ahead of the ship)
	var look_target = target.global_position + target_forward * look_ahead_distance
	look_target += target_up * 1.0  # Slightly above ship center
	
	# Smooth look-at
	var current_look = global_position + (-global_transform.basis.z * 10.0)
	var smooth_look = current_look.lerp(look_target, look_at_smoothing * delta)
	
	# Apply look-at without banking first
	look_at(smooth_look, Vector3.UP)
	
	# Apply banking roll (THIS IS THE KEY TO ROGUE SQUADRON FEEL)
	var current_rotation = rotation_degrees
	var target_roll = current_bank
	current_rotation.z = lerp_angle(deg_to_rad(current_rotation.z), deg_to_rad(target_roll), bank_smoothing * delta)
	
	# Reconstruct the rotation with the new roll
	var look_direction = (smooth_look - global_position).normalized()
	var right = Vector3.UP.cross(look_direction).normalized()
	var up = look_direction.cross(right).normalized()
	
	# Apply roll to the up vector
	var roll_rotation = Basis(look_direction, deg_to_rad(target_roll)).orthonormalized()
	up = roll_rotation * up
	right = up.cross(look_direction).normalized()
	
	# Construct final basis
	var final_basis = Basis(right, up, -look_direction).orthonormalized()
	
	var basis_interpolation = global_transform.basis.get_rotation_quaternion()#.slerp(final_basis, rotation_smoothing * delta)
	global_transform.basis = Basis(basis_interpolation)#.slerp(final_basis, rotation_smoothing * delta)
	
	
# Optional: Add camera shake for impacts/shooting
func add_camera_shake(intensity: float, duration: float):
	# Implement if needed
	pass
func _exit_tree() -> void:
	GlobalWorldOrigin.unregister(self)
	pass
