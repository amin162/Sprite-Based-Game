extends SkeletonBaseState

var state_name = "Get_Hit"

var stun_duration := 1
var stun_timer := 0.0
var knockback_force := Vector2(200, 0)  # Adjust values as needed

func enter(skeleton) -> void:
	stun_timer = stun_duration
	
	# Determine knockback direction (push skeleton away from player)
	var direction = sign(skeleton.global_position.x - skeleton.player.global_position.x)
	skeleton.velocity = knockback_force * direction  # Apply knockback
	
	# Play animations & sounds
	skeleton.skeleton_sprite.play("get_hit")
	if skeleton.get_stunned_sound and skeleton.get_hurt_sound:
		skeleton.get_stunned_sound.play()
		skeleton.get_hurt_sound.play()
	
	# Disable skeleton's attack range during stun
	skeleton.chasing_area_collision.call_deferred("set_disabled", true)

func update(skeleton, delta) -> void:
	stun_timer -= delta

	# Apply friction to slow down knockback over time
	skeleton.velocity.x = move_toward(skeleton.velocity.x, 0, 500 * delta)  # Adjust deceleration as needed

	# End stun and transition to appropriate state
	if stun_timer <= 0:
		#if skeleton.attack_range_box is Area2D and skeleton.attack_range_box.has_overlapping_bodies():
			#skeleton.change_state(skeleton.ground_attack_state)  # Player is close, so attack
		#else:
		skeleton.change_state(skeleton.chasing_state)  # Player is far, so chase
			
func exit(skeleton) -> void:
	skeleton.chasing_area_collision.call_deferred("set_disabled", false)
