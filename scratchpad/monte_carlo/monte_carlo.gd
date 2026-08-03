extends Node

# Parameters
@export var radius = 10.0  # Radius of the circle (in world units)
@export var z_distance = 5.0  # Fixed z-distance from center
@export var num_points = 100  # Number of random points to generate

var spawn_points : Array[Vector3] = []

func _ready():
	generate_radial_spawn_points()


func generate_radial_spawn_points():
	var start = Time.get_ticks_usec()
	for i in range(num_points):
		# Generate a random angle θ ∈ [0, 2π)
		var theta = randf() * PI * 2.0

		# Calculate x and y using polar coordinates (uniform distribution over area)
		var r = sqrt(radius * radius - z_distance * z_distance) * cos(theta)

		# Convert to Cartesian coordinates
		var x = r * cos(theta)
		var y = r * sin(theta)

		# Create a new point at (x, y, z_distance)
		var point = Vector3(x, y, z_distance)
		spawn_points.append(point)
	var elapsed = Time.get_ticks_usec() - start

	print("Generated ", num_points, " points in ", elapsed, " microseconds.")


# Alternative: If you want uniform distribution over the circumference (not area)
func generate_uniform_circumference_points():
	for i in range(num_points):
		var theta = randf() * PI * 2.0
		var x = radius * cos(theta)
		var y = radius * sin(theta)
		var point = Vector3(x, y, z_distance)
		spawn_points.append(point)
	print("Generated ", num_points ," uniform circumference points ", spawn_points)
