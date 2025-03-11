extends BossBaseState

var state_name = "SprintChargeAttack"
var speed = 500.0
var direction = 1  # Moving direction, 1 for right, -1 for left
var area_position: Vector2
var area_extents: Vector2

var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.2 # Adjust the interval based on the desired footstep frequency

func enter(boss):
	boss.boss_sprite.play("Sprint_Charge")
	# Access SprintChargeAttackArea from the stage's hierarchy
	var sprint_charge_area = boss.get_parent().get_node_or_null("BossEngageArea/SprintChargeAttackArea")
	if sprint_charge_area:
		# Retrieve position and extents for the sprint area
		area_position = sprint_charge_area.global_position
		var collision_shape = sprint_charge_area.get_node_or_null("SprintChargeAttackCollision")
		if collision_shape and collision_shape is CollisionShape2D:
			area_extents = collision_shape.shape.extents

			# Determine direction and update sprite flip
			direction = 1 if boss.global_position.x < area_position.x else -1
			boss.toggle_flip_sprite(direction)  # Flip the sprite based on direction
		else:
			#print("Error: SprintChargeAttackCollision node is missing or not a CollisionShape2D!")
			boss.change_state("Idle")  # Fallback to IdleState if collision node is invalid

func update(boss, delta):
	# Move the boss towards the edge of the sprint area
	boss.velocity.x = direction * speed

	# Calculate the left and right edges of the sprint area
	var left_edge = area_position.x - (1.4 * area_extents.x)
	var right_edge = area_position.x + (1.4 * area_extents.x)

	# Check if the boss has reached the edge of the sprint area
	if (direction == 1 and boss.global_position.x >= right_edge) or (direction == -1 and boss.global_position.x <= left_edge):
		boss.velocity = Vector2.ZERO
		boss.change_state("Idle")
	
	if boss.is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = FOOTSTEP_INTERVAL
			if boss.sprint_sound:  # Ensure you have a sound node, e.g., AudioStreamPlayer
				boss.sprint_sound.play()

func exit(boss):
	# Stop the boss movement
	boss.velocity = Vector2.ZERO
	footstep_timer = 0.0
