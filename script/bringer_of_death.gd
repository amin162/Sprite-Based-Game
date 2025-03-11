extends CharacterBody2D

#Load Node
@onready var state_label = $StateLabel  # Reference to the Label node
@onready var bod_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detect_raycast : RayCast2D = $DetectRayCast
@onready var physics_body : CollisionShape2D = $PhysicsBody
@onready var damage_collision : CollisionPolygon2D = $DamageArea/DamageCollisionPolygon
@onready var damage_area : Area2D = $DamageArea

@onready var death_slice_sound : AudioStreamPlayer2D = $BringerOfDeathSound/DeathSliceSound
@onready var schyte_sound : AudioStreamPlayer2D = $BringerOfDeathSound/SchyteSound
@onready var growl_sound : AudioStreamPlayer2D = $BringerOfDeathSound/GrowlSound
@onready var teleport_sound : AudioStreamPlayer2D = $BringerOfDeathSound/TeleportSound
@onready var footstep_sound : AudioStreamPlayer2D = $BringerOfDeathSound/FootstepSound
@onready var death_sound : AudioStreamPlayer2D = $BringerOfDeathSound/DeathSound
@onready var vanishing_sound : AudioStreamPlayer2D = $BringerOfDeathSound/VanishSound

@onready var screen_healthbar : ProgressBar = $CanvasLayer/ScreenHealthBar
@onready var character_healtbar : ProgressBar = $CharacterHealthbar

# Load state scripts
@onready var idle_state = preload("res://bringer_of_death_state/bringer_of_death_idle_state.gd").new()
@onready var teleport_out_state = preload("res://bringer_of_death_state/bringer_of_death_teleport_out_state.gd").new()
@onready var teleport_in_state = preload("res://bringer_of_death_state/bringer_of_death_teleport_in_state.gd").new()
@onready var chasing_state = preload("res://bringer_of_death_state/bringer_of_death_chasing_state.gd").new()
@onready var melee_death_slice_state = preload("res://bringer_of_death_state/bringer_of_death_death_slice_state.gd").new()
@onready var range_death_slice_state = preload("res://bringer_of_death_state/bringer_of_death_range_death_slice_state.gd").new()
@onready var hand_of_death_state = preload("res://bringer_of_death_state/bringer_of_death_hand_of_death_state.gd").new()
@onready var death_state = preload("res://bringer_of_death_state/bringer_of_death_death_state.gd").new()

@onready var player = get_tree().get_first_node_in_group("Player")

# Load scene
@onready var DamageLabel = preload("res://scene/damage_label.tscn")

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 500.0
var max_health = 1500
var health = 1500  # Adjust as needed
var melee_range = 70

var is_dead = false  # New flag to indicate if the enemy is dead
var is_cast_magic = false
var is_range_attack = false  # Flag to check if we should attack after teleporting
var is_alerted = false  # Ensures boss only switches to chasing once

var state_machine: BODBaseState
var chase_timer = 0.0  # Timer to control chase duration
var platform_threshold = 20

var range_death_slice_cooldown: float = 15  # Starts ready to attack
var range_death_slice_cooldown_time: float = 15  # Cooldown duration (adjust as needed)

var hand_of_death_cooldown: float = 10  # Starts ready to attack
var hand_of_death_cooldown_time: float = 10 # Cooldown duration (adjust as needed)

func get_state_name() -> String:
	return state_machine.state_name if state_machine else "None"

func update_state_label():
	if state_label:
		state_label.text = "State: " + get_state_name()

func apply_damage(amount: int):  #the only one who can use this function is player
	if is_dead:
		return

	health -= amount
	health = max(health, 0)  # Prevent negative values
	#print(name, "health:", health)  # Debugging line
		
		# Set Boss UI Health bar
	screen_healthbar._set_health(health)
	character_healtbar._set_health(health)
	show_damage(amount, global_position)
	
	flash_hit()  # Call the flash effect
	
	if health <= 0:
		health = 0
		screen_healthbar.visible = false
		character_healtbar.visible = false
		change_state(death_state)  # Enter death state

func toggle_flip_sprite(direction):
	if direction < 0:
		bod_sprite.flip_h = false
		bod_sprite.position.x = -35
		damage_area.position.x = -24
		damage_area.scale.x = 1

	elif direction > 0:
		bod_sprite.flip_h = true
		bod_sprite.position.x = 35
		damage_area.position.x = 24
		damage_area.scale.x = -1

func change_state(new_state):
	# Prevent state change if enemy is dead
	if is_dead:
		return

	# Proceed with state change
	if state_machine:
		state_machine.exit(self)
	state_machine = new_state
	state_machine.enter(self)
	
	#print(get_state_name())

func show_damage(amount: int, _position: Vector2):
	var damage_label = DamageLabel.instantiate()
	damage_label.set_damage(amount)
	
	# Adjust the position to appear above the enemy
	var offset = Vector2(0, -20)  # Move label 20 pixels upward (adjust as needed)
	damage_label.position = _position + offset
	
	get_parent().add_child(damage_label)  # Add to the scene tree
	
func flash_hit():
	var tween = get_tree().create_tween()
	for i in range(5):  # Flash 5 times within 1 second
		tween.tween_property(bod_sprite, "self_modulate", Color(5, 5, 5, 1), 0.1)  # Extreme white
		tween.tween_property(bod_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)  # Return to normal

func _process(delta):
	if state_label:
		state_label.text = "State: " + get_state_name()

	#print("Hand of Death CD: ",hand_of_death_cooldown)
	#print("Range Death Slice CD: ",range_death_slice_cooldown)

	if state_machine == chasing_state and range_death_slice_cooldown > 0 and hand_of_death_cooldown > 0:
		range_death_slice_cooldown -= delta
		hand_of_death_cooldown -= delta
		if range_death_slice_cooldown <= 0:
			is_range_attack = true
			if growl_sound:
				growl_sound.play()
			#print("✅ Range Death Slice is now available!")
		elif hand_of_death_cooldown <= 0:
			is_cast_magic = true
			if growl_sound:
				growl_sound.play()
			#print("✅ Hand of Death is now available!")

func _ready() -> void:
	state_machine = idle_state
	state_machine.enter(self)
	
	screen_healthbar.init_health(health)
	character_healtbar.init_health(health)
	
	screen_healthbar.visible = false

func _physics_process(delta: float) -> void:
		# Update the current state
	state_machine.update(self, delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
