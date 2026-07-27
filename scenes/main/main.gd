extends Control

const COUNT_FEEDING_SCENE := preload("res://scenes/games/count_feeding/count_feeding.tscn")


func _ready() -> void:
	var game := COUNT_FEEDING_SCENE.instantiate()
	add_child(game)
	if game is Control:
		game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

