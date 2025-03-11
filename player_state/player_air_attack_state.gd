extends BaseState

var state_name = "Air_Attack"


func enter(character):
	# Play the air attack animation
	character.character_sprite.play("air_attack")
	if character.attack_sound:
		character.attack_sound.play()
		character.attack_sound.pitch_scale = 1
	
	if not character.character_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(character)):
		character.character_sprite.frame_changed.connect(Callable(self, "_on_frame_changed").bind(character))

func update(character, _delta):
	# Handle horizontal movement during the air attack
	var direction = Input.get_axis("left", "right")
	character.velocity.x = direction * character.SPEED
	
	# Flip the sprite according to the direction of movement
	character.toggle_flip_sprite(direction)
	
	# Check if the attack animation has finished
	if not character.character_sprite.is_playing():
		# If still rising, transition to the jump state
		if character.velocity.y < 0:
			character.change_state(character.jump_state)
		# If falling, transition to the fall state
		elif character.velocity.y > 0:
			character.change_state(character.fall_state)
	
	# Handle transition to the fall state when the character is falling and on the ground
	if character.is_on_floor():
		character.change_state(character.idle_state)

func exit(character) -> void:
	character.deactivate_attack_range()  # Disable attack range
		# Disconnect frame_changed signal
	if character.character_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(character)):
		character.character_sprite.frame_changed.disconnect(Callable(self, "_on_frame_changed").bind(character))
	if character.attack_sound.is_playing():
		character.attack_sound.stop()

func _on_frame_changed(character):
	var current_frame = character.character_sprite.frame
	character.attack_range_box1.call_deferred("set_disabled", !(current_frame in [2, 3]))
