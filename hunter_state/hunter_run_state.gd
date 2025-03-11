extends HunterBaseState

var state_name = "Run"
var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.2  # Adjust the interval based on the desired footstep frequency

func enter(hunter):
	footstep_timer = 0.0  # Reset the timer when entering the state
	hunter.animated_character.play("run")
	#hunter.character_animation.play("run")
	#hunter.can_double_jump = true

func update(hunter, delta):
	# Check if the player starts moving horizontally
	var direction := Input.get_axis("left", "right")
	
	# Handle footstep sound
	if hunter.is_on_floor() and direction != 0:
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = FOOTSTEP_INTERVAL
			if hunter.footstep_sound:  # Ensure you have a sound node, e.g., AudioStreamPlayer
				hunter.footstep_sound.play()
				
	if direction == 0:
		# Only transition to run_state if no collision is detected by run_raycast
		hunter.change_state(hunter.idle_state)

	if hunter.velocity.y > 0:
		hunter.change_state(hunter.fall_state)
		return
		# Handle jumping
	if Input.is_action_just_pressed("jump") and hunter.is_on_floor():
		hunter.change_state(hunter.jump_state)

	if Input.is_action_just_pressed("sliding") and hunter.is_on_floor():
		hunter.change_state(hunter.dash_state)

	if Input.is_action_just_pressed("attack") and hunter.is_on_floor() and direction != 0:
		hunter.change_state(hunter.run_attack_state)
		return

	if Input.is_action_just_pressed("special_attack") and hunter.is_on_floor():
		hunter.change_state(hunter.special_attack_state)
		return

	hunter.velocity.x = direction * hunter.SPEED
	hunter.toggle_flip_sprite(direction)

func exit(_hunter):
	footstep_timer = 0.0  # Reset the timer when exiting the state
