extends BaseState

var state_name = "Sliding"

# Define the sliding speed and duration
const SLIDE_SPEED = 300.0
const SLIDE_DURATION = 0.2

var slide_timer = 0.0
var SLIDE_INTERVAL = 0.3  # Interval for playing the sliding sound
var sound_timer = 0.0  # Separate timer for sound playback
var slide_direction = 0

func enter(character):
	# Ensure the raycast direction matches the slide direction
	slide_direction = sign(character.velocity.x)  # Use the current velocity direction
	if slide_direction == 0:
		slide_direction = sign(Input.get_axis("left", "right"))  # Default to input direction if velocity is zero

	character.slide_raycast.scale.x = slide_direction  # Flip the raycast direction

	# Check if the raycast is colliding
	if character.slide_raycast.is_colliding():
		# If colliding with a slope or wall, transition to idle or run
		if character.is_on_floor():
			if Input.get_axis("left", "right") != 0:
				character.change_state(character.run_state)
			else:
				character.change_state(character.idle_state)
		else:
			character.change_state(character.fall_state)
		return

	# Set the slide timer and sound timer
	slide_timer = SLIDE_DURATION
	sound_timer = SLIDE_INTERVAL

	# Set the velocity for sliding in the correct direction
	character.velocity.x = slide_direction * SLIDE_SPEED
	character.velocity.y = min(character.velocity.y + character.GRAVITY, SLIDE_SPEED)  # Limit downward speed
	# Play the sliding animation
	character.character_sprite.play("slide")

	# Flip the sprite according to the slide direction
	character.toggle_flip_sprite(slide_direction)

	# Play the sliding sound immediately upon entering the state
	if character.slide_sound:
		character.slide_sound.play()

func update(character, delta):
	# Decrease the slide and sound timers
	slide_timer -= delta
	sound_timer -= delta

	# Play the sliding sound at intervals
	if sound_timer <= 0 and character.slide_sound:
		sound_timer = SLIDE_INTERVAL  # Reset the sound timer
		character.slide_sound.play()

	# Continue sliding for the duration
	if slide_timer > 0:
		# Maintain sliding direction and speed
		character.velocity.x = slide_direction * SLIDE_SPEED
		character.velocity.y = min(character.velocity.y + character.GRAVITY, SLIDE_SPEED)  # Limit downward speed


		# Check for collisions during the slide
		if character.slide_raycast.is_colliding():
			# Stop the slide if a slope or wall is encountered
			if character.is_on_floor():
				if Input.get_axis("left", "right") != 0:
					character.change_state(character.run_state)
				else:
					character.change_state(character.idle_state)
			else:
				character.change_state(character.fall_state)
	else:
		# After sliding ends, transition based on current state
		if character.is_on_floor():
			if Input.get_axis("left", "right") != 0:
				character.change_state(character.run_state)
			else:
				character.change_state(character.idle_state)
		else:
			character.change_state(character.fall_state)

	# Handle transition if attack input is pressed during the slide
	if Input.is_action_just_pressed("attack"):
		character.change_state(character.attack_state)

func exit(character):
	# Reset the velocity when leaving the sliding state
	character.velocity.x = 0
	slide_timer = 0.0  # Reset the slide timer
	sound_timer = 0.0  # Reset the sound timer
