# world_environment.gd
extends WorldEnvironment


func _ready():
	#rotate the background sky relative to Earth's magnetic field
	#var magnetometer = Input.get_magnetometer()
	#environment.sky_rotation = Vector3(deg_to_rad(magnetometer.x - 60), 0, 0)
	GlobalSignal.magnetic_field_vector.connect(Callable(self, "orient_sky"))
	
func orient_sky(b_vec):
	print("sig b_vec: ", b_vec)
	environment.sky_rotation = Vector3(deg_to_rad(b_vec.x - 60), 0, 0)
