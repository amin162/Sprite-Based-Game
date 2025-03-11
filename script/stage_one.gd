extends Node2D

# Load ability collision related node
@onready var sprint_charge_collision: CollisionShape2D = $BossEngageArea/SprintChargeAttackArea/SprintChargeAttackCollision
@onready var left_ray: RayCast2D = $BossEngageArea/SprintChargeAttackArea/LeftRay
@onready var right_ray: RayCast2D = $BossEngageArea/SprintChargeAttackArea/RightRay
@onready var blink_strike_collision1: CollisionShape2D = $BossEngageArea/BlinkStrikeArea/BlinkStrikeCollision1
@onready var blink_strike_collision2: CollisionShape2D = $BossEngageArea/BlinkStrikeArea/BlinkStrikeCollision2
@onready var blink_strike_collision3: CollisionShape2D = $BossEngageArea/BlinkStrikeArea/BlinkStrikeCollision3
@onready var right_ray_blink: RayCast2D = $BossEngageArea/BlinkStrikeArea/RightRayCastBlink
@onready var left_ray_blink: RayCast2D = $BossEngageArea/BlinkStrikeArea/LeftRayCastBlink
@onready var bottom_ray_blink: RayCast2D = $BossEngageArea/BlinkStrikeArea/BottomRayCastBlink
@onready var lightning_strike_collision1: CollisionShape2D = $BossEngageArea/MagicCastArea/LightningStrikeCastCollisionLeft1
@onready var lightning_strike_collision2: CollisionShape2D = $BossEngageArea/MagicCastArea2/LightningStrikeCastCollisionLeft2
@onready var lightning_left_ray_cast1: RayCast2D = $BossEngageArea/MagicCastArea/LightningCastRayLeft1
@onready var lightning_left_ray_cast2: RayCast2D = $BossEngageArea/MagicCastArea/LightningCastRayLeft2
@onready var fireball_collision1: CollisionShape2D = $BossEngageArea/MagicCastArea/FireBallCastCollisionRight1
@onready var fireball_collision2: CollisionShape2D = $BossEngageArea/MagicCastArea2/FireBallCastCollisionRight2
@onready var fireball_right_ray_cast1: RayCast2D = $BossEngageArea/MagicCastArea/FireBallCastRayRight1
@onready var fireball_right_ray_cast2: RayCast2D = $BossEngageArea/MagicCastArea/FireBallCastRayRight2
@onready var teleport_left1: CollisionShape2D = $BossEngageArea/MagicCastArea/TeleportSpotLeft1
@onready var teleport_left2: CollisionShape2D = $BossEngageArea/MagicCastArea2/TeleportSpotLeft2
@onready var teleport_left3: CollisionShape2D = $BossEngageArea/SprintChargeAttackArea/TeleportSpotLeft3
@onready var teleport_right1: CollisionShape2D = $BossEngageArea/MagicCastArea/TeleportSpotRight1
@onready var teleport_right2: CollisionShape2D = $BossEngageArea/MagicCastArea2/TeleportSpotRight2
@onready var teleport_right3: CollisionShape2D = $BossEngageArea/SprintChargeAttackArea/TeleportSpotRight3

# Load Audio Music Theme
@onready var boss_theme : AudioStreamPlayer = $Boss/AudioStreamPlayer
@onready var restart_timer : Timer = $Boss/RestartSoundTimer
@onready var evil_laugh : AudioStreamPlayer = $Boss/EvilLaugh
var loop_mark : float = 62.00  # Length of the boss theme sound in seconds
#var sound_start_offset : float = 0.2  # Offset to wait before restarting the sound (in seconds)

# Enabled the boss
@onready var engage_area: CollisionShape2D = $BossEngageArea/EngageArea/EngageAreaCollision

# Enabled InvisibleBorder and Lightning scene border
@onready var invisible_wall1: CollisionShape2D = $InvisibleBorder/Invisiblewall
@onready var invisible_wall2: CollisionShape2D = $InvisibleBorder/Invisiblewall2
@onready var lightning_border1: Node2D = $InvisibleBorder/Lightning_Emit
@onready var lightning_border2: Node2D = $InvisibleBorder/Lightning_Emit2
# Reference to the boss node
@onready var boss: Node2D = $Boss 

