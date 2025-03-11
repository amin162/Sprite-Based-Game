extends BaseState

var state_name = "Idle"

func enter(character):
	# Reset horizontal velocity and stop movement
	character.velocity.x = 0
	character.character_sprite.play("idle")

func update(character, _delta):
	# Check if the player starts moving horizontally
	var direction := Input.get_axis("left", "right")
	if direction != 0 and not character.run_raycast.is_colliding():
		# Only transition to run_state if no collision is detected by run_raycast
		character.change_state(character.run_state)

	# Handle jumping
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		character.change_state(character.jump_state)

	# Handle attack
	if Input.is_action_just_pressed("attack") and character.is_on_floor():
		character.change_state(character.attack_state)

	# Handle falling
	if character.velocity.y > 0:
		character.change_state(character.fall_state)

	# Flip sprite based on the direction of movement
	character.toggle_flip_sprite(direction)
