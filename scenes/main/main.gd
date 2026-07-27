extends Control

const STORY_INTRO_SCENE := preload("res://scenes/story/garden_intro.tscn")
const COUNT_FEEDING_SCENE := preload("res://scenes/games/count_feeding/count_feeding.tscn")

var _current_view: Control


func _ready() -> void:
	_show_story_intro()


func _show_story_intro() -> void:
	_clear_current_view()
	var story := STORY_INTRO_SCENE.instantiate()
	_current_view = story
	add_child(story)
	story.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story.finished.connect(_show_count_feeding)


func _show_count_feeding() -> void:
	_clear_current_view()
	var game := COUNT_FEEDING_SCENE.instantiate()
	_current_view = game
	add_child(game)
	if game is Control:
		game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _clear_current_view() -> void:
	if _current_view != null and is_instance_valid(_current_view):
		_current_view.queue_free()
		_current_view = null
