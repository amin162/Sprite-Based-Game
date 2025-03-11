extends BossBaseState

var state_name = "MeleeAttack"
var attack_damage = 20  # Example damage value
var charge_sound_playing = false  # Track if charge sound is playing
var slash_sound_playing = false  # Track if slash sound is playing

func enter(boss):
	# Play melee attack animation
	boss.boss_sprite.play("Melee_Attack")
	charge_sound_playing = false
	slash_sound_playing = false  # Reset slash sound flag

	# Connect frame change signal to handle sound timing
	if not boss.boss_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(boss)):
		boss.boss_sprite.frame_changed.connect(Callable(self, "_on_frame_changed").bind(boss))

func update(boss, _delta):
	# Transition back to Idle when the animation finishes
	if not boss.boss_sprite.is_playing():
		boss.change_state("Idle")

func exit(boss):
	# Stop the charge sound if it's still playing
	if boss.charge_sound and boss.charge_sound.is_playing():
		boss.charge_sound.stop()

	# Stop the slash sound if it's still playing
	if boss.slash_sound and boss.slash_sound.is_playing():
		boss.slash_sound.stop()

	# Disconnect the frame_changed signal to avoid unnecessary calls
	if boss.boss_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed").bind(boss)):
		boss.boss_sprite.frame_changed.disconnect(Callable(self, "_on_frame_changed").bind(boss))

# Handle the frame change to play the charge and slash sounds at specific frames
func _on_frame_changed(boss):
	var current_frame = boss.boss_sprite.frame

	# Charge sound between frames 2 and 11
	if current_frame >= 2 and current_frame <= 11:
		if boss.charge_sound and not charge_sound_playing:
			boss.charge_sound.play()
			charge_sound_playing = true
	elif charge_sound_playing:
		# Stop the charge sound if it's outside the range
		if boss.charge_sound and boss.charge_sound.is_playing():
			boss.charge_sound.stop()
		charge_sound_playing = false

	# Slash sound between frames 12 and 14
	if current_frame >= 12 and current_frame <= 14:
		boss.attack_area_collision.call_deferred("set_disabled", !(current_frame in [12, 13]))
		if boss.slash_sound and not slash_sound_playing:
			boss.slash_sound.play()
			slash_sound_playing = true
	elif slash_sound_playing:
		# Stop the slash sound if it's outside the range
		if boss.slash_sound and boss.slash_sound.is_playing():
			boss.slash_sound.stop()
		slash_sound_playing = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.apply_damage(attack_damage)
