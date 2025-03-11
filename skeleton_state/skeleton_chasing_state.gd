extends SkeletonBaseState

var state_name = "Chasing"
const CHASE_SPEED = 40.0				# Speed for chasing
const X_PROXIMITY_THRESHOLD = 10.0	# Horizontal distance to stop chasing
var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.2			# Interval for footstep sounds

func enter(skeleton):
	# Start chasing animation and reset footstep timer
	skeleton.skeleton_sprite.play("chasing")
	footstep_timer = 0.0

func update(skeleton, delta):
	footstep_timer -= delta  # Decrement footstep timer

	# Ensure the player is still detected
	if skeleton.player:
		# Calculate direction to the player
		var direction = (skeleton.player.global_position - skeleton.global_position).normalized()
		var distance_to_player = skeleton.player.global_position.distance_to(skeleton.global_position)
		
		# Update RayCast to always stick to the player
		skeleton.chasing_raycast.target_position = direction * distance_to_player
		skeleton.chasing_raycast.force_raycast_update()

		# Check the distance from the player
		var x_distance_to_player = abs(skeleton.global_position.x - skeleton.player.global_position.x)

		# If close enough horizontally, stop movement and play idle animation
		if x_distance_to_player <= X_PROXIMITY_THRESHOLD:
			skeleton.velocity = Vector2.ZERO
			if skeleton.skeleton_sprite.animation != "idle":
				skeleton.skeleton_sprite.play("idle")
		else:
			# Set horizontal velocity towards the player at chase speed
			skeleton.velocity.x = direction.x * CHASE_SPEED
			skeleton.velocity.y += skeleton.GRAVITY * delta  # Apply gravity

			# Ensure the chasing animation is playing
			if skeleton.velocity.x != 0 and skeleton.skeleton_sprite.animation != "chasing":
				skeleton.skeleton_sprite.play("chasing")

			# Flip the sprite to face movement direction
			skeleton.toggle_flip_sprite(direction.x)
			skeleton.move_and_slide()

		# Handle footstep sound when on the floor and in "chasing" animation
		if skeleton.skeleton_sprite.animation == "chasing" and skeleton.is_on_floor():
			if footstep_timer <= 0:
				footstep_timer = FOOTSTEP_INTERVAL
				if skeleton.footstep_sound:
					skeleton.footstep_sound.play()
	else:
		# If the player is no longer detected, revert to idle state
		skeleton.change_state(skeleton.idle_state)

func exit(skeleton):
	# Reset velocity and timer when exiting the state
	skeleton.velocity = Vector2.ZERO
	footstep_timer = 0.0
