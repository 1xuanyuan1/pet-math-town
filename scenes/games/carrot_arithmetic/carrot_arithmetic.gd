extends Control

signal exit_requested

@export_enum("addition", "subtraction") var operation := "addition"

var _config: Dictionary = {}
var _questions: Array[Dictionary] = []
var _round_index := 0
var _round_locked := false

var _title_label: Label
var _progress_dots: ProgressDots
var _equation_label: Label
var _left_title: Label
var _right_title: Label
var _left_grid: GridContainer
var _right_grid: GridContainer
var _feedback_label: Label
var _answer_row: HBoxContainer
var _replay_button: Button
var _session_overlay: Control


func _ready() -> void:
	_config = ContentRepository.get_arithmetic_config()
	_build_ui()
	_start_session()


func _build_ui() -> void:
	var backdrop := TownBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 26)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_right", 26)
	outer.add_theme_constant_override("margin_bottom", 20)
	add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	outer.add_child(page)

	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 58)
	top_bar.add_theme_constant_override("separation", 12)
	page.add_child(top_bar)

	var back_button := Button.new()
	back_button.text = "←"
	back_button.tooltip_text = "回到萌宠小镇"
	back_button.custom_minimum_size = Vector2(70, 58)
	back_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(back_button, Color("#FFF2D4"), Color("#FFF9E7"), Color("#E4C98E"))
	back_button.pressed.connect(_request_exit)
	top_bar.add_child(back_button)

	_title_label = _make_label("", 29, UIStyles.INK, false)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_title_label)

	_progress_dots = ProgressDots.new()
	_progress_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_progress_dots)

	_replay_button = Button.new()
	_replay_button.text = "▶"
	_replay_button.tooltip_text = "重播题目"
	_replay_button.custom_minimum_size = Vector2(74, 58)
	_replay_button.add_theme_font_size_override("font_size", 28)
	UIStyles.apply_button(_replay_button, Color("#66B9DC"), Color("#7BC9E8"), Color("#4696BA"))
	_replay_button.pressed.connect(_play_question_prompt)
	top_bar.add_child(_replay_button)

	var visual_row := HBoxContainer.new()
	visual_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_row.add_theme_constant_override("separation", 16)
	page.add_child(visual_row)

	var left_panel_data := _make_group_panel(Color("#FFF4D9"))
	visual_row.add_child(left_panel_data["panel"])
	_left_title = left_panel_data["title"]
	_left_grid = left_panel_data["grid"]

	var sign_column := VBoxContainer.new()
	sign_column.custom_minimum_size = Vector2(175, 0)
	sign_column.alignment = BoxContainer.ALIGNMENT_CENTER
	visual_row.add_child(sign_column)
	_equation_label = _make_label("2 + 3 = ?", 52, Color("#D87545"))
	_equation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign_column.add_child(_equation_label)
	_feedback_label = _make_label("看一看，数一数", 21, UIStyles.INK)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign_column.add_child(_feedback_label)

	var right_panel_data := _make_group_panel(Color("#E9F7FF"))
	visual_row.add_child(right_panel_data["panel"])
	_right_title = right_panel_data["title"]
	_right_grid = right_panel_data["grid"]

	_answer_row = HBoxContainer.new()
	_answer_row.custom_minimum_size = Vector2(0, 154)
	_answer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_answer_row.add_theme_constant_override("separation", 22)
	page.add_child(_answer_row)


func _make_group_panel(color: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UIStyles.rounded_box(color, 28, Color.WHITE, 4))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := _make_label("原来有", 25, UIStyles.INK)
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	return {"panel": panel, "title": title, "grid": grid}


func _start_session() -> void:
	if _config.is_empty():
		_feedback_label.text = "加减法内容暂时走丢了"
		return
	var session: Dictionary = _config.get("session", {})
	var seed_offset := 137 if operation == "addition" else 271
	_questions = ArithmeticQuestionGenerator.generate_sequence(
		operation,
		int(session.get("round_count", 5)),
		int(session.get("maximum_result", 10)),
		ProgressStore.session_seed() + seed_offset
	)
	_round_index = 0
	_progress_dots.round_count = _questions.size()
	_progress_dots.completed = 0
	_title_label.text = "萌宠小镇 · %s" % ("合起来" if operation == "addition" else "拿走了")
	_begin_round()


