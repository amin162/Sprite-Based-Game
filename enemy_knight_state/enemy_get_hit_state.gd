extends EnemyBaseState

var state_name = "Get_Hit"

var stun_duration := 0.7
var stun_timer := 0.0
var knockback_force := Vector2(200, 0)  # Adjust values as needed

func enter(enemy) -> void:
	stun_timer = stun_duration
	
	# Determine knockback direction (push enemy away from player)
	var direction = sign(enemy.global_position.x - enemy.player.global_position.x)
	enemy.velocity = knockback_force * direction  # Apply knockback
	
	# Play animations & sounds
	enemy.enemy_sprite.play("get_hit")
	if enemy.get_stunned_sound and enemy.get_hurt_sound:
		enemy.get_stunned_sound.play()
		enemy.get_hurt_sound.play()
	
	# Disable enemy's attack range during stun
	enemy.chasing_area.call_deferred("set_disabled", true)

func update(enemy, delta) -> void:
	stun_timer -= delta

	# Apply friction to slow down knockback over time
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, 500 * delta)  # Adjust deceleration as needed

	# End stun and transition to appropriate state
	if stun_timer <= 0:
		if enemy.attack_range_box is Area2D and enemy.attack_range_box.has_overlapping_bodies():
			enemy.change_state(enemy.ground_attack_state)  # Player is close, so attack
		else:
			enemy.change_state(enemy.chasing_state)  # Player is far, so chase
			
func exit(enemy) -> void:
	enemy.chasing_area.call_deferred("set_disabled", false)
