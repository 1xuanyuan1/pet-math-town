extends Control

signal exit_requested

const TAKE_STAGE := "take_from_ten"
const ANSWER_STAGE := "answer"
const ANSWER_FEEDBACK_SECONDS := 5.0

var _config: Dictionary = {}
var _questions: Array[Dictionary] = []
var _round_index := 0
var _round_locked := false
var _stage := TAKE_STAGE
var _removed_indices: Array[int] = []
var _answer_feedback_seconds := ANSWER_FEEDBACK_SECONDS

var _progress_dots: ProgressDots
var _equation_label: Label
var _feedback_label: Label
var _ten_title: Label
var _ones_title: Label
var _bridge_action_label: Label
var _bridge_symbol_label: Label
var _bridge_hint_label: Label
var _ten_grid: GridContainer
var _ones_grid: GridContainer
var _answer_row: HBoxContainer
var _confirm_button: Button
var _replay_button: Button
var _idle_timer: Timer
var _session_overlay: Control


func _ready() -> void:
	_config = ContentRepository.get_break_ten_config()
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
	page.add_theme_constant_override("separation", 10)
	outer.add_child(page)

	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 58)
	top_bar.add_theme_constant_override("separation", 12)
	page.add_child(top_bar)

	var back_button := Button.new()
	back_button.text = "←"
	back_button.tooltip_text = "回到十格策略营"
	back_button.custom_minimum_size = Vector2(70, 58)
	back_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(back_button, Color("#FFF2D4"), Color("#FFF9E7"), Color("#E4C98E"))
	back_button.pressed.connect(_request_exit)
	top_bar.add_child(back_button)

	var title_label := _make_label("十格策略营 · 破十山洞", 29, UIStyles.INK, false)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_label)

	_progress_dots = ProgressDots.new()
	_progress_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_progress_dots)

	_replay_button = Button.new()
	_replay_button.text = "▶"
	_replay_button.tooltip_text = "重播提示"
	_replay_button.custom_minimum_size = Vector2(74, 58)
	_replay_button.add_theme_font_size_override("font_size", 28)
	UIStyles.apply_button(_replay_button, Color("#66B9DC"), Color("#7BC9E8"), Color("#4696BA"))
	_replay_button.pressed.connect(_play_stage_prompt)
	top_bar.add_child(_replay_button)

	_equation_label = _make_label("13 − 5 = ?", 44, Color("#C9633E"))
	_equation_label.custom_minimum_size = Vector2(0, 64)
	page.add_child(_equation_label)

	var visual_row := HBoxContainer.new()
	visual_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_row.add_theme_constant_override("separation", 18)
	page.add_child(visual_row)

	var ten_panel_data := _make_group_panel(Color("#FFF4D9"), Vector2(555, 0), 5)
	visual_row.add_child(ten_panel_data["panel"])
	_ten_title = ten_panel_data["title"]
	_ten_grid = ten_panel_data["grid"]

	var bridge_column := VBoxContainer.new()
	bridge_column.custom_minimum_size = Vector2(150, 0)
	bridge_column.alignment = BoxContainer.ALIGNMENT_CENTER
	bridge_column.add_theme_constant_override("separation", 8)
	visual_row.add_child(bridge_column)
	_bridge_action_label = _make_label("从十里拿走", 21, Color("#6E7D70"))
	bridge_column.add_child(_bridge_action_label)
	_bridge_symbol_label = _make_label("−", 58, Color("#D77D61"))
	bridge_column.add_child(_bridge_symbol_label)
	_bridge_hint_label = _make_label("目标：拿走 5", 22, Color("#9D563F"))
	bridge_column.add_child(_bridge_hint_label)

	var ones_panel_data := _make_group_panel(Color("#EEF0FF"), Vector2(485, 0), 3)
	visual_row.add_child(ones_panel_data["panel"])
	_ones_title = ones_panel_data["title"]
	_ones_grid = ones_panel_data["grid"]

	_feedback_label = _make_label("先从十格篮子里拿走", 23, UIStyles.INK)
	_feedback_label.custom_minimum_size = Vector2(0, 40)
	page.add_child(_feedback_label)

	var action_area := CenterContainer.new()
	action_area.custom_minimum_size = Vector2(0, 132)
	page.add_child(action_area)

	_confirm_button = Button.new()
	_confirm_button.text = "✓  拿好了"
	_confirm_button.custom_minimum_size = Vector2(410, 92)
	_confirm_button.add_theme_font_size_override("font_size", 31)
	UIStyles.apply_button(_confirm_button, UIStyles.GREEN, Color("#6ED08C"), UIStyles.GREEN_DARK)
	_confirm_button.pressed.connect(_on_take_confirmed)
	action_area.add_child(_confirm_button)

	_answer_row = HBoxContainer.new()
	_answer_row.custom_minimum_size = Vector2(0, 126)
	_answer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_answer_row.add_theme_constant_override("separation", 26)
	_answer_row.visible = false
	action_area.add_child(_answer_row)

	_idle_timer = Timer.new()
	_idle_timer.one_shot = true
	_idle_timer.wait_time = 10.0
	_idle_timer.timeout.connect(_on_idle_timeout)
	add_child(_idle_timer)


