extends BODBaseState

var state_name = "Melee_Death_Slice"
var damage: int = 30

func enter(bod):
	if not bod.player:
		bod.change_state(bod.idle_state)
		return
		
	var direction_to_player = sign(bod.player.global_position.x - bod.global_position.x)
	bod.toggle_flip_sprite(direction_to_player)
	
	# Stop movement before attacking
	bod.velocity = Vector2.ZERO  
	bod.bod_sprite.play("melee_death_slice")

	# Connect animation finished event
	if not bod.bod_sprite.animation_finished.is_connected(Callable(self, "_on_animation_finished").bind(bod)):
		bod.bod_sprite.animation_finished.connect(Callable(self, "_on_animation_finished").bind(bod), CONNECT_ONE_SHOT)
	
	# Connect frame change signal for sound & hitbox handling
	if not bod.bod_sprite.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(bod)):
		bod.bod_sprite.frame_changed.connect(Callable(self, "_on_frame_changed").bind(bod))
	
func update(bod, _delta):
	# Transition back to chasing when the animation finishes
	if not bod.bod_sprite.is_playing():
		bod.change_state(bod.chasing_state)

func exit(bod):
	# Stop the death slice sound if it's still playing
	if bod.death_slice_sound and bod.death_slice_sound.is_playing():
		bod.death_slice_sound.stop()

	# Disconnect signals to prevent duplication
	if bod.bod_sprite.frame_changed.is_connected(Callable(self, "_on_frame_changed").bind(bod)):
		bod.bod_sprite.frame_changed.disconnect(Callable(self, "_on_frame_changed").bind(bod))

	if bod.bod_sprite.animation_finished.is_connected(Callable(self, "_on_animation_finished").bind(bod)):
		bod.bod_sprite.animation_finished.disconnect(Callable(self, "_on_animation_finished").bind(bod))

func _on_animation_finished(bod):
	if not bod.player:
		bod.change_state(bod.idle_state)
		return

	# Return to chasing after the attack
	bod.change_state(bod.chasing_state)

# Handle sound effects & hitbox enabling based on animation frame
func _on_frame_changed(bod):
	var current_frame = bod.bod_sprite.frame

	# Enable attack hitbox at frame 5
	bod.damage_collision.call_deferred("set_disabled", !(current_frame == 5))

	# Play slash sound exactly at frame 5
	if current_frame == 5:
		if bod.death_slice_sound and not bod.death_slice_sound.is_playing() and bod.schyte_sound and not bod.schyte_sound.is_playing():
			bod.death_slice_sound.play()
			bod.schyte_sound.play()
	#elif bod.death_slice_sound and bod.death_slice_sound.is_playing():
		## Stop the slash sound if the animation moves past frame 5
		#bod.death_slice_sound.stop()

# Handle damage when the attack hits the player
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.apply_damage(damage)
