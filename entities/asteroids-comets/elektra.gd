#elektra.gd
extends RigidBody3D

#______________________Initialization_________________#
@export var damage_amount: int = 20
var target: CharacterBody3D
var tracking_strength := 20.0
var max_speed := 1000.0

#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#if not target:
		#return
	#
	## Direction toward player
	#var to_target = (target.global_position - state.transform.origin).normalized()
	#
	## Steer toward player
	#state.apply_central_force(to_target * tracking_strength)
	#
	## Clamp speed so it doesn't accelerate forever
	#if state.linear_velocity.length() > max_speed:
		#state.linear_velocity = state.linear_velocity.normalized() * max_speed

#__________________________________Functions_____________________________#
##upon damage it returns damage amount as set in inspector (default initialization = int 20)
func get_damage():
	return damage_amount

##signal to notify gameloop of offscreen objects so objectpool can remove instance 
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	#print("[Node:VisibleOnScreenNotifier3D] --> [Script:elektra.gd] Object: ", self, " exited offscreen...")
	GlobalSignal.exited_id.emit(self)
	if GameState.game_over_state != true:
		HighScore.current_score += 1
		

func _on_body_shape_entered(body_rid: RID, _body: Node, _body_shape_index: int, _local_shape_index: int) -> void:
	#print("elektra.gd -> collision_detected")
	GlobalSignal.collision_detected.emit(self)

func _on_area_3d_body_entered(body: Node3D) -> void:
	
	"""INFO: THIS FUNCTION IS CURRENTLY REDUNDANT. CONSIDER ELIMINATION."""
	
	if body is CharacterBody3D:
		if body.has_method("apply_damage"):
			#print("applying 10 damage from rigidbody3d signal")
			#body.apply_damage(10)
			pass # Replace with function body.
	
	#print("player collision")
	#GlobalSignal.collision_detected.emit(self)
	
func _physics_process(delta: float) -> void:
	if not target:
		return
	# Direction toward player
	var to_target = (target.global_position - transform.origin).normalized()
	linear_velocity = linear_velocity.lerp(to_target * max_speed, tracking_strength * delta)
	
