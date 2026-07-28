extends Control

signal exit_requested

const UNBUNDLE_STAGE := "unbundle"
const TAKE_STAGE := "take"
const ANSWER_STAGE := "answer"
const ANSWER_FEEDBACK_SECONDS := 5.0

var _config: Dictionary = {}
var _questions: Array[Dictionary] = []
var _round_index := 0
var _round_locked := false
var _stage := UNBUNDLE_STAGE
var _borrowed_bundle_index := -1
var _ones_removed_indices: Array[int] = []
var _answer_feedback_seconds := ANSWER_FEEDBACK_SECONDS

var _progress_dots: ProgressDots
var _equation_label: Label
var _feedback_label: Label
var _tens_title: Label
var _ones_title: Label
var _step_label: Label
var _step_symbol_label: Label
var _step_hint_label: Label
var _tens_grid: GridContainer
var _ones_grid: GridContainer
var _answer_row: HBoxContainer
var _confirm_button: Button
var _replay_button: Button
var _idle_timer: Timer
var _session_overlay: Control


func _ready() -> void:
	_config = ContentRepository.get_borrow_ten_config()
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

	var title_label := _make_label("十格策略营 · 借十挑战", 29, UIStyles.INK, false)
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

	_equation_label = _make_label("23 − 7 = ?", 43, Color("#C9633E"))
	_equation_label.custom_minimum_size = Vector2(0, 62)
	page.add_child(_equation_label)

	var visual_row := HBoxContainer.new()
	visual_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_row.add_theme_constant_override("separation", 16)
	page.add_child(visual_row)

	var tens_panel_data := _make_group_panel(Color("#FFF0DB"), Vector2(360, 0), 3)
	visual_row.add_child(tens_panel_data["panel"])
	_tens_title = tens_panel_data["title"]
	_tens_grid = tens_panel_data["grid"]

	var step_column := VBoxContainer.new()
	step_column.custom_minimum_size = Vector2(190, 0)
	step_column.alignment = BoxContainer.ALIGNMENT_CENTER
	step_column.add_theme_constant_override("separation", 8)
	visual_row.add_child(step_column)
	_step_label = _make_label("第 1 步 · 十位借一", 21, Color("#6E7D70"))
	step_column.add_child(_step_label)
	_step_symbol_label = _make_label("→", 50, Color("#D77D61"))
	step_column.add_child(_step_symbol_label)
	_step_hint_label = _make_label("个位不够减", 21, Color("#9D563F"))
	_step_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	step_column.add_child(_step_hint_label)

	var ones_panel_data := _make_group_panel(Color("#EEF0FF"), Vector2(630, 0), 8)
	visual_row.add_child(ones_panel_data["panel"])
	_ones_title = ones_panel_data["title"]
	_ones_grid = ones_panel_data["grid"]

	_feedback_label = _make_label("先点一捆十根，把它拆开", 23, UIStyles.INK)
	_feedback_label.custom_minimum_size = Vector2(0, 40)
	page.add_child(_feedback_label)

	var action_area := CenterContainer.new()
	action_area.custom_minimum_size = Vector2(0, 132)
	page.add_child(action_area)

	_confirm_button = Button.new()
	_confirm_button.text = "✓  借好一捆了"
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
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := _make_label("", 23, UIStyles.INK)
	title.custom_minimum_size = Vector2(0, 42)
	box.add_child(title)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(center)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	center.add_child(grid)
	return {"panel": panel, "title": title, "grid": grid}


func _start_session() -> void:
	if _config.is_empty():
		return
	var session: Dictionary = _config.get("session", {})
	_questions = BorrowTenQuestionGenerator.generate_sequence(
		session.get("question_pool", []),
		int(session.get("round_count", 5)),
		ProgressStore.session_seed() + 83
	)
	_round_index = 0
	_progress_dots.round_count = _questions.size()
	_progress_dots.completed = 0
	_begin_round()


func _begin_round() -> void:
	_round_locked = false
	_stage = UNBUNDLE_STAGE
	_borrowed_bundle_index = -1
	_ones_removed_indices.clear()
	_confirm_button.visible = true
	_confirm_button.text = "✓  借好一捆了"
	_answer_row.visible = false
	_feedback_label.text = "先点一捆十根，把它拆开"
	_feedback_label.add_theme_color_override("font_color", UIStyles.INK)
	_render_round()
	call_deferred("_play_unbundle_prompt")
	_restart_idle_timer()