func _begin_round() -> void:
	_round_locked = false
	var question := _current_question()
	var left := int(question.get("left", 0))
	var right := int(question.get("right", 0))
	_left_title.text = "原来有 %d 个" % left
	_right_title.text = ("又来了 %d 个" if operation == "addition" else "拿走 %d 个") % right
	_equation_label.text = "%d %s %d = ?" % [left, "+" if operation == "addition" else "−", right]
	_feedback_label.text = "合在一起数一数" if operation == "addition" else "看看还剩几个"
	_feedback_label.add_theme_color_override("font_color", UIStyles.INK)
	_fill_carrots(_left_grid, left, false)
	_fill_carrots(_right_grid, right, operation == "subtraction")
	_build_answer_buttons(question)
	call_deferred("_play_question_prompt")


func _fill_carrots(grid: GridContainer, count: int, faded: bool) -> void:
	for child in grid.get_children():
		child.queue_free()
	for _index in range(count):
		var carrot := CarrotButton.new()
		carrot.compact = true
		carrot.disabled = true
		carrot.focus_mode = Control.FOCUS_NONE
		carrot.removed = faded
		grid.add_child(carrot)


func _build_answer_buttons(question: Dictionary) -> void:
	for child in _answer_row.get_children():
		child.queue_free()
	var maximum := int(_config.get("session", {}).get("maximum_result", 10))
	var choices := ArithmeticQuestionGenerator.answer_choices(
		question,
		maximum,
		ProgressStore.session_seed() + _round_index * 97 + (13 if operation == "addition" else 29)
	)
	for value in choices:
		var button := Button.new()
		button.custom_minimum_size = Vector2(270, 150)
		button.set_meta("answer_value", value)
		UIStyles.apply_button(button, Color("#FFEFC6"), Color("#FFF8E8"), Color("#EBCB78"))
		button.add_theme_stylebox_override(
			"normal",
			UIStyles.rounded_box(Color("#FFEFC6"), 24, Color("#E6C36C"), 3)
		)
		var answer_content := VBoxContainer.new()
		answer_content.alignment = BoxContainer.ALIGNMENT_CENTER
		answer_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		answer_content.add_theme_constant_override("separation", 0)
		button.add_child(answer_content)
		answer_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
		var number_label := _make_label(str(value), 58, Color("#C95F35"))
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		answer_content.add_child(number_label)
		var dots_label := _make_label(_dot_text(value), 23, Color("#47745D"))
		dots_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		answer_content.add_child(dots_label)
		button.set_meta("number_label", number_label)
		button.set_meta("dots_label", dots_label)
		button.pressed.connect(_on_answer_pressed.bind(value, button))
		_answer_row.add_child(button)


func _dot_text(value: int) -> String:
	if value == 0:
		return "○"
	var dots: PackedStringArray = []
	for index in range(value):
		dots.append("●")
		if index == 4 and value > 5:
			dots.append(" ")
	return " ".join(dots)


func _on_answer_pressed(value: int, button: Button) -> void:
	if _round_locked:
		return
	var answer := int(_current_question().get("answer", -1))
	if value != answer:
		_feedback_label.text = str(_config.get("prompts", {}).get("retry", "再慢慢数一数。"))
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("arithmetic.retry", _feedback_label.text)
		_shake_button(button)
		return
	_round_locked = true
	for answer_button in _answer_row.get_children():
		(answer_button as Button).disabled = true
	button.disabled = false
	UIStyles.apply_button(button, UIStyles.GREEN, Color("#6ED08C"), UIStyles.GREEN_DARK)
	(button.get_meta("number_label") as Label).add_theme_color_override("font_color", Color.WHITE)
	(button.get_meta("dots_label") as Label).add_theme_color_override("font_color", Color.WHITE)
	_progress_dots.completed = _round_index + 1
	ProgressStore.complete_round()
	var correct_lines: Array = _config.get("prompts", {}).get("correct", ["对啦！"])
	_feedback_label.text = str(correct_lines[_round_index % correct_lines.size()])
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	AudioManager.play_prompt("arithmetic.correct_%02d" % ((_round_index % 3) + 1), _feedback_label.text)
	await get_tree().create_timer(1.05).timeout
	if not is_inside_tree():
		return
	_round_index += 1
	if _round_index >= _questions.size():
		_finish_session()
	else:
		_begin_round()


