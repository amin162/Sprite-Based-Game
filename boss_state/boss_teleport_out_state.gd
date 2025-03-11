extends BossBaseState

#@onready var attack_area : CollisionPolygon2D = $Area2D/AttackAreaCollision
var state_name = "TeleportOut"

func enter(boss):
	# Play the teleport out animation
	boss.boss_sprite.play("Teleport_Out")
	
	if boss.teleport_sound:
		boss.teleport_sound.play()

	# Ensure the player reference exists
	if boss.stage.player:
		var player_position = boss.stage.player.global_position

		if boss.stage.melee_count1 == 5:
			# Teleport to the specific node for lightning barrage
			var teleport_node = boss.get_parent().get_node("BossEngageArea/MagicCastArea2/TeleportSpotLeft2")
			if teleport_node:
				boss.global_position = teleport_node.global_position
				print("Boss teleported to TeleportSpotLeft2 for Barrage of Lightning.")
			else:
				print("Error: TeleportSpotLeft2 not found. Defaulting to current position.")

		elif boss.stage.melee_count2 == 5:
			# Teleport to the specific node for explosion barrage
			var teleport_node = boss.get_parent().get_node("BossEngageArea/MagicCastArea2/TeleportSpotRight2")
			if teleport_node:
				boss.global_position = teleport_node.global_position
				print("Boss teleported to TeleportSpotRight2 for Barrage of Explosion.")
			else:
				print("Error: TeleportSpotRight2 not found. Defaulting to current position.")
#
		elif boss.stage.melee_count3 == 5:
			# Access Blink Collision and Teleport Spot for melee_count3
			var teleport_left_node = boss.get_parent().get_node("BossEngageArea/SprintChargeAttackArea/TeleportSpotLeft3")
			var teleport_right_node = boss.get_parent().get_node("BossEngageArea/SprintChargeAttackArea/TeleportSpotRight3")
			var blink_collision = boss.get_parent().get_node("BossEngageArea/BlinkStrikeArea/BlinkStrikeCollision3")
			var blink_collision_position = blink_collision.global_position
#
			## Player is to the left of the collision center
			if player_position.x < blink_collision_position.x:
				teleport_left_node.disabled = false
				_teleport_to_sprint_area(boss, -1)
				print("Boss teleported to TeleportSpotLeft3 for Sprint Charge Attack Trail of Fire.")

			## Player is to the right of the collision center
			elif player_position.x > blink_collision_position.x:
				teleport_right_node.disabled = false
				_teleport_to_sprint_area(boss, 1)
				print("Boss teleported to TeleportSpotRight3 for Sprint Charge Attack Trail of Fire.")
			else:
				print("Error: TeleportSpotLeft3 not found. Defaulting to current position.")
		else:
			# Default ray-based teleportation logic
			if boss.teleport_ray:
				match boss.teleport_ray.name:
					"LeftRay":
						_teleport_to_sprint_area(boss, -1)
					"RightRay":
						_teleport_to_sprint_area(boss, 1)
					"LeftRayCastBlink":
						_teleport_to_blink_area(boss, "BlinkStrikeCollision1")
					"RightRayCastBlink":
						_teleport_to_blink_area(boss, "BlinkStrikeCollision2")
					"BottomRayCastBlink":
						_teleport_to_blink_area(boss, "BlinkStrikeCollision3")
					"LightningCastRayLeft1", "LightningCastRayLeft2":
						_teleport_to_lightning_cast_area(boss)
					"FireBallCastRayRight1", "FireBallCastRayRight2":
						_teleport_to_fireball_cast_area(boss)
			else:
				print("Error: No triggering ray set for teleportation. Defaulting to current position.")
				boss.global_position = boss.global_position  # Failsafe: Boss doesn't move
		
	# Make the boss face the player
	_face_player(boss)

