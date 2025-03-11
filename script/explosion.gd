extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var explosion_sound: AudioStreamPlayer2D = $Explosion
@onready var damage_timer: Timer = $Area2D/Timer  # Ensure there's a Timer inside Area2D

var explosion_lifetime := 15.0  # Spark stays for 10 seconds
var timer := 0.0
var damage = 10
var player_in_explosion : Node2D = null  # Store reference to player

func _ready() -> void:
	damage_timer.wait_time = 1 # Apply damage every second
	damage_timer.one_shot = false  # Allow repeating
	damage_timer.timeout.connect(_apply_damage)  # Connect timer to function

func start_explode() -> void:
	# Play the spark animation
	animated_sprite.play("Explosion")
	_trigger_camera_shake()
	collision_shape.disabled = false  # Enable collisions if needed
	if explosion_sound:
		explosion_sound.play()

func _trigger_camera_shake() -> void:
	# Get the Player node from the scene tree
	var player = get_tree().get_first_node_in_group("Player")  # Alternative if you later use groups
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Player")  # Direct lookup without groups
	
	# Access the PlayerCamera node and trigger the shake
	if player:
		var camera = player.get_node_or_null("PlayerCamera")
		if camera:
			camera.shake(explosion_lifetime, 2)  # (duration, intensity) - Adjust as needed

func _apply_damage() -> void:
	if player_in_explosion:
		player_in_explosion.apply_damage(damage)  # Apply damage every second

func _process(delta: float) -> void:
	timer += delta
	if timer >= explosion_lifetime:
		queue_free()  # Remove spark after lifetime expires

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_explosion = body
		body.apply_damage(damage)
		damage_timer.start()  # Start periodic damage

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_in_explosion:
		player_in_explosion = null
		damage_timer.stop()  # Stop periodic damage
