extends BossBaseState

var state_name = "MagicAbility"

func enter(boss):
	boss.boss_sprite.play("Magic_Charge_Attack")

func update(boss, _delta):
	if not boss.boss_sprite.is_playing():
		boss.change_state("Idle")
	pass

func exit(boss):
	var magic_cast_area = boss.get_parent().get_node_or_null("BossEngageArea/MagicCastArea")
	if magic_cast_area:
		var collision_shape1 = magic_cast_area.get_node_or_null("LightningCastCollisionLeft1")
		var collision_shape2 = magic_cast_area.get_node_or_null("FireballCastCollisionRight1")
		var collision_shape3 = magic_cast_area.get_node_or_null("LightningCastCollisionLeft2")
		var collision_shape4 = magic_cast_area.get_node_or_null("FireballCastCollisionRight2")
		if collision_shape1 and collision_shape1 is CollisionShape2D:
			collision_shape1.disabled = false  # Disable the collision area
		if collision_shape2 and collision_shape2 is CollisionShape2D:
			collision_shape2.disabled = false  # Disable the collision area
		if collision_shape3 and collision_shape3 is CollisionShape2D:
			collision_shape3.disabled = false  # Disable the collision area
		if collision_shape4 and collision_shape4 is CollisionShape2D:
			collision_shape4.disabled = false  # Disable the collision area
