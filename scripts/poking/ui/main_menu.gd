extends Node

func _ready() -> void:
	call_deferred("_change_to_main")
xiao
func _change_to_main() -> void:
	get_tree().change_scene_to_file("res://scenes/poking/poking_main.tscn")
