extends EnemyBaseState

var state_name = "Idle"

# Duration the enemy stays idle before wandering
var idle_time = 2.0
var timer = 0.0

func enter(enemy):
	# Play idle animation
	enemy.enemy_sprite.play("idle")
	timer = 0.0  # Reset timer

func update(enemy, delta):
	# Stay idle for a set amount of time before changing to wandering state
	timer += delta
	if timer >= idle_time and enemy.is_on_floor():
		enemy.change_state(enemy.wandering_state)
	
