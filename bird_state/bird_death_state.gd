extends BirdBaseState

var state_name = "Death"

func enter(bird):
	bird.is_dead = true  # Mark enemy as dead
	bird.bird_sprite.rotation_degrees = 180  # Flip the bird sprite upside down
	bird.bird_sprite.play("death")  # Assuming you have a death animation
	#bird.gravity_scale = 1.0  # Apply gravity effect
	bird.velocity = Vector2.ZERO  # Stop horizontal movement

func update(bird, delta):
	bird.velocity.y += bird.GRAVITY * delta  # Apply gravity to simulate falling
	bird.attack_area.disabled = true  # Ensure attack area is disabled
	bird.move_and_slide()
