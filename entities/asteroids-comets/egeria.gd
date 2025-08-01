extends RigidBody3D

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	print("[Node:VisibleOnScreenNotifier3D] --> [Script:egeria.gd] Object: ", self, " exited offscreen...")
	GlobalSignal.exited_id.emit(self)
