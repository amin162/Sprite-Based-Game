extends Node2D

@onready var range_death_slice_collision : CollisionShape2D = $BossTeleportAccess/RangeDeathSliceTeleportPosition/RangeDeathSlicePosition

# Enabled InvisibleBorder and Lightning scene border
@onready var invisible_wall1: CollisionShape2D = $InvisibleBorder/Invisiblewall
@onready var invisible_wall2: CollisionShape2D = $InvisibleBorder/Invisiblewall2
@onready var lightning_border1: Node2D = $InvisibleBorder/Lightning_Emit
@onready var lightning_border2: Node2D = $InvisibleBorder/Lightning_Emit2

@onready var bringer_of_death = get_tree().get_first_node_in_group("Boss")
@onready var hunter = get_tree().get_first_node_in_group("Player")

@onready var boss_theme : AudioStreamPlayer = $BringerOfDeath/BossTheme

const LOOP_POINT = 55.0  # Time (in seconds) where the track should restart

var loop_timer = 0.0  # Track time manually

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the boundary to disabled before engaging the boss
	invisible_wall1.set_deferred("disabled", true)
	invisible_wall2.set_deferred("disabled", true)
	
	if boss_theme and boss_theme.playing:
		boss_theme.finished.connect(_on_boss_theme_finished)

func _process(_delta: float) -> void:
	# Ensure bringer_of_death is not null before checking its state
	if bringer_of_death and is_instance_valid(bringer_of_death):
		if bringer_of_death.get_state_name() == "Chasing":
			activate_boss_battle_arena()
		if bringer_of_death.get_state_name() == "Death":
			disable_boss_battle_arena()

		## Loop the boss theme at the specified time mark
		#if boss_theme and boss_theme.playing:
			#loop_timer += delta  # Track elapsed time
#
			## If the boss theme reaches the end, restart from 54s
			#if loop_timer >= boss_theme.stream.get_length():
				#boss_theme.play(LOOP_POINT)
				#loop_timer = LOOP_POINT  # Reset timer to match the new start position
func activate_boss_battle_arena():
	if invisible_wall1 and invisible_wall2 and lightning_border1 and lightning_border2:
		invisible_wall1.set_deferred("disabled", false)
		invisible_wall2.set_deferred("disabled", false)
		lightning_border1.start_emit()
		lightning_border2.start_emit()

		# Start the boss theme if it's not playing
		if boss_theme and not boss_theme.playing:
			boss_theme.play()

func disable_boss_battle_arena():
	if invisible_wall1 and invisible_wall2 and lightning_border1 and lightning_border2:
		invisible_wall1.set_deferred("disabled", true)
		invisible_wall2.set_deferred("disabled", true)
		lightning_border1.stop_emit()
		lightning_border2.stop_emit()
		lightning_border1.queue_free()
		lightning_border2.queue_free()

		# Stop the boss theme when the boss dies
		if boss_theme and boss_theme.playing:
			boss_theme.stop()

func _on_boss_theme_finished():
	if boss_theme:
		boss_theme.play(LOOP_POINT)  # Restart from 54s when finished