# Reference to the player
@onready var player: Node2D = $Player  # Adjust to your player's path

# Preload the Lightning Scene
@onready var lightning_strike_scene = preload("res://scene/lightning.tscn")
@onready var lightning_emit_scene = preload("res://scene/lightning_emit.tscn")  # Preload your lightning effect scene
@onready var lightning_spark_scene = preload("res://scene/lightning_spark.tscn")

# Preload the Fire Scene
@onready var fireball_scene = preload("res://scene/fireball.tscn")
@onready var explosion_scene = preload("res://scene/explosion.tscn")
@onready var fire_aura_scene = preload("res://scene/fire_aura.tscn")
@onready var trail_of_fire_scene = preload("res://scene/trail_of_fire.tscn")

#Stage Theme Sound and fade-in and fade-out properties
@onready var stage_theme : AudioStreamPlayer = $StageTheme
var fade_in_duration = 2.0  # Time to fade in (seconds)
var fade_out_duration = 2.0  # Time to fade out (seconds)
var min_volume_db = -80.0  # Lowest possible volume (silence)
var max_volume_db = -15.0  # Target volume level for fade-in (you can adjust this value)

# Cooldown Variables
var cooldown_timer: float = 0.0  # Tracks remaining cooldown time
var lightning_cooldown : float = 1  # Cooldown in seconds
var lightning_cooldown_timer : float = 0.0  # Cooldown in seconds
var fireball_cooldown : float = 0.7 # Cooldown in seconds
var fireball_cooldown_timer : float = 0.0  # Cooldown in seconds
var lightning_barrage_delay : float = 0.4  # Cooldown in seconds
var lightning_barrage_delay_timer : float = 0.0  # Cooldown in seconds
var explosion_barrage_delay : float = 0.4  # Cooldown in seconds
var explosion_barrage_delay_timer : float = 0.0  # Cooldown in seconds
var fireball_barrage_delay : float = 0.4  # Cooldown in seconds
var fireball_barrage_delay_timer : float = 0.0  # Cooldown in seconds

# Array Position Index Variables
var lightning_positions: Array[Vector2] = []   # Holds positions for the barrage
var current_lightning_index: int = 0 # Tracks the current position index in the barrage
var explosion_positions: Array[Vector2] = []   # Holds positions for the barrage
var current_explosion_index: int = 0 # Tracks the current position index in the barrage
var fireball_positions: Array[Vector2] = []   # Holds positions for the barrage
var current_fireball_index: int = 0 # Tracks the current position index in the barrage
var trail_positions:  Array[Vector2] = []
var current_trail_index : int = 0 #
var last_trail_position: Vector2 = Vector2.ZERO

# Ability Scene Variables
var lightning_instance: Node = null  # To hold the lightning instance when created
var lightning_emit_instance: Node2D = null  # To track lightning emit instance
var fireball_instance: CharacterBody2D = null
var fire_aura_instance: Node2D = null  # To track fire aura instance

#A bility track requirements
var melee_count1: int = 0
var melee_count2: int = 0
var melee_count3: int = 0
var previous_state: String = ""
var is_sprint_charge_active = false
var sprint_charge_direction = 0

func _ready():
	#Set the collisions related that trigger the boss
	_disable_sprint_charge_collision()
	_disable_blink_collisions()
	_disable_magic_area_collisions()
	_disable_magic_area_teleport_collisions()
	_disable_rays()
	
	#Set the boundary to disabled before engaging the boss
	invisible_wall1.set_deferred("disabled", true)
	invisible_wall2.set_deferred("disabled", true)
	
	# Start playing the stage theme
	if stage_theme:
		stage_theme.play()
		stage_theme.stream.loop = true  # Ensure the stream is set to loop
	
	# Connect the finished signal to restart the sound
	if boss_theme:
		boss_theme.connect("finished", Callable(self, "_on_boss_theme_finished"))
		boss_theme.stream.loop = true  # Ensure the stream is set to loop

	# Configure the timer
	restart_timer.wait_time = loop_mark
	restart_timer.one_shot = false  # Make the timer repeat
	restart_timer.connect("timeout", Callable(self, "_on_restart_timer_timeout"))

