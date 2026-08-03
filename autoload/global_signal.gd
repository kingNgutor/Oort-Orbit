#global_signal.gd
extends Node

signal exited_id(offscreen_instance : RigidBody3D) #notifies when asteroid(s) are offscreen
signal spaceship_velocity(velocity : Vector3) #use this to inform the camera how to follow
#signal ready_to_recycle(asteroid: RigidBody3D) #more sophisticated notifier for offscreen asteroid remove_instance() 
signal spaceship_position(player_position: Vector3) #inform pooled_asteroid.gd of player's current location in global space
signal collision_detected(collision: KinematicCollision3D) #use to pass collision data to spaceship health sys
signal current_health(health: int) #player health
signal died()
signal magnetic_field_vector(b_vec: Vector3) # use to send magnetic orientation to world environment
signal _on_map_turn_input(x: float, y: float)
#signal Game_Over()
#signal spaceship_orientation(fused_quaternion: Quaternion) # calculate camera orientation using spaceship orientation
