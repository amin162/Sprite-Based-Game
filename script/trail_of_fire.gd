extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var fire_sound: AudioStreamPlayer2D = $Fire
@onready var damage_timer: Timer = $Area2D/Timer  # Ensure there's a Timer inside Area2D

var fire_lifetime := 15.0  # Default lifetime for temporary fire
var timer := 0.0
var is_permanent := true
var sound_loop_time := 14.0  # Restart sound just before it ends
var sound_start_offset := 1.0  # Start at 1-second mark
var damage = 10
var player_in_fire: Node2D = null  # Store reference to player

func _ready():
	start_fire()  # Automatically play animation when scene starts
	damage_timer.wait_time = 1 # Apply damage every second
	damage_timer.one_shot = false  # Allow repeating
	damage_timer.timeout.connect(_apply_damage)  # Connect timer to function

func start_fire(permanent: bool = true) -> void:
	# Play the fire animation
	animated_sprite.play("Fire_Trail2")
	collision_shape.disabled = false  # Enable collisions if needed
	is_permanent = permanent

	if fire_sound:
		fire_sound.play()
		fire_sound.seek(sound_start_offset)

		if is_permanent:
			get_tree().create_timer(sound_loop_time).timeout.connect(_restart_sound)

func _restart_sound() -> void:
	if fire_sound and is_permanent:
		fire_sound.seek(sound_start_offset)
		get_tree().create_timer(sound_loop_time).timeout.connect(_restart_sound)

func _process(delta: float) -> void:
	if is_permanent:
		return  # Skip lifetime check for permanent fire

	timer += delta
	if timer >= fire_lifetime:
		queue_free()  # Remove fire after lifetime expires

func _apply_damage() -> void:
	if player_in_fire:
		player_in_fire.apply_damage(10)  # Apply damage every second

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_fire = body
		body.apply_damage(damage)  # First hit on entry
		damage_timer.start()  # Start periodic damage
	if body.is_in_group("Enemy"):
		#body.apply_damage(10)
		pass

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_in_fire:
		player_in_fire = null
		damage_timer.stop()  # Stop periodic damage
