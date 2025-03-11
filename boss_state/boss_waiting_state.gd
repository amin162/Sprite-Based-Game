extends BossBaseState

var state_name = "Waiting"

func enter(boss):
	# Play idle animation
	boss.boss_sprite.play("Idle")
