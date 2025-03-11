extends BaseState

var state_name = "Jump"

func enter(character):
	# Start the jump
	character.velocity.y = character.JUMP_VELOCITY
	character.character_sprite.play("jump")

	# Play the jump sound
	if character.jump_sound:
		character.jump_sound.play()

func update(character, _delta):
	# Handle horizontal movement during the jump
	var direction = Input.get_axis("left", "right")
	character.velocity.x = direction * character.SPEED

	# Flip the sprite according to movement direction
	character.toggle_flip_sprite(direction)

	# Handle cut jumping
	if Input.is_action_just_released("jump") and character.velocity.y < 0:
		character.velocity.y *= 0.5  # Reduce upward velocity to cut the jump

	# Handle wall sliding
	if character.is_on_wall() and direction != 0:
		# Ignore wall sliding on Layer 10 (Invisible Wall)
		var collision = character.get_last_slide_collision()
		if collision:
			var collider = collision.get_collider()
			# Check if the collider is on Layer 10 (Invisible Wall)
			if collider is CollisionObject2D and collider.collision_layer & (1 << 9):  # Layer 10
				return  # Ignore wall slide on invisible walls

		# Transition to wall slide only if falling and not holding jump
		if character.velocity.y > 0 and not Input.is_action_pressed("jump"):
			character.change_state(character.wall_slide_state)
			return

	# Transition to fall state if falling
	if character.velocity.y > 0:
		character.change_state(character.fall_state)
		return

	# Transition to air attack state if attack is pressed
	if Input.is_action_just_pressed("attack"):
		character.change_state(character.air_attack_state)
		return

	# Transition to idle state if on the ground and not moving vertically
	if character.is_on_floor() and character.velocity.y == 0:
		character.change_state(character.idle_state)
		return
