extends BossBaseState

var state_name = "TeleportIn"

func enter(boss):
	# Play teleport in animation
	boss.boss_sprite.play("Teleport_In")

	if boss.teleport_sound:
		boss.teleport_sound.play()

func update(boss, _delta):
	# Wait until the animation finishes before transitioning
	if not boss.boss_sprite.is_playing():
		boss.change_state("TeleportOut")  # Transition to the next state

func exit(boss):
	if boss.teleport_sound:
		boss.teleport_sound.stop()
