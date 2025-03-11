extends BaseState

var state_name = "Wall_Slide"
var wall_slide_timer = 0.0
var WALL_SLIDE_INTERVAL = 0.2 # Adjust the interval based on the desired footstep frequency
# Define the wall slide speed and push force
const wall_slide_speed = 40.0
const push_wall_force = 10

func enter(character):
	# Play the wall slide animation
	character.character_sprite.play("wall slide")
	# Set vertical speed for controlled sliding down the wall
	character.velocity.y = wall_slide_speed
	
	wall_slide_timer = 0.0

	# Ensure the sound plays if entering the state
	if character.wall_slide_sound and not character.wall_slide_sound.is_playing():
		character.wall_slide_sound.play()

func update(character, delta):
	# Calculate an adjusted interval based on the character's velocity
	var adjusted_interval = WALL_SLIDE_INTERVAL * (character.velocity.y / wall_slide_speed)
	wall_slide_timer -= delta

	# Handle sound playback based on interval
	if character.is_on_wall() and !character.is_on_floor() and character.velocity.y > 0:
		if wall_slide_timer <= 0:
			wall_slide_timer = max(0.1, adjusted_interval)  # Ensure a minimum interval
			if character.wall_slide_sound and not character.wall_slide_sound.is_playing():
				character.wall_slide_sound.play()

	# Check for directional input
	var direction = Input.get_axis("left", "right")

	# Ensure the wall slide only applies while the direction button is pressed
	if direction == 0:
		# If no direction input, switch to fall state
		character.change_state(character.fall_state)
		return

	# Allow jumping off the wall
	if Input.is_action_just_pressed("jump"):
		# Trigger a normal jump and apply horizontal push force away from the wall
		character.velocity.y = character.JUMP_VELOCITY
		character.velocity.x = -push_wall_force * direction * character.SPEED
		character.change_state(character.jump_state)
		return

	# Handle horizontal movement while sliding
	character.velocity.x = direction * character.SPEED
	character.toggle_flip_sprite(direction)

	# Stop wall slide if the character is no longer next to a wall
	if not character.is_on_wall():
		character.change_state(character.fall_state)
	elif character.is_on_floor() and direction != 0:
		character.change_state(character.idle_state)
	#print("Direction :", direction)

func exit(_character):
	wall_slide_timer = 0.0
