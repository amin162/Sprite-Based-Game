extends HunterBaseState

var state_name = "Dash"

# Define the sliding speed and duration
const DASH_SPEED = 300.0
const DASH_DURATION = 0.2

var dash_timer = 0.0
var DASH_INTERVAL = 0.3  # Interval for playing the sliding sound
var sound_timer = 0.0  # Separate timer for sound playback
var dash_direction = 0

func enter(hunter):
	# Ensure the raycast direction matches the dash direction
	dash_direction = sign(hunter.velocity.x)  # Use the current velocity direction
	if dash_direction == 0:
		dash_direction = sign(Input.get_axis("left", "right"))  # Default to input direction if velocity is zero

	hunter.dash_raycast.scale.x = dash_direction  # Flip the raycast direction

	# Check if the raycast is colliding
	if hunter.dash_raycast.is_colliding():
		# If colliding with a slope or wall, transition to idle or run
		if hunter.is_on_floor():
			if Input.get_axis("left", "right") != 0:
				hunter.change_state(hunter.run_state)
			else:
				hunter.change_state(hunter.idle_state)
		else:
			hunter.change_state(hunter.fall_state)
		return

	# Set the dash timer and sound timer
	dash_timer = DASH_DURATION
	sound_timer = DASH_INTERVAL

	# Set the velocity for sliding in the correct direction
	hunter.velocity.x = dash_direction * DASH_SPEED
	hunter.velocity.y = min(hunter.velocity.y + hunter.GRAVITY, DASH_SPEED)  # Limit downward speed
	# Play the sliding animation
	hunter.animated_character.play("dash")
	#hunter.character_animation.play("dash")

	# Flip the sprite according to the dash direction
	hunter.toggle_flip_sprite(dash_direction)

	# Play the sliding sound immediately upon entering the state
	if hunter.dash_sound:
		hunter.dash_sound.play()

func update(hunter, delta):
	# Decrease the dash and sound timers
	dash_timer -= delta
	sound_timer -= delta

	# Play the sliding sound at intervals
	if sound_timer <= 0 and hunter.dash_sound:
		sound_timer = DASH_INTERVAL  # Reset the sound timer
		hunter.dash_sound.play()

	# Continue sliding for the duration
	if dash_timer > 0:
		# Maintain sliding direction and speed
		hunter.velocity.x = dash_direction * DASH_SPEED
		hunter.velocity.y = min(hunter.velocity.y + hunter.GRAVITY, DASH_SPEED)  # Limit downward speed


		# Check for collisions during the dash
		if hunter.dash_raycast.is_colliding():
			# Stop the dash if a slope or wall is encountered
			if hunter.is_on_floor():
				if Input.get_axis("left", "right") != 0:
					hunter.change_state(hunter.run_state)
				else:
					hunter.change_state(hunter.idle_state)
			else:
				hunter.change_state(hunter.fall_state)
	else:
		# After sliding ends, transition based on current state
		if hunter.is_on_floor():
			if Input.get_axis("left", "right") != 0:
				hunter.change_state(hunter.run_state)
			else:
				hunter.change_state(hunter.idle_state)
		else:
			hunter.change_state(hunter.fall_state)

	# Handle transition if attack input is pressed during the dash
	if Input.is_action_just_pressed("attack"):
		hunter.change_state(hunter.attack_state)

func exit(hunter):
	# Reset the velocity when leaving the sliding state
	hunter.velocity.x = 0
	dash_timer = 0.0  # Reset the dash timer
	sound_timer = 0.0  # Reset the sound timer
