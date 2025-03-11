extends BODBaseState

var state_name = "Idle"

func enter(bod):
	bod.velocity = Vector2.ZERO  # Ensure no movement
	bod.bod_sprite.play("idle")  

func update(bod, _delta):
	# Check if boss takes damage
	if bod.health < bod.max_health:  # Only react if health is reduced
		bod.change_state(bod.chasing_state)  # Wake up and start chasing
		bod.screen_healthbar.visible = true


func exit(_bod):
	pass  # No cleanup needed
