extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Start the lightning emit effect
func start_emit():
	animated_sprite.play("Fire_Aura")
	show()

# Stop the lightning emit effect
func stop_emit():
	animated_sprite.stop()
	hide()

func _ready():
	# Ensure the node is initially hidden
	hide()
