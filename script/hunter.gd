extends CharacterBody2D

@onready var character_animation = $AnimationPlayer
@onready var character_sprite = $Sprite2D
@onready var animated_character : AnimatedSprite2D = $AnimatedSprite2D
@onready var state_label = $StateLabel
@onready var charge_animation : AnimatedSprite2D = $ChargeAnimation

@onready var footstep_sound : AudioStreamPlayer2D =$Hunter_Sound_Effect/Footstep
@onready var jump_sound : AudioStreamPlayer2D =$Hunter_Sound_Effect/Jump
@onready var touch_platform_sound : AudioStreamPlayer2D = $Hunter_Sound_Effect/TouchPlatform
@onready var dash_sound : AudioStreamPlayer2D = $Hunter_Sound_Effect/Dash
@onready var bow_release_sound : AudioStreamPlayer2D = $Hunter_Sound_Effect/BowRelease
@onready var charge_shot_release_sound : AudioStreamPlayer2D = $Hunter_Sound_Effect/ChargeShotRelease
@onready var charge_sound : AudioStreamPlayer2D = $Hunter_Sound_Effect/ChargeSound
@onready var get_hit_sound : AudioStreamPlayer2D = $Hunter_Sound_Effect/GetHit
@onready var hurtbox: Area2D = $HurtboxArea
@onready var dash_raycast : RayCast2D = $DashRayCast 

#UI related node
@onready var health_bar_canvas: ProgressBar = $CanvasLayer/Healthbar
@onready var charge_bar : ProgressBar = $CanvasLayer/ChargeBar

# Timer node for invisibility frame
@onready var invincibility_timer : Timer = $InvincibilityTimer

#Platform Detection
@onready var left_ray := $LeftRayCast2D
@onready var right_ray := $RightRayCast2D

# Adjust these values based on your game
const RAYCAST_DISTANCE := 20  # Distance to check beyond player width
const RAYCAST_HEIGHT_OFFSET := 5  # Slightly above the feet
var safe_platforms: Dictionary = {"left": false, "right": false, "current": false}

@onready var idle_state = preload("res://hunter_state/hunter_idle_state.gd").new()
@onready var run_state = preload("res://hunter_state/hunter_run_state.gd").new()
@onready var jump_state = preload("res://hunter_state/hunter_jump_state.gd").new()
@onready var fall_state = preload("res://hunter_state/hunter_fall_state.gd").new()
@onready var dash_state = preload("res://hunter_state/hunter_dash_state.gd").new()
@onready var attack_state = preload("res://hunter_state/hunter_attack_state.gd").new()
@onready var special_attack_state = preload("res://hunter_state/hunter_special_attack_state.gd").new()
@onready var jump_attack_state = preload("res://hunter_state/hunter_jump_attack_state.gd").new()
@onready var get_hit_state = preload("res://hunter_state/hunter_get_hit_state.gd").new()
@onready var charge_shot_state = preload("res://hunter_state/hunter_charge_shot_state.gd").new()
@onready var run_attack_state = preload("res://hunter_state/hunter_run_attack_state.gd").new()
@onready var jump_down_state = preload("res://hunter_state/hunter_jump_down_state.gd").new()

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 1000.0  # Gravity constant
var health = 100  # Adjust as needed
var max_health = 100
var is_invincible := false
var can_double_jump: bool = true  # Track whether the player can double jump

@export var max_charge_time: float = 1.3  # Time to reach max charge
var charge_timer: float = 0.0
var is_charging: bool = false
var charge_level: String = "none"  # Default state: "none", "moderate", or "max"
var charge_cooldown = false  # Prevent spamming
var charge_delay_timer = 0.0
const CHARGE_DELAY = 0.2  # Delay before charge starts
var previous_state = null  # Store the state before entering ChargeShotState
var layer_2_activated = false  # Track if layer 2 has been activated once

@onready var DamageLabel = preload("res://scene/damage_label.tscn")

# Initialize state machine
var state_machine: HunterBaseState

