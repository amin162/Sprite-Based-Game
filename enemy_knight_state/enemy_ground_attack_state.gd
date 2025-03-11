# Main GroundAttackState
extends EnemyBaseState

var state_name = "Ground_Attack"

# Constants
const SWING_TIMER_DURATION = 0.5
const ATTACK_DURATION = 0.5
var damage = 10

var current_phase

func enter(enemy):
		# Ensure the enemy faces the player
	var direction = sign(enemy.player.global_position.x - enemy.global_position.x)
	enemy.toggle_flip_sprite(direction)

	current_phase = SwingPhase.new(enemy)
	enemy.velocity = Vector2.ZERO  # Ensure enemy stays in place

func update(enemy, delta):
	current_phase.update(enemy, delta)
	var next_phase = current_phase.get_next_phase(enemy)
	if next_phase == null:
		# Transition out of GroundAttackState to Chasing only after attack phases complete
		enemy.change_state(enemy.chasing_state)
	else:
		current_phase = next_phase  # Continue to the next phase in the attack sequence

# Swing Phase Substate
class SwingPhase:
	var timer = SWING_TIMER_DURATION

	func _init(enemy):
		enemy.enemy_sprite.play("idle")  # Play the swinging animation
		enemy.swing_progress_bar.value = 0  # Reset swing progress bar at start of swing phase

	func update(enemy, delta):
		timer -= delta
		enemy.swing_progress_bar.value = 1 - (timer / SWING_TIMER_DURATION)  # Update swing progress bar

	func get_next_phase(enemy):
		if timer <= 0:
			return AttackPhase.new(enemy)
		return self

# Attack Phase Substate
class AttackPhase:
	var timer = ATTACK_DURATION

	func _init(enemy):
		enemy.activate_attack_applied()  # Enemy enters attack mode
		enemy.enemy_sprite.play("attack_1")  # Play the attack animation
		#enemy.enemy_sprite.animation_finished
		enemy.cooldown_progress_bar.value = 0  # Reset cooldown progress bar
		
		# Adjust hit impact position based on facing direction
		enemy.hit_impact_sprite.play("hit_impact1")
		
		if enemy.swordhit_sound:
				enemy.swordhit_sound.play()

	func update(enemy, delta):
		timer -= delta
		enemy.cooldown_progress_bar.value = 1 - (timer / ATTACK_DURATION)  # Update cooldown progress bar

	func get_next_phase(enemy):
		enemy.deactivate_attack_applied()  # Turn off attack hitbox
		if timer <= 0:
			# Attack animation has finished; now decide next action

			# If player is still in range, re-enter SwingPhase; otherwise, exit to another state
			if enemy.attack_range.has_overlapping_bodies():
				return SwingPhase.new(enemy)
			return null  # Null indicates transition out of GroundAttackState
		return self


# Damage application function (triggered when player enters attack range)
func _on_attack_area_applied_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("apply_damage"):
		body.apply_damage(damage)
