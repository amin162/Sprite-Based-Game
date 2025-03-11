extends HunterBaseState

var state_name = "GetHit"

var stun_duration = 0.3
var stun_timer = 0.0

func enter(hunter) -> void:
	stun_timer = stun_duration
	hunter.velocity = Vector2.ZERO
	hunter.animated_character.play("get_hit")
	if hunter.get_hit_sound:
		hunter.get_hit_sound.play()

func update(hunter, delta) -> void:
	stun_timer -= delta
	
	if stun_timer <= 0:
		hunter.change_state(hunter.idle_state)
