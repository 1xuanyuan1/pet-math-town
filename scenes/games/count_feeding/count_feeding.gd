extends Control

signal exit_requested

var _config: Dictionary = {}
var _sequence: Array[int] = []
var _round_index := 0
var _target_count := 1
var _selected_sources: Array[int] = []
var _supply_buttons: Array[CarrotButton] = []
var _round_locked := false
var _play_greeting_on_next_round := true

var _progress_dots: ProgressDots
var _mascot: MascotView
var _feedback_label: Label
var _basket_card: PanelContainer
var _selected_grid: GridContainer
var _empty_hint: Label
var _target_card: PanelContainer
var _target_number: Label
var _confirm_button: Button
var _replay_button: Button
var _session_overlay: Control
var _idle_timer: Timer


func _ready() -> void:
	_build_ui()
	_config = ContentRepository.get_game_config("count_feeding")
	if _config.is_empty():
		_show_content_error()
		return
	_start_session()


func _build_ui() -> void:
	var backdrop := TownBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 24)
	outer_margin.add_theme_constant_override("margin_top", 18)
	outer_margin.add_theme_constant_override("margin_right", 24)
	outer_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(outer_margin)
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	outer_margin.add_child(page)

	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 58)
	top_bar.add_theme_constant_override("separation", 14)
	page.add_child(top_bar)

	var back_button := Button.new()
	back_button.text = "←"
	back_button.tooltip_text = "回到萌宠小镇"
	back_button.custom_minimum_size = Vector2(70, 58)
	back_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(
		back_button,
		Color("#FFF2D4"),
		Color("#FFF9E7"),
		Color("#E4C98E")
	)
	back_button.pressed.connect(_request_exit)
	top_bar.add_child(back_button)

	var title := _make_label("萌宠小镇 · 数数配餐", 28, UIStyles.INK, false)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	_progress_dots = ProgressDots.new()
	_progress_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_progress_dots)

	var right_spacer := Control.new()
	right_spacer.custom_minimum_size = Vector2(96, 0)
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(right_spacer)

	_replay_button = Button.new()
	_replay_button.text = "▶"
	_replay_button.tooltip_text = "重播提示"
	_replay_button.custom_minimum_size = Vector2(74, 58)
	_replay_button.add_theme_font_size_override("font_size", 28)
	UIStyles.apply_button(
		_replay_button,
		Color("#66B9DC"),
		Color("#7BC9E8"),
		Color("#4696BA")
	)
	_replay_button.pressed.connect(_play_current_prompt)
	top_bar.add_child(_replay_button)

	var main_row := HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 14)
	page.add_child(main_row)

	var mascot_card := PanelContainer.new()
	mascot_card.custom_minimum_size = Vector2(225, 0)
	mascot_card.add_theme_stylebox_override(
		"panel",
		UIStyles.rounded_box(Color("#FFF7E3"), 28, Color("#FFFFFF"), 3)
	)
	main_row.add_child(mascot_card)

	var mascot_box := VBoxContainer.new()
	mascot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mascot_box.add_theme_constant_override("separation", 3)
	mascot_card.add_child(mascot_box)
	var mascot_name := _make_label("米米", 30, UIStyles.INK)
	mascot_box.add_child(mascot_name)
	_mascot = MascotView.new()
	_mascot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mascot_box.add_child(_mascot)
	_feedback_label = _make_label("准备好了吗？", 21, UIStyles.INK)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.custom_minimum_size = Vector2(0, 52)
	mascot_box.add_child(_feedback_label)

	_basket_card = PanelContainer.new()
	_basket_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_basket_card.size_flags_stretch_ratio = 2.8
	_basket_card.add_theme_stylebox_override(
		"panel",
		UIStyles.rounded_box(Color("#FFE1B2"), 30, Color("#FFFFFF"), 4)
	)
	main_row.add_child(_basket_card)

	var basket_box := VBoxContainer.new()
	basket_box.add_theme_constant_override("separation", 6)
	_basket_card.add_child(basket_box)
	var basket_title := _make_label("米米的篮子", 25, Color("#7A5535"))
	basket_box.add_child(basket_title)
	_empty_hint = _make_label("点下面的胡萝卜，把它放进来", 23, Color("#A37A52"))
	_empty_hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	basket_box.add_child(_empty_hint)
	_selected_grid = GridContainer.new()
	_selected_grid.columns = 5
	_selected_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_selected_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_selected_grid.add_theme_constant_override("h_separation", 14)
	_selected_grid.add_theme_constant_override("v_separation", 8)
	basket_box.add_child(_selected_grid)

	_target_card = PanelContainer.new()
	_target_card.custom_minimum_size = Vector2(225, 0)
	_target_card.add_theme_stylebox_override(
		"panel",
		UIStyles.rounded_box(Color("#EEF8FF"), 28, Color("#FFFFFF"), 3)
	)
	main_row.add_child(_target_card)

	var target_box := VBoxContainer.new()
	target_box.alignment = BoxContainer.ALIGNMENT_CENTER
	target_box.add_theme_constant_override("separation", 0)
	_target_card.add_child(target_box)
	var target_title := _make_label("米米想要", 24, UIStyles.INK)
	target_box.add_child(target_title)
	_target_number = _make_label("1", 108, Color("#E77845"))
	_target_number.size_flags_vertical = Control.SIZE_EXPAND_FILL
	target_box.add_child(_target_number)
	var target_carrot := CarrotButton.new()
	target_carrot.compact = true
	target_carrot.disabled = true
	target_carrot.focus_mode = Control.FOCUS_NONE
	target_carrot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	target_box.add_child(target_carrot)
	var unit_label := _make_label("个胡萝卜", 25, UIStyles.INK)
	target_box.add_child(unit_label)

	var action_row := HBoxContainer.new()
	action_row.custom_minimum_size = Vector2(0, 142)
	action_row.add_theme_constant_override("separation", 14)
	page.add_child(action_row)

	var supply_card := PanelContainer.new()
	supply_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supply_card.add_theme_stylebox_override(
		"panel",
		UIStyles.rounded_box(Color("#F8FFF4"), 26, Color("#FFFFFF"), 3)
	)
	action_row.add_child(supply_card)

	var supply_grid := GridContainer.new()
	supply_grid.columns = 10
	supply_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	supply_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	supply_grid.add_theme_constant_override("h_separation", 11)
	supply_card.add_child(supply_grid)
	for index in range(10):
		var carrot := CarrotButton.new()
		carrot.tooltip_text = "胡萝卜 %d" % (index + 1)
		carrot.pressed.connect(_on_supply_pressed.bind(index))
		supply_grid.add_child(carrot)
		_supply_buttons.append(carrot)

	_confirm_button = Button.new()
	_confirm_button.text = "✓"
	_confirm_button.tooltip_text = "确认"
	_confirm_button.custom_minimum_size = Vector2(146, 142)
	_confirm_button.add_theme_font_size_override("font_size", 72)
	UIStyles.apply_button(
		_confirm_button,
		UIStyles.GREEN,
		Color("#69CA88"),
		UIStyles.GREEN_DARK
	)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	action_row.add_child(_confirm_button)

	_idle_timer = Timer.new()
	_idle_timer.one_shot = true
	_idle_timer.wait_time = 9.0
	_idle_timer.timeout.connect(_on_idle_timeout)
	add_child(_idle_timer)


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


