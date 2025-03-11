extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var lightning_sound: AudioStreamPlayer2D = $LightningSound
# Delay before enabling the collision (adjust to match animation impact timing)
var collision_delay := 0.2
var lightning_sound_duration := 1.5  # Duration for the lightning sound in seconds
var damage = 20

func start_strike(target_position: Vector2) -> void:
	# Position the lightning above the target
	global_position = Vector2(target_position.x, 0)

	# Initially disable collision
	collision_shape.disabled = true
	
	# Play the strike animation
	animated_sprite.play("Lightning_Strike")
	
	# Play the Lightning Sound
	if lightning_sound:
		lightning_sound.play()
	
	# Trigger camera shake** (This was missing before)
	_trigger_camera_shake()

	# Activate collision after the delay
	get_tree().create_timer(collision_delay).timeout.connect(_enable_collision)

func _trigger_camera_shake() -> void:
	# Get the Player node from the scene tree
	var player = get_tree().get_first_node_in_group("Player")  # Alternative if you later use groups
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Player")  # Direct lookup without groups
	
	# Access the PlayerCamera node and trigger the shake
	if player:
		var camera = player.get_node_or_null("PlayerCamera")
		if camera:
			camera.shake(0.3, 5)  # (duration, intensity) - Adjust as needed

func _enable_collision() -> void:
	# Enable collision after delay
	collision_shape.disabled = false

func _ready():
	# Connect the animation_finished signal for cleanup
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	# Disable the collision shape again and wait for the sound to finish
	collision_shape.disabled = true

	# Delay the `queue_free()` call until the sound finishes
	get_tree().create_timer(lightning_sound_duration).timeout.connect(_finalize_cleanup)

func _finalize_cleanup() -> void:
	# Ensure the sound is stopped and free the node
	if lightning_sound.is_playing():
		lightning_sound.stop()
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.apply_damage(damage)  # First hit on entry
		#print("Player Attacked ")
		pass
