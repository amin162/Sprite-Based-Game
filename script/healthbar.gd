extends ProgressBar

@onready var timer: Timer = $Timer  # Timer for delayed damage bar effect
@onready var damage_bar: ProgressBar = $Damagebar  # Secondary damage bar
@onready var health_text: Label = $HealthText  # Label to display health numbers

var health = 0 : set = _set_health  # Current health with setter function

func _set_health(new_health):
	var prev_health = health  # Store previous health value
	health = min(max_value, new_health)  # Ensure health does not exceed max value

	# Update health bar and text display
	value = health
	_update_health_text()

	# If health reaches 0, remove the node
	#if health <= 0:
		#queue_free()

	# Smoothly decrease the health bar using Godot 4's built-in tween
	var tween = create_tween()
	tween.tween_property(self, "value", health, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# If health decreased, start the timer to delay damage bar update
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health  # Instantly update damage bar if healing
# Initializes health values on spawn
func init_health(_health):
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health
	_update_health_text()  # Update the number display
	
func _update_health_text():
	health_text.text = str(health) + " / " + str(max_value)

# Delayed update for the damage bar after taking damage
func _on_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(damage_bar, "value", health, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
