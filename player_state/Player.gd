# In player.gd

extends CharacterBody2D

@onready var animation_player: AnimatedSprite2D = $AnimationPlayerSprite2D
@onready var attack_area_2d: Area2D = $Area2D
@onready var attack1_hitbox: CollisionShape2D = $Area2D/Hitbox1
@onready var attack2_hitbox: CollisionShape2D = $Area2D/Hitbox2
@onready var attack3_hitbox: CollisionShape2D = $Area2D/Hitbox3

@export var speed: float = 300.0
@export var jump_velocity: float = -500.0
@export var combo_timeout: float = 0.28  # Time to press attack again to continue the combo
@export var player_health : int = 100
@export var stun_duration: float = 0.3  # Duration the enemy remains stunned

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2 = Vector2.ZERO

var is_dead : bool = false
var is_jumping: bool = false
var is_attacking: bool = false
var is_hit: bool = false  # Track whether the player is in the "getHit" state
var combo_step: int = 0
var combo_timer: float = 0
var last_direction: Vector2 = Vector2.ZERO

var initial_hitbox1_position: Vector2
var initial_hitbox2_position: Vector2
var initial_hitbox3_position: Vector2

var stun_timer = 0.0  # Timer for how long the player stays stunned

var attack_damage: int = 10  # Base damage, can be modified per attack

func _ready():
	initial_hitbox1_position = attack1_hitbox.position
	initial_hitbox2_position = attack2_hitbox.position
	initial_hitbox3_position = attack3_hitbox.position

func _physics_process(delta):
	handle_gravity(delta)
	handle_input()
	apply_movement()
	update_animation()

	# Decrease combo timer
	if combo_timer > 0:
		combo_timer -= delta
	else:
		reset_combo()

	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		is_jumping = false

func handle_input():
	direction = Input.get_vector("left", "right", "up", "down")
	
	# Check if the character has moved or changed direction
	if direction != Vector2.ZERO and direction != last_direction:
		reset_combo()

	# Handle character direction
	if direction.x < 0:
		animation_player.flip_h = true
		flip_hitboxes()
	elif direction.x > 0:
		animation_player.flip_h = false
		flip_hitboxes()
	
	# Save the current direction
	last_direction = direction

	# Handle jumping
	if Input.is_action_just_pressed("jump") and not is_jumping:
		velocity.y = jump_velocity
		is_jumping = true

	# Handle attacking only if on the ground
	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_attacking:
		start_combo()

func start_combo():
	if combo_step == 0 or combo_step == 1:
		combo_step += 1
	elif combo_step == 2:
		combo_step = 3
	
	is_attacking = true
	velocity.x = 0  # Stop movement during attack
	play_attack_animation()
	combo_timer = combo_timeout  # Reset combo timer

func play_attack_animation():
	disable_all_hitboxes()  # Disable all hitboxes first
	
	match combo_step:
		1:
			animation_player.play("attack1")
			attack1_hitbox.disabled = false
			attack_damage = 10  # Set damage for attack 1
		2:
			animation_player.play("attack2")
			attack2_hitbox.disabled = false
			attack_damage = 20  # Set damage for attack 2
		3:
			animation_player.play("attack3")
			attack3_hitbox.disabled = false
			attack_damage = 30  # Set damage for attack 3

func apply_movement():
	if not is_attacking:
		velocity.x = direction.x * speed

func update_animation():
	if is_attacking:
		return  # Skip updating other animations during the attack
	
	if velocity.y < 0 and not is_on_floor():
		animation_player.play("jump")
	elif velocity.y > 0 and not is_on_floor():
		animation_player.play("fall")
	elif velocity.x != 0 and is_on_floor():
		animation_player.play("run")
	elif velocity.x == 0 and is_on_floor():
		animation_player.play("idle")

func _on_animation_player_sprite_2d_animation_finished():
	if is_attacking:
		is_attacking = false

		# If at the last combo step, reset the combo
		if combo_step == 3:
			reset_combo()
		else:
			combo_timer = combo_timeout  # Allow for combo continuation

	# Disable hitboxes after the attack is done
	disable_all_hitboxes()

func reset_combo():
	combo_step = 0
	is_attacking = false
	disable_all_hitboxes()

func disable_all_hitboxes():
	attack1_hitbox.disabled = true
	attack2_hitbox.disabled = true
	attack3_hitbox.disabled = true

func flip_hitboxes():
	var flip_value: float = get_flip_value()

	# Flip hitbox positions based on the character's direction
	update_hitbox_position(attack1_hitbox, initial_hitbox1_position, flip_value)
	update_hitbox_position(attack2_hitbox, initial_hitbox2_position, flip_value)
	update_hitbox_position(attack3_hitbox, initial_hitbox3_position, flip_value)

	# Set the rotation of attack3_hitbox
	set_attack3_rotation()

func get_flip_value() -> float:
	if animation_player.flip_h:
		return -1
	else:
		return 1

func update_hitbox_position(hitbox: Node2D, initial_position: Vector2, flip_value: float):
	var hitbox_pos = initial_position
	hitbox_pos.x *= flip_value
	hitbox.position = hitbox_pos

func set_attack3_rotation():
	if animation_player.flip_h:
		attack3_hitbox.rotation = get_attack3_rotation_flip_h()
	else:
		attack3_hitbox.rotation = get_attack3_rotation_normal()

func get_attack3_rotation_flip_h() -> float:
	return -79.2

func get_attack3_rotation_normal() -> float:
	return 79.2

# Method to get the current attack damage
func get_current_attack_damage() -> int:
	return attack_damage

func apply_player_damage(damage: int):
	# Prevent further damage if the enemy is dead
	if is_dead:
		return
	
	# Apply damage and check if health is below or equal to 0
	player_health -= damage
	print("Plauer health: ", player_health)  # Debug print to check health value

	if player_health <= 0:
		player_die()

	else:# Apply stun effect and play getHit animation
		animation_player.play("getHit")
		is_hit = true  # Set enemy to the "hit" state
		stun_timer = stun_duration  # Set stun timer
		velocity = Vector2.ZERO  # Stop enemy movement during stun

func player_die():
	# Prevent further actions if already dead
	if is_dead:
		return
	
	print("Playing death animation")
	animation_player.play("death")
	is_dead = true

	# Wait for the death animation to finish (adjust the timer duration)
	await get_tree().create_timer(10.0).timeout

	print("Enemy removed from scene")
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Check if the collided body is an enemy
	if body.has_method("apply_enemy_damage"):
		# Apply damage to the enemy
		body.apply_enemy_damage(get_current_attack_damage(), combo_step == 3)  # Pass whether it is the third attack