func _make_group_panel(color: Color, minimum_size: Vector2, columns: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UIStyles.rounded_box(color, 28, Color.WHITE, 4))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := _make_label("", 24, UIStyles.INK)
	title.custom_minimum_size = Vector2(0, 42)
	box.add_child(title)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(center)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	center.add_child(grid)
	return {"panel": panel, "title": title, "grid": grid}


func _start_session() -> void:
	if _config.is_empty():
		return
	var session: Dictionary = _config.get("session", {})
	_questions = BreakTenQuestionGenerator.generate_sequence(
		session.get("question_pool", []),
		int(session.get("round_count", 5)),
		ProgressStore.session_seed() + 59
	)
	_round_index = 0
	_progress_dots.round_count = _questions.size()
	_progress_dots.completed = 0
	_begin_round()


func _begin_round() -> void:
	_round_locked = false
	_stage = TAKE_STAGE
	_removed_indices.clear()
	_confirm_button.visible = true
	_answer_row.visible = false
	_feedback_label.text = "先从十格篮子里拿走"
	_feedback_label.add_theme_color_override("font_color", UIStyles.INK)
	_render_round()
	call_deferred("_play_take_prompt")
	_restart_idle_timer()


func _render_round() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var left := int(question.get("left"))
	var right := int(question.get("right"))
	var ones := int(question.get("ones"))
	var ten_left := int(question.get("ten_left"))
	if _stage == TAKE_STAGE:
		_bridge_action_label.text = "从十里拿走"
		_bridge_symbol_label.text = "−"
		_bridge_hint_label.text = "目标：拿走 %d" % right
		_ten_title.text = "十格篮子 · 已拿走 %d / %d" % [_removed_indices.size(), right]
		_ones_title.text = "外面留着 %d 个" % ones
		if _removed_indices.is_empty():
			_equation_label.text = "%d − %d = ?" % [left, right]
		else:
			_equation_label.text = "%d − %d  →  10 − %d + %d" % [
				left, right, _removed_indices.size(), ones
			]
	else:
		_bridge_action_label.text = "合起来"
		_bridge_symbol_label.text = "+"
		_bridge_hint_label.text = "%d 加 %d" % [ten_left, ones]
		_ten_title.text = "十格里剩 %d 个" % ten_left
		_ones_title.text = "外面还有 %d 个" % ones
		_equation_label.text = "%d − %d  =  10 − %d + %d  = ?" % [left, right, right, ones]
	_render_ten_frame(question)
	_render_ones(question)


func _render_ten_frame(_question: Dictionary) -> void:
	_clear_children(_ten_grid)
	for slot_index in range(10):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(88, 96)
		var removed := slot_index in _removed_indices
		var border_color := Color("#E5AB97") if removed else Color("#9ED7B0")
		slot.add_theme_stylebox_override(
			"panel", UIStyles.rounded_box(Color(1, 1, 1, 0.72), 15, border_color, 3)
		)
		_ten_grid.add_child(slot)
		var center := CenterContainer.new()
		slot.add_child(center)
		var carrot := CarrotButton.new()
		carrot.compact = true
		carrot.removed = removed
		if _stage == ANSWER_STAGE:
			carrot.disabled = true
			carrot.focus_mode = Control.FOCUS_NONE
		else:
			carrot.tooltip_text = "点一下拿走或放回"
			carrot.pressed.connect(_on_ten_carrot_pressed.bind(slot_index))
		center.add_child(carrot)


