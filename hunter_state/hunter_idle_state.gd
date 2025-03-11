extends HunterBaseState

var state_name = "Idle"

func enter(hunter):
	# Reset horizontal velocity and stop movement
	hunter.velocity.x = 0
	hunter.animated_character.play("idle")
	hunter.character_animation.play("idle")
	hunter.can_double_jump = true

func update(hunter, _delta):
	var direction := Input.get_axis("left", "right")

	if direction != 0:
		# Only transition to run_state if no collision is detected by run_raycast
		hunter.change_state(hunter.run_state)
	
	# Handle jumping
	if Input.is_action_just_pressed("jump") and hunter.is_on_floor():
		hunter.change_state(hunter.jump_state)

	if Input.is_action_just_pressed("attack") and hunter.is_on_floor():
		hunter.change_state(hunter.attack_state)
		return
	
	if Input.is_action_just_pressed("special_attack") and hunter.is_on_floor():
		hunter.change_state(hunter.special_attack_state)
		return
		
		# Handle falling
	if hunter.velocity.y > 0:
		hunter.change_state(hunter.fall_state)

	hunter.toggle_flip_sprite(direction)
