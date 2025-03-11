extends CharacterBody2D

@export var heal_amount: int = 40  # Amount of health restored

@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound
@onready var health_potion_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_collision : CollisionShape2D = $PickupArea/PickupCollision
var GRAVITY: float = 1000

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta 
	move_and_slide()
	
func _ready() -> void:
	health_potion_sprite.play()

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):  # Ensure only the player can pick it up
		if body.health < body.max_health:  # Only heal if not at full HP
			body.receive_healing(heal_amount)  # Call healing function
			print("Player healed! Current HP: ", body.health)
			
			# Play pickup sound and delete the potion
			if pickup_sound:
				pickup_sound.play()
				health_potion_sprite.visible = false
				if pickup_collision:
					pickup_collision.set_deferred("disabled", true)
				await pickup_sound.finished  # Wait for sound to finish
			queue_free()