func _render_ones(question: Dictionary) -> void:
	_clear_children(_ones_grid)
	for _index in range(int(question.get("ones"))):
		var carrot := CarrotButton.new()
		carrot.compact = true
		carrot.disabled = true
		carrot.focus_mode = Control.FOCUS_NONE
		_ones_grid.add_child(carrot)


func _on_ten_carrot_pressed(slot_index: int) -> void:
	if _round_locked or _stage != TAKE_STAGE:
		return
	var target := int(_current_question().get("right"))
	if slot_index in _removed_indices:
		_removed_indices.erase(slot_index)
	elif _removed_indices.size() < target:
		_removed_indices.append(slot_index)
	if _removed_indices.size() == target:
		_feedback_label.text = "拿好啦，点绿色对勾！"
	else:
		_feedback_label.text = "还要拿走 %d 个" % (target - _removed_indices.size())
	_render_round()
	_restart_idle_timer()


func _on_take_confirmed() -> void:
	if _round_locked or _stage != TAKE_STAGE:
		return
	var target := int(_current_question().get("right"))
	if _removed_indices.size() != target:
		_feedback_label.text = str(_config.get("prompts", {}).get("retry_take", "再看看要拿走几个。"))
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("break_ten.retry_take", _feedback_label.text)
		_pulse_control(_ten_grid)
		_restart_idle_timer()
		return
	_stage = ANSWER_STAGE
	_confirm_button.visible = false
	_answer_row.visible = true
	_feedback_label.text = str(_config.get("prompts", {}).get("combine_left", "把剩下的合起来。"))
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	_render_round()
	_build_answer_buttons(_current_question())
	AudioManager.play_sequence(
		["break_ten.broke_ten", "break_ten.combine_left"],
		"%s %s" % [
			_config.get("prompts", {}).get("broke_ten", "十格篮子里拿好啦！"),
			_feedback_label.text
		]
	)
	_restart_idle_timer()


func _build_answer_buttons(question: Dictionary) -> void:
	_clear_children(_answer_row)
	var choices := ArithmeticQuestionGenerator.answer_choices(
		question, 9, ProgressStore.session_seed() + _round_index * 103 + 73
	)
	for value in choices:
		var button := Button.new()
		button.custom_minimum_size = Vector2(260, 118)
		button.set_meta("answer_value", value)
		UIStyles.apply_button(button, Color("#FFEFC6"), Color("#FFF8E8"), Color("#EBCB78"))
		button.add_theme_stylebox_override(
			"normal", UIStyles.rounded_box(Color("#FFEFC6"), 22, Color("#E6C36C"), 3)
		)
		var content := VBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
		var number_label := _make_label(str(value), 53, Color("#C95F35"))
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(number_label)
		button.set_meta("number_label", number_label)
		button.pressed.connect(_on_answer_pressed.bind(value, button))
		_answer_row.add_child(button)


func _on_answer_pressed(value: int, button: Button) -> void:
	if _round_locked or _stage != ANSWER_STAGE:
		return
	var question := _current_question()
	var answer := int(question.get("answer"))
	if value != answer:
		_feedback_label.text = str(_config.get("prompts", {}).get("retry_answer", "再数一数。"))
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("break_ten.retry_answer", _feedback_label.text)
		_shake_button(button)
		_restart_idle_timer()
		return
	_round_locked = true
	_idle_timer.stop()
	for answer_button in _answer_row.get_children():
		(answer_button as Button).disabled = true
	button.disabled = false
	UIStyles.apply_button(button, UIStyles.GREEN, Color("#6ED08C"), UIStyles.GREEN_DARK)
	(button.get_meta("number_label") as Label).add_theme_color_override("font_color", Color.WHITE)
	_progress_dots.completed = _round_index + 1
	ProgressStore.complete_round()
	_feedback_label.text = str(_config.get("prompts", {}).get("correct", "破十法算出来啦！"))
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	AudioManager.play_sequence(_answer_audio_sequence(question), _feedback_label.text)
	await get_tree().create_timer(_answer_feedback_seconds).timeout
	if not is_inside_tree():
		return
	_round_index += 1
	if _round_index >= _questions.size():
		_finish_session()
	else:
		_begin_round()