func _process(delta: float) -> void:
	# Re-enable rays only when the boss is in Idle state
	if boss.call("get_current_state_name") == "Idle":
		_enable_rays()
		_disable_sprint_charge_collision()
		_disable_magic_area_collisions()
		_disable_blink_collisions() 
		_disable_magic_area_teleport_collisions()

	# Check if melee count reached 5 during Idle state
	if boss.call("get_current_state_name") == "Idle":
		if melee_count1 == 5:
			_trigger_lightning_barrage_ability()
		elif melee_count2 == 5:
			_trigger_explosion_barrage_ability()
		elif melee_count3 == 5:
			_trigger_sprint_charge_trail_of_fire_ability()

	# Check for state transition into "MeleeAttack"
	if  boss.call("get_current_state_name") == "MeleeAttack" and  boss.call("get_current_state_name") != previous_state:
		# Count for BlinkStrikeCollision1
		melee_count1 = _handle_melee_count(blink_strike_collision1, melee_count1, 6, 1)
		# Count for BlinkStrikeCollision2
		melee_count2 = _handle_melee_count(blink_strike_collision2, melee_count2, 6, 2)
		# Count for BlinkStrikeCollision3
		melee_count3 = _handle_melee_count(blink_strike_collision3, melee_count3, 6, 3)

	# Update the previous state
	previous_state =  boss.call("get_current_state_name")
	
	if boss.call("get_current_state_name") == "Death":
		# Disalbe invisible walls and lightning borders
		if invisible_wall1 and invisible_wall2 and lightning_border1 and lightning_border2:
			invisible_wall1.set_deferred("disabled", true)
			invisible_wall2.set_deferred("disabled", true)
			lightning_border1.stop_emit()
			lightning_border2.stop_emit()
			lightning_border1.queue_free()
			if boss_theme and boss_theme.playing:
				boss_theme.stop()
			lightning_border2.queue_free()
			
		if lightning_emit_instance:
			lightning_emit_instance.call("stop_emit")
			lightning_emit_instance.queue_free()
			lightning_emit_instance = null

		if fire_aura_instance:
			fire_aura_instance.call("stop_emit")
			fire_aura_instance.queue_free()
			fire_aura_instance = null
			
		set_process(false)
	# Process rays to determine boss behavior
	_process_ray_collisions()
	
	# Process ability based on teleport spot and bosses state machine
	if not teleport_left1.disabled or not teleport_right1.disabled or not teleport_left2.disabled or not teleport_right2.disabled or not teleport_left3.disabled or not teleport_right3.disabled:
		if boss.call("get_current_state_name") == "MagicAbility":
			# Handle single lightning mechanics
			if not teleport_left1.disabled:
				if lightning_cooldown_timer > 0:
					lightning_cooldown_timer -= delta  # Decrease cooldown timer
				elif lightning_cooldown_timer <= 0:
					_trigger_lightning()

				# Start lightning emitter
				if not lightning_emit_instance:
					lightning_emit_instance = lightning_emit_scene.instantiate()
					add_child(lightning_emit_instance)
					lightning_emit_instance.global_position = boss.global_position + Vector2(-10, -150)  # Position above boss
					lightning_emit_instance.call("start_emit")

			# Handle lightning barrage mechanics
			if not teleport_left2.disabled:
				if lightning_barrage_delay_timer > 0:
					lightning_barrage_delay_timer -= delta  # Decrease cooldown timer
				elif lightning_barrage_delay_timer <= 0:
					_trigger_lightning_barrage(delta)

				# Start lightning emitter
				if not lightning_emit_instance:
					lightning_emit_instance = lightning_emit_scene.instantiate()
					add_child(lightning_emit_instance)
					lightning_emit_instance.global_position = boss.global_position + Vector2(0, -150)  # Position above boss
					lightning_emit_instance.call("start_emit")

			# Handle fireball mechanics
			if not teleport_right1.disabled:
				if fireball_cooldown_timer > 0:
					fireball_cooldown_timer -= delta  # Decrease cooldown timer
				elif fireball_cooldown_timer <= 0:
					_trigger_fireball()

				# Start Fire Aura
				if not fire_aura_instance:
					fire_aura_instance = fire_aura_scene.instantiate()
					add_child(fire_aura_instance)
					fire_aura_instance.global_position = boss.global_position + Vector2(0, 25)  # Position at the boss
					fire_aura_instance.call("start_emit")
			
			# Handle explosion barrage mechanics
			if not teleport_right2.disabled:
				if fireball_barrage_delay_timer > 0:
					fireball_barrage_delay_timer -= delta  # Decrease cooldown timer
				elif fireball_barrage_delay_timer <= 0:
					_trigger_fireball_barrage(delta)
					
				if explosion_barrage_delay_timer > 0:
					explosion_barrage_delay_timer -= delta  # Decrease cooldown timer
				elif explosion_barrage_delay_timer <= 0:
					_trigger_explosion_barrage(delta)

				# NOTEBOOK: 
				# the _trigger_explosion_barrage and the _trigger_fireball_barrage are being executed at the same time
				# but since the code hierachy made _trigger_explosion_barrage anterior than _trigger_fireball_barrage
				# the rearmost ability MUST call the function boss.call("change_state", "Idle"), because if both ability
				# calling boss.call("change_state", "Idle") inside their function, it will make the ability stop and 
				# turn the boss into an Idle state immediately and execute into another state, you may change the codes hierarchy 
				# for example, you want to put a _trigger_fireball_barrage over _trigger_explosion_barrage, that means
				# you have to put boss.call("change_state", "Idle") commented inside _trigger_fireball_barrage and unccomment boss.call("change_state", "Idle") 
				# inside _trigger_explosion_barrage

				# Start Fire Aura
				if not fire_aura_instance:
					fire_aura_instance = fire_aura_scene.instantiate()
					add_child(fire_aura_instance)
					fire_aura_instance.global_position = boss.global_position + Vector2(0, 25)  # Position at the boss
					fire_aura_instance.call("start_emit")

		if boss.call("get_current_state_name") == "SprintChargeAttack":
			if not teleport_left3.disabled:
				_trigger_sprint_charge_trail_of_fire(delta)
			if not teleport_right3.disabled:
				_trigger_sprint_charge_trail_of_fire(delta)
	else:
		# Cleanup lightning emitter when leaving MagicAbility state
		if lightning_emit_instance:
			lightning_emit_instance.call("stop_emit")
			lightning_emit_instance.queue_free()
			lightning_emit_instance = null

		if fire_aura_instance:
			fire_aura_instance.call("stop_emit")
			fire_aura_instance.queue_free()
			fire_aura_instance = null

