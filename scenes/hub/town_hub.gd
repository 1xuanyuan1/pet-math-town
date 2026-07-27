extends Control

signal route_selected(route_id: String)
signal story_requested

const COUNTING_ICON := preload("res://assets/art/hub/counting.png")
const ADDITION_ICON := preload("res://assets/art/hub/addition.png")
const SUBTRACTION_ICON := preload("res://assets/art/hub/subtraction.png")
const MAKE_TEN_ICON := preload("res://assets/art/hub/make_ten.png")

var _route_buttons: Dictionary = {}


func _ready() -> void:
	_build_ui()
	AudioManager.play_prompt("hub.choose_game", "想玩哪一个？点一张大卡片开始吧！")


func set_route_available(route_id: String, available: bool) -> void:
	var button := _route_buttons.get(route_id) as Button
	if button == null:
		return
	button.disabled = not available
	button.modulate = Color.WHITE if available else Color(0.80, 0.83, 0.80, 0.85)


func _build_ui() -> void:
	var backdrop := TownBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 38)
	outer.add_theme_constant_override("margin_top", 26)
	outer.add_theme_constant_override("margin_right", 38)
	outer.add_theme_constant_override("margin_bottom", 30)
	add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	outer.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 76)
	header.add_theme_constant_override("separation", 14)
	page.add_child(header)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_column)
	var title := _make_label("萌宠小镇·今天去哪里？", 32, UIStyles.INK, false)
	title_column.add_child(title)
	var subtitle := _make_label("每张大卡片都是一个数学小冒险", 20, Color("#668071"), false)
	title_column.add_child(subtitle)

	var story_button := Button.new()
	story_button.text = "▶"
	story_button.tooltip_text = "再听一次小镇故事"
	story_button.custom_minimum_size = Vector2(76, 64)
	story_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(
		story_button,
		Color("#67B7D4"),
		Color("#7DC8E2"),
		Color("#4594B2")
	)
	story_button.pressed.connect(story_requested.emit)
	header.add_child(story_button)

	var cards := GridContainer.new()
	cards.columns = 4
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 16)
	page.add_child(cards)

	_add_route_card(
		cards,
		"count_feeding",
		COUNTING_ICON,
		"1  2  3",
		"数数配餐",
		"数一数，放进一样多的胡萝卜",
		Color("#F5B76E")
	)
	_add_route_card(
		cards,
		"addition",
		ADDITION_ICON,
		"＋",
		"合起来",
		"两篮胡萝卜合在一起",
		Color("#74C79A")
	)
	_add_route_card(
		cards,
		"subtraction",
		SUBTRACTION_ICON,
		"−",
		"拿走了",
		"看看篮子里还剩几个",
		Color("#77B9DA")
	)
	_add_route_card(
		cards,
		"ten_frame",
		MAKE_TEN_ICON,
		"8 + 5",
		"凑十小桥",
		"先补满十格，再加剩下的",
		Color("#B99AD8")
	)

	var hint := _make_label("点一张图画卡片就出发，右上角可以重播语音。", 18, Color("#6B806F"))
	hint.custom_minimum_size = Vector2(0, 32)
	page.add_child(hint)


func _add_route_card(
	parent: GridContainer,
	route_id: String,
	icon: Texture2D,
	equation: String,
	title: String,
	description: String,
	color: Color
) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(280, 505)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	UIStyles.apply_button(button, color, color.lightened(0.08), color.darkened(0.13))
	button.pressed.connect(route_selected.emit.bind(route_id))
	parent.add_child(button)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	var icon_view := TextureRect.new()
	icon_view.texture = icon
	icon_view.custom_minimum_size = Vector2(0, 215)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_view)

	var equation_label := _make_label(equation, 31, Color.WHITE)
	content.add_child(equation_label)
	var title_label := _make_label(title, 27, Color.WHITE)
	content.add_child(title_label)
	var description_label := _make_label(description, 20, Color(1, 1, 1, 0.94))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 68)
	content.add_child(description_label)
	_route_buttons[route_id] = button


func _make_label(text_value: String, font_size: int, color: Color, centered: bool = true) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.75))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
