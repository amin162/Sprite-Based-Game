extends BirdBaseState

var state_name = "Wandering"
var wing_flap_timer = 0.0
var WING_FLAP_INTERVAL = 0.4  # Adjust the interval based on the desired footstep frequency

# Define the wandering duration and speed
var wander_time = 5.0
var timer = 0.0
var direction = 1
var wandering_speed_amplification = 0.5 

func enter(bird):
	# Start wandering animation and reset the timer
	bird.bird_sprite.play("flying_wandering")
	timer = 0.0
	wing_flap_timer = 0.0
	# Alternate direction every time the state is entered
	direction = -direction

func update(bird, delta):
	timer += delta
	wing_flap_timer -= delta

	if wing_flap_timer <= 0:
		wing_flap_timer = WING_FLAP_INTERVAL
		if bird.wing_flap_sound:
			bird.wing_flap_sound.play()
	
	if bird.idle_squawking_sound and not bird.idle_squawking_sound.is_playing():
		bird.idle_squawking_sound.play()

	# Check if the player is in range and not obstructed by a wall
	if bird.detection_ray.is_colliding() and bird.detection_ray.get_collider() == bird.player:
		bird.change_state(bird.attack_chasing_state)
		return  # Exit early to prevent wandering behavior if chasing player

	# Apply movement in the current direction
	bird.velocity.x = direction * bird.SPEED * wandering_speed_amplification

	# Reverse direction if the bird encounters a wall
	direction = -1 if bird.is_on_wall() else direction
	
	# Switch back to idle state after the wandering duration
	if timer >= wander_time:
		bird.change_state(bird.idle_state)

	# Update sprite flip based on movement direction
	bird.toggle_flip_sprite(direction)

func exit(bird):
	# Stop horizontal movement when exiting the wandering state
	bird.velocity.x = 0
	wing_flap_timer = 0.0
	if not bird.idle_squawking_sound.is_playing():
		bird.idle_squawking_sound.stop()
