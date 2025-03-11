extends SkeletonBaseState

var state_name = "Idle"

# Duration the enemy stays idle before wandering
var idle_time = 2.0
var timer = 0.0

func enter(skeleton):
	# Play idle animation
	skeleton.skeleton_sprite.play("idle")
	timer = 0.0  # Reset timer

func update(skeleton, delta):
	# Stay idle for a set amount of time before changing to wandering state
	timer += delta

	# If idle time is up and the skeleton is on the floor, transition to wandering state
	if timer >= idle_time and skeleton.is_on_floor():
		skeleton.change_state(skeleton.wandering_state)
