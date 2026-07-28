extends Control

signal exit_requested

const FIRST_TAKE_STAGE := "first_take"
const SECOND_TAKE_STAGE := "second_take"
const ANSWER_STAGE := "answer"
const ANSWER_FEEDBACK_SECONDS := 5.0

var _config: Dictionary = {}
var _questions: Array[Dictionary] = []
var _round_index := 0
var _round_locked := false
var _stage := FIRST_TAKE_STAGE
var _loose_removed_indices: Array[int] = []
var _ten_removed_indices: Array[int] = []
var _answer_feedback_seconds := ANSWER_FEEDBACK_SECONDS

var _progress_dots: ProgressDots
var _equation_label: Label
var _feedback_label: Label
var _ten_title: Label
var _loose_title: Label
var _step_label: Label
var _step_symbol_label: Label
var _split_hint_label: Label
var _ten_grid: GridContainer
var _loose_grid: GridContainer
var _answer_row: HBoxContainer
var _confirm_button: Button
var _replay_button: Button
var _idle_timer: Timer
var _session_overlay: Control


func _ready() -> void:
	_config = ContentRepository.get_flat_ten_config()
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

	var title_label := _make_label("十格策略营 · 平十阶梯", 29, UIStyles.INK, false)
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

	_equation_label = _make_label("14 − 6 = ?", 43, Color("#C9633E"))
	_equation_label.custom_minimum_size = Vector2(0, 62)
	page.add_child(_equation_label)

	var visual_row := HBoxContainer.new()
	visual_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_row.add_theme_constant_override("separation", 18)
	page.add_child(visual_row)

	var ten_panel_data := _make_group_panel(Color("#FFF4D9"), Vector2(570, 0), 5)
	visual_row.add_child(ten_panel_data["panel"])
	_ten_title = ten_panel_data["title"]
	_ten_grid = ten_panel_data["grid"]

	var step_column := VBoxContainer.new()
	step_column.custom_minimum_size = Vector2(190, 0)
	step_column.alignment = BoxContainer.ALIGNMENT_CENTER
	step_column.add_theme_constant_override("separation", 8)
	visual_row.add_child(step_column)
	_step_label = _make_label("第 1 步 · 先到十", 21, Color("#6E7D70"))
	step_column.add_child(_step_label)
	_step_symbol_label = _make_label("− 4", 50, Color("#D77D61"))
	step_column.add_child(_step_symbol_label)
	_split_hint_label = _make_label("6 拆成 4 和 2", 21, Color("#9D563F"))
	_split_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	step_column.add_child(_split_hint_label)

	var loose_panel_data := _make_group_panel(Color("#EEF0FF"), Vector2(380, 0), 3)
	visual_row.add_child(loose_panel_data["panel"])
	_loose_title = loose_panel_data["title"]
	_loose_grid = loose_panel_data["grid"]

	_feedback_label = _make_label("先拿走十外面的胡萝卜", 23, UIStyles.INK)
	_feedback_label.custom_minimum_size = Vector2(0, 40)
	page.add_child(_feedback_label)

	var action_area := CenterContainer.new()
	action_area.custom_minimum_size = Vector2(0, 132)
	page.add_child(action_area)

	_confirm_button = Button.new()
	_confirm_button.text = "✓  第一步拿好了"
	_confirm_button.custom_minimum_size = Vector2(410, 92)
	_confirm_button.add_theme_font_size_override("font_size", 31)
	UIStyles.apply_button(_confirm_button, UIStyles.GREEN, Color("#6ED08C"), UIStyles.GREEN_DARK)
	_confirm_button.pressed.connect(_on_confirm_pressed)
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
	_questions = FlatTenQuestionGenerator.generate_sequence(
		session.get("question_pool", []),
		int(session.get("round_count", 5)),
		ProgressStore.session_seed() + 71
	)
	_round_index = 0
	_progress_dots.round_count = _questions.size()
	_progress_dots.completed = 0
	_begin_round()


func _begin_round() -> void:
	_round_locked = false
	_stage = FIRST_TAKE_STAGE
	_loose_removed_indices.clear()
	_ten_removed_indices.clear()
	_confirm_button.visible = true
	_confirm_button.text = "✓  第一步拿好了"
	_answer_row.visible = false
	_feedback_label.text = "先拿走十外面的胡萝卜"
	_feedback_label.add_theme_color_override("font_color", UIStyles.INK)
	_render_round()
	call_deferred("_play_first_prompt")
	_restart_idle_timer()


