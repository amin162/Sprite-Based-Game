extends BaseState

@onready var hit_impact_sprite: AnimatedSprite2D = $"../../PlayerAttackArea2D/Hit_Impact_Animation"
@onready var camera : Camera2D = $"../../PlayerCamera" #Adjust path as needed
@onready var slash_hit_sound : AudioStreamPlayer2D = $"../../Player_Sound_Effect/SlashHit"

var state_name = "Attack"

# Track combo progress
var combo_count: int = 1
var combo_window_timer = 0.0  # Time window to trigger the next attack
const COMBO_WINDOW = 0.5  # Time window to chain combo (0.5 seconds)
var attack_interval_timer = 0.0  # Time allowed for the attack animation to finish before the next attack
const ATTACK_INTERVAL = 0.3
var grace_period_timer = 0.1  # Grace period to allow combo chaining after the window expires

func enter(character) -> void:
	# Stop movement during attack
	character.velocity.x = 0
	
	# Start the attack
	start_attack(character)
	
	# Connect frame_changed signal
	if not character.character_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(character)):
		character.character_sprite.frame_changed.connect(Callable(self, "_on_frame_changed").bind(character))

func update(character, delta):
	# Reduce timers
	attack_interval_timer -= delta
	combo_window_timer -= delta
	grace_period_timer -= delta

	var direction := Input.get_axis("left", "right")

	# Handle attack chaining
	if Input.is_action_just_pressed("attack") and attack_interval_timer <= 0:
		if combo_window_timer > 0:
			# Chain the combo
			combo_count += 1
			if combo_count > 3:
				combo_count = 1
			start_attack(character)
		elif grace_period_timer <= 0:
			# Restart combo after window expires with grace period
			combo_count = 1
			start_attack(character)

	# Transition back to idle or run state
	if combo_window_timer <= 0 and not character.character_sprite.is_playing():
		if direction != 0:
			character.change_state(character.run_state)
		else:
			character.change_state(character.idle_state)

func exit(character) -> void:
	# Reset state variables
	combo_count = 1
	combo_window_timer = 0.0
	attack_interval_timer = 0.0
	grace_period_timer = 0.1  # Reset grace period
	character.deactivate_attack_range()  # Disable attack range
	# Disconnect frame_changed signal
	if character.character_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(character)):
		character.character_sprite.frame_changed.disconnect(Callable(self, "_on_frame_changed").bind(character))

# Start the attack depending on the combo count
func start_attack(character) -> void:
	match combo_count:
		1:
			character.character_sprite.play("attack_1")
			character.attack_sound.play()
			character.attack_sound.pitch_scale = 1
		2:
			character.character_sprite.play("attack_2")
			character.attack_sound.play()
			character.attack_sound.pitch_scale = 1.1
		3:
			character.character_sprite.play("attack_3")
			character.attack_sound.play()
			character.attack_sound.pitch_scale = 1.2
	#print("Combo Animation:", combo_count)

	# Reset timers
	attack_interval_timer = ATTACK_INTERVAL
	combo_window_timer = COMBO_WINDOW

# Handle frame changes to activate/deactivate attack boxes
func _on_frame_changed(character):
	var current_frame = character.character_sprite.frame

	match combo_count:
		1:
			character.attack_range_box1.call_deferred("set_disabled", !(current_frame in [2, 3]))
		2:
			character.attack_range_box2.call_deferred("set_disabled", !(current_frame in [3, 4]))
		3:
			character.attack_range_box3.call_deferred("set_disabled", !(current_frame in [2, 3]))

# Apply damage to enemy based on the combo count and trigger animations
func apply_combo_damage_to_enemy(enemy: Node2D) -> void:
	var damage = 0
	match combo_count:
		1:
			damage = 10 
			slash_hit_sound.play()
			slash_hit_sound.pitch_scale = 1
		2:
			damage = 15  
			slash_hit_sound.play()
			slash_hit_sound.pitch_scale = 1.1
		3:
			hit_impact_sprite.play("hit_impact")
			slash_hit_sound.play()
			slash_hit_sound.pitch_scale = 1.2
			damage = 20  
			#shake_camera(6, 1)  # Strong shake for combo 3

	# Apply calculated damage to enemy
	if enemy.has_method("apply_damage"):
		enemy.apply_damage(damage)

# Custom function to handle body entered event
func custom_handle_body_entered(body: Node2D, _delta: float) -> void:
	# Check if the body is one of the enemies (e.g., "Enemy_Knight" or "Bird") and if the body can handle state change
	if body.is_in_group("Enemy") and body.has_method("change_state"):
		# Apply combo damage to the enemy
		apply_combo_damage_to_enemy(body)

	elif body.is_in_group("Boss"):
		apply_combo_damage_to_enemy(body)

# Handle player attack area body entered event
func _on_player_attack_area_2d_body_entered(body: Node2D) -> void:
	custom_handle_body_entered(body, get_process_delta_time())

func shake_camera(intensity: float, duration: float) -> void:
	var tween = get_tree().create_tween()
	var steps = 5  # Number of shake movements
	var step_duration = duration / steps  # Duration of each shake step

	for i in range(steps):
		# Shake in a random direction
		var random_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", random_offset, step_duration * 0.5).set_trans(Tween.TRANS_SINE)
		
		# Return to center before next shake
		tween.tween_property(camera, "offset", Vector2.ZERO, step_duration * 0.5).set_trans(Tween.TRANS_SINE)


# Process combo window and attack interval
func _process(delta: float) -> void:
	# Handle combo increment only if the attack interval timer has expired
	if attack_interval_timer <= 0 and Input.is_action_just_pressed("attack"):
		# Increase combo count, but limit to a maximum of 3
		if combo_window_timer > 0:
			combo_count += 1
			if combo_count > 3:
				combo_count = 1  # Reset back to 1 after reaching the third combo
		#print("Combo count:", combo_count)
		# Reset the attack interval and combo window timers
		attack_interval_timer = ATTACK_INTERVAL
		combo_window_timer = COMBO_WINDOW
	
	# Countdown for both the attack interval and combo window timers
	if attack_interval_timer > 0:
		attack_interval_timer -= delta

	if combo_window_timer > 0:
		combo_window_timer -= delta
		if combo_window_timer <= 0:
			# Allow brief grace period before combo count resets
			grace_period_timer = 0.1
			# Reset combo count if the combo window expires
			combo_count = 1
