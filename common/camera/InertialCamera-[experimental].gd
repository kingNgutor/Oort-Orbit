extends Camera3D

@export var target_node: CharacterBody3D # Assign the 'Brain' node, not the Visuals
@export var follow_offset: Vector3 = Vector3(0, 1.2, 4.5)

@export var pos_tightness: float = 10.0
@export var rot_tightness: float = 5.0

func _physics_process(delta: float) -> void:
	if not target_node: return
	
	# Ideal position is relative to the ship's 'Brain'
	var target_pos = target_node.global_transform * follow_offset
	
	# Smoothly follow position
	global_position = global_position.lerp(target_pos, pos_tightness * delta)
	
	# Smoothly slerp rotation to match the ship's 'Brain'
	# This creates the delay that allows the displaced mesh to move toward screen edges
	global_basis = global_basis.slerp(target_node.global_basis, rot_tightness * delta)