func _render_round() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var left := int(question.get("left"))
	var right := int(question.get("right"))
	var tens_left := int(question.get("tens_left"))
	var borrowed_ones := int(question.get("borrowed_ones"))
	match _stage:
		UNBUNDLE_STAGE:
			_step_label.text = "第 1 步 · 十位借一"
			_step_symbol_label.text = "→"
			_step_hint_label.text = "个位 %d 不够减 %d" % [question.get("ones"), right]
			_tens_title.text = "十位 · %d 捆十根" % question.get("tens")
			_ones_title.text = "个位 · %d 个" % question.get("ones")
			_equation_label.text = "%d − %d = ?" % [left, right]
		TAKE_STAGE:
			_step_label.text = "第 2 步 · 个位拿走"
			_step_symbol_label.text = "− %d" % right
			_step_hint_label.text = "个位变成 %d 个" % borrowed_ones
			_tens_title.text = "十位 · 还剩 %d 捆" % tens_left
			_ones_title.text = "个位 · 已拿走 %d / %d" % [_ones_removed_indices.size(), right]
			_equation_label.text = "%d − %d  =  %d + %d − %d" % [
				left, right, tens_left * 10, borrowed_ones, right
			]
		_:
			_step_label.text = "十位和个位合起来"
			_step_symbol_label.text = "="
			_step_hint_label.text = "%d 个十和 %d 个一" % [
				tens_left, question.get("ones_left")
			]
			_tens_title.text = "十位 · 还剩 %d 捆" % tens_left
			_ones_title.text = "个位 · 还剩几个？"
			_equation_label.text = "%d − %d  =  %d + %d  = ?" % [
				left, right, tens_left * 10, question.get("ones_left")
			]
	_render_tens(question)
	_render_ones(question)


func _render_tens(question: Dictionary) -> void:
	_clear_children(_tens_grid)
	for bundle_index in range(int(question.get("tens"))):
		var bundle := TenBundleButton.new()
		bundle.borrowed = bundle_index == _borrowed_bundle_index
		if _stage != UNBUNDLE_STAGE:
			bundle.disabled = true
			bundle.focus_mode = Control.FOCUS_NONE
		else:
			bundle.tooltip_text = "点一下借开这一捆"
			bundle.pressed.connect(_on_bundle_pressed.bind(bundle_index))
		_tens_grid.add_child(bundle)


func _render_ones(question: Dictionary) -> void:
	_clear_children(_ones_grid)
	var count := (
		int(question.get("ones"))
		if _stage == UNBUNDLE_STAGE
		else int(question.get("borrowed_ones"))
	)
	for ones_index in range(count):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(61, 78)
		var from_borrowed_bundle := _stage != UNBUNDLE_STAGE and ones_index < 10
		var removed := ones_index in _ones_removed_indices
		var border_color := Color("#E5AB97") if removed else (
			Color("#E6B96C") if from_borrowed_bundle else Color("#9FC5E8")
		)
		slot.add_theme_stylebox_override(
			"panel", UIStyles.rounded_box(Color(1, 1, 1, 0.68), 13, border_color, 3)
		)
		_ones_grid.add_child(slot)
		var center := CenterContainer.new()
		slot.add_child(center)
		var carrot := CarrotButton.new()
		carrot.compact = true
		carrot.removed = removed
		if _stage != TAKE_STAGE:
			carrot.disabled = true
			carrot.focus_mode = Control.FOCUS_NONE
		else:
			carrot.tooltip_text = "点一下拿走或放回"
			carrot.pressed.connect(_on_ones_carrot_pressed.bind(ones_index))
		center.add_child(carrot)


func _on_bundle_pressed(bundle_index: int) -> void:
	if _round_locked or _stage != UNBUNDLE_STAGE:
		return
	_borrowed_bundle_index = -1 if _borrowed_bundle_index == bundle_index else bundle_index
	_feedback_label.text = (
		"选好啦，点绿色对勾！"
		if _borrowed_bundle_index >= 0
		else "先点一捆十根，把它拆开"
	)
	_render_round()
	_restart_idle_timer()


func _on_ones_carrot_pressed(ones_index: int) -> void:
	if _round_locked or _stage != TAKE_STAGE:
		return
	var target := int(_current_question().get("right"))
	if ones_index in _ones_removed_indices:
		_ones_removed_indices.erase(ones_index)
	elif _ones_removed_indices.size() < target:
		_ones_removed_indices.append(ones_index)
	_feedback_label.text = (
		"个位拿好啦，点绿色对勾！"
		if _ones_removed_indices.size() == target
		else "个位还要拿走 %d 个" % (target - _ones_removed_indices.size())
	)
	_render_round()
	_restart_idle_timer()


