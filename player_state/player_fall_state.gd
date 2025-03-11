extends BaseState

var state_name = "Fall"

func enter(character):
	# Play the falling animation
	character.character_sprite.play("fall")

func update(character, _delta):
	# Handle horizontal movement during falling
	var direction = Input.get_axis("left", "right")
	character.velocity.x = direction * character.SPEED
	
	# Flip the sprite based on direction
	character.toggle_flip_sprite(direction)
	
	# Check if the character is on the ground
	if character.is_on_floor():
		if character.wall_slide_sound:
			character.wall_slide_sound.play()
		character.change_state(character.idle_state)
		return
	
	# Check if the player attacks during the fall
	if Input.is_action_just_pressed("attack"):
		character.change_state(character.air_attack_state)
		return