func _process_ray_collisions() -> void:
	# Check SprintChargeArea rays
	if left_ray.enabled and left_ray.is_colliding() and left_ray.get_collider().name == "Player":
		_trigger_sprint_charge(left_ray)
	elif right_ray.enabled and right_ray.is_colliding() and right_ray.get_collider().name == "Player":
		_trigger_sprint_charge(right_ray)

	# Check BlinkStrikeArea rays
	if left_ray_blink.enabled and left_ray_blink.is_colliding() and left_ray_blink.get_collider().name == "Player":
		_trigger_blink_strike(left_ray_blink)
	elif right_ray_blink.enabled and right_ray_blink.is_colliding() and right_ray_blink.get_collider().name == "Player":
		_trigger_blink_strike(right_ray_blink)
	elif bottom_ray_blink.enabled and bottom_ray_blink.is_colliding() and bottom_ray_blink.get_collider().name == "Player":
		_trigger_blink_strike(bottom_ray_blink)

	# Check MagicCastArea rays
	if lightning_left_ray_cast1.enabled and lightning_left_ray_cast1.is_colliding() and lightning_left_ray_cast1.get_collider().name == "Player":
		_trigger_lightning_ability(lightning_left_ray_cast1)
	elif lightning_left_ray_cast2.is_colliding() and lightning_left_ray_cast2.get_collider().name == "Player":
		_trigger_lightning_ability(lightning_left_ray_cast2)

	if fireball_right_ray_cast1.enabled and fireball_right_ray_cast1.is_colliding() and fireball_right_ray_cast1.get_collider().name == "Player":
		_trigger_fireball_ability(fireball_right_ray_cast1)
	elif fireball_right_ray_cast2.is_colliding() and fireball_right_ray_cast2.get_collider().name == "Player":
		_trigger_fireball_ability(fireball_right_ray_cast2)

