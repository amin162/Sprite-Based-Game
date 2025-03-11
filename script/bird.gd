extends CharacterBody2D

# Node references
@onready var bird_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_impact_sprite : AnimatedSprite2D = $AttackArea2D/HitImpactAnimation
@onready var detection_ray: RayCast2D = $DetectionRayCast
@onready var state_label = $StateLabel
@onready var character_health_bar : ProgressBar = $CharacterHealthbar

@onready var physics_body : CollisionShape2D = $PhysicsBody
@onready var attack_area : CollisionShape2D = $AttackArea2D/DamageZone
@onready var chasing_range: Area2D = $ChasingArea2D
@onready var chasing_range_collision_box: CollisionShape2D = $ChasingArea2D/ChasingRange
@onready var pulling_area: Area2D = $PullingArea2D
@onready var pulling_area_collision_box: CollisionShape2D = $PullingArea2D/PullingArea

# Sound Node
@onready var blade_hit_sound = $Bird_Sound/Blade_Hit
@onready var attack_sound = $Bird_Sound/Attack
@onready var wing_flap_sound = $Bird_Sound/WingFlap
@onready var idle_squawking_sound = $Bird_Sound/IdleSquawking
@onready var chase_squawking_sound = $Bird_Sound/ChaseSquawking

# Load state scripts
@onready var idle_state = preload("res://bird_state/bird_idle_state.gd").new()
@onready var wandering_state = preload("res://bird_state/bird_wandering_state.gd").new()
@onready var attack_chasing_state = preload("res://bird_state/bird_attack_chasing_state.gd").new()
@onready var get_hit_state = preload("res://bird_state/bird_get_hit_state.gd").new()
@onready var death_state = preload("res://bird_state/bird_death_state.gd").new()
@onready var get_knocked_state = preload("res://bird_state/bird_get_knocked_state.gd").new()

# Load scene
@onready var DamageLabel = preload("res://scene/damage_label.tscn")

# Movement constants
const SPEED = 50.0
const GRAVITY = 1000.0  # Gravity constant
var player: Node2D = null
var player_in_range = false  # Tracks if player is within chasing range
var health = 50  # Adjust as needed
var is_dead  = false

# Initialize state machine
var state_machine: BirdBaseState

func get_state_name() -> String:
	return state_machine.state_name if state_machine else "None"	

func _ready():
	# Set initial state to idle
	state_machine = idle_state
	state_machine.enter(self)
	update_state_label()
	character_health_bar.init_health(health)

func _physics_process(delta: float) -> void:
	# Update current state machine behavior
	state_machine.update(self, delta)
	move_and_slide()

# Function to handle state transitions and update the label
func change_state(new_state):
	if is_dead:
		return  # Do not allow state changes if the bird is dead
	if state_machine != new_state:
		state_machine.exit(self)
		state_machine = new_state
		state_machine.enter(self)
		update_state_label()

func toggle_flip_sprite(direction):
	if direction < 0:
		hit_impact_sprite.flip_h = true
		bird_sprite.flip_h = true
	elif direction > 0:
		hit_impact_sprite.flip_h = false
		bird_sprite.flip_h = false

# Function to update label text for debugging
func update_state_label():
	if state_label:
		state_label.text = "State: " + get_state_name()


func show_damage(amount: int, _position: Vector2):
	var damage_label = DamageLabel.instantiate()
	damage_label.set_damage(amount)
	damage_label.position = _position  # Set position to where the damage occurs
	get_parent().add_child(damage_label)  # Add to the scene tree to make it visible

func apply_damage(amount: int):
	if is_dead:
		return
	health -= amount
	health = max(health, 0) # Prevent negative values
	character_health_bar._set_health(health)
	show_damage(amount, global_position)  # Show damage at enemy's position
	flash_hit()  # Call the flash effect
	change_state(get_hit_state)
	if health <= 0:
		health = 0
		change_state(death_state)  # Enter death state
	if amount == 20: 
		change_state(get_knocked_state)

func flash_hit():
	var tween = get_tree().create_tween()
	for i in range(5):  # Flash 5 times within 1 second
		tween.tween_property(bird_sprite, "self_modulate", Color(10, 10, 10, 1), 0.1)  # Extreme white
		tween.tween_property(bird_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)  # Return to normal

# Signal handler for player entering the chasing area
func _on_pulling_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		player_in_range = true
		detection_ray.enabled = true  # Activate detection ray on player entry
		change_state(attack_chasing_state)

# Signal handler for player exiting the chasing area
func _on_chasing_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		player_in_range = false
		detection_ray.enabled = false  # Disable detection ray when player leaves range
