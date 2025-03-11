extends HunterBaseState

var state_name = "Run_Attack"
var ArrowScene = preload("res://scene/projectile_arrow.tscn")

var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.2  # Adjust the interval based on the desired footstep frequency

var combo_count: int = 1
var combo_window_timer = 0.0  
const COMBO_WINDOW = 0.8  
var attack_interval_timer = 0.0  
const ATTACK_INTERVAL = 0.5  
var grace_period_timer = 0.1  

func enter(hunter):
	# Start run attack animation
	hunter.animated_character.play("run_attack")
	hunter.animated_character.speed_scale = 3.0  # Speed up attack
	
	footstep_timer = 0.0  # Reset the timer when entering the state
	start_attack(hunter)
	if not hunter.animated_character.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(hunter)):
		hunter.animated_character.frame_changed.connect(Callable(self, "_on_frame_changed").bind(hunter))

func update(hunter, delta):
	var direction := Input.get_axis("left", "right")
	hunter.velocity.x = direction * hunter.SPEED
	hunter.toggle_flip_sprite(direction)
	
	# If attack animation is playing, don't transition yet
	if hunter.animated_character.is_playing() and hunter.animated_character.animation == "run_attack":
		if Input.is_action_just_pressed("jump"):
			if hunter.is_on_floor():  # First jump only when grounded
				hunter.velocity.y = hunter.JUMP_VELOCITY
				if hunter.jump_sound:
					hunter.jump_sound.play()
			elif hunter.can_double_jump:  # Only allow double jump if available
				hunter.velocity.y = hunter.JUMP_VELOCITY
				hunter.can_double_jump = false  # Consume double jump
				if hunter.jump_sound:
					hunter.jump_sound.play()


	# Handle footstep sounds
	if hunter.is_on_floor() and direction != 0:
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = FOOTSTEP_INTERVAL
			if hunter.footstep_sound:
				hunter.footstep_sound.play()
		
	# Check for combo attack
	if Input.is_action_just_pressed("attack") and attack_interval_timer <= 0:
		if combo_window_timer > 0:
			combo_count = min(combo_count + 1, 2)
			start_attack(hunter)
		elif grace_period_timer <= 0:
			combo_count = 1
			start_attack(hunter)

	# Handle movement transitions only when attack animation is not active
	if not hunter.animated_character.is_playing():
		if hunter.velocity.y > 0:
			hunter.change_state(hunter.fall_state)  # Prioritize falling over everything else
		elif hunter.is_on_floor():  # Only allow idle or run if on the floor
			if direction == 0:
				hunter.change_state(hunter.idle_state)
			else:  # Implies direction != 0
				hunter.change_state(hunter.run_state)

	# Handle jumping and other transitions only if attack isn't happening
	if not hunter.animated_character.is_playing():
		if Input.is_action_just_pressed("jump") and hunter.is_on_floor():
			hunter.change_state(hunter.jump_state)
		elif Input.is_action_just_pressed("sliding") and hunter.is_on_floor():
			hunter.change_state(hunter.dash_state)
		elif Input.is_action_just_pressed("special_attack") and hunter.is_on_floor():
			hunter.change_state(hunter.special_attack_state)
			return

	hunter.velocity.x = direction * hunter.SPEED
	hunter.toggle_flip_sprite(direction)


func exit(hunter):
	footstep_timer = 0.0  # Reset the timer when exiting the state
	hunter.animated_character.speed_scale = 1.0  # Speed up attack
	
	if hunter.animated_character.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(hunter)):
		hunter.animated_character.frame_changed.disconnect(Callable(self, "_on_frame_changed").bind(hunter))

func start_attack(hunter):
	# Play the jump attack animation again
	hunter.animated_character.play("run_attack")
	hunter.animated_character.speed_scale = 1.5  

	# Reset attack timers
	attack_interval_timer = ATTACK_INTERVAL
	combo_window_timer = COMBO_WINDOW

func spawn_arrow(hunter):
	# Ensure ArrowScene is properly assigned
	if not ArrowScene:
		print("Error: ArrowScene is not assigned!")
		return

	# Instantiate arrow
	var arrow = ArrowScene.instantiate()

	# Determine direction based on sprite flip
	var direction = -1 if hunter.animated_character.flip_h else 1
	
	# Set arrow position near Hunter's hand
	arrow.global_position = hunter.global_position + Vector2(30 * direction, -10)
	
	# Assign charge level before adding it to the scene
	arrow.charge_level = hunter.charge_level  
	arrow.direction = Vector2(direction, -0.05).normalized()  # Set movement direction
	arrow.rotation_degrees = -90 if direction == -1 else 90  # Adjust rotation
	
	# Debugging info
	#print("Arrow spawned! Charge Level:", hunter.charge_level, " Direction:", direction, " Rotation:", arrow.rotation_degrees)

	# Add arrow to the scene
	hunter.get_parent().add_child(arrow)

func _on_frame_changed(hunter):
	# Spawn arrow and play sound at frame 7
	if hunter.animated_character.frame == 7:
		spawn_arrow(hunter)
		#print("Spawning arrow during jump attack!")

		# Play bow release sound
		if hunter.bow_release_sound:
			hunter.bow_release_sound.play()

			# Create a timer to stop sound after 0.4 sec
			var stop_timer = Timer.new()
			stop_timer.wait_time = 0.4
			stop_timer.one_shot = true
			stop_timer.connect("timeout", Callable(self, "_stop_bow_sound").bind(hunter))
			hunter.add_child(stop_timer)
			stop_timer.start()

func _stop_bow_sound(hunter):
	if hunter.bow_release_sound:
		hunter.bow_release_sound.stop()
