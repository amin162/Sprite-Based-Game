extends BODBaseState

var state_name = "Death"
var death_sound_playing = false
var vanishing_sound_playing = false

func enter(bod) -> void:
	# Mark the bod as dead and start death animation
	bod.is_dead = true
	bod.bod_sprite.play("death")
	
	# Connect frame_changed signal to track animation frames
	if not bod.bod_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(bod)):
		bod.bod_sprite.frame_changed.connect(Callable(self, "_on_frame_changed").bind(bod))

	# Await the animation to finish before freeing the bod
	await bod.bod_sprite.animation_finished
	bod.queue_free()  # Remove the boss from the scene after animation finishes

func _on_frame_changed(bod):
	var current_frame = bod.bod_sprite.frame
	
	# Play death sound between frames 0 and 29
	if current_frame >= 0 and current_frame <= 22:
		if bod.death_sound and not death_sound_playing:
			bod.death_sound.play()
			death_sound_playing = true

	# Play explosion sound between frames 30 and 43
	if current_frame >= 20 and current_frame <= 32:
		if bod.vanishing_sound and not vanishing_sound_playing:
			bod.vanishing_sound.play()
			vanishing_sound_playing = true