func update(boss, _delta):
	# Wait until the animation finishes before transitioning
	if not boss.boss_sprite.is_playing():
		if boss.stage:
			if boss.stage.melee_count1 == 5:
				# Transition to MagicAbility after teleporting
				boss.stage.reset_melee_count1() # Reset the count after teleporting
				boss.change_state("MagicAbility")
			elif boss.stage.melee_count2 == 5:
				# Transition to MagicAbility after teleporting
				boss.stage.reset_melee_count2() # Reset the count after teleporting
				boss.change_state("MagicAbility")
			elif boss.stage.melee_count3 == 5:
				# Transition to MagicAbility after teleporting
				boss.stage.reset_melee_count3() # Reset the count after teleporting
				boss.change_state("SprintChargeAttack")
			else:
				# Handle ray-based transitions
				if boss.teleport_ray:
					match boss.teleport_ray.name:
						"LeftRay", "RightRay":
							boss.change_state("SprintChargeAttack")
						"LeftRayCastBlink", "RightRayCastBlink", "BottomRayCastBlink":
							boss.change_state("MeleeAttack")
						"LightningCastRayLeft1", "LightningCastRayLeft2", "FireBallCastRayRight1", "FireBallCastRayRight2":
							boss.change_state("MagicAbility")
				else:
					print("No valid ray for transition. Staying in TeleportOut state.")


func exit(boss):
	if boss.teleport_sound:
		boss.teleport_sound.stop()

# Helper: Teleport to Sprint Charge area
func _teleport_to_sprint_area(boss, direction: int):
	var sprint_area = boss.get_parent().get_node("BossEngageArea/SprintChargeAttackArea/SprintChargeAttackCollision")
	if sprint_area:
		boss.global_position = sprint_area.global_position + Vector2(1.4 * sprint_area.shape.extents.x * direction, 0)
	else:
		print("Error: Sprint area not found.")

func _teleport_to_lightning_cast_area(boss):
	var lightning_cast_area = boss.get_parent().get_node("BossEngageArea/MagicCastArea/TeleportSpotLeft1")
	if lightning_cast_area:
		boss.global_position = lightning_cast_area.global_position

func _teleport_to_fireball_cast_area(boss):
	var fireball_cast_area = boss.get_parent().get_node("BossEngageArea/MagicCastArea/TeleportSpotRight1")
	if fireball_cast_area:
		boss.global_position = fireball_cast_area.global_position

# Helper: Teleport inside the Blink Strike collision area, relative to the player
func _teleport_to_blink_area(boss, collision_name: String):
	var blink_collision = boss.get_parent().get_node("BossEngageArea/BlinkStrikeArea/" + collision_name)
	if blink_collision and boss.teleport_ray:
		var player = boss.teleport_ray.get_collider()
		if player and player.name == "Player":
			var player_position = player.global_position
			var blink_collision_position = blink_collision.global_position
			var blink_collision_extents = blink_collision.shape.extents

			# Determine a slight gap offset between the boss and player
			var gap_offset = 25.0  # Adjust this value as needed for a comfortable gap

			# Calculate teleport position relative to the player
			var boss_position = blink_collision_position

			if player_position.x < blink_collision_position.x:  
				# Player is to the left of the collision center
				boss_position.x = max(
					blink_collision_position.x - 1.4 * blink_collision_extents.x + gap_offset,
					player_position.x - gap_offset
				)
			elif player_position.x > blink_collision_position.x:  
				# Player is to the right of the collision center
				boss_position.x = min(
					blink_collision_position.x +  1.4 * blink_collision_extents.x - gap_offset,
					player_position.x + gap_offset
				)

			# Assign the calculated position to the boss
			boss.global_position = boss_position

		else:
			print("Error: Player not found for teleportation.")
	else:
		print("Error: Blink Strike collision node '%s' not found or no valid ray set." % collision_name)

func _face_player(boss):
	if boss.teleport_ray:
		var player = boss.teleport_ray.get_collider()
		if player and player.name == "Player":
			# Determine direction based on player's position relative to the boss
			var player_position = player.global_position
			if player_position.x < boss.global_position.x:
				boss.boss_sprite.flip_h = true # Face left
				boss.attack_area.position.x = -abs(boss.attack_area.position.x)  # Position to the left
				boss.attack_area.scale.x = 1
			else:
				boss.boss_sprite.flip_h = false  # Face right
				boss.attack_area.scale.x = -1
				boss.attack_area.position.x = abs(boss.attack_area.position.x)  # Position to the left
		else:
			print("Error: Player not found for facing direction.")
	else:
		print("Error: No teleport ray set for facing direction.")
