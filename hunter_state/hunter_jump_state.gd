extends HunterBaseState

var state_name = "Jump"

func enter(hunter):
	# Start the first jump
	hunter.velocity.y = hunter.JUMP_VELOCITY
	hunter.animated_character.play("jump")

	# Play the jump sound
	if hunter.jump_sound:
		hunter.jump_sound.play()

func update(hunter, _delta):
	# Handle horizontal movement during the jump
	var direction = Input.get_axis("left", "right")
	hunter.velocity.x = direction * hunter.SPEED

	# Flip the sprite according to movement direction
	hunter.toggle_flip_sprite(direction)
	
	# Double Jump Mechanic
	if Input.is_action_just_pressed("jump") and hunter.can_double_jump:
		hunter.velocity.y = hunter.JUMP_VELOCITY  # Apply second jump velocity
		hunter.animated_character.play("jump")  # Play jump animation again
		hunter.can_double_jump = false  # Disable further double jumps
			# Play the jump sound
		if hunter.jump_sound:
			hunter.jump_sound.play()

	# Check for attack input to trigger Jump Attack
	if Input.is_action_just_pressed("attack"):
		hunter.change_state(hunter.jump_attack_state)
		return

	# Handle cut jumping (jump release reduces upward velocity)
	if Input.is_action_just_released("jump") and hunter.velocity.y < 0:
		hunter.velocity.y *= 0.5  # Reduce upward velocity to cut the jump

	# If falling, transition to fall state
	if hunter.velocity.y > 0:
		hunter.change_state(hunter.fall_state)
