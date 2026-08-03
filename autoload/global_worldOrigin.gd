# global_worldOrigin.gd — autoload singleton
extends Node

signal origin_shifted(delta: Vector3)

const REBASE_THRESHOLD := 1000000.0 #0.01

var _tracked: Array[Node3D] = []

func register(node: Node3D) -> void:
	if node not in _tracked:
		_tracked.append(node)

func unregister(node: Node3D) -> void:
	_tracked.erase(node)

func _physics_process(_delta: float) -> void:
	
	process_priority = 0
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.global_position.length() > REBASE_THRESHOLD:
		print("player.global_position.length() pre-rebase: ", player.global_position.length())
		print('pre-rebase rotation basis: ', player.global_rotation)
		_rebase(player.global_position)
		print("player position rebased : ", player.global_transform.origin)
		print("rebased player rotation basis: ", player.global_rotation)
		

func _rebase(pos_delta: Vector3) -> void:
	var player := get_tree().get_first_node_in_group("player")
	for node in _tracked:
		if not is_instance_valid(node):
			continue
		node.global_position -= pos_delta
		#player.velocity = Vector3.ZERO
		#node.force_update_transform()
		#lerp(node.global_position, -pos_delta, 1.0)
		node.reset_physics_interpolation()  # critical: prevents visible slide

	emit_signal("origin_shifted", pos_delta)
