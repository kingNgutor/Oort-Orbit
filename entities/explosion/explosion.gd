extends Node3D

@onready var debris: GPUParticles3D = $Debris
@onready var fire: GPUParticles3D = $Fire
@onready var smoke: GPUParticles3D = $Smoke
@onready var explosion_sfx: AudioStreamPlayer3D = $ExplosionSFX

func explode():
	# manually restarting each GPUParticles3D, respectively
	debris.emitting = false
	debris.restart()
	debris.emitting = true
	
	smoke.emitting = false
	smoke.restart()
	smoke.emitting = true
	
	fire.emitting = false
	fire.restart()
	fire.emitting = true
	
	explosion_sfx.play()
	await explosion_sfx.finished
	get_tree().change_scene_to_file(GlobalScenepath.game_over)
	#await get_tree().create_timer(5.0).timeout
	
