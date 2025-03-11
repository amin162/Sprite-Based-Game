extends BaseState

var state_name = "Run"
var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.2  # Adjust the interval based on the desired footstep frequency

func enter(character):
	character.character_sprite.play("run")
	footstep_timer = 0.0  # Reset the timer when entering the state

func update(character, delta):
	var direction := Input.get_axis("left", "right")

	# Handle footstep sound
	if character.is_on_floor() and direction != 0:
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = FOOTSTEP_INTERVAL
			if character.footstep_sound:  # Ensure you have a sound node, e.g., AudioStreamPlayer
				character.footstep_sound.play()

	# Handle raycast collision during running
	if character.run_raycast.is_colliding():
		# If the run_raycast collides, transition to idle state
		character.change_state(character.idle_state)
		return

	# If no input and the player is not moving horizontally, switch to idle state
	if direction == 0 and character.velocity.x == 0:
		# Transition to idle state if no input and not moving horizontally
		character.change_state(character.idle_state)
		return

	# If the player is falling, switch to the fall state
	if character.velocity.y > 0:
		character.change_state(character.fall_state)
		return

	# Handle jump state
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		character.change_state(character.jump_state)
		return

	# Handle attack
	if Input.is_action_just_pressed("attack") and character.is_on_floor():
		character.change_state(character.attack_state)
		return

	# Handle Sliding
	if Input.is_action_just_pressed("sliding") and character.is_on_floor():
		character.change_state(character.sliding_state)
		return

	# Update velocity based on input if no collision
	character.velocity.x = direction * character.SPEED

	# Flip sprite based on direction
	character.toggle_flip_sprite(direction)
	#print("Direction :", direction," Velocity.x : ", character.velocity.x)

func exit(_character):
	footstep_timer = 0.0  # Reset the timer when exiting the state