func _trigger_sprint_charge(ray: RayCast2D):
	_enable_sprint_charge_collision()
	_disable_rays()
	boss.call("set_teleport_ray", ray)
	boss.call("change_state", "TeleportIn")

func _trigger_blink_strike(ray: RayCast2D):
	if ray == left_ray_blink:
		blink_strike_collision1.disabled = false
	elif ray == right_ray_blink:
		blink_strike_collision2.disabled = false
	elif ray == bottom_ray_blink:
		blink_strike_collision3.disabled = false
	_disable_rays()
	boss.call("set_teleport_ray", ray)
	boss.call("change_state", "TeleportIn")

func _trigger_lightning_ability(ray):
	if ray == lightning_left_ray_cast1 or ray == lightning_left_ray_cast2:
		lightning_strike_collision1.disabled = false
		teleport_left1.disabled = false
	_disable_rays()
	boss.call("set_teleport_ray", ray)
	boss.call("change_state", "TeleportIn")

func _trigger_fireball_ability(ray):
	if ray == fireball_right_ray_cast1 or ray == fireball_right_ray_cast2:
		fireball_collision1.disabled = false
		teleport_right1.disabled = false
	_disable_rays()
	boss.call("set_teleport_ray", ray)
	boss.call("change_state", "TeleportIn")

func _trigger_lightning_barrage_ability():
	if evil_laugh:
		evil_laugh.play()
	lightning_strike_collision2.disabled = false
	teleport_left2.disabled = false
	_disable_rays()
	boss.call("change_state", "TeleportIn")
	
func _trigger_explosion_barrage_ability():
	if evil_laugh:
		evil_laugh.play()
	fireball_collision2.disabled = false
	teleport_right2.disabled = false
	_disable_rays()
	boss.call("change_state", "TeleportIn")

func _trigger_sprint_charge_trail_of_fire_ability():
	_enable_sprint_charge_collision()
	_disable_rays()
	boss.call("change_state", "TeleportIn")

func _trigger_fireball() -> void:
	# Instantiate the fireball
	var fireball = fireball_scene.instantiate()
	add_child(fireball)

	# Start the fireball's trajectory targeting the player
	fireball.launch_from_sky(player.position)
	
	# Reset the cooldown timer
	fireball_cooldown_timer = fireball_cooldown
	#print("Fireball instantiated at:", fireball_instance.global_position)
	
func _trigger_lightning() -> void:
	# Instantiate the lightning strike
	var lightning = lightning_strike_scene.instantiate()
	add_child(lightning)

	# Get the AnimatedSprite2D node from the lightning instance
	var animated_sprite: AnimatedSprite2D = lightning.get_node("AnimatedSprite2D")
	if animated_sprite:
		# Connect the animation_finished signal to a local handler
		animated_sprite.animation_finished.connect(self._on_lightning_finished)
	else:
		push_error("AnimatedSprite2D node not found in lightning scene")

	# Start the lightning strike at the player's position
	lightning.start_strike(player.position)

	# Reset the cooldown timer
	lightning_cooldown_timer = lightning_cooldown
	
func _trigger_lightning_barrage(delta: float) -> void:
	if current_lightning_index == 0:
		_setup_lightning_positions()  # Ensure positions are updated before the barrage starts

	if current_lightning_index < lightning_positions.size():
		if lightning_barrage_delay_timer > 0:
			lightning_barrage_delay_timer -= delta  # Decrease the delay timer
		elif lightning_barrage_delay_timer <= 0:
			# Instantiate lightning strike at the current position
			var lightning = lightning_strike_scene.instantiate()
			add_child(lightning)
			lightning.start_strike(lightning_positions[current_lightning_index])

			# Check for ground intersections
			var ground_positions = _check_ground_collision(lightning_positions[current_lightning_index])
			if ground_positions:
				for ground_position in ground_positions:
					_create_lightning_spark(ground_position)

			# Move to the next position and reset the delay timer
			current_lightning_index += 1
			lightning_barrage_delay_timer = lightning_barrage_delay
	else:
		# All strikes are done; reset and transition to idle state
		_reset_lightning_barrage()
		boss.call("change_state", "Idle")  # Transition boss to idle state

