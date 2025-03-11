extends HunterBaseState

var state_name = "ChargeShot"
var ArrowScene = preload("res://scene/projectile_arrow.tscn")

func enter(hunter):
	# Prevent exiting early to ensure attack animation plays
	if hunter.charge_level == "none":
		print("No charge detected, exiting charge state.")
		hunter.change_state(hunter.idle_state)
		return

	# Determine correct attack animation
	var attack_animation = "run_attack" if hunter.previous_state in [hunter.run_state, hunter.idle_state] else "jump_attack"

	# Play the attack animation
	hunter.animated_character.play(attack_animation)
	hunter.animated_character.speed_scale = 2  # Adjust manually if needed

	# Ensure animation is actually set
	#print("Playing animation:", attack_animation)  

	# Ensure frame change signal is connected ONCE
	if not hunter.animated_character.frame_changed.is_connected(_on_frame_changed):
		hunter.animated_character.frame_changed.connect(_on_frame_changed.bind(hunter))

	# Wait for animation to finish before changing states
	await hunter.animated_character.animation_finished

	# Reset charge level AFTER animation execution
	hunter.charge_level = "none"

	# Determine correct next state
	if hunter.is_on_floor():
		var direction = Input.get_axis("left", "right")
		if direction != 0:
			hunter.change_state(hunter.run_state)  # If moving, go to run state
		else:
			hunter.change_state(hunter.idle_state)  # Otherwise, go to idle
	else:
		if hunter.velocity.y < 0:
			hunter.change_state(hunter.jump_state)  # If rising
		else:
			hunter.change_state(hunter.fall_state)  # If falling

func update(hunter, _delta):
	# Only allow movement if player is in air (jump_attack animation)
	if hunter.animated_character.animation == "jump_attack" or hunter.animated_character.animation == "run_attack":
		var direction = Input.get_axis("left", "right")
		hunter.velocity.x = direction * hunter.SPEED
		hunter.toggle_flip_sprite(direction)
		if Input.is_action_just_pressed("jump") and hunter.can_double_jump:
			hunter.velocity.y = hunter.JUMP_VELOCITY  # Apply second jump velocity
			hunter.can_double_jump = false  # Disable further double jumps
				# Play the jump sound
			if hunter.jump_sound:
				hunter.jump_sound.play()

func exit(hunter):
	hunter.animated_character.speed_scale = 1.0
	# Disconnect frame signal properly
	if hunter.animated_character.frame_changed.is_connected(_on_frame_changed):
		hunter.animated_character.frame_changed.disconnect(_on_frame_changed)

func _on_frame_changed(hunter):
	# Spawn arrow and play sound at frame 7
	if hunter.animated_character.frame == 7:
		emit_charge_shot(hunter, hunter.charge_level)
	
			# Play bow release sound
		if hunter.charge_shot_release_sound:
			hunter.charge_shot_release_sound.play()

			# Create a timer to stop sound after 0.4 sec
			var stop_timer = Timer.new()
			stop_timer.wait_time = 0.4
			stop_timer.one_shot = true
			stop_timer.connect("timeout", Callable(self, "_stop_bow_sound").bind(hunter))
			hunter.add_child(stop_timer)
			stop_timer.start()

func _stop_bow_sound(hunter):
	if hunter.charge_shot_release_sound:
		hunter.charge_shot_release_sound.stop()

func emit_charge_shot(hunter, charge_level):
	# Debugging: Print charge level
	print("Emitting charge shot:", charge_level)

	# Determine projectile direction
	var direction = -1 if hunter.animated_character.flip_h else 1

	# Ensure ArrowScene is properly instantiated
	if not ArrowScene:
		print("Error: ArrowScene is not assigned!")
		return

	var arrow = ArrowScene.instantiate()
	arrow.global_position = hunter.global_position + Vector2(30 * direction, -10)
	arrow.charge_level = charge_level  # Set charge level BEFORE adding to scene
	arrow.direction = Vector2(direction, -0.05).normalized()  # Set direction manually
	arrow.rotation_degrees = -90 if direction == -1 else 90  # Adjust rotation

	# Add projectile to scene
	hunter.get_parent().add_child(arrow)