func _render_round() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var left := int(question.get("left"))
	var right := int(question.get("right"))
	var to_ten := int(question.get("to_ten"))
	var remainder := int(question.get("remainder"))
	_split_hint_label.text = "%d 拆成 %d 和 %d" % [right, to_ten, remainder]
	match _stage:
		FIRST_TAKE_STAGE:
			_step_label.text = "第 1 步 · 先到十"
			_step_symbol_label.text = "− %d" % to_ten
			_ten_title.text = "十格篮子 · 10 个"
			_loose_title.text = "十外面 · 已拿走 %d / %d" % [
				_loose_removed_indices.size(), to_ten
			]
			_equation_label.text = "%d − %d  →  %d − %d − %d" % [
				left, right, left, to_ten, remainder
			]
		SECOND_TAKE_STAGE:
			_step_label.text = "第 2 步 · 再拿走"
			_step_symbol_label.text = "− %d" % remainder
			_ten_title.text = "十格篮子 · 已拿走 %d / %d" % [
				_ten_removed_indices.size(), remainder
			]
			_loose_title.text = "第一步已拿走 %d 个" % to_ten
			_equation_label.text = "%d − %d  =  %d − %d − %d" % [
				left, right, left, to_ten, remainder
			]
		_:
			_step_label.text = "两步走完啦"
			_step_symbol_label.text = "="
			_ten_title.text = "十格里还剩几个？"
			_loose_title.text = "一共拿走 %d 个" % right
			_equation_label.text = "%d − %d  =  %d − %d − %d  = ?" % [
				left, right, left, to_ten, remainder
			]
	_render_ten_frame()
	_render_loose_carrots(question)


func _render_ten_frame() -> void:
	_clear_children(_ten_grid)
	for slot_index in range(10):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(88, 96)
		var removed := slot_index in _ten_removed_indices
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
		if _stage != SECOND_TAKE_STAGE:
			carrot.disabled = true
			carrot.focus_mode = Control.FOCUS_NONE
		else:
			carrot.tooltip_text = "点一下拿走或放回"
			carrot.pressed.connect(_on_ten_carrot_pressed.bind(slot_index))
		center.add_child(carrot)


func _render_loose_carrots(question: Dictionary) -> void:
	_clear_children(_loose_grid)
	for loose_index in range(int(question.get("to_ten"))):
		var carrot := CarrotButton.new()
		carrot.compact = true
		carrot.removed = loose_index in _loose_removed_indices
		if _stage != FIRST_TAKE_STAGE:
			carrot.disabled = true
			carrot.focus_mode = Control.FOCUS_NONE
		else:
			carrot.tooltip_text = "点一下拿走或放回"
			carrot.pressed.connect(_on_loose_carrot_pressed.bind(loose_index))
		_loose_grid.add_child(carrot)


func _on_loose_carrot_pressed(loose_index: int) -> void:
	if _round_locked or _stage != FIRST_TAKE_STAGE:
		return
	if loose_index in _loose_removed_indices:
		_loose_removed_indices.erase(loose_index)
	else:
		_loose_removed_indices.append(loose_index)
	var target := int(_current_question().get("to_ten"))
	_feedback_label.text = (
		"第一步拿好啦，点绿色对勾！"
		if _loose_removed_indices.size() == target
		else "第一步还要拿走 %d 个" % (target - _loose_removed_indices.size())
	)
	_render_round()
	_restart_idle_timer()


func _on_ten_carrot_pressed(slot_index: int) -> void:
	if _round_locked or _stage != SECOND_TAKE_STAGE:
		return
	var target := int(_current_question().get("remainder"))
	if slot_index in _ten_removed_indices:
		_ten_removed_indices.erase(slot_index)
	elif _ten_removed_indices.size() < target:
		_ten_removed_indices.append(slot_index)
	_feedback_label.text = (
		"第二步拿好啦，点绿色对勾！"
		if _ten_removed_indices.size() == target
		else "第二步还要拿走 %d 个" % (target - _ten_removed_indices.size())
	)
	_render_round()
	_restart_idle_timer()


func _on_confirm_pressed() -> void:
	if _round_locked:
		return
	if _stage == FIRST_TAKE_STAGE:
		_confirm_first_take()
	elif _stage == SECOND_TAKE_STAGE:
		_confirm_second_take()


