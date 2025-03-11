extends BODBaseState

var state_name = "TeleportIn"

func enter(bod):
	# Play teleport-in animation
	bod.bod_sprite.play("teleport_in")
	
	if bod.teleport_sound:
		bod.teleport_sound.play()

func update(bod, _delta):
	# Ensure the animation finishes before transitioning
	if not bod.bod_sprite.is_playing():
		bod.change_state(bod.teleport_out_state)  

func exit(bod):
	if bod.teleport_sound:
		bod.teleport_sound.stop()
