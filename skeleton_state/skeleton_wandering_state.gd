extends SkeletonBaseState

var state_name = "Wandering"
var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.4  # Adjust the interval based on the desired footstep frequency

# Define the wandering duration
var wander_time = 5.0
var timer = 0.0
var direction = 1
var wandering_speed_amplification = 0.5

func enter(skeleton):
	# Play wandering animation
	skeleton.skeleton_sprite.play("wandering")
	# Reset timers
	timer = 0.0
	footstep_timer = 0.0
	# Reverse direction each time this state is entered
	direction = -direction

func update(skeleton, delta):
	timer += delta
	footstep_timer -= delta  # Decrement the footstep timer
	
	## Handle footstep sound
	#if skeleton.is_on_floor():
		#if footstep_timer <= 0:
			#footstep_timer = FOOTSTEP_INTERVAL
			#if skeleton.footstep_sound:
					#skeleton.footstep_sound.play()

	# Move the skeleton in the selected direction
	skeleton.velocity.x = direction * skeleton.SPEED * wandering_speed_amplification

	# Flip the direction of movement if there is a wall
	if skeleton.is_on_wall():
		direction = -1 if direction > 0 else 1

	# Change back to idle after the wandering duration is over
	if timer >= wander_time and skeleton.is_on_floor():
		skeleton.change_state(skeleton.idle_state)

	# Flip the sprite based on the direction of movement
	skeleton.toggle_flip_sprite(direction)

func exit(skeleton):
	skeleton.velocity.x = 0
	skeleton.velocity.y = skeleton.GRAVITY
	footstep_timer = 0.0  # Reset the timer when exiting the state