func _setup_lightning_positions():
	# Set fixed positions based on the area of lightning_strike_collision2
	var collision_shape = lightning_strike_collision2.shape
	if collision_shape:
		var area_width = collision_shape.extents.x * 2
		var num_positions = 12 # Number of lightning strikes
		var start_x = lightning_strike_collision2.global_position.x - (area_width / 1.4)
		var end_x = lightning_strike_collision2.global_position.x + (area_width / 1.4)
		
		lightning_positions.clear()
		for i in range(num_positions):
			var x = lerp(start_x, end_x, float(i) / (num_positions - 1))
			lightning_positions.append(Vector2(x, lightning_strike_collision2.global_position.y))

func _on_lightning_finished():
	# Animation finished logic (optional cleanup or additional actions)
	#print("Lightning animation finished.")
	pass

func _end_lightning_barrage() -> void:
	# Transition the boss to the idle state
	if boss:
		boss.call("change_state", "Idle")

	# Reset variables for the next barrage
	_setup_lightning_positions()  # Prepare for the next usage
	lightning_barrage_delay_timer = 0

func _reset_lightning_barrage() -> void:
	# Reset variables for the next barrage
	current_lightning_index = 0
	lightning_barrage_delay_timer = lightning_barrage_delay
	lightning_positions.clear()  # Clear positions to avoid reuse without setup

#@warning_ignore("shadowed_variable_base_class")
func _check_ground_collision(_position: Vector2) -> Array:
	var ray_start = _position
	var ray_end = _position + Vector2(0, 1000)  # Extend the ray downward
	var detected_positions = []
	var space_state = get_world_2d().direct_space_state
	
	# Reference to the player node
	#var player = get_node("Path/To/Player")  # Update the path to the player node
	
	while true:
		# Set up ray query parameters
		var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		query.collision_mask = 1  # Update to match the ground layer/collision mask
		query.exclude = [player]  # Exclude the player node from collisions
		
		var collision = space_state.intersect_ray(query)
		
		# Check if the ray hit something
		if collision.has("position"):
			var collision_position = collision["position"]
			
			# If this position is not already detected, add it
			if not detected_positions.has(collision_position):
				detected_positions.append(collision_position)
			
			# Update the ray_start to continue searching below the current collision
			ray_start = collision_position + Vector2(0, 50)  # Slight offset to avoid re-detection
		else:
			# No more collisions
			break
	
	return detected_positions

#@warning_ignore("shadowed_variable_base_class")
func _create_lightning_spark(_position) -> void:
	var lightning_spark = lightning_spark_scene.instantiate()
	add_child(lightning_spark)
	lightning_spark.global_position = _position
	lightning_spark.start_spark(false)  # Assuming a method in the spark script to handle behavior

func _trigger_explosion_barrage(delta: float) -> void:
	if current_explosion_index == 0:
		_setup_explosion_positions()  # Ensure positions are updated before the barrage starts
	
	if current_explosion_index < explosion_positions.size():
		if explosion_barrage_delay_timer > 0:
			explosion_barrage_delay_timer -= delta  # Decrease the delay timer
		elif explosion_barrage_delay_timer <= 0:
			# Check for ground intersections
			var ground_positions = _check_ground_collision(explosion_positions[current_explosion_index])
			if ground_positions:
				for ground_position in ground_positions:
					_create_explosion(ground_position)

			# Move to the next position and reset the delay timer
			current_explosion_index += 1
			explosion_barrage_delay_timer = explosion_barrage_delay

	else:
		# All strikes are done; reset and transition to idle state
		_reset_explosion_barrage()
		#boss.call("change_state", "Idle")  # Transition boss to idle state

func _setup_explosion_positions():
	# Set fixed positions based on the area of fireball_collision2
	var collision_shape = fireball_collision2.shape
	if collision_shape:
		var area_width = collision_shape.extents.x * 2
		var num_positions = 12 # Number of lightning strikes
		var start_x = fireball_collision2.global_position.x + (area_width / 1.4)
		var end_x = fireball_collision2.global_position.x - (area_width / 1.4)

		explosion_positions.clear()
		for i in range(num_positions):
			var x = lerp(start_x, end_x, float(i) / (num_positions - 1))
			explosion_positions.append(Vector2(x, fireball_collision2.global_position.y))

