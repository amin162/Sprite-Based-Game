extends BODBaseState

var state_name = "TeleportOut"

func enter(bod):
	# Play teleport out animation
	bod.bod_sprite.play("teleport_out")
	bod.bod_sprite.animation_finished.connect(_on_teleport_out_finished.bind(bod), CONNECT_ONE_SHOT)
	
	if bod.teleport_sound:
		bod.teleport_sound.play()
	
		## **Check if Range Death Slice is off cooldown FIRST**
	if bod.hand_of_death_cooldown <= 0 and bod.is_cast_magic == true:
		#print("🔥 Boss preparing Range Death Slice! Teleporting to attack position.")
		bod.global_position = get_hand_of_death_casting_position(bod)
		return  # Do not process chasing teleport

	## **Check if Range Death Slice is off cooldown FIRST**
	if bod.range_death_slice_cooldown <= 0 and bod.is_range_attack == true:
		#print("🔥 Boss preparing Range Death Slice! Teleporting to attack position.")
		bod.global_position = get_range_attack_position(bod)
		return  # Do not process chasing teleport

	# **Chasing Teleport - Adjusted Position**
	var chase_position = get_safe_teleport_position(bod)
	var capsule_height = bod.physics_body.shape.height
	chase_position.y -= capsule_height / 2  # Align boss properly

	# Apply slight offset to avoid direct overlap with player
	var teleport_offset = Vector2(sign(bod.global_position.x - bod.player.global_position.x), 0)
	bod.global_position = chase_position + teleport_offset
	
	print(get_safe_teleport_position(bod))

func exit(bod):
	if bod.teleport_sound:
		bod.teleport_sound.stop()

func _on_teleport_out_finished(bod):
	if bod.hand_of_death_cooldown <= 0 and  bod.is_cast_magic == true:
		bod.change_state(bod.hand_of_death_state)
	elif bod.range_death_slice_cooldown <= 0 and  bod.is_range_attack == true:
		bod.change_state(bod.range_death_slice_state)
	else:
		bod.change_state(bod.chasing_state)

# Function to get the teleport position for range attack
func get_range_attack_position(bod) -> Vector2:
	var range_position_node = bod.get_parent().get_node("BossTeleportAccess/RangeDeathSliceTeleportPosition/RangeDeathSlicePosition")
	return range_position_node.global_position if range_position_node else bod.global_position
	
# Function to get the teleport position for range attack
func get_hand_of_death_casting_position(bod) -> Vector2:
	var casting_hand_of_death_position_node = bod.get_parent().get_node("BossTeleportAccess/HandOfDeathTeleportPosition/HandOfDeathPosition")
	return casting_hand_of_death_position_node.global_position if casting_hand_of_death_position_node else bod.global_position


func get_safe_teleport_position(bod) -> Vector2:
	if not bod.player:
		return bod.player.global_position  # Default to player's position if no player found

	# Get player's RayCast2D nodes
	var left_ray = bod.player.get_node("LeftRayCast2D")
	var right_ray = bod.player.get_node("RightRayCast2D")

	# Get detected platform positions
	var left_x = left_ray.get_collision_point().x if left_ray.is_colliding() else bod.player.global_position.x
	var right_x = right_ray.get_collision_point().x if right_ray.is_colliding() else bod.player.global_position.x

	# Choose the teleport position based on raycast detection
	if left_ray.is_colliding() and right_ray.is_colliding():
		# If both raycasts detect platforms, teleport somewhere in between
		var teleport_x = [left_x, right_x].pick_random()
		return Vector2(teleport_x, left_ray.get_collision_point().y)
	elif left_ray.is_colliding():
		# If only the left ray detects a platform, teleport there
		print("Left")
		return Vector2(left_x, left_ray.get_collision_point().y)
	elif right_ray.is_colliding():
		# If only the right ray detects a platform, teleport there
		print("Right")
		return Vector2(right_x, right_ray.get_collision_point().y)
	

	# Default to player's position if no safe platform is detected
	return bod.player.global_position



## Function to find a safe teleport position on the player's platform
#func get_safe_teleport_position(bod) -> Vector2:
	#var space = bod.get_world_2d().direct_space_state
	#var player_x = bod.player.global_position.x
	#var search_range = 200  # Search range for platforms
	#var vertical_ray_length = 300  # How far downward to detect platforms
	#var platform_positions = []
#
	## Search multiple positions around the player to find a valid platform
	#for offset in [-search_range, 0, search_range]:
		#var ray_origin = Vector2(player_x + offset, bod.player.global_position.y)
		#var ray_end = ray_origin + Vector2(0, vertical_ray_length)
#
		#var query = PhysicsRayQueryParameters2D.create(ray_origin, ray_end, bod.collision_layer)
		#var result = space.intersect_ray(query)
#
		#if result and "position" in result:
			#platform_positions.append(result.position)
#
	## No valid platforms found, return default position (avoid teleporting to empty space)
	#if platform_positions.is_empty():
		#return bod.player.global_position
#
	## Choose the nearest valid platform
	#platform_positions.sort_custom(func(a, b): return abs(a.x - player_x) < abs(b.x - player_x))
	#var platform_position = platform_positions.front()
#
	## Detect platform edges **once**
	#var platform_left = detect_platform_edge(bod, platform_position, -1)
	#var platform_right = detect_platform_edge(bod, platform_position, 1)
#
	## Clamp the boss position within the platform bounds
	#var clamped_x = clamp(player_x, platform_left + 50, platform_right - 50)
	#return Vector2(clamped_x, platform_position.y)
#
## Function to detect platform edges
func detect_platform_edge(bod, start_position: Vector2, direction: int) -> float:
	var space = bod.get_world_2d().direct_space_state
	var max_distance = 100  # Maximum width for edge detection

	# Cast a ray in the given direction
	var ray_end = start_position + Vector2(direction * max_distance, 0)
	var query = PhysicsRayQueryParameters2D.create(start_position, ray_end, bod.collision_layer)
	var result = space.intersect_ray(query)

	# Get Player's RayCast2D results for more accurate platform detection
	if bod.player:
		var left_ray = bod.player.get_node("LeftRayCast2D")
		var right_ray = bod.player.get_node("RightRayCast2D")

		var left_x = left_ray.get_collision_point().x if left_ray.is_colliding() else start_position.x - max_distance
		var right_x = right_ray.get_collision_point().x if right_ray.is_colliding() else start_position.x + max_distance

		# Adjust platform detection using both methods
		if result and "position" in result:
			return clamp(result.position.x, left_x, right_x)  # Ensure it's within the player's detected safe area
		else:
			return clamp(start_position.x + (direction * max_distance), left_x, right_x)  # Fallback to safe area

	return start_position.x + (direction * max_distance)  # Default fallback
