extends RigidBody2D

@export var base_speed: float = 500  
@export var base_damage: int = 15  

@onready var physics_body: CollisionShape2D = $PhysicsBody
@onready var lifetime_timer: Timer = $LifeTimer  
@onready var charge_arrow: AnimatedSprite2D = $ChargeArrow  
@onready var arrow_sprite: Sprite2D = $ArrowSprite  
@onready var explosion_sound: AudioStreamPlayer2D = $Explosion
@onready var enemy = get_tree().get_first_node_in_group("Enemy")
@onready var boss = get_tree().get_first_node_in_group("Boss")

#var enemy: Node2D = null  # To store reference to the enemy when detected
var direction: Vector2 = Vector2.RIGHT  
var speed: float = base_speed
var damage: int = base_damage
var charge_level: String = "none"
var exploded: bool = false  
var last_collision_position: Vector2 = Vector2.ZERO

func _ready():
	# Enable contact monitoring in code for Godot 4
	contact_monitor = true
	max_contacts_reported = 1
	
	# Set base speed and damage
	speed = base_speed
	damage = base_damage

	# Default arrow visibility
	arrow_sprite.visible = true  
	charge_arrow.visible = false  

	# Apply charge effects if necessary
	match charge_level:
		"moderate":
			speed *= 1.1  
			damage *= 2  
			_set_charge_arrow(Color(0.7, 0.7, 1.5, 1.0))  
		"max":
			speed *= 1.5  
			damage *= 3  
			charge_arrow.scale *= 1.5
			physics_body.scale *= 1.5
			_set_charge_arrow(Color(1.2, 1.2, 1.2, 1.0))  
		_:
			_reset_charge_arrow()  # Regular arrow

	linear_velocity = direction * speed  # Apply movement

func initialize(dir: int, rotation_value: float, _charge_level: String):
	direction = Vector2(dir, 0).normalized()  
	rotation_degrees = rotation_value
	charge_level = _charge_level

func _set_charge_arrow(color: Color):
	charge_arrow.visible = true  
	charge_arrow.self_modulate = color  # Apply color tint
	charge_arrow.frame = 0  
	charge_arrow.play("charge_arrow")  

func _reset_charge_arrow():
	charge_arrow.visible = false  
	charge_arrow.stop()  
	charge_arrow.frame = 0  

func _physics_process(delta):
	if exploded:
		linear_velocity = Vector2.ZERO  
		return  

	var collision = move_and_collide(linear_velocity * delta)  
	if collision:
		last_collision_position = collision.get_position()
		_handle_collision()

func _handle_collision():
	if exploded:
		return  

	var impact_force = linear_velocity.length()

	# If charged arrow collides, trigger explosion
	if charge_level in ["moderate", "max"]:
		last_collision_position = global_position
		_trigger_explosion()
		return

	# If impact is weak or projectile slows down, stop and remove after a short delay
	if impact_force < 10:  
		linear_velocity = Vector2.ZERO
		await get_tree().create_timer(0.5).timeout
		queue_free()

func _on_lifetime_timer_timeout():
	queue_free()

func _trigger_explosion():
	exploded = true  
	arrow_sprite.visible = false  
	charge_arrow.visible = true  

	# Keep charge arrow at impact position
	global_position = last_collision_position

	# Ensure explosion animation plays at the correct position
	charge_arrow.global_position = global_position

	# Ensure the explosion faces the correct direction
	charge_arrow.scale.y = abs(charge_arrow.scale.y)
	if direction.x < 0:
		charge_arrow.scale.y *= -1
		charge_arrow.rotation_degrees -= 180
	
	charge_arrow.play("explosion")
	charge_arrow.rotation_degrees -= 90
	
	if explosion_sound:
		explosion_sound.play()

	# Apply area-of-effect damage
	var space_state = get_world_2d().direct_space_state
	var explosion_radius = 50
	var explosion_area = CircleShape2D.new()
	explosion_area.radius = explosion_radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = explosion_area
	query.transform = Transform2D.IDENTITY.translated(global_position)
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if (body.is_in_group("Enemy") or body.is_in_group("Boss")) and body.has_method("apply_damage"):
			print("Explosion damage applied to: ", body.name, " for damage: ", damage)
			body.apply_damage(damage)

	# Stop movement and disable physics
	linear_velocity = Vector2.ZERO  
	physics_body.call_deferred("set_disabled", true)
	set_deferred("freeze", true)  

	# Wait for the explosion animation to finish before removing
	await charge_arrow.animation_finished
	queue_free()


func _on_body_entered(body: Node) -> void:
	if (body.is_in_group("Enemy") or body.is_in_group("Boss")) and body.has_method("apply_damage"):
		#print("Arrow hit enemy: ", body.name, " with damage: ", damage)
		body.apply_damage(damage)
		enemy = body
		
		# Defer disabling the collision shape to avoid modifying physics state during flush
		physics_body.call_deferred("set_disabled", true)
		
		# Stop arrow movement
		linear_velocity = Vector2.ZERO
		gravity_scale = 0
		# Remove the arrow from its current parent in a deferred way
		var current_parent = get_parent()
		if current_parent:
			current_parent.call_deferred("remove_child", self)
		
		# Wait a short moment to ensure the removal is processed
		await get_tree().create_timer(0.1).timeout
		
		# Reparent the arrow to the enemy so it sticks
		body.add_child(self)
		
		# Optionally adjust the arrow's position relative to the enemy
		global_position = last_collision_position

		# Freeze the arrow to prevent rotation (change its mode to static)
		angular_velocity = 0
		rotation = rotation  # optionally, lock to the current rotation

		# If the arrow is a charge shot, explode after sticking
		#if charge_level in ["moderate", "max"]:
			##await get_tree().create_timer(0.5).timeout  # Small delay before exploding
			#_trigger_explosion()
		#else:
			# Wait before removing the normal arrow
		await get_tree().create_timer(2).timeout
		queue_free()
