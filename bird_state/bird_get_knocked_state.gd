extends BirdBaseState

var state_name = "Get_Knocked"

var stun_duration := 0.7
var stun_timer := 0.0
var knockback_force := Vector2(200, 0)  # Adjust values as needed

func enter(bird) -> void:
	stun_timer = stun_duration
	
	# Determine knockback direction (push enemy away from player)
	var direction = sign(bird.global_position.x - bird.player.global_position.x)
	bird.velocity = knockback_force * direction  # Apply knockback
	
	# Disable enemy's attack range during stun
	bird.pulling_area_collision_box.call_deferred("set_disabled", true)
	bird.chasing_range_collision_box.call_deferred("set_disabled", true)

func update(bird, delta) -> void:
	stun_timer -= delta

	# Apply friction to slow down knockback over time
	bird.velocity.x = move_toward(bird.velocity.x, 0, 500 * delta)  # Adjust deceleration as needed

	# End stun and transition to appropriate state
	if stun_timer <= 0:
		bird.change_state(bird.idle_state)  # Player is close, so attack
			
func exit(bird) -> void:
	bird.pulling_area_collision_box.call_deferred("set_disabled", false)
	bird.chasing_range_collision_box.call_deferred("set_disabled", false)