func _confirm_first_take() -> void:
	var question := _current_question()
	var target := int(question.get("to_ten"))
	if _loose_removed_indices.size() != target:
		_feedback_label.text = str(
			_config.get("prompts", {}).get("retry_first_take", "先把十外面的胡萝卜拿走。")
		)
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("flat_ten.retry_first_take", _feedback_label.text)
		_pulse_control(_loose_grid)
		_restart_idle_timer()
		return
	_stage = SECOND_TAKE_STAGE
	_confirm_button.text = "✓  第二步拿好了"
	_feedback_label.text = str(_config.get("prompts", {}).get("reached_ten", "正好剩十个！"))
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	_render_round()
	_play_second_prompt()
	_restart_idle_timer()


func _confirm_second_take() -> void:
	var question := _current_question()
	var target := int(question.get("remainder"))
	if _ten_removed_indices.size() != target:
		_feedback_label.text = str(
			_config.get("prompts", {}).get("retry_second_take", "还要再拿走几个？")
		)
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("flat_ten.retry_second_take", _feedback_label.text)
		_pulse_control(_ten_grid)
		_restart_idle_timer()
		return
	_stage = ANSWER_STAGE
	_confirm_button.visible = false
	_answer_row.visible = true
	_feedback_label.text = str(
		_config.get("prompts", {}).get("choose_answer", "看看十格里还剩几个胡萝卜。")
	)
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	_render_round()
	_build_answer_buttons(question)
	AudioManager.play_prompt("flat_ten.choose_answer", _feedback_label.text)
	_restart_idle_timer()


func _build_answer_buttons(question: Dictionary) -> void:
	_clear_children(_answer_row)
	var choices := ArithmeticQuestionGenerator.answer_choices(
		question, 9, ProgressStore.session_seed() + _round_index * 107 + 79
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
		_feedback_label.text = str(
			_config.get("prompts", {}).get("retry_answer", "数一数十格里剩下的胡萝卜。")
		)
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("flat_ten.retry_answer", _feedback_label.text)
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
	_feedback_label.text = str(_config.get("prompts", {}).get("correct", "平十法算出来啦！"))
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
		"common.number_%02d" % int(question.get("left")),
		"common.operator_minus",
		"common.number_%02d" % int(question.get("to_ten")),
		"common.operator_minus",
		"common.number_%02d" % int(question.get("remainder")),
		"common.operator_equals",
		"common.number_%02d" % int(question.get("answer")),
		"flat_ten.correct"
	]


func _play_stage_prompt() -> void:
	if _stage == FIRST_TAKE_STAGE:
		_play_first_prompt()
	elif _stage == SECOND_TAKE_STAGE:
		_play_second_prompt()
	else:
		AudioManager.play_prompt(
			"flat_ten.choose_answer",
			str(_config.get("prompts", {}).get("choose_answer", "看看还剩几个。"))
		)
	_restart_idle_timer()


func _play_first_prompt() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var prompts: Dictionary = _config.get("prompts", {})
	var fallback := "%s %s" % [
		str(prompts.get("question_template", "")) % [
			question.get("left"), question.get("right")
		],
		str(prompts.get("first_take_template", "")) % question.get("to_ten")
	]
	AudioManager.play_sequence(_first_audio_sequence(question), fallback)


func _first_audio_sequence(question: Dictionary) -> Array[String]:
	return [
		"common.character_mimi_continuing",
		"break_ten.has_%02d" % int(question.get("left")),
		"arithmetic.take_away_%02d" % int(question.get("right")),
		"flat_ten.first_take_%02d" % int(question.get("to_ten"))
	]


func _play_second_prompt() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var prompts: Dictionary = _config.get("prompts", {})
	var fallback := "%s %s" % [
		prompts.get("reached_ten", "正好剩十个！"),
		str(prompts.get("second_take_template", "")) % question.get("remainder")
	]
	AudioManager.play_sequence(
		[
			"flat_ten.reached_ten",
			"flat_ten.second_take_%02d" % int(question.get("remainder"))
		],
		fallback
	)


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
	ProgressStore.complete_session("flat_ten")
	AudioManager.play_prompt(
		"flat_ten.complete",
		str(_config.get("prompts", {}).get("complete", "你会用平十法啦！"))
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
	box.add_child(_make_label("★ 平十小能手！ ★", 34, UIStyles.GREEN_DARK))
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