func _answer_audio_sequence(question: Dictionary) -> Array[String]:
	return [
		"common.number_10",
		"common.operator_minus",
		"common.number_%02d" % int(question.get("right")),
		"common.operator_plus",
		"common.number_%02d" % int(question.get("ones")),
		"common.operator_equals",
		"common.number_%02d" % int(question.get("answer")),
		"break_ten.correct"
	]


func _play_stage_prompt() -> void:
	if _stage == TAKE_STAGE:
		_play_take_prompt()
	else:
		AudioManager.play_sequence(
			["break_ten.broke_ten", "break_ten.combine_left"],
			str(_config.get("prompts", {}).get("combine_left", "把剩下的合起来。"))
		)
	_restart_idle_timer()


func _play_take_prompt() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var left := int(question.get("left"))
	var right := int(question.get("right"))
	var prompts: Dictionary = _config.get("prompts", {})
	var fallback := "%s %s" % [
		str(prompts.get("question_template", "")) % [left, right],
		str(prompts.get("take_template", "")) % right
	]
	AudioManager.play_sequence(_take_audio_sequence(question), fallback)


func _take_audio_sequence(question: Dictionary) -> Array[String]:
	return [
		"common.character_mimi_continuing",
		"break_ten.has_%02d" % int(question.get("left")),
		"arithmetic.take_away_%02d" % int(question.get("right")),
		"break_ten.take_from_ten"
	]


func _on_idle_timeout() -> void:
	if not _round_locked:
		_play_stage_prompt()


func _restart_idle_timer() -> void:
	if not _round_locked and _idle_timer != null:
		_idle_timer.start()


func _current_question() -> Dictionary:
	if _round_index < 0 or _round_index >= _questions.size():
		return {}
	return _questions[_round_index]


func _finish_session() -> void:
	ProgressStore.complete_session("break_ten")
	AudioManager.play_prompt(
		"break_ten.complete",
		str(_config.get("prompts", {}).get("complete", "你会用破十法啦！"))
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
	card.custom_minimum_size = Vector2(540, 370)
	card.add_theme_stylebox_override("panel", UIStyles.rounded_box(Color("#FFF9E8"), 34, Color.WHITE, 5))
	center.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	card.add_child(box)
	box.add_child(_make_label("★ 破十小能手！ ★", 34, UIStyles.GREEN_DARK))
	var again := Button.new()
	again.text = "再玩一次"
	again.custom_minimum_size = Vector2(340, 82)
	again.add_theme_font_size_override("font_size", 28)
	UIStyles.apply_button(again, UIStyles.GREEN, Color("#6ED08C"), UIStyles.GREEN_DARK)
	again.pressed.connect(_restart_session)
	box.add_child(again)
	var strategy := Button.new()
	strategy.text = "回到策略营"
	strategy.custom_minimum_size = Vector2(340, 72)
	strategy.add_theme_font_size_override("font_size", 25)
	UIStyles.apply_button(strategy, Color("#67B7D4"), Color("#7DC8E2"), Color("#4594B2"))
	strategy.pressed.connect(_request_exit)
	box.add_child(strategy)


func _restart_session() -> void:
	if _session_overlay != null:
		_session_overlay.queue_free()
		_session_overlay = null
	_start_session()


func _request_exit() -> void:
	AudioManager.stop_voice()
	exit_requested.emit()


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _pulse_control(control: Control) -> void:
	var original_scale := control.scale
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", original_scale * 1.035, 0.12)
	tween.tween_property(control, "scale", original_scale, 0.16)


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
