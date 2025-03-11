extends Node2D

@onready var camera_manager: Node2D = $"../CameraManager"

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Notify CameraManager to transition to BossCamera
		camera_manager.transition_to_camera(camera_manager.boss_camera)
