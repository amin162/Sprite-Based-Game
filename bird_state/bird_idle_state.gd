extends BirdBaseState

var state_name = "Idle"
var wing_flap_timer = 0.0
var WING_FLAP_INTERVAL = 0.6  # Adjust the interval based on the desired footstep frequency

# Duration the enemy stays idle before wandering
var idle_time = 2.0
var timer = 0.0

func enter(bird):
	# Play idle animation
	bird.bird_sprite.play("flying_idle")
	timer = 0.0  # Reset timer
	wing_flap_timer = 0.0

func update(bird, delta):
	# Stay idle for a set amount of time before changing to wandering state
	timer += delta
	wing_flap_timer -= delta
	
	if wing_flap_timer <= 0:
		wing_flap_timer = WING_FLAP_INTERVAL
		if bird.wing_flap_sound:
			bird.wing_flap_sound.play()

	# Check if player is in range and chase immediately
	if bird.player and bird.detection_ray.is_colliding() and bird.detection_ray.get_collider() == bird.player:
		bird.change_state(bird.attack_chasing_state)
	if timer >= idle_time:
		bird.change_state(bird.wandering_state)

func exit(_bird):
	wing_flap_timer = 0.0
