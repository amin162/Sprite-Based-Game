extends BaseState

var state_name = "GetHit"

var stun_duration = 0.3
var stun_timer = 0.0

func enter(character) -> void:
	stun_timer = stun_duration
	character.velocity = Vector2.ZERO
	character.character_sprite.play("get_hit")
	if character.get_hit_sound:
		character.get_hit_sound.play()

func update(character, delta) -> void:
	stun_timer -= delta
	
	if stun_timer <= 0:
		character.change_state(character.idle_state)
