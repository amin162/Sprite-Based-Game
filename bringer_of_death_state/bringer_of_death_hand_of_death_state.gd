extends BODBaseState

var state_name = "Hand_of_Death"
var hand_of_death_scene = preload("res://scene/hand_of_death.tscn")  # Preload once

# Store reusable callables to prevent redundant connections
var casting_finished_callable
var frame_changed_callable
var action_timer = 10  # Fixed duration for the action

func enter(bod):
	var direction_to_player = sign(bod.player.global_position.x - bod.global_position.x)
	bod.detect_raycast.enabled = false  # Disable detect ray during attack
	
	bod.toggle_flip_sprite(direction_to_player)
	bod.bod_sprite.play("cast_hand_of_death")
	
	bod.is_cast_magic = true
	
	# Prepare reusable Callable objects
	casting_finished_callable = Callable(self, "_on_casting_finished").bind(bod)
	frame_changed_callable = Callable(self, "_on_frame_changed").bind(bod)

	# Ensure signals are connected properly
	if not bod.bod_sprite.animation_finished.is_connected(casting_finished_callable):
		bod.bod_sprite.animation_finished.connect(casting_finished_callable)
	if not bod.bod_sprite.frame_changed.is_connected(frame_changed_callable):
		bod.bod_sprite.frame_changed.connect(frame_changed_callable)

	# Start action timer **ONLY IF FIRST TIME**
	if action_timer <= 0:  # Prevent resetting if the boss re-enters the state
		action_timer = 10

func update(bod, delta):
	# Reduce action timer
	action_timer -= delta
	
	# If the timer runs out, transition to chasing state
	if action_timer <= 0:
		bod.change_state(bod.chasing_state)
		bod.is_cast_magic = false
		bod.hand_of_death_cooldown = bod.hand_of_death_cooldown_time

func exit(bod):
	# Disconnect signals properly
	if bod.bod_sprite.frame_changed.is_connected(frame_changed_callable):
		bod.bod_sprite.frame_changed.disconnect(frame_changed_callable)
	if bod.bod_sprite.animation_finished.is_connected(casting_finished_callable):
		bod.bod_sprite.animation_finished.disconnect(casting_finished_callable)

func _on_casting_finished(bod):
	# Enable detect ray and transition based on the timer
	bod.detect_raycast.enabled = true
	
	# Only restart if there's still time left
	if action_timer > 0:
		bod.change_state(bod.hand_of_death_state)  # Repeat attack if time remains
	else:
		bod.change_state(bod.chasing_state)  # Otherwise, transition to chasing

# Handle frame change to spawn the attack at the right moment
func _on_frame_changed(bod):
	if bod.bod_sprite.frame == 5:
		spawn_hand_of_death(bod)

func spawn_hand_of_death(bod):
	var hand_of_death = hand_of_death_scene.instantiate()
	bod.get_parent().add_child(hand_of_death)  # Add to the same scene tree
	if hand_of_death.has_method("start_strike"):
		hand_of_death.start_strike(bod.player.global_position)
