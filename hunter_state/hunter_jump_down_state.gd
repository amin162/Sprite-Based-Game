extends HunterBaseState

var state_name = "JumpDown"

func enter(hunter):
	# Shift the character's position downward to simulate jumping through the platform
	hunter.global_position.y += 1  # Adjust this value to match your platform height

	# Transition to the "Fall" state immediately after
	hunter.change_state(hunter.idle_state)
