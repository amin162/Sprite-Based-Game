extends HunterBaseState

var state_name = "SpecialAttack"

var ArrowScene = preload("res://scene/projectile_arrow.tscn")

var shots_fired: int = 0  # Track how many arrows have been shot
const MAX_SHOTS = 4  # The special attack fires 3 arrows

func enter(hunter) -> void:
	hunter.velocity.x = 0  # Stop movement while attacking
	hunter.velocity.y = 0  # Stop movement while attacking
	shots_fired = 0  # Reset shot count
	start_special_attack(hunter)
	
	if not hunter.animated_character.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(hunter)):
		hunter.animated_character.frame_changed.connect(Callable(self, "_on_frame_changed").bind(hunter))

func update(hunter, _delta):
	# If the animation has finished and we haven't fired 3 arrows, continue attack
	if not hunter.animated_character.is_playing() and shots_fired < MAX_SHOTS:
		start_special_attack(hunter)
	elif shots_fired >= MAX_SHOTS:
		hunter.change_state(hunter.idle_state)

func exit(hunter) -> void:
	shots_fired = 0  # Reset for next special attack
	hunter.animated_character.speed_scale = 1.0  # Adjust speed manually (if using custom handling)
	if hunter.animated_character.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(hunter)):
		hunter.animated_character.frame_changed.disconnect(Callable(self, "_on_frame_changed").bind(hunter))

func start_special_attack(hunter) -> void:
	hunter.animated_character.animation = "attack"  # Set the animation
	hunter.animated_character.frame = 0  # Start from the first frame
	hunter.animated_character.play()  # Play the animation
	hunter.animated_character.speed_scale = 2.5  # Adjust speed manually (if using custom handling)
	shots_fired += 1  # Increment shot count

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
	# Spawn arrow at frame 7
	if hunter.animated_character.frame == 7:
		spawn_arrow(hunter)
		#print("Spawning arrow rapid shot attack!")

		# Delay bow sound start (0.15 sec)
		var start_timer = Timer.new()
		start_timer.wait_time = 0.15
		start_timer.one_shot = true
		start_timer.connect("timeout", Callable(self, "_play_bow_sound").bind(hunter))
		hunter.add_child(start_timer)
		start_timer.start()

func _play_bow_sound(hunter):
	if hunter.bow_release_sound:
		hunter.bow_release_sound.play()
		
		# Stop the sound after 0.25 sec (0.4 - 0.15 = 0.25)
		var stop_timer = Timer.new()
		stop_timer.wait_time = 0.3
		stop_timer.one_shot = true
		stop_timer.connect("timeout", Callable(self, "_stop_bow_sound").bind(hunter))
		hunter.add_child(stop_timer)
		stop_timer.start()

func _stop_bow_sound(hunter):
	if hunter.bow_release_sound:
		hunter.bow_release_sound.stop()
