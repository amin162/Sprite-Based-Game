extends HunterBaseState

var state_name = "Fall"

func enter(hunter):
	# Play the falling animation
	#hunter.character_animation.play("fall")
	hunter.animated_character.play("fall")

func update(hunter, _delta):
	# Handle horizontal movement during falling
	var direction = Input.get_axis("left", "right")
	hunter.velocity.x = direction * hunter.SPEED

	# Double Jump Mechanic
	if Input.is_action_just_pressed("jump") and hunter.can_double_jump:
		hunter.velocity.y = hunter.JUMP_VELOCITY  # Apply second jump velocity
		hunter.can_double_jump = false  # Disable further double jumps
		hunter.change_state(hunter.jump_state)

	# Check if the character is on the ground
	if hunter.is_on_floor():
		if hunter.touch_platform_sound:
			hunter.touch_platform_sound.play()
		hunter.change_state(hunter.idle_state)
		return
	# Flip the sprite based on direction
	hunter.toggle_flip_sprite(direction)
	
		# Check for attack input to trigger Jump Attack
	if Input.is_action_just_pressed("attack"):
		hunter.change_state(hunter.jump_attack_state)
		return
