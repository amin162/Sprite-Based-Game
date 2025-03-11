extends BossBaseState

var state_name = "Death"
var death_sound_playing = false
var explosion_sound_playing = false

func enter(boss) -> void:
	# Mark the boss as dead and start death animation
	boss.is_dead = true
	boss.boss_sprite.play("Death")
	
	# Connect frame_changed signal to track animation frames
	if not boss.boss_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(boss)):
		boss.boss_sprite.frame_changed.connect(Callable(self, "_on_frame_changed").bind(boss))

	# Await the animation to finish before freeing the boss
	await boss.boss_sprite.animation_finished
	boss.queue_free()  # Remove the boss from the scene after animation finishes

func _on_frame_changed(boss):
	var current_frame = boss.boss_sprite.frame
	
	# Play death sound between frames 0 and 29
	if current_frame >= 0 and current_frame <= 29:
		if boss.death_sound and not death_sound_playing:
			boss.death_sound.play()
			death_sound_playing = true

	# Play explosion sound between frames 30 and 43
	if current_frame >= 28 and current_frame <= 43:
		if boss.explosion_sound and not explosion_sound_playing:
			boss.explosion_sound.play()
			explosion_sound_playing = true
