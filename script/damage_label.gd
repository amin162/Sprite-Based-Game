# DamageLabel.gd
extends Label

# Variables for animation
@export var float_speed = 50  # Speed at which the label moves upwards
@export var fade_duration = 1.0  # Duration of fade-out effect

var fade_timer = 0.0

func _ready():
	fade_timer = fade_duration
	modulate.a = 1.0  # Ensure label starts fully visible

func set_damage(amount: int):
	text = str(amount)  # Set the label text to the damage amount

func _process(delta):
	# Move the label upwards
	position.y -= float_speed * delta
	
	# Fade out over time
	fade_timer -= delta
	modulate.a = fade_timer / fade_duration  # Adjust transparency
	
	# Queue free when fade-out is complete
	if fade_timer <= 0:
		queue_free()
