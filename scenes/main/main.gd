extends Control

const STORY_INTRO_SCENE := preload("res://scenes/story/garden_intro.tscn")
const TOWN_HUB_SCENE := preload("res://scenes/hub/town_hub.tscn")
const STRATEGY_HUB_SCENE := preload("res://scenes/hub/strategy_hub.tscn")
const COUNT_FEEDING_SCENE := preload("res://scenes/games/count_feeding/count_feeding.tscn")
const CARROT_ARITHMETIC_SCENE := preload(
	"res://scenes/games/carrot_arithmetic/carrot_arithmetic.tscn"
)
const MAKE_TEN_SCENE := preload("res://scenes/games/make_ten/make_ten.tscn")
const BREAK_TEN_SCENE := preload("res://scenes/games/break_ten/break_ten.tscn")

var _current_view: Control


func _ready() -> void:
	_show_story_intro()


func _show_story_intro() -> void:
	_clear_current_view()
	var story := STORY_INTRO_SCENE.instantiate()
	_current_view = story
	add_child(story)
	story.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story.finished.connect(_show_town_hub)


func _show_town_hub() -> void:
	_clear_current_view()
	var hub := TOWN_HUB_SCENE.instantiate()
	_current_view = hub
	add_child(hub)
	hub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hub.route_selected.connect(_on_route_selected)
	hub.story_requested.connect(_show_story_intro)
	hub.set_route_available("addition", true)
	hub.set_route_available("subtraction", true)
	hub.set_route_available("ten_frame", true)


func _on_route_selected(route_id: String) -> void:
	if route_id == "count_feeding":
		_show_count_feeding()
	elif route_id == "addition" or route_id == "subtraction":
		_show_arithmetic(route_id)
	elif route_id == "ten_frame":
		_show_strategy_hub()


func _show_strategy_hub() -> void:
	_clear_current_view()
	var hub := STRATEGY_HUB_SCENE.instantiate()
	_current_view = hub
	add_child(hub)
	hub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hub.route_selected.connect(_on_strategy_route_selected)
	hub.back_requested.connect(_show_town_hub)
	hub.set_route_available("make_ten", true)
	hub.set_route_available("break_ten", true)
	hub.set_route_available("flat_ten", false)
	hub.set_route_available("borrow_ten", false)


func _on_strategy_route_selected(route_id: String) -> void:
	if route_id == "make_ten":
		_show_make_ten()
	elif route_id == "break_ten":
		_show_break_ten()


func _show_count_feeding() -> void:
	_clear_current_view()
	var game := COUNT_FEEDING_SCENE.instantiate()
	_current_view = game
	add_child(game)
	if game is Control:
		game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_requested.connect(_show_town_hub)


func _show_arithmetic(selected_operation: String) -> void:
	_clear_current_view()
	var game := CARROT_ARITHMETIC_SCENE.instantiate()
	game.operation = selected_operation
	_current_view = game
	add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_requested.connect(_show_town_hub)


func _show_make_ten() -> void:
	_clear_current_view()
	var game := MAKE_TEN_SCENE.instantiate()
	_current_view = game
	add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_requested.connect(_show_strategy_hub)


func _show_break_ten() -> void:
	_clear_current_view()
	var game := BREAK_TEN_SCENE.instantiate()
	_current_view = game
	add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.exit_requested.connect(_show_strategy_hub)


func _clear_current_view() -> void:
	if _current_view != null and is_instance_valid(_current_view):
		_current_view.queue_free()
		_current_view = null
