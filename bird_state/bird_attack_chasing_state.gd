extends BirdBaseState

var state_name = "Attack_Chasing"
var wing_flap_timer = 0.0
var WING_FLAP_INTERVAL = 0.4  # Adjust the interval based on the desired footstep frequency

var squawking_timer = 0.0
var SQUAWKING_INTERVAL = 2  # Adjust the interval based on the desired footstep frequency

const CHASE_SPEED = 40.0
var damage = 5
var is_attack_enabled = true  # Flag to control attack area activity
const TOGGLE_INTERVAL = 0.5  # Interval in seconds for toggling
var STOP_DISTANCE = 10.0  # Adjust this to fine-tune how close the bird stops to the player

func enter(bird):
	var direction = (bird.player.global_position - bird.global_position).normalized()
	bird.bird_sprite.play("flying_chasing")
	bird.toggle_flip_sprite(direction.x)
	_start_toggle_loop(bird)  # Start toggling attack area
	wing_flap_timer = 0.0

func update(bird, delta):
	wing_flap_timer -= delta
	squawking_timer -= delta
	
	if bird.player:  # Ensure player is still detected
		# Update ray target position to point toward the player
		bird.detection_ray.target_position = bird.to_local(bird.player.global_position)
		bird.detection_ray.force_raycast_update()

		# Handle collisions with raycast
		if bird.detection_ray.is_colliding():
			var detected_object = bird.detection_ray.get_collider()

			# If the detected object is not the player, stop or change state
			if detected_object != bird.player:
				if bird.player_in_range:
					bird.velocity = Vector2.ZERO
					return
				else:
					bird.change_state(bird.idle_state)
					return

		# Check distance to the player
		var distance_to_player = bird.global_position.distance_to(bird.player.global_position)
		if distance_to_player <= STOP_DISTANCE:  # Replace STOP_DISTANCE with a value like 10.0
			bird.velocity = Vector2.ZERO  # Stop movement
			return  # Exit early, bird doesn't need to move further

		# If far from the player, move toward the player
		var direction = (bird.player.global_position - bird.global_position).normalized()
		bird.velocity = direction * CHASE_SPEED

		bird.toggle_flip_sprite(bird.velocity.x)
		bird.move_and_slide()

		# Wing flap sound logic
		if wing_flap_timer <= 0:
			wing_flap_timer = WING_FLAP_INTERVAL
			if bird.wing_flap_sound:
				bird.wing_flap_sound.play()
		
		# Wing flap sound logic
		if squawking_timer <= 0:
			squawking_timer = SQUAWKING_INTERVAL
			if bird.chase_squawking_sound:
				bird.chase_squawking_sound.play()
	else:
		# If the player is no longer detected, switch to idle state
		bird.change_state(bird.idle_state)

func exit(bird):
	bird.velocity = Vector2.ZERO
	bird.attack_area.call_deferred("set_disabled", true) # Ensure attack area is disabled
	is_attack_enabled = false  # Disable attack area on state exit
	wing_flap_timer = 0.0
	if bird.chase_squawking_sound.is_playing():
		bird.chase_squawking_sound.stop()

	
func _start_toggle_loop(bird) -> void:
	# Coroutine-like loop for toggling attack area
	var current_state = bird.state_machine
	while bird.state_machine == current_state:  # Ensure toggling runs only in this state
		await bird.get_tree().create_timer(TOGGLE_INTERVAL).timeout
		_toggle_attack_area(bird)

func _toggle_attack_area(bird) -> void:
	is_attack_enabled = !is_attack_enabled
	bird.attack_area.disabled = not is_attack_enabled  # Toggle attack area
	#print("Attack Area Disabled:", bird.attack_area.disabled)

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("apply_damage"):
		body.apply_damage(damage)
		# Play the attack sound
		var animation_node = get_node("../../AttackArea2D/HitImpactAnimation")
		if animation_node and animation_node is AnimatedSprite2D:
			animation_node.play("Normal_Hit")
		var sound_node = get_node("../../Bird_Sound/Attack")
		if sound_node and sound_node is AudioStreamPlayer2D:
			sound_node.play()
		#print("Attack player")