func _show_content_error() -> void:
	_round_locked = true
	_feedback_label.text = "内容加载失败"
	_feedback_label.add_theme_color_override("font_color", Color("#C44747"))
	_confirm_button.disabled = true
	_replay_button.disabled = true


func _request_exit() -> void:
	AudioManager.stop_voice()
	exit_requested.emit()


func _start_session() -> void:
	if _session_overlay != null and is_instance_valid(_session_overlay):
		_session_overlay.queue_free()
		_session_overlay = null
	var sessions_completed := int(ProgressStore.data.get("sessions_completed", 0))
	_sequence = CountQuestionGenerator.generate_for_session(
		_config,
		sessions_completed,
		ProgressStore.session_seed()
	)
	_round_index = 0
	_play_greeting_on_next_round = true
	_progress_dots.round_count = _sequence.size()
	_progress_dots.completed = 0
	_begin_round()


func _begin_round() -> void:
	_round_locked = false
	_selected_sources.clear()
	_target_count = _sequence[_round_index]
	_target_number.text = str(_target_count)
	_feedback_label.text = "帮米米准备好吧！"
	_feedback_label.add_theme_color_override("font_color", UIStyles.INK)
	_mascot.mood = "happy"
	for carrot in _supply_buttons:
		carrot.unavailable = false
	_rebuild_basket()
	call_deferred("_play_round_prompt")


