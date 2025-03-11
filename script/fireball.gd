extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $DamageArea2D/DamageBody2D
@onready var explosion_sound: AudioStreamPlayer2D = $FireballSound/Explosion
@onready var fireball_fall_sound: AudioStreamPlayer2D = $FireballSound/FireballFall

# Movement variables
var speed: float = 300.0
var gravity: float = 200.0

# Damage
var damage = 20

# Explosion settings
var explosion_scale: Vector2 = Vector2(2, 2)
var explosion_position_offset: Vector2 = Vector2(-8, -4)
var collision_disable_delay: float = 0.6

# State tracking
var is_exploding: bool = false

func launch_from_sky(target_position: Vector2) -> void:
	global_position = Vector2(target_position.x, -200)
	velocity = (target_position - global_position).normalized() * speed
	animated_sprite.play("Fireball")
	if fireball_fall_sound:
		fireball_fall_sound.play()
	show()

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()
	if velocity.length() < 1:  # Adjust threshold as needed
		_trigger_camera_shake()
		_trigger_explosion()

func _trigger_explosion() -> void:
	if is_exploding:
		return
	
	is_exploding = true
	animated_sprite.rotation = 0
	animated_sprite.scale = explosion_scale
	collision_shape.scale = explosion_scale
	collision_shape.position = Vector2(0, 0)
	animated_sprite.position = explosion_position_offset
	animated_sprite.play("Explosion")
	if explosion_sound:
		explosion_sound.play()

	if fireball_fall_sound:
		fireball_fall_sound.stop()
	set_physics_process(false)
	await get_tree().create_timer(collision_disable_delay).timeout
	collision_shape.disabled = true
	animated_sprite.animation_finished.connect(_on_explosion_complete)

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

func _on_explosion_complete() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node) -> void:
	if is_exploding or not body:
		return
	
	if body.is_in_group("Player") and body is CharacterBody2D:
		#_trigger_explosion()
		body.apply_damage(damage)
		#print("player damaged")
		pass
	#else:
		#print("Collided with: ", body)
