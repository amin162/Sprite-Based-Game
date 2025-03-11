extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var electric_spark_sound: AudioStreamPlayer2D = $Spark
@onready var lightning_emit_area: CollisionShape2D = $LightningEmitArea/LightningEmitCollision

const LOOP_BEGIN = 2.0  # Start looping at 2 seconds
const LOOP_END = 5.0    # End looping at 5 seconds
var damage = 10

# Track whether the signal is connected
var is_sound_connected: bool = false

# Start the lightning emit effect
func start_emit():
	lightning_emit_area.call_deferred("set_disabled", false)
	animated_sprite.play("Lightning_Emit")
	if electric_spark_sound and electric_spark_sound.stream:
		electric_spark_sound.stream.loop = false  # Disable built-in looping
		electric_spark_sound.play(LOOP_BEGIN)  # Start from loop begin

		# Connect the finished signal only if it's not already connected
		if not is_sound_connected:
			electric_spark_sound.finished.connect(_on_sound_finished, CONNECT_ONE_SHOT)
			is_sound_connected = true

	show()

# Stop the lightning emit effect
func stop_emit():
	lightning_emit_area.call_deferred("set_disabled", true)
	animated_sprite.stop()
	if electric_spark_sound:
		electric_spark_sound.stop()

		# Disconnect the finished signal
		if is_sound_connected and electric_spark_sound.finished.is_connected(_on_sound_finished):
			electric_spark_sound.finished.disconnect(_on_sound_finished)
			is_sound_connected = false

# Manually loop between LOOP_BEGIN and LOOP_END
func _on_sound_finished():
	if electric_spark_sound and electric_spark_sound.get_playback_position() >= LOOP_END:
		electric_spark_sound.play(LOOP_BEGIN)  # Seek back to LOOP_BEGIN
	else:
		electric_spark_sound.play()  # Just restart normally

func _ready():
	lightning_emit_area.call_deferred("set_disabled", true)
	hide()  # Ensure the node is initially hidden

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.apply_damage(damage)
