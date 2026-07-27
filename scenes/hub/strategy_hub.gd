extends Control

signal route_selected(route_id: String)
signal back_requested

const MAKE_TEN_ICON := preload("res://assets/art/hub/make_ten.png")
const BREAK_TEN_ICON := preload("res://assets/art/hub/break_ten.png")
const FLAT_TEN_ICON := preload("res://assets/art/hub/flat_ten.png")
const BORROW_TEN_ICON := preload("res://assets/art/hub/borrow_ten.png")

var _route_buttons: Dictionary = {}


func _ready() -> void:
	_build_ui()
	AudioManager.play_prompt("hub.choose_game", "想玩哪一个？点一张大卡片开始吧！")


func set_route_available(route_id: String, available: bool) -> void:
	var button := _route_buttons.get(route_id) as Button
	if button == null:
		return
	button.disabled = not available
	button.modulate = Color.WHITE if available else Color(0.72, 0.77, 0.74, 0.82)


func _build_ui() -> void:
	var backdrop := TownBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 38)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_right", 38)
	outer.add_theme_constant_override("margin_bottom", 28)
	add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	outer.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 78)
	header.add_theme_constant_override("separation", 14)
	page.add_child(header)

	var back_button := Button.new()
	back_button.text = "←"
	back_button.tooltip_text = "回到萌宠小镇"
	back_button.custom_minimum_size = Vector2(70, 62)
	back_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(back_button, Color("#FFF2D4"), Color("#FFF9E7"), Color("#E4C98E"))
	back_button.pressed.connect(back_requested.emit)
	header.add_child(back_button)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_column)
	title_column.add_child(_make_label("十格策略营·选一条路", 31, UIStyles.INK, false))
	title_column.add_child(_make_label("每一关都把算式变成看得见的胡萝卜", 19, Color("#668071"), false))

	var replay_button := Button.new()
	replay_button.text = "▶"
	replay_button.tooltip_text = "重播提示"
	replay_button.custom_minimum_size = Vector2(76, 64)
	replay_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(replay_button, Color("#67B7D4"), Color("#7DC8E2"), Color("#4594B2"))
	replay_button.pressed.connect(
		AudioManager.play_prompt.bind("hub.choose_game", "想玩哪一个？点一张大卡片开始吧！")
	)
	header.add_child(replay_button)

	var cards := GridContainer.new()
	cards.columns = 4
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 16)
	page.add_child(cards)

	_add_route_card(
		cards, "make_ten", MAKE_TEN_ICON, "＋10", "凑十小桥",
		"先补成十，再加剩下的", Color("#8CBF92")
	)
	_add_route_card(
		cards, "break_ten", BREAK_TEN_ICON, "10−", "破十山洞",
		"先从十里减，再把剩下的合起来", Color("#75B9D8")
	)
	_add_route_card(
		cards, "flat_ten", FLAT_TEN_ICON, "→10", "平十阶梯",
		"先减到十，再减剩下的", Color("#E0A66D")
	)
	_add_route_card(
		cards, "borrow_ten", BORROW_TEN_ICON, "借10", "借十挑战",
		"更难的减法挑战，稍后开放", Color("#B69AD2")
	)

	var hint := _make_label("亮色卡片可以出发，灰色卡片还在建设中。", 18, Color("#6B806F"))
	hint.custom_minimum_size = Vector2(0, 30)
	page.add_child(hint)


func _add_route_card(
	parent: GridContainer,
	route_id: String,
	icon: Texture2D,
	symbol: String,
	title: String,
	description: String,
	color: Color
) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(280, 500)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	UIStyles.apply_button(button, color, color.lightened(0.08), color.darkened(0.13))
	UIStyles.apply_card_motion(button)
	button.pressed.connect(route_selected.emit.bind(route_id))
	parent.add_child(button)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 18)
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	var icon_view := TextureRect.new()
	icon_view.texture = icon
	icon_view.custom_minimum_size = Vector2(0, 210)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_view)
	content.add_child(_make_label(symbol, 31, Color.WHITE))
	content.add_child(_make_label(title, 27, Color.WHITE))
	var description_label := _make_label(description, 19, Color(1, 1, 1, 0.94))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 72)
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
