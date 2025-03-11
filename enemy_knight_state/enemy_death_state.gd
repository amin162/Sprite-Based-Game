# DeathState.gd
extends EnemyBaseState

var state_name = "Death"

func enter(enemy) -> void:
	if enemy.death_sound:
		enemy.death_sound.play()
	enemy.is_dead = true  # Mark enemy as dead
	enemy.enemy_sprite.play("death")  # Play the death animation

	# Kill the hit tween if it exists
	if enemy.hit_tween and enemy.hit_tween.is_valid():
		enemy.hit_tween.kill()
	
	# Await the completion of the animation before removing the enemy
	await enemy.enemy_sprite.animation_finished
	enemy.queue_free()  # Remove the enemy from the scene
