# Character.gd
extends CharacterBody2D

# Animation node
@onready var character_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_impact_sprite: AnimatedSprite2D = $PlayerAttackArea2D/Hit_Impact_Animation

# Debugging node
@onready var state_label = $StateLabel  # Reference to the Label node

# Timer node for invisibility frame
@onready var invincibility_timer : Timer = $InvincibilityTimer

#UI related node
@onready var health_bar_canvas: ProgressBar = $CanvasLayer/Healthbar

# Raycast node to prevent certain action
@onready var slide_raycast : RayCast2D = $SlideRayCast 
# (Prevent a slide state when the raycast intersect with any platform such as slope and wall)
@onready var run_raycast : RayCast2D = $RunRayCast 
# (Prevent a run state to be executed while the raycast intersect with wall and execute the idle state instead)

# Attackbox collision node related
@onready var attack_range : Area2D = $PlayerAttackArea2D
@onready var attack_range_box1: CollisionShape2D = $PlayerAttackArea2D/Attack_Range_Box1
@onready var attack_range_box2: CollisionShape2D = $PlayerAttackArea2D/Attack_Range_Box2
@onready var attack_range_box3: CollisionShape2D = $PlayerAttackArea2D/Attack_Range_Box3
@onready var hurtbox: Area2D = $HurtboxArea

# Load sound node
@onready var footstep_sound = $Player_Sound_Effect/Footstep
@onready var slide_sound = $Player_Sound_Effect/Slide
@onready var jump_sound = $Player_Sound_Effect/Jump
@onready var attack_sound = $Player_Sound_Effect/Attack
@onready var wall_slide_sound = $Player_Sound_Effect/Wallslide
@onready var get_hit_sound = $Player_Sound_Effect/GetHit
@onready var slash_hit_sound = $Player_Sound_Effect/SlashHit

# Load State
@onready var idle_state = preload("res://player_state/player_idle_state.gd").new()
@onready var run_state = preload("res://player_state/player_run_state.gd").new()
@onready var jump_state = preload("res://player_state/player_jump_state.gd").new()
@onready var fall_state = preload("res://player_state/player_fall_state.gd").new()
@onready var attack_state = preload("res://player_state/player_attack_state.gd").new()
@onready var air_attack_state = preload("res://player_state/player_air_attack_state.gd").new()
@onready var sliding_state = preload("res://player_state/player_sliding_state.gd").new()
@onready var wall_slide_state = preload("res://player_state/player_wall_slide_state.gd").new()
@onready var get_hit_state = preload("res://player_state/player_get_hit_state.gd").new()
@onready var jump_down_state = preload("res://player_state/player_jump_down_state.gd").new()

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 1000.0  # Gravity constant
var health = 100  # Adjust as needed
var max_health = 100
var is_invincible := false
var floor_check_distance: float = 20.0  # Distance to check below the player for wall sliding

# Load Scene
@onready var DamageLabel = preload("res://scene/damage_label.tscn")

var layer_2_activated = false  # Track if layer 2 has been activated once

# Initialize state machine
var state_machine: BaseState

func _ready():
	state_machine = idle_state  # Start in idle state
	state_machine.enter(self)
	attack_range_box1.call_deferred("set_disabled", true)
	attack_range_box2.call_deferred("set_disabled", true)
	attack_range_box3.call_deferred("set_disabled", true)
	deactivate_then_activate_once(self)

	invincibility_timer.wait_time = 1.0  # Set the duration of invincibility
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_end_invincibility)  # Connect once
	
	health_bar_canvas.init_health(health)

func _process(_delta) -> void:
	if state_label:
		state_label.text = "State: " + get_state_name()

func _physics_process(delta: float):
	var direction = Input.get_axis("left", "right")
	# Apply gravity each frame if not on the ground
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Update state machine
	state_machine.update(self, delta)
	
	# Wall sliding condition
	if should_wall_slide():
		change_state(wall_slide_state)
	
	if slide_raycast.is_colliding():
		direction = 0
		# Transition to idle state only when on the ground and not moving horizontally
		if is_on_floor() and is_on_wall() and direction == 0 and velocity.x == 0:
			if state_machine == run_state:  # Avoid changing state unnecessarily
				change_state(idle_state)

	# Handle down state transition
	if Input.is_action_just_pressed("down") and is_on_floor():
		change_state(jump_down_state)
	
	#print("Direction :", direction," Velocity.x : ", velocity.x)
	# Move the character
	move_and_slide()

func get_state_name() -> String:
	return state_machine.state_name if state_machine else "None"

