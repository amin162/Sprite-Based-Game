extends BaseState

var state_name = "JumpDown"

func enter(character):
	# Shift the character's position downward to simulate jumping through the platform
	character.global_position.y += 1  # Adjust this value to match your platform height

	# Transition to the "Fall" state immediately after
	character.change_state(character.idle_state)
