extends Node3D

var instanceNode = preload("res://scratchpad/multimeshinstance3d_exp/suzanne.obj")
@export var number_of_mesh : int = 1000
@export var rotation_speed : float = 0.2
 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_mesh()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.rotate_y(rotation_speed * delta)
	pass

func generate_mesh():
	for _i in range(0, number_of_mesh - 1):
		var child = instanceNode.instance()
		var x = randf_range(-50.0, 50.0)
		var y = randf_range(0.0, 20.0)
		var z = randf_range(-50.0, 50.0)
		child.translate(Vector3(x,y,z))
		add_child(child)
