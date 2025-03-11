extends BossBaseState

var state_name = "Idle"

func enter(boss):
	# Play idle animation
	boss.boss_sprite.play("Idle")
