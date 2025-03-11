extends Node2D

@export var damage: int = 20
@onready var death_slice: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: CollisionPolygon2D = $DamageArea/CollisionPolygon2D  # Ensure this node exists in the scene
@onready var death_slice_sound : AudioStreamPlayer2D = $DeathSliceSound

func set_position_and_activate(target_position):
	global_position = target_position
	death_slice.play("death_slice")  # Play animation immediately
	
	# Disable hitbox at start
	damage_area.set_deferred("disabled", true)
	
	# Delay enabling the hitbox (e.g., 0.3s delay before it activates)
	await get_tree().create_timer(0.5).timeout
	damage_area.set_deferred("disabled", false)
	death_slice_sound.play()
	
	# Ensure the animation finishes before deleting
	if not death_slice.animation_finished.is_connected(_on_animation_finished):
		death_slice.animation_finished.connect(_on_animation_finished)

func toggle_flip_sprite(direction):
	if direction < 0:
		death_slice.flip_h = false
		death_slice.position.x = 35
	elif direction > 0:
		death_slice.flip_h = true
		death_slice.position.x = -35

func _on_animation_finished():
	queue_free()  # Destroy after animation ends

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.apply_damage(damage)
