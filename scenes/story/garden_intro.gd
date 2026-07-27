extends Control

signal finished

var _config: Dictionary = {}
var _line_index := 0
var _speaker_label: Label
var _dialogue_label: Label
var _progress_label: Label
var _replay_button: Button
var _next_button: Button


func _ready() -> void:
	_config = ContentRepository.get_story_intro_config()
	_build_ui()
	if _config.is_empty() or _config.get("lines", []).is_empty():
		_dialogue_label.text = "故事暂时走丢了，我们直接去帮米米吧！"
		_next_button.text = "▶"
		return
	_show_line(0)


func _build_ui() -> void:
	var background := TextureRect.new()
	var background_path := str(
		_config.get("background", "res://assets/art/story/garden_intro.png")
	)
	if ResourceLoader.exists(background_path):
		background.texture = load(background_path) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top_shade := ColorRect.new()
	top_shade.color = Color(0.08, 0.20, 0.16, 0.14)
	top_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_shade)
	top_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.text = "胡萝卜野餐·小镇故事"
	title.position = Vector2(30, 22)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#315D4E"))
	title.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.92))
	title.add_theme_constant_override("outline_size", 5)
	add_child(title)

	var skip_button := Button.new()
	skip_button.text = "↠"
	skip_button.tooltip_text = "跳过故事"
	skip_button.custom_minimum_size = Vector2(68, 54)
	skip_button.position = Vector2(1182, 20)
	skip_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(
		skip_button,
		Color("#FFF7E3"),
		Color.WHITE,
		Color("#E9D5A6")
	)
	skip_button.pressed.connect(_finish_story)
	add_child(skip_button)

	var dialogue_card := PanelContainer.new()
	dialogue_card.anchor_left = 0.16
	dialogue_card.anchor_top = 0.75
	dialogue_card.anchor_right = 0.985
	dialogue_card.anchor_bottom = 0.975
	dialogue_card.offset_left = 0
	dialogue_card.offset_top = 0
	dialogue_card.offset_right = 0
	dialogue_card.offset_bottom = 0
	dialogue_card.add_theme_stylebox_override(
		"panel",
		UIStyles.rounded_box(Color(1.0, 0.98, 0.90, 0.95), 30, Color.WHITE, 4)
	)
	add_child(dialogue_card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 26)
	card_margin.add_theme_constant_override("margin_top", 14)
	card_margin.add_theme_constant_override("margin_right", 18)
	card_margin.add_theme_constant_override("margin_bottom", 14)
	dialogue_card.add_child(card_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card_margin.add_child(row)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 2)
	row.add_child(text_column)

	var header := HBoxContainer.new()
	text_column.add_child(header)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 23)
	_speaker_label.add_theme_color_override("font_color", Color("#C86F45"))
	_speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_speaker_label)
	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 18)
	_progress_label.add_theme_color_override("font_color", Color("#6C8D7C"))
	header.add_child(_progress_label)

	_dialogue_label = Label.new()
	_dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialogue_label.add_theme_font_size_override("font_size", 28)
	_dialogue_label.add_theme_color_override("font_color", Color("#3F574B"))
	text_column.add_child(_dialogue_label)

	_replay_button = Button.new()
	_replay_button.text = "▶"
	_replay_button.tooltip_text = "重播这句话"
	_replay_button.custom_minimum_size = Vector2(82, 106)
	_replay_button.add_theme_font_size_override("font_size", 30)
	UIStyles.apply_button(
		_replay_button,
		Color("#67B7D4"),
		Color("#7DC8E2"),
		Color("#4594B2")
	)
	_replay_button.pressed.connect(_play_current_line)
	row.add_child(_replay_button)

	_next_button = Button.new()
	_next_button.text = "➜"
	_next_button.tooltip_text = "下一句"
	_next_button.custom_minimum_size = Vector2(98, 106)
	_next_button.add_theme_font_size_override("font_size", 42)
	UIStyles.apply_button(
		_next_button,
		UIStyles.GREEN,
		Color("#6ED08C"),
		UIStyles.GREEN_DARK
	)
	_next_button.pressed.connect(_on_next_pressed)
	row.add_child(_next_button)


func _show_line(index: int) -> void:
	var lines: Array = _config.get("lines", [])
	if index < 0 or index >= lines.size():
		_finish_story()
		return
	_line_index = index
	var line: Dictionary = lines[_line_index]
	_speaker_label.text = str(line.get("speaker", "萌宠伙伴"))
	var spoken_text := str(line.get("text", ""))
	if "$child_name" in line.get("audio_sequence", []):
		spoken_text = "%s，%s" % [ProgressStore.get_child_name(), spoken_text]
	_dialogue_label.text = spoken_text
	_progress_label.text = _make_progress_text(lines.size(), _line_index)
	_next_button.text = "✓" if _line_index == lines.size() - 1 else "➜"
	_next_button.tooltip_text = "开始帮忙" if _line_index == lines.size() - 1 else "下一句"
	_play_current_line()


func _make_progress_text(total: int, active_index: int) -> String:
	var parts: PackedStringArray = []
	for index in range(total):
		parts.append("●" if index == active_index else "○")
	return " ".join(parts)


func _play_current_line() -> void:
	var lines: Array = _config.get("lines", [])
	if _line_index < 0 or _line_index >= lines.size():
		return
	var line: Dictionary = lines[_line_index]
	var spoken_text := str(line.get("text", ""))
	var sequence := _resolve_audio_sequence(line.get("audio_sequence", []))
	var child_name := ProgressStore.get_child_name()
	var fallback_text := (
		"%s，%s" % [child_name, spoken_text]
		if "$child_name" in line.get("audio_sequence", [])
		else spoken_text
	)
	AudioManager.play_sequence(sequence, fallback_text)


func _resolve_audio_sequence(raw_sequence: Array) -> Array[String]:
	var resolved: Array[String] = []
	for value in raw_sequence:
		var audio_id := str(value)
		if audio_id == "$child_name":
			resolved.append(ContentRepository.child_name_audio_id(ProgressStore.get_child_name()))
		else:
			resolved.append(audio_id)
	return resolved


func _on_next_pressed() -> void:
	var lines: Array = _config.get("lines", [])
	if _line_index >= lines.size() - 1:
		_finish_story()
	else:
		_show_line(_line_index + 1)


func _finish_story() -> void:
	AudioManager.stop_voice()
	finished.emit()