func should_wall_slide() -> bool:
	# Early exit if not on a wall or on the floor
	if not is_on_wall() or is_on_floor():
		return false

	# Early exit if not moving downward
	if velocity.y <= 0:
		return false

	# Get the last wall collision
	var wall_collision = get_last_slide_collision()  # Renamed to avoid shadowing
	if not wall_collision:
		return false

	# Check the collision layer of the wall
	var collider = wall_collision.get_collider()
	if collider is CollisionObject2D:
		# Allow wall sliding only on Layer 1 (TileMap)
		if not collider.collision_layer & (1 << 0):  # Layer 1
			return false  # Disallow wall sliding on other layers (e.g., Layer 10)

	# Check for proximity to the floor
	var floor_check_position = position + Vector2(0, floor_check_distance)
	var space_state = get_world_2d().direct_space_state
	var point_query = PhysicsPointQueryParameters2D.new()
	point_query.collide_with_areas = true
	point_query.exclude = [self]
	point_query.position = floor_check_position

	# Perform the point query and filter out Area2D results
	var floor_collisions = space_state.intersect_point(point_query)  # Renamed to avoid shadowing
	floor_collisions = floor_collisions.filter(func(collision): return not (collision.collider is Area2D))

	# If there are no real collisions, check if moving toward the wall
	if floor_collisions.is_empty():
		var wall_direction = -1 if slide_raycast.scale.x < 0 else 1
		var is_moving_toward_wall = Input.get_axis("left", "right") == wall_direction
		return is_moving_toward_wall

	return false

func change_state(new_state):
	if state_machine:
		state_machine.exit(self)
	state_machine = new_state
	state_machine.enter(self)

func play_footstep_sound():
	if footstep_sound:  # Ensure you have a sound node, e.g., AudioStreamPlayer
		footstep_sound.play()

func toggle_flip_sprite(direction):
	if direction < 0:
		attack_range_box1.position.x = -abs(attack_range_box1.position.x)
		attack_range_box2.position.x = -abs(attack_range_box2.position.x)
		attack_range_box3.position.x = -abs(attack_range_box3.position.x)
		hit_impact_sprite.position.x = -abs(attack_range_box1.position.x - 10)
		hit_impact_sprite.flip_h = true
		character_sprite.flip_h = true
		slide_raycast.scale.x = -1 # Reposition RayCast2D for left direction
		run_raycast.scale.x = -1

	elif direction > 0:
		attack_range_box1.position.x = abs(attack_range_box1.position.x)
		attack_range_box2.position.x = abs(attack_range_box2.position.x)
		attack_range_box3.position.x = abs(attack_range_box3.position.x)
		hit_impact_sprite.position.x = abs(attack_range_box1.position.x + 10)
		hit_impact_sprite.flip_h = false 
		character_sprite.flip_h = false
		slide_raycast.scale.x = 1 # Reposition RayCast2D for left direction
		run_raycast.scale.x = 1

func activate_attack_range():
	attack_range_box1.call_deferred("set_disabled", false)
	attack_range_box2.call_deferred("set_disabled", false)
	attack_range_box3.call_deferred("set_disabled", false)

func deactivate_attack_range():
	attack_range_box1.call_deferred("set_disabled", true)
	attack_range_box2.call_deferred("set_disabled", true)
	attack_range_box3.call_deferred("set_disabled", true)

func deactivate_then_activate_once(player: Node2D):
	deactivate_player_layer(player, 1)
	await get_tree().create_timer(0.1).timeout
	activate_player_layer(player, 1)
	layer_2_activated = true

func deactivate_player_layer(player: Node2D, layer: int):
	player.collision_layer &= ~(1 << layer)

func activate_player_layer(player: Node2D, layer: int):
	player.collision_layer |= (1 << layer)

func show_damage(amount: int, _position: Vector2):
	var damage_label = DamageLabel.instantiate()
	damage_label.set_damage(amount)
	
	# Adjust the position to appear above the enemy
	var offset = Vector2(0, -20)  # Move label 20 pixels upward (adjust as needed)
	damage_label.position = _position + offset
	
	get_parent().add_child(damage_label)  # Add to the scene tree

# Apply damage function
func apply_damage(amount: int):
	if is_invincible:
		return  # Ignore damage during invincibility

	health -= amount  # Update player health first
	health = max(health, 0)  # Prevent negative values
	
	#print("Player health:", health)  # Debugging line
	# Sync the health bar by calling its setter
	health_bar_canvas._set_health(health)
	show_damage(amount, global_position)

	start_invincibility()
	
	#if health <= 0:
		#change_state(death_state)
	#else:
	change_state(get_hit_state)

func receive_healing(amount: int):
	if health >= max_health:
		return  # Ignore healing if already at full health

	# Increase health and ensure it does not exceed max health
	health += amount
	health = min(health, max_health)

	# Sync health with the health bar
	health_bar_canvas._set_health(health)

	# Optional: Play a healing effect or sound
	print("Player healed! Current HP:", health)


func start_invincibility():
	if is_invincible:
		return  # Prevent overlapping invincibility

	is_invincible = true
	invincibility_timer.start()

	# Disable the hitbox so the player doesn't take damage
	hurtbox.set_deferred("monitoring", false)

	# Create a tween for flashing effect
	var tween := create_tween()
	tween.set_loops(5)  # Flash 5 times

	var flash_duration := 0.1
	tween.tween_property(character_sprite, "modulate", Color(1, 1, 1, 0.5), flash_duration)
	tween.tween_property(character_sprite, "modulate", Color(1, 1, 1, 1), flash_duration)

func _end_invincibility():
	is_invincible = false
	character_sprite.modulate = Color(1, 1, 1, 1)  # Restore original color

	# Re-enable the hitbox so the player can take damage again
	hurtbox.set_deferred("monitoring", true)
