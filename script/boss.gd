extends CharacterBody2D

# Load node
@onready var boss_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_label = $StateLabel
@onready var attack_area : Area2D = $Area2D
@onready var attack_area_collision : CollisionPolygon2D = $Area2D/AttackAreaCollision
@onready var screen_healthbar : ProgressBar = $CanvasLayer/ScreenHealthBar
@onready var character_healtbar : ProgressBar = $CharacterHealthbar

# Load Sound Node
@onready var teleport_sound : AudioStreamPlayer2D = $BossSound/Teleport
@onready var sprint_sound : AudioStreamPlayer2D = $BossSound/Sprint
@onready var charge_sound : AudioStreamPlayer2D = $BossSound/Charge
@onready var slash_sound : AudioStreamPlayer2D = $BossSound/Slash
@onready var get_hit_sound1 :AudioStreamPlayer2D =$BossSound/GetHit1
@onready var get_hit_sound2 :AudioStreamPlayer2D =$BossSound/GetHit2
@onready var death_sound :AudioStreamPlayer2D =$BossSound/Death
@onready var explosion_sound :AudioStreamPlayer2D =$BossSound/Explosion

# Load state scripts
@onready var idle_state = preload("res://boss_state/boss_idle_state.gd").new()
@onready var sprint_charge_attack_state = preload("res://boss_state/boss_sprint_charge_attack.gd").new()
@onready var teleport_in_state = preload("res://boss_state/boss_teleport_in_state.gd").new()
@onready var teleport_out_state = preload("res://boss_state/boss_teleport_out_state.gd").new()
@onready var melee_attack = preload("res://boss_state/boss_melee_attack_state.gd").new()
@onready var magic_ability_state = preload("res://boss_state/boss_magic_ability_state.gd").new()
@onready var waiting_state = preload("res://boss_state/boss_waiting_state.gd").new()
@onready var death_state = preload("res://boss_state/boss_death_state.gd").new()

# Load scene
@onready var DamageLabel = preload("res://scene/damage_label.tscn")

# Define constants for movement, etc.
@warning_ignore("unused_signal")
signal state_changed(new_state: String)  # Define the signal
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var player: Node2D = null  # To store reference to the player when detected
const GRAVITY = 500.0
var max_health = 1500
var health = 1500  # Adjust as needed
var is_dead = false  # New flag to indicate if the enemy is dead
var teleport_ray: RayCast2D = null  # Tracks the ray triggering teleportation
var stage: Node = null

# Initialize state machine
var state_machine =  null
var current_state_name = ""  # Track state by name

# Add a variable to store the teleport position
var target_position: Vector2 = Vector2.ZERO

func get_state_name() -> String:
	return state_machine.state_name if state_machine else "None"	

func update_state_label():
	if state_label:
		state_label.text = "State: " + get_state_name()

func _ready():
	# Set initial state
	change_state("Waiting")
	update_state_label()
	stage = get_parent()  # Assuming the boss is a child of StageOne
	screen_healthbar.visible = false
	
	screen_healthbar.init_health(health)
	character_healtbar.init_health(health)

func _physics_process(delta: float) -> void:
	# Update the current state
	state_machine.update(self, delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func change_state(new_state_name: String):
	if current_state_name == new_state_name:
		return

	# Match the state name to its corresponding object
	var new_state = null
	match new_state_name:
		"Death":
			new_state = death_state
		"Waiting":
			new_state = waiting_state
		"Idle":
			new_state = idle_state
		"SprintChargeAttack":
			new_state = sprint_charge_attack_state
		"TeleportIn":
			new_state = teleport_in_state
		"TeleportOut":
			new_state = teleport_out_state
		"MeleeAttack":
			new_state = melee_attack
		"MagicAbility":
			new_state = magic_ability_state
		_:
			return  # Invalid state, exit function

	# Proceed only if the new state is valid
	if new_state:
		if state_machine:
			state_machine.exit(self)  # Exit the current state if set
		state_machine = new_state
		state_machine.enter(self)  # Enter the new state
		current_state_name = new_state_name  # Update the current state name
		emit_signal("state_changed", new_state_name)
		update_state_label()
	if new_state_name == "TeleportIn":
		screen_healthbar.visible = true
		pass

func toggle_flip_sprite(direction):
	if direction < 0:
		attack_area.position.x = -abs(attack_area.position.x)  # Position to the left
		attack_area.scale.x = -1
		boss_sprite.flip_h = true
	elif direction > 0:
		attack_area.position.x = abs(attack_area.position.x)  # Position to the left
		attack_area.scale.x = -1
		boss_sprite.flip_h = false

# Called by stage_one.gd when a ray triggers the teleport
func set_teleport_ray(ray: RayCast2D):
	teleport_ray = ray

func set_state(state_name: String):
	current_state_name = state_name

func get_current_state_name() -> String:
	return current_state_name
	
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
	health = max(health, 0) # Prevent negative values
	
	# Set Boss UI Health bar
	screen_healthbar._set_health(health)
	character_healtbar._set_health(health)
	show_damage(amount, global_position)
	
	print("Boss health:", health)  # Debugging line
	flash_hit()  # Call the flash effect
	if health <= 0:
		health = 0
		screen_healthbar.visible = false
		character_healtbar.visible = false
		change_state("Death")  # Enter death state

func flash_hit():
	var tween = get_tree().create_tween()
	for i in range(5):  # Flash 5 times within 1 second
		tween.tween_property(boss_sprite, "self_modulate", Color(5, 5, 5, 1), 0.1)  # Extreme white
		tween.tween_property(boss_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)  # Return to normal

func _on_damaged_body_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.apply_damage(5)
