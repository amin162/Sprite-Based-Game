extends Node2D

@onready var hand_of_death_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var hand_of_death_sound: AudioStreamPlayer2D = $HandOfDeathSound

var damage = 30  # Damage dealt by the attack
const SOUND_START_FRAME = 10
const SOUND_DURATION = 1.0  # 1 second

func start_strike(target_position: Vector2) -> void:
	# Position the hand_of_death above the target
	global_position = Vector2(target_position.x, 0)

	# Initially disable collision
	collision_shape.set_deferred("disabled", true)
	
	# Play the strike animation
	hand_of_death_sprite.play("hand_of_death")
	
	# Play the Hand of Death Sound
	if hand_of_death_sound:
		hand_of_death_sound.play()
	
	# Trigger camera shake
	_trigger_camera_shake()

func _ready():
	# Connect the frame_changed signal to enable/disable collision based on the frame number
	hand_of_death_sprite.frame_changed.connect(_on_frame_changed)

	# Connect animation_finished signal for cleanup
	hand_of_death_sprite.animation_finished.connect(_on_animation_finished)

func _on_frame_changed() -> void:
	var current_frame = hand_of_death_sprite.frame

	# Enable collision only between frames 8 and 12
	collision_shape.set_deferred("disabled", not (current_frame >= 8 and current_frame <= 12))

	# Play the Hand of Death Sound at frame 10
	if current_frame == SOUND_START_FRAME and hand_of_death_sound and not hand_of_death_sound.playing:
		hand_of_death_sound.play()
		get_tree().create_timer(SOUND_DURATION).timeout.connect(_stop_hand_of_death_sound)

func _stop_hand_of_death_sound() -> void:
	if hand_of_death_sound.playing:
		hand_of_death_sound.stop()
		
func _trigger_camera_shake() -> void:
	# Get the Player node from the scene tree
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Player")
	
	# Access the PlayerCamera node and trigger the shake
	if player:
		var camera = player.get_node_or_null("PlayerCamera")
		if camera:
			camera.shake(0.3, 5)  # (duration, intensity) - Adjust as needed

func _on_animation_finished() -> void:
	# Disable collision when animation finishes
	collision_shape.set_deferred("disabled", true)

	# Remove the attack effect after the sound ends
	if hand_of_death_sound:
		await get_tree().create_timer(hand_of_death_sound.stream.get_length()).timeout
	
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("Boss"):
		body.apply_damage(damage)  # First hit on entry
