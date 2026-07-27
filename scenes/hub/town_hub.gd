extends Control

signal route_selected(route_id: String)
signal story_requested

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
		"1  2  3",
		"数数配餐",
		"数一数，放进一样多的胡萝卜",
		Color("#F5B76E")
	)
	_add_route_card(
		cards,
		"addition",
		"2 + 3",
		"合起来",
		"两篮胡萝卜合在一起",
		Color("#74C79A")
	)
	_add_route_card(
		cards,
		"subtraction",
		"5 − 2",
		"拿走了",
		"看看篮子里还剩几个",
		Color("#77B9DA")
	)
	_add_route_card(
		cards,
		"ten_frame",
		"10",
		"十格魔法",
		"凑十、破十、平十和借十",
		Color("#B99AD8")
	)

	var hint := _make_label("浅色卡片正在建设中，很快就能去玩啦！", 18, Color("#6B806F"))
	hint.custom_minimum_size = Vector2(0, 32)
	page.add_child(hint)


func _add_route_card(
	parent: GridContainer,
	route_id: String,
	equation: String,
	title: String,
	description: String,
	color: Color
) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(280, 505)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "%s\n\n%s\n\n%s" % [equation, title, description]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 25)
	UIStyles.apply_button(button, color, color.lightened(0.08), color.darkened(0.13))
	button.pressed.connect(route_selected.emit.bind(route_id))
	parent.add_child(button)
	_route_buttons[route_id] = button


func _make_label(text_value: String, font_size: int, color: Color, centered: bool = true) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.75))
	label.add_theme_constant_override("outline_size", 2)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
