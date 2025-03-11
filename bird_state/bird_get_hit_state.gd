extends BirdBaseState

var state_name = "GetHit"
var knockback_force = Vector2.ZERO

func enter(bird):
	# Calculate knockback direction and strength
	var direction = (bird.global_position - bird.player.global_position).normalized()
	knockback_force = direction * 120.0  # Adjust knockback strength as needed
	if bird.blade_hit_sound:
		bird.blade_hit_sound.play()

func update(bird, delta):
	# Apply knockback
	bird.velocity += knockback_force * delta
	knockback_force = knockback_force.move_toward(Vector2.ZERO, 300 * delta)  # Gradual reduction to zero

	# Once knockback is negligible, return to the previous state
	if knockback_force.length() < 10.0:
		# Transition back to chasing or idle state
		if bird.player_in_range:
			bird.change_state(bird.attack_chasing_state)
		else:
			bird.change_state(bird.idle_state)

	# Move the bird
	bird.move_and_slide()

func exit(bird):
	# Reset velocity when leaving the state
	bird.velocity = Vector2.ZERO
