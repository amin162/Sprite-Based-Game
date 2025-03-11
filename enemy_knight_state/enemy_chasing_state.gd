extends EnemyBaseState

var state_name = "Chasing"
const CHASE_SPEED = 40.0  # Speed for chasing
const X_PROXIMITY_THRESHOLD = 10.0  # Horizontal distance to stop chasing
var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.2  # Interval for footstep sounds

func enter(enemy):
	enemy.enemy_sprite.play("chasing")  # Start with the chasing animation
	footstep_timer = 0.0  # Reset footstep timer

func update(enemy, delta):
	footstep_timer -= delta  # Decrement footstep timer

	if enemy.player:  # Ensure player is still detected
		var x_distance_to_player = abs(enemy.global_position.x - enemy.player.global_position.x)

		# Stop chasing if horizontally close enough
		if x_distance_to_player <= X_PROXIMITY_THRESHOLD:
			enemy.velocity = Vector2.ZERO  # Stop movement
			if enemy.enemy_sprite.animation != "idle":
				enemy.enemy_sprite.play("idle")  # Switch to idle animation
		else:
			# Move towards the player if not too close horizontally
			var direction = (enemy.player.global_position - enemy.global_position).normalized()
			enemy.velocity.x = direction.x * CHASE_SPEED
			enemy.velocity.y += enemy.GRAVITY * delta  # Apply gravity

			# Resume chasing animation if moving
			if enemy.velocity.x != 0 and enemy.enemy_sprite.animation != "chasing":
				enemy.enemy_sprite.play("chasing")

			enemy.toggle_flip_sprite(direction.x)
			enemy.move_and_slide()

		# Handle footstep sound only when "chasing" animation is playing
		if enemy.enemy_sprite.animation == "chasing" and enemy.is_on_floor():
			if footstep_timer <= 0:
				footstep_timer = FOOTSTEP_INTERVAL
				if enemy.footstep_sound:
					enemy.footstep_sound.play()
	else:
		# If player is no longer detected, switch to idle state
		enemy.change_state(enemy.idle_state)

func exit(enemy):
	enemy.velocity = Vector2.ZERO  # Reset velocity when exiting the state
	footstep_timer = 0.0  # Reset the timer when exiting the state