func _play_question_prompt() -> void:
	if _questions.is_empty():
		return
	var question := _current_question()
	var left := int(question.get("left", 0))
	var right := int(question.get("right", 0))
	var prompts: Dictionary = _config.get("prompts", {})
	var fallback_template := str(
		prompts.get("addition_template" if operation == "addition" else "subtraction_template", "")
	)
	AudioManager.play_sequence(_question_audio_sequence(), fallback_template % [left, right])


func _question_audio_sequence() -> Array[String]:
	var question := _current_question()
	var left := int(question.get("left", 0))
	var right := int(question.get("right", 0))
	var sequence: Array[String] = [
		"common.character_mimi_continuing",
		"arithmetic.has_%02d" % left
	]
	if operation == "addition":
		sequence.append_array([
			"common.character_diandian_continuing",
			"arithmetic.brings_%02d" % right,
			"arithmetic.how_many_total"
		])
	else:
		sequence.append_array([
			"arithmetic.take_away_%02d" % right,
			"arithmetic.how_many_left"
		])
	return sequence


func _current_question() -> Dictionary:
	if _round_index < 0 or _round_index >= _questions.size():
		return {}
	return _questions[_round_index]


func _finish_session() -> void:
	ProgressStore.complete_session("carrot_%s" % operation)
	AudioManager.play_prompt(
		"arithmetic.complete",
		str(_config.get("prompts", {}).get("complete", "任务完成啦！"))
	)
	_show_session_overlay()


func _show_session_overlay() -> void:
	_session_overlay = ColorRect.new()
	_session_overlay.color = Color(0.20, 0.31, 0.23, 0.55)
	_session_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_session_overlay.z_index = 50
	add_child(_session_overlay)
	_session_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_session_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 360)
	card.add_theme_stylebox_override("panel", UIStyles.rounded_box(Color("#FFF9E8"), 34, Color.WHITE, 5))
	center.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	card.add_child(box)
	box.add_child(_make_label("★ 任务完成啦！ ★", 34, UIStyles.GREEN_DARK))
	var again := Button.new()
	again.text = "再玩一次"
	again.custom_minimum_size = Vector2(330, 82)
	again.add_theme_font_size_override("font_size", 28)
	UIStyles.apply_button(again, UIStyles.GREEN, Color("#6ED08C"), UIStyles.GREEN_DARK)
	again.pressed.connect(_restart_session)
	box.add_child(again)
	var town := Button.new()
	town.text = "回到小镇"
	town.custom_minimum_size = Vector2(330, 72)
	town.add_theme_font_size_override("font_size", 25)
	UIStyles.apply_button(town, Color("#67B7D4"), Color("#7DC8E2"), Color("#4594B2"))
	town.pressed.connect(_request_exit)
	box.add_child(town)


func _restart_session() -> void:
	if _session_overlay != null:
		_session_overlay.queue_free()
		_session_overlay = null
	_start_session()


func _request_exit() -> void:
	AudioManager.stop_voice()
	exit_requested.emit()


func _shake_button(button: Control) -> void:
	var original_x := button.position.x
	var tween := create_tween()
	for offset in [8.0, -8.0, 5.0, -5.0, 0.0]:
		tween.tween_property(button, "position:x", original_x + offset, 0.06)


func _make_label(text_value: String, font_size: int, color: Color, centered: bool = true) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.75))
	label.add_theme_constant_override("outline_size", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