func _ready() -> void:
	state_machine = idle_state
	state_machine.enter(self)
	deactivate_then_activate_once(self)
	
	health_bar_canvas.init_health(health)
	
	invincibility_timer.wait_time = 1.0  # Set the duration of invincibility
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_end_invincibility)  # Connect once
	
		# Automatically set raycast positions relative to the player
	left_ray.position = Vector2(-RAYCAST_DISTANCE, RAYCAST_HEIGHT_OFFSET)
	right_ray.position = Vector2(RAYCAST_DISTANCE, RAYCAST_HEIGHT_OFFSET)

	# Make sure the raycasts are always pointing downward
	left_ray.target_position = Vector2(0, 50)  
	right_ray.target_position = Vector2(0, 50)

func _process(delta) -> void:
	if state_label:
		state_label.text = "State: " + get_state_name()
	
	#print(get_safe_teleport_direction())

	# Ensure charge logic only updates after the delay
	if is_charging and not charge_cooldown:
		charge_timer = min(charge_timer + delta, max_charge_time)
		update_charge_ui()
		update_charge_animation()

	# If attack is pressed and not charging yet, start the delay timer
	if Input.is_action_just_pressed("attack") and not is_charging:
		charge_delay_timer = 0.0  # Reset delay

	# If holding attack, increment charge delay timer
	if Input.is_action_pressed("attack") and not is_charging:
		charge_delay_timer += delta

		# Start charging only after the delay is reached
		if charge_delay_timer >= CHARGE_DELAY:
			start_charge()

	# If the attack button is released and charging is active, release the charge
	if Input.is_action_just_released("attack") and is_charging:
		release_charge()

	# Handle down state transition
	if Input.is_action_just_pressed("down") and is_on_floor():
		change_state(jump_down_state)

	if is_on_floor():
		can_double_jump = true
	#print("Double Jump:", can_double_jump)

func _physics_process(delta: float) -> void:
	# Update state machine
	state_machine.update(self, delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
		# Update platform detection
	safe_platforms["left"] = left_ray.is_colliding()
	safe_platforms["right"] = right_ray.is_colliding()
	safe_platforms["current"] = is_on_floor()

func get_state_name() -> String:
	return state_machine.state_name if state_machine else "None"

func change_state(new_state):
	if state_machine:
		state_machine.exit(self)
	state_machine = new_state
	state_machine.enter(self)
	
func toggle_flip_sprite(direction):
	if direction < 0:
		#character_sprite.flip_h = true
		animated_character.flip_h = true
		
	elif direction > 0:
		#character_sprite.flip_h = false
		animated_character.flip_h = false

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
	print("Player get damaged!")
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

func update_charge_ui():
	var charge_percent = (charge_timer / max_charge_time) * 100
	charge_bar.value = charge_percent

func update_charge_animation():
	charge_animation.show()
	if charge_timer >= max_charge_time:
		charge_animation.play("charge_full")  # Maximum charge animation
	elif charge_timer > max_charge_time * 0.5:
		charge_animation.play("charge")  # Moderate charge animation

func start_charge():
	is_charging = true
	charge_timer = 0.0
	charge_bar.value = 0
	charge_cooldown = true  # Prevent spammy charge activation

	# Play charge sound only if it's NOT already playing
	if not charge_sound.playing:
		charge_sound.play()

	charge_animation.play("charge")

	# Reset cooldown after a short delay
	get_tree().create_timer(0.3).timeout.connect(func():
		charge_cooldown = false
	)
	
func release_charge():
	is_charging = false
	charge_animation.stop()
	
	charge_sound.stop()
	previous_state = state_machine
	# Determine charge level and switch states
	if charge_timer >= max_charge_time:
		#print("Max Charge Shot Released!")
		charge_level = "max"
		change_state(charge_shot_state)
	elif charge_timer > max_charge_time * 0.5:
		#print("Moderate Charge Shot Released!")
		charge_level = "moderate"
		change_state(charge_shot_state)
	else:
		#print("No Charge, Regular Shot.")
		charge_level = "none"
		#change_state(attack_state)  # Regular attack for no charge

	# Reset charge timer and UI
	charge_animation.hide()
	charge_bar.value = 0
	charge_timer = 0.0

func get_safe_teleport_direction() -> String:
	var left_detect = $LeftRayCast2D.is_colliding()
	var right_detect = $RightRayCast2D.is_colliding()

	if left_detect and right_detect:
		return "any"  # Both sides safe
	elif left_detect:
		return "left"  # Only left is safe
	elif right_detect:
		return "right"  # Only right is safe
	else:
		return "none"  # No safe spot detected