#@warning_ignore("shadowed_variable_base_class")
func _create_explosion(_position) -> void:
	var explosion = explosion_scene.instantiate()
	add_child(explosion)
	explosion.global_position = _position
	explosion.start_explode()  # Assuming a method in the spark script to handle behavior
	
func _reset_explosion_barrage() -> void:
	# Reset variables for the next barrage
	current_explosion_index = 0
	explosion_barrage_delay_timer = explosion_barrage_delay
	explosion_positions.clear()  # Clear positions to avoid reuse without setup

func _trigger_fireball_barrage(delta: float) -> void:
	if current_fireball_index == 0:
		_setup_fireball_positions()  # Ensure positions are updated before the barrage starts
	
	if current_fireball_index < fireball_positions.size():
		if fireball_barrage_delay_timer > 0:
			fireball_barrage_delay_timer -= delta  # Decrease the delay timer
		elif fireball_barrage_delay_timer <= 0:
			 #Instantiate fireball at the current position
			var fireball = fireball_scene.instantiate()
			add_child(fireball)
			fireball.launch_from_sky(fireball_positions[current_fireball_index])

			# Move to the next position and reset the delay timer
			current_fireball_index += 1
			fireball_barrage_delay_timer = fireball_barrage_delay

	else:
		# All strikes are done; reset and transition to idle state
		_reset_fireball_barrage()
		boss.call("change_state", "Idle")  # Transition boss to idle state

func _setup_fireball_positions():
	# Set fixed positions based on the area of fireball_collision2
	var collision_shape = fireball_collision2.shape
	if collision_shape:
		var area_width = collision_shape.extents.x * 2
		var num_positions = 12 # Number of lightning strikes
		var start_x = fireball_collision2.global_position.x - (area_width / 1.4)
		var end_x = fireball_collision2.global_position.x + (area_width / 1.4)

		explosion_positions.clear()
		for i in range(num_positions):
			var x = lerp(start_x, end_x, float(i) / (num_positions - 1))
			fireball_positions.append(Vector2(x, fireball_collision2.global_position.y))

func _reset_fireball_barrage() -> void:
	# Reset variables for the next barrage
	current_fireball_index = 0
	fireball_barrage_delay_timer = fireball_barrage_delay
	fireball_positions.clear()  # Clear positions to avoid reuse without setup

func _trigger_sprint_charge_trail_of_fire(delta: float) -> void:
	# Calculate trail position behind the boss
	var trail_position = boss.global_position - Vector2(sprint_charge_direction * boss.velocity.x * delta, 0)

	# Ensure there's a significant distance between trails to avoid overlap
	if last_trail_position.distance_to(trail_position) > 40:  # Adjust threshold as needed
		last_trail_position = trail_position

		# Check for ground collisions to spawn fire
		var ground_positions = _check_ground_collision(trail_position)
		if ground_positions:
			for ground_position in ground_positions:
				_create_fire_trail(ground_position)

func start_sprint_charge_trail(direction: int, start_position: Vector2) -> void:
	is_sprint_charge_active = true
	sprint_charge_direction = direction
	last_trail_position = start_position

func end_sprint_charge_trail() -> void:
	is_sprint_charge_active = false
	sprint_charge_direction = 0

func _create_fire_trail(_position: Vector2) -> void:
	var fire_trail = trail_of_fire_scene.instantiate()
	add_child(fire_trail)
	fire_trail.global_position = _position
	fire_trail.start_fire(false)  # Assuming a method in the fire trail script

func _reset_trail() -> void:
	trail_positions.clear()
	current_trail_index = 0

func _handle_melee_count(collision_node: CollisionShape2D, current_count: int, reset_threshold: int, collision_index: int) -> int:
	# Check if the collision is not disabled
	if not collision_node.disabled:
		current_count += 1
		print("Melee Count for BlinkStrikeCollision", collision_index, ": ", current_count)

		# Check if count has reached the threshold
		if current_count >= reset_threshold:
			print("Melee Count for BlinkStrikeCollision", collision_index, "reached", reset_threshold, ". Triggering ability and resetting count.")
			current_count = 0

	return current_count

func reset_melee_count1() -> void:
	melee_count1 = 0
	print("Melee Count for BlinkStrikeCollision1 reset.")

