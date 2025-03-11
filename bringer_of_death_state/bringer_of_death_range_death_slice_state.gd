extends BODBaseState

var state_name = "Range_Death_Slice"
var death_slice_scene = preload("res://scene/death_slice.tscn")  # Preload once

# Store reusable callables to prevent redundant connections
var attack_finished_callable
var frame_changed_callable
var action_timer = 10  # Fixed duration for the action

func enter(bod):
	var direction_to_player = sign(bod.player.global_position.x - bod.global_position.x)
	bod.detect_raycast.enabled = false  # Disable detect ray during attack
	
	bod.toggle_flip_sprite(direction_to_player)
	bod.bod_sprite.play("range_death_slice")
	
	bod.is_range_attack = true

	
	# Prepare reusable Callable objects
	attack_finished_callable = Callable(self, "_on_attack_finished").bind(bod)
	frame_changed_callable = Callable(self, "_on_frame_changed").bind(bod)

	# Ensure signals are connected properly
	if not bod.bod_sprite.animation_finished.is_connected(attack_finished_callable):
		bod.bod_sprite.animation_finished.connect(attack_finished_callable)
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
		bod.is_range_attack = false
		bod.range_death_slice_cooldown = bod.range_death_slice_cooldown_time
		
func exit(bod):
	# Disconnect signals properly
	if bod.bod_sprite.frame_changed.is_connected(frame_changed_callable):
		bod.bod_sprite.frame_changed.disconnect(frame_changed_callable)
	if bod.bod_sprite.animation_finished.is_connected(attack_finished_callable):
		bod.bod_sprite.animation_finished.disconnect(attack_finished_callable)

func _on_attack_finished(bod):
	# Enable detect ray and transition based on the timer
	bod.detect_raycast.enabled = true
	
	# Only restart if there's still time left
	if action_timer > 0:
		bod.change_state(bod.range_death_slice_state)  # Repeat attack if time remains
	else:
		bod.change_state(bod.chasing_state)  # Otherwise, transition to chasing

# Handle frame change to spawn the attack at the right moment
func _on_frame_changed(bod):
	if bod.bod_sprite.frame == 5:
		spawn_death_slice(bod)

func spawn_death_slice(bod):
	var death_slice = death_slice_scene.instantiate()
	var direction_to_player = sign(bod.player.global_position.x - bod.global_position.x)
	bod.get_parent().add_child(death_slice)  # Add to the same scene tree
	death_slice.global_position = bod.global_position  # Place at boss position
	death_slice.toggle_flip_sprite(direction_to_player)
	if death_slice.has_method("set_position_and_activate"):
		death_slice.set_position_and_activate(bod.player.global_position)
