extends CharacterBody2D

# Load node
@onready var enemy_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_impact_sprite : AnimatedSprite2D = $AttackAreaApplied/Hit_Impact_Animation
@onready var chasing_range : Area2D = $ChasingArea2D
@onready var attack_range : Area2D = $AttackArea2D
@onready var attack_range_box: CollisionShape2D = $AttackArea2D/AttackRange
@onready var attack_applied_box :CollisionShape2D = $AttackAreaApplied/AttackApplied
@onready var state_label = $StateLabel  # Reference to the Label node
@onready var swing_progress_bar : ProgressBar = $AttackSwingTimer
@onready var cooldown_progress_bar : ProgressBar = $AttackCooldown
@onready var character_health_bar : ProgressBar = $CharacterHealthBar

#Ability node
@onready var detection_ray : RayCast2D =  $DetectionRayCast # Adjust the path if needed
@onready var chasing_area : CollisionShape2D = $ChasingArea2D/ChasingRange

# Sound Node
@onready var get_hit_sound: AudioStreamPlayer2D = $EnemySound/GetHit
@onready var get_stunned_sound: AudioStreamPlayer2D = $EnemySound/GetStunned
@onready var get_hurt_sound: AudioStreamPlayer2D = $EnemySound/GetHurt
@onready var footstep_sound: AudioStreamPlayer2D = $EnemySound/FootStep
@onready var swordhit_sound: AudioStreamPlayer2D = $EnemySound/SwordHit
@onready var death_sound: AudioStreamPlayer2D = $EnemySound/Death

# Load state scripts
@onready var idle_state = preload("res://enemy_knight_state/enemy_idle_state.gd").new()
@onready var wandering_state = preload("res://enemy_knight_state/enemy_wandering_state.gd").new()
@onready var chasing_state = preload("res://enemy_knight_state/enemy_chasing_state.gd").new()
@onready var ground_attack_state = preload("res://enemy_knight_state/enemy_ground_attack_state.gd").new()
@onready var get_hit_state = preload("res://enemy_knight_state/enemy_get_hit_state.gd").new()
@onready var death_state = preload("res://enemy_knight_state/enemy_death_state.gd").new()

# Load scene
@onready var DamageLabel = preload("res://scene/damage_label.tscn")

# Define constants for movement, etc.
var player: Node2D = null  # To store reference to the player when detected
const SPEED = 90.0
const GRAVITY = 500.0
var health = 100  # Adjust as needed
var is_dead = false  # New flag to indicate if the enemy is dead
var hit_tween  # Store the tween reference

# Initialize state machine
var state_machine: EnemyBaseState

func get_state_name() -> String:
	return state_machine.state_name if state_machine else "None"

func _process(_delta):
	if state_label:
		state_label.text = "State: " + get_state_name()

func _ready():
	# Set the initial state to idle
	state_machine = idle_state
	state_machine.enter(self)
	deactivate_attack_applied()
	
	character_health_bar.init_health(health)

func _physics_process(delta: float):
	# Apply gravity each frame if not on the ground
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Update the state machine
	state_machine.update(self, delta)

	# Move the enemy
	move_and_slide()

# Function to change states
func change_state(new_state):
	# Prevent state change if enemy is dead
	if is_dead:
		return
	# Proceed with state change
	if state_machine:
		state_machine.exit(self)
	state_machine = new_state
	state_machine.enter(self)
	
func toggle_flip_sprite(direction):
	if direction < 0:
		attack_range_box.position.x = -abs(attack_range_box.position.x)  # Position to the left
		attack_applied_box.position.x = -abs(attack_applied_box.position.x)
		hit_impact_sprite.position.x = -abs(attack_applied_box.position.x - 20)
		hit_impact_sprite.flip_h = false
		enemy_sprite.flip_h = true
	elif direction > 0:
		attack_range_box.position.x = abs(attack_range_box.position.x)  # Position to the right
		attack_applied_box.position.x = abs(attack_applied_box.position.x)
		hit_impact_sprite.position.x = abs(attack_applied_box.position.x + 20)
		hit_impact_sprite.flip_h = true
		enemy_sprite.flip_h = false

func activate_attack_applied():
	attack_applied_box.disabled = false

func deactivate_attack_applied():
	attack_applied_box.disabled = true

# Signal handler for when the player enters the Area2D
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		# You can change to chasing state here if desired
		change_state(chasing_state)

# Signal handler for when the player exits the Area2D
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		# You can switch back to idle or wandering state here
		#change_state(idle_state)

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		change_state(ground_attack_state)

func _on_attack_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		# You can change to chasing state here if desired
		#change_state(idle_state)

func show_damage(amount: int, _position: Vector2):
	var damage_label = DamageLabel.instantiate()
	damage_label.set_damage(amount)
	
	# Adjust the position to appear above the enemy
	var offset = Vector2(0, -20)  # Move label 20 pixels upward (adjust as needed)
	damage_label.position = _position + offset
	
	get_parent().add_child(damage_label)  # Add to the scene tree

func apply_damage(amount: int):
	if is_dead:
		return

	health -= amount
	health = max(health, 0)  # Prevent negative values
	character_health_bar._set_health(health)

	if get_hit_sound:
		get_hit_sound.play()
	show_damage(amount, global_position)
	if amount == 20:
		change_state(get_hit_state)
	if health > 0:
		flash_hit()  # Flash only if alive
	else:
		change_state(death_state)

func flash_hit():
	# Kill the previous tween if it exists
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()

	# Create a new tween and store it
	hit_tween = get_tree().create_tween()
	for i in range(5):  # Flash 5 times within 1 second
		hit_tween.tween_property(enemy_sprite, "self_modulate", Color(10, 10, 10, 1), 0.1)  # Extreme white
		hit_tween.tween_property(enemy_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)  # Return to normal
