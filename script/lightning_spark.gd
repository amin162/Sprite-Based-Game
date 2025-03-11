extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var spark_sound: AudioStreamPlayer2D = $SparkSound
@onready var damage_timer: Timer = $Area2D/Timer  # Ensure there's a Timer inside Area2D

var spark_lifetime := 15.0  # Spark stays for 10 seconds
var timer := 0.0
var is_permanent := true
var sound_loop_time := 14.0  # Restart sound just before it ends
var sound_start_offset := 1.0  # Start at 1-second mark
var damage = 10
var player_in_spark: Node2D = null  # Store reference to player

func _ready() -> void:
	start_spark()
	damage_timer.wait_time = 1 # Apply damage every second
	damage_timer.one_shot = false  # Allow repeating
	damage_timer.timeout.connect(_apply_damage)  # Connect timer to function

func start_spark(permanent: bool = true) -> void:
	# Play the spark animation
	animated_sprite.play("Lightning_Spark")
	collision_shape.disabled = false  # Enable collisions if needed
	is_permanent = permanent

	if spark_sound:
		spark_sound.play()
		spark_sound.seek(sound_start_offset)

		if is_permanent:
			get_tree().create_timer(sound_loop_time).timeout.connect(_restart_sound)

func _restart_sound() -> void:
	if spark_sound and is_permanent:
		spark_sound.seek(sound_start_offset)
		get_tree().create_timer(sound_loop_time).timeout.connect(_restart_sound)

func _process(delta: float) -> void:
	if is_permanent:
		return  # Skip lifetime check for permanent fire
		
	timer += delta
	if timer >= spark_lifetime:
		queue_free()  # Remove spark after lifetime expires

func _apply_damage() -> void:
	if player_in_spark:
		player_in_spark.apply_damage(10)  # Apply damage every second

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_spark = body
		body.apply_damage(damage)  # First hit on entry
		damage_timer.start()  # Start periodic damage
	if body.is_in_group("Enemy"):
		#body.apply_damage(10)
		pass

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_in_spark:
		player_in_spark = null
		damage_timer.stop()  # Stop periodic damage
