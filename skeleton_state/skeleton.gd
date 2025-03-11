extends CharacterBody2D

@onready var skeleton_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_label = $StateLabel  # Reference to the Label node
@onready var chasing_area_collision : CollisionShape2D = $ChasingArea2D/ChasingAreaCollision
@onready var chasing_raycast : RayCast2D = $ChasingRayCast
# Sound Node
@onready var get_hit_sound: AudioStreamPlayer2D = $EnemySound/GetHit
@onready var get_stunned_sound: AudioStreamPlayer2D = $EnemySound/GetStunned
@onready var get_hurt_sound: AudioStreamPlayer2D = $EnemySound/GetHurt
@onready var footstep_sound: AudioStreamPlayer2D = $EnemySound/FootStep
@onready var swordhit_sound: AudioStreamPlayer2D = $EnemySound/SwordHit
@onready var death_sound: AudioStreamPlayer2D = $EnemySound/Death

# Load state scripts
@onready var idle_state = preload("res://skeleton_state/skeleton_idle_state.gd").new()
@onready var wandering_state = preload("res://skeleton_state/skeleton_wandering_state.gd").new()
@onready var chasing_state = preload("res://skeleton_state/skeleton_chasing_state.gd").new()
@onready var get_hit_state = preload("res://skeleton_state/skeleton_get_hit_state.gd").new()
@onready var player = get_tree().get_first_node_in_group("Player")

# Define constants for movement, etc.
#var player: Node2D = null  # To store reference to the player when detected
const SPEED = 90.0
const GRAVITY = 500.0
var health = 100  # Adjust as needed
var is_dead = false  # New flag to indicate if the enemy is dead
var hit_tween  # Store the tween reference

# Initialize state machine
var state_machine: SkeletonBaseState

func get_state_name() -> String:
	return state_machine.state_name if state_machine else "None"

func _process(_delta):
	if state_label:
		state_label.text = "State: " + get_state_name()

func _ready():
	# Set the initial state to idle
	state_machine = idle_state
	state_machine.enter(self)
	#deactivate_attack_applied()

func _physics_process(delta: float):
	# Apply gravity each frame if not on the ground
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Update the state machine
	state_machine.update(self, delta)

	# Move the enemy
	move_and_slide()
	
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
		#attack_range_box.position.x = -abs(attack_range_box.position.x)  # Position to the left
		#attack_applied_box.position.x = -abs(attack_applied_box.position.x)
		#hit_impact_sprite.position.x = -abs(attack_applied_box.position.x - 20)
		#hit_impact_sprite.flip_h = false
		skeleton_sprite.flip_h = true
	elif direction > 0:
		#attack_range_box.position.x = abs(attack_range_box.position.x)  # Position to the right
		#attack_applied_box.position.x = abs(attack_applied_box.position.x)
		#hit_impact_sprite.position.x = abs(attack_applied_box.position.x + 20)
		#hit_impact_sprite.flip_h = true
		skeleton_sprite.flip_h = false

func apply_damage(amount: int):  # Allow tracking the attacker
	if is_dead:
		return

	health -= amount
	health = max(health, 0)  # Prevent negative values
	print(name, "health:", health)  # Debugging line

	# If the attacker is a player, update target
	if player and player.is_in_group("Player"):
		#player = attacker  # Ensure the enemy knows who attacked

		var direction = (player.global_position - global_position).normalized()
		var distance_to_player = player.global_position.distance_to(global_position)

		# Update RayCast to track player upon taking damage
		chasing_raycast.target_position = direction * distance_to_player

		# Transition to chasing state when hit
		change_state(chasing_state)

	# If damage is high, enter "get hit" state
	if amount >= 20:
		change_state(get_hit_state)


	#character_health_bar._set_health(health)

func _on_chasing_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		change_state(chasing_state)
		print("Player Entered")
		#change_state(chasing_state)

func _on_chasing_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Player Exit")
		
		# Check if the enemy is still in the "Chasing" state before switching to idle
		if get_state_name() == "Chasing":
			change_state(idle_state)