func _on_supply_pressed(source_index: int) -> void:
	if _round_locked or source_index in _selected_sources:
		return
	_selected_sources.append(source_index)
	_supply_buttons[source_index].unavailable = true
	_rebuild_basket()
	_restart_idle_timer()


func _on_basket_pressed(source_index: int) -> void:
	if _round_locked:
		return
	_selected_sources.erase(source_index)
	_supply_buttons[source_index].unavailable = false
	_rebuild_basket()
	_restart_idle_timer()


func _rebuild_basket() -> void:
	for child in _selected_grid.get_children():
		_selected_grid.remove_child(child)
		child.queue_free()
	for source_index in _selected_sources:
		var carrot := CarrotButton.new()
		carrot.compact = true
		carrot.tooltip_text = "取回这根胡萝卜"
		carrot.pressed.connect(_on_basket_pressed.bind(source_index))
		_selected_grid.add_child(carrot)
	_empty_hint.visible = _selected_sources.is_empty()
	_selected_grid.visible = not _selected_sources.is_empty()
	_confirm_button.disabled = _selected_sources.is_empty() or _round_locked


func _on_confirm_pressed() -> void:
	if _round_locked or _selected_sources.is_empty():
		return
	_restart_idle_timer()
	if _selected_sources.size() == _target_count:
		_handle_correct()
	else:
		_handle_retry()


func _handle_retry() -> void:
	_feedback_label.text = str(_config.get("prompts", {}).get("retry", "再数一数。"))
	_feedback_label.add_theme_color_override("font_color", Color("#C9782D"))
	_mascot.mood = "thinking"
	AudioManager.play_prompt("count_feeding.retry", _feedback_label.text)
	_shake_basket()
	_pulse_control(_target_card)
	_restart_idle_timer()


func _handle_correct() -> void:
	_round_locked = true
	_idle_timer.stop()
	_confirm_button.disabled = true
	_progress_dots.completed = _round_index + 1
	ProgressStore.complete_round()
	var correct_lines: Array = _config.get("prompts", {}).get("correct", ["正好！"])
	_feedback_label.text = str(correct_lines[_round_index % correct_lines.size()])
	_feedback_label.add_theme_color_override("font_color", UIStyles.GREEN_DARK)
	_mascot.mood = "happy"
	var feedback_index := (_round_index % 3) + 1
	if feedback_index == 3:
		AudioManager.play_sequence(
			["common.character_mimi_continuing", "count_feeding.eats_just_right"],
			_feedback_label.text
		)
	else:
		AudioManager.play_prompt(
			"count_feeding.correct_%02d" % feedback_index,
			_feedback_label.text
		)
	_burst_stars()
	_pulse_control(_basket_card)
	await get_tree().create_timer(1.15).timeout
	if not is_inside_tree():
		return
	_round_index += 1
	if _round_index >= _sequence.size():
		_finish_session()
	else:
		_begin_round()


func _play_current_prompt() -> void:
	if _config.is_empty() or _sequence.is_empty():
		return
	var template := str(
		_config.get("prompts", {}).get(
			"target_template",
			"米米想要%d个胡萝卜。你可以帮我把胡萝卜放在篮子里吗？"
		)
	)
	var prompt := template % _target_count
	AudioManager.play_sequence(_target_audio_sequence(), prompt)
	_pulse_control(_target_card)
	_restart_idle_timer()


