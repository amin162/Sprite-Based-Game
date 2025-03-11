extends Camera2D

var shake_intensity := 0.0
var shake_duration := 0.0

func shake(duration: float, intensity: float) -> void:
	shake_duration = duration
	shake_intensity = intensity

func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_duration -= delta
		offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		offset = Vector2.ZERO  # Reset camera position
