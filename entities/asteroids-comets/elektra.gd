extends RigidBody3D


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	print("[Node:VisibleOnScreenNotifier3D] --> [Script:elektra.gd] Object: ", self, " exited offscreen...")
	#ObjectPool.return_instance(self)
	#GlobalAutoload._in_use
	GlobalSignal.exited_id.emit(self)