func _play_round_prompt() -> void:
	if not _play_greeting_on_next_round:
		_play_current_prompt()
		return
	_play_greeting_on_next_round = false
	var child_name := ProgressStore.get_child_name()
	var name_audio_id := ContentRepository.child_name_audio_id(child_name)
	var template := str(
		_config.get("prompts", {}).get(
			"target_template",
			"米米想要%d个胡萝卜。你可以帮我把胡萝卜放在篮子里吗？"
		)
	)
	var target_prompt := template % _target_count
	AudioManager.play_sequence(
		[name_audio_id] + _target_audio_sequence(),
		"%s，%s" % [child_name, target_prompt]
	)
	_pulse_control(_target_card)
	_restart_idle_timer()


func _on_idle_timeout() -> void:
	if _round_locked or _config.is_empty():
		return
	var template := str(
		_config.get("prompts", {}).get(
			"target_template",
			"米米想要%d个胡萝卜。你可以帮我把胡萝卜放在篮子里吗？"
		)
	)
	var prompt := template % _target_count
	AudioManager.play_sequence(_short_target_audio_sequence(), prompt)
	_pulse_control(_target_card)


func _target_audio_sequence() -> Array[String]:
	return [
		"common.character_mimi_continuing",
		"count_feeding.wants_%02d" % _target_count,
		"count_feeding.help_put_in_basket"
	]


func _short_target_audio_sequence() -> Array[String]:
	return [
		"common.character_mimi_continuing",
		"count_feeding.wants_%02d" % _target_count
	]


func _restart_idle_timer() -> void:
	if not _round_locked and _idle_timer != null:
		_idle_timer.start()


func _pulse_control(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(1.045, 1.045), 0.12)
	tween.tween_property(control, "scale", Vector2.ONE, 0.22)


func _shake_basket() -> void:
	_basket_card.pivot_offset = _basket_card.size * 0.5
	var tween := create_tween()
	for angle in [2.0, -2.0, 1.2, -1.2, 0.0]:
		tween.tween_property(_basket_card, "rotation", deg_to_rad(angle), 0.07)


func _burst_stars() -> void:
	var colors := [Color("#F7C94C"), Color("#F28A5C"), Color("#65BFE2"), Color("#78C88A")]
	for index in range(8):
		var star := _make_label("★", 30 + (index % 3) * 6, colors[index % colors.size()])
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.position = _basket_card.position + _basket_card.size * 0.5 + Vector2((index - 4) * 18, 20)
		star.z_index = 20
		add_child(star)
		var destination := star.position + Vector2((index - 4) * 15, -85 - (index % 2) * 28)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "position", destination, 0.75)
		tween.tween_property(star, "modulate:a", 0.0, 0.75)
		tween.chain().tween_callback(star.queue_free)


func _finish_session() -> void:
	ProgressStore.complete_session("count_feeding")
	_round_locked = true
	_idle_timer.stop()
	AudioManager.play_prompt(
		"count_feeding.complete",
		str(_config.get("prompts", {}).get("complete", "完成啦！"))
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
	card.custom_minimum_size = Vector2(520, 470)
	card.add_theme_stylebox_override(
		"panel",
		UIStyles.rounded_box(Color("#FFF9E8"), 34, Color.WHITE, 5)
	)
	center.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var heading := _make_label("配餐完成啦！", 44, UIStyles.GREEN_DARK)
	box.add_child(heading)
	var mascot := MascotView.new()
	mascot.custom_minimum_size = Vector2(220, 220)
	mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(mascot)
	var subheading := _make_label("米米还想再玩一次", 25, UIStyles.INK)
	box.add_child(subheading)
	var replay := Button.new()
	replay.text = "↻  再玩一次"
	replay.custom_minimum_size = Vector2(300, 78)
	replay.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(replay, UIStyles.GREEN, Color("#69CA88"), UIStyles.GREEN_DARK)
	replay.pressed.connect(_start_session)
	box.add_child(replay)
	_pulse_control(card)