func _on_confirm_pressed() -> void:
	if _round_locked:
		return
	if _stage == UNBUNDLE_STAGE:
		_confirm_unbundle()
	elif _stage == TAKE_STAGE:
		_confirm_take()


func _confirm_unbundle() -> void:
	if _borrowed_bundle_index < 0:
		_feedback_label.text = str(
			_config.get("prompts", {}).get("retry_unbundle", "先从十位借一捆十根。")
		)
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("borrow_ten.retry_unbundle", _feedback_label.text)
		_pulse_control(_tens_grid)
		_restart_idle_timer()
		return
	_stage = TAKE_STAGE
	_confirm_button.text = "✓  个位拿好了"
	_feedback_label.text = str(_config.get("prompts", {}).get("regrouped", "一捆十根拆开啦！"))
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	_render_round()
	_play_take_prompt()
	_restart_idle_timer()


func _confirm_take() -> void:
	var question := _current_question()
	var target := int(question.get("right"))
	if _ones_removed_indices.size() != target:
		_feedback_label.text = str(
			_config.get("prompts", {}).get("retry_take", "再看看，个位要拿走几个。")
		)
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("borrow_ten.retry_take", _feedback_label.text)
		_pulse_control(_ones_grid)
		_restart_idle_timer()
		return
	_stage = ANSWER_STAGE
	_confirm_button.visible = false
	_answer_row.visible = true
	_feedback_label.text = str(
		_config.get("prompts", {}).get("choose_answer", "把剩下的十位和个位合起来。")
	)
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	_render_round()
	_build_answer_buttons(question)
	AudioManager.play_prompt("borrow_ten.choose_answer", _feedback_label.text)
	_restart_idle_timer()


func _build_answer_buttons(question: Dictionary) -> void:
	_clear_children(_answer_row)
	var choices := ArithmeticQuestionGenerator.answer_choices(
		question, 39, ProgressStore.session_seed() + _round_index * 109 + 89
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
			_config.get("prompts", {}).get("retry_answer", "数一数还剩几捆和几个胡萝卜。")
		)
		_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
		AudioManager.play_prompt("borrow_ten.retry_answer", _feedback_label.text)
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
	_feedback_label.text = str(_config.get("prompts", {}).get("correct", "借十挑战算出来啦！"))
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
		"common.number_%02d" % int(question.get("right")),
		"common.operator_equals",
		"common.number_%02d" % int(question.get("answer")),
		"borrow_ten.correct"
	]


func _play_stage_prompt() -> void:
	if _stage == UNBUNDLE_STAGE:
		_play_unbundle_prompt()
	elif _stage == TAKE_STAGE:
		_play_take_prompt()
	else:
		AudioManager.play_prompt(
			"borrow_ten.choose_answer",
			str(_config.get("prompts", {}).get("choose_answer", "把剩下的合起来。"))
		)
	_restart_idle_timer()


func _play_unbundle_prompt() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var fallback := str(_config.get("prompts", {}).get("question_template", "")) % [
		question.get("left"), question.get("right")
	]
	AudioManager.play_sequence(_unbundle_audio_sequence(question), fallback)


func _unbundle_audio_sequence(question: Dictionary) -> Array[String]:
	return [
		"common.character_mimi_continuing",
		"borrow_ten.has_%02d" % int(question.get("left")),
		"arithmetic.take_away_%02d" % int(question.get("right")),
		"borrow_ten.unbundle"
	]


func _play_take_prompt() -> void:
	var question := _current_question()
	if question.is_empty():
		return
	var prompts: Dictionary = _config.get("prompts", {})
	var fallback := "%s %s" % [
		prompts.get("regrouped", "一捆十根拆开啦！"),
		str(prompts.get("take_template", "")) % [
			question.get("borrowed_ones"), question.get("right")
		]
	]
	AudioManager.play_sequence(
		[
			"borrow_ten.regrouped",
			"borrow_ten.ones_now_%02d" % int(question.get("borrowed_ones")),
			"arithmetic.take_away_%02d" % int(question.get("right"))
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
	ProgressStore.complete_session("borrow_ten")
	AudioManager.play_prompt(
		"borrow_ten.complete",
		str(_config.get("prompts", {}).get("complete", "你会把一捆十根拆开来减啦！"))
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
	card.custom_minimum_size = Vector2(560, 390)
	card.add_theme_stylebox_override("panel", UIStyles.rounded_box(Color("#FFF9E8"), 34, Color.WHITE, 5))
	center.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	card.add_child(box)
	box.add_child(_make_label("★ 借十挑战小能手！ ★", 32, UIStyles.GREEN_DARK))
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
