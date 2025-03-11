extends EnemyBaseState

var state_name = "Wandering"
var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.4  # Adjust the interval based on the desired footstep frequency

# Define the wandering duration
var wander_time = 5.0
var timer = 0.0
var direction = 1
var wandering_speed_amplification = 0.5

func enter(enemy):
	# Play wandering animation
	enemy.enemy_sprite.play("wandering")
	# Reset timers
	timer = 0.0
	footstep_timer = 0.0
	# Reverse direction each time this state is entered
	direction = -direction

func update(enemy, delta):
	timer += delta
	footstep_timer -= delta  # Decrement the footstep timer
	
	# Handle footstep sound
	if enemy.is_on_floor():
		if footstep_timer <= 0:
			footstep_timer = FOOTSTEP_INTERVAL
			if enemy.footstep_sound:
					enemy.footstep_sound.play()

	# Move the enemy in the selected direction
	enemy.velocity.x = direction * enemy.SPEED * wandering_speed_amplification

	# Flip the direction of movement if there is a wall
	if enemy.is_on_wall():
		direction = -1 if direction > 0 else 1

	# Change back to idle after the wandering duration is over
	if timer >= wander_time and enemy.is_on_floor():
		enemy.change_state(enemy.idle_state)

	# Flip the sprite based on the direction of movement
	enemy.toggle_flip_sprite(direction)

func exit(enemy):
	enemy.velocity.x = 0
	enemy.velocity.y = enemy.GRAVITY
	footstep_timer = 0.0  # Reset the timer when exiting the state
