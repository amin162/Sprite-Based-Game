extends HunterBaseState

var state_name = "Attack"

var ArrowScene = preload("res://scene/projectile_arrow.tscn")

var combo_count: int = 1
var combo_window_timer = 0.0  
const COMBO_WINDOW = 0.8  
var attack_interval_timer = 0.0  
const ATTACK_INTERVAL = 0.5  
var grace_period_timer = 0.1  

func enter(hunter) -> void:
	hunter.velocity.x = 0 
	hunter.velocity.y = 0  # Stop movement while attacking
	start_attack(hunter)  
	
	if not hunter.animated_character.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(hunter)):
		hunter.animated_character.frame_changed.connect(Callable(self, "_on_frame_changed").bind(hunter))

func update(hunter, delta):
	attack_interval_timer -= delta
	combo_window_timer -= delta
	grace_period_timer -= delta

	if Input.is_action_just_pressed("attack") and attack_interval_timer <= 0:
		if combo_window_timer > 0:
			combo_count += 1
			if combo_count > 1:
				combo_count = 1
			start_attack(hunter)
		elif grace_period_timer <= 0:
			combo_count = 1
			start_attack(hunter)

	if combo_window_timer <= 0 and not hunter.animated_character.is_playing():
		if Input.get_axis("left", "right") != 0:
			hunter.change_state(hunter.run_state)
		else:
			hunter.change_state(hunter.idle_state)

func exit(hunter) -> void:
	combo_count = 1
	combo_window_timer = 0.0
	attack_interval_timer = 0.0
	grace_period_timer = 0.1  
	hunter.animated_character.speed_scale = 1.0  # Adjust speed manually (if using custom handling)

	if hunter.animated_character.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(hunter)):
		hunter.animated_character.frame_changed.disconnect(Callable(self, "_on_frame_changed").bind(hunter))

func start_attack(hunter) -> void:
	hunter.animated_character.play("attack")
	hunter.animated_character.speed_scale = 1.5 # Adjust speed manually (if using custom handling)
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
