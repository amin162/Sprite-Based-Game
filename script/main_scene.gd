extends Node

var stage_one = "res://scene/starting_level.tscn"  # Change this to your desired scene
var stage_two = "res://scene/stage_two.tscn"  # Change this to your desired scene

func _ready():
	call_deferred("_change_scene")

func _change_scene():
	get_tree().change_scene_to_file(stage_one)
