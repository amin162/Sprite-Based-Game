extends BODBaseState

var state_name = "Chasing"
const CHASE_SPEED = 40.0
const X_PROXIMITY_THRESHOLD = 30.0
var footstep_timer = 0.0
var FOOTSTEP_INTERVAL = 0.8

func enter(bod):
	# Start chasing animation and reset footstep timer
	bod.bod_sprite.play("chasing")
	footstep_timer = 0.0

func update(bod, delta):
	footstep_timer -= delta  # Decrement footstep timer

	var direction = (bod.player.global_position - bod.global_position).normalized()
	var distance_to_player = bod.player.global_position.distance_to(bod.global_position)
	
		# Handle footstep sound
	if bod.is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = FOOTSTEP_INTERVAL
			if bod.footstep_sound:  # Ensure you have a sound node, e.g., AudioStreamPlayer
				bod.footstep_sound.play()

	if bod.player:
		# 🛠 Get the Y position of the boss's platform
		var boss_platform_y = get_platform_y(bod, bod.global_position)

		# 🛠 Get the Y position of the player's platform
		var player_platform_y = get_platform_y(bod, bod.player.global_position)

		# Check if the player is on a different platform
		var platform_difference = abs(boss_platform_y - player_platform_y)
		
				# **Range Attack Check - PRIORITY OVER PLATFORM TELEPORT**
		if bod.hand_of_death_cooldown <= 0 and bod.is_cast_magic == true:
			#print("🔥 Boss preparing Range Death Slice! Teleporting in first.")
			bod.change_state(bod.teleport_in_state)  
			return  # Stop execution
			
		# **Range Attack Check - PRIORITY OVER PLATFORM TELEPORT**
		elif bod.range_death_slice_cooldown <= 0 and bod.is_range_attack == true:
			#print("🔥 Boss preparing Range Death Slice! Teleporting in first.")
			bod.change_state(bod.teleport_in_state)  
			return  # Stop execution

		# **Platform Teleport Only If NOT Doing Range Attack**
		elif platform_difference > bod.platform_threshold and bod.player.is_on_floor():
			#print("⚠️ Boss detected platform change! Transitioning to Teleport In.")
			bod.change_state(bod.teleport_in_state)
			return  # Stop further execution

		# **Chasing logic remains unchanged**
		var x_distance_to_player = abs(bod.global_position.x - bod.player.global_position.x)

		if x_distance_to_player <= X_PROXIMITY_THRESHOLD:
			bod.velocity = Vector2.ZERO
			if bod.bod_sprite.animation != "idle":
				bod.bod_sprite.play("idle")
		else:
			bod.velocity.x = direction.x * CHASE_SPEED
			bod.velocity.y += bod.GRAVITY * delta  # Apply gravity

			if bod.velocity.x != 0 and bod.bod_sprite.animation != "chasing":
				bod.bod_sprite.play("chasing")

			bod.move_and_slide()
			bod.toggle_flip_sprite(direction.x)

		# Check for melee attack range
		if distance_to_player <= bod.melee_range:
			bod.velocity = Vector2.ZERO  # Stop movement before attacking
			bod.change_state(bod.melee_death_slice_state)

func exit(bod):
	# Reset velocity and timer when exiting the state
	bod.velocity = Vector2.ZERO
	footstep_timer = 0.0

# 📌 **Local function for platform detection**
func is_player_on_different_platform(bod) -> bool:
	var boss_platform_y = get_platform_y(bod, bod.global_position)
	var player_platform_y = get_platform_y(bod, bod.player.global_position)

	var platform_difference = abs(boss_platform_y - player_platform_y)
	return platform_difference > bod.platform_threshold

# 📌 **Local function for getting platform Y position**
func get_platform_y(bod: CharacterBody2D, position: Vector2) -> float:
	# Temporarily reposition the raycast to check the platform
	var previous_target_position = bod.detect_raycast.target_position  # Save previous position
	bod.detect_raycast.target_position = position - bod.global_position  # Adjust target relative to the boss
	bod.detect_raycast.force_raycast_update()

	# Check if the raycast collides with a platform
	if bod.detect_raycast.is_colliding():
		var collision_point = bod.detect_raycast.get_collision_point().y
		bod.detect_raycast.target_position = previous_target_position  # Restore raycast position
		return collision_point

	# Restore raycast position before returning default value
	bod.detect_raycast.target_position = previous_target_position
	return position.y  # Default to the provided Y position