func reset_melee_count2() -> void:
	melee_count2 = 0
	print("Melee Count for BlinkStrikeCollision2 reset.")
	
func reset_melee_count3() -> void:
	melee_count3 = 0
	print("Melee Count for BlinkStrikeCollision3 reset.")

func _enable_sprint_charge_collision():
	sprint_charge_collision.disabled = false

func _disable_sprint_charge_collision():
	sprint_charge_collision.call_deferred("set_disabled", true)

func _disable_magic_area_teleport_collisions():
	teleport_left1.disabled = true
	teleport_left2.disabled = true
	teleport_left3.disabled = true
	teleport_right1.disabled = true
	teleport_right2.disabled = true
	teleport_right3.disabled = true

func _disable_blink_collisions():
	blink_strike_collision1.disabled = true
	blink_strike_collision2.disabled = true
	blink_strike_collision3.disabled = true

func _disable_magic_area_collisions():
	lightning_strike_collision1.disabled = true
	lightning_strike_collision2.disabled = true
	fireball_collision1.disabled = true
	fireball_collision2.disabled = true

func _disable_rays():
	left_ray.enabled = false
	right_ray.enabled = false
	left_ray_blink.enabled = false
	right_ray_blink.enabled = false
	bottom_ray_blink.enabled = false
	lightning_left_ray_cast1.enabled = false
	lightning_left_ray_cast2.enabled = false
	fireball_right_ray_cast1.enabled = false
	fireball_right_ray_cast2.enabled = false

func _enable_rays():
	left_ray.enabled = true
	right_ray.enabled = true
	left_ray_blink.enabled = true
	right_ray_blink.enabled = true
	bottom_ray_blink.enabled = true
	lightning_left_ray_cast1.enabled = true
	lightning_left_ray_cast2.enabled = true
	fireball_right_ray_cast1.enabled = true
	fireball_right_ray_cast2.enabled = true

# Fade-in function
func fade_in_music():
	var _tween = get_tree().create_tween()  # Create a new tween instance
	_tween.tween_property(stage_theme, "volume_db", max_volume_db, fade_in_duration)

# Fade-out function (can be called when the game is ending)
func fade_out_music():
	var _tween = get_tree().create_tween()  # Create a new tween instance
	_tween.tween_property(stage_theme, "volume_db", min_volume_db, fade_out_duration)

# This can be used for looping (if you want to fade out and fade in again)
func _on_game_end():
	# Fade out the music when the game is about to end
	fade_out_music()

	# After fade out is complete, you can trigger fade-in again or do something else (e.g., restart the game)
	await get_tree().create_timer(fade_out_duration).timeout
	fade_in_music()

func _on_magic_cast_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		_disable_rays()

func _on_magic_cast_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		boss.call("change_state", "Idle")
		call_deferred("_disable_magic_area_teleport_collisions")

func _on_engage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Player entered engage area!")

		# Start playing the music when the player enters the area
		if boss_theme and not boss_theme.playing:
			boss_theme.play()  # Start playing the music
			restart_timer.start()  # Start the timer to loop the sound at the 60-second mark
		else:
			print("Music already playing.")

		# Disable engage area
		if engage_area:
			engage_area.set_deferred("disabled", true)  # Disable monitoring to prevent retriggering
		else:
			print("Error: engage_area is null!")

		# Enable invisible walls and lightning borders
		if invisible_wall1 and invisible_wall2 and lightning_border1 and lightning_border2:
			invisible_wall1.set_deferred("disabled", false)
			invisible_wall2.set_deferred("disabled", false)
			lightning_border1.start_emit()
			lightning_border2.start_emit()
		_enable_rays()

func _on_stage_theme_stop_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Stage theme sound stopping...")
		
		var _tween = get_tree().create_tween()
		_tween.tween_property(stage_theme, "volume_db", -80, 6.0)  # Fade out over 6 seconds
		
		await _tween.finished  # Wait until the fade-out completes
		stage_theme.stop()  # Stop the music

func _on_boss_theme_finished():
	print("Boss theme finished, restarting sound.")
	boss_theme.play()  # Restart the sound seamlessly

func _on_restart_timer_timeout():
	print("60-second mark reached, restarting sound.")
	boss_theme.stop()  # Stop the current sound
	boss_theme.play()  # Restart the sound from the beginning
