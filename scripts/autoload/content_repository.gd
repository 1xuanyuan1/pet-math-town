extends Node

const COUNT_FEEDING_PATH := "res://content/math/grade1_sem1/count_feeding.json"
const CARROT_ARITHMETIC_PATH := "res://content/math/grade1_sem1/carrot_arithmetic.json"
const PLAYER_PROFILE_PATH := "res://content/player_profile.json"
const STORY_INTRO_PATH := "res://content/story/garden_intro.json"

var _configs: Dictionary = {}
var validation_errors: PackedStringArray = []


func _ready() -> void:
	reload()


func reload() -> void:
	_configs.clear()
	validation_errors.clear()
	var config := load_json_file(COUNT_FEEDING_PATH)
	if config.is_empty():
		validation_errors.append("无法读取数数配餐内容：%s" % COUNT_FEEDING_PATH)
		return
	var errors := validate_count_feeding(config)
	validation_errors.append_array(errors)
	if errors.is_empty():
		_configs[config["id"]] = config
	else:
		for message in errors:
			push_error(message)
	var arithmetic := load_json_file(CARROT_ARITHMETIC_PATH)
	var arithmetic_errors := validate_carrot_arithmetic(arithmetic)
	validation_errors.append_array(arithmetic_errors)
	if arithmetic_errors.is_empty():
		_configs[arithmetic["id"]] = arithmetic
	else:
		for message in arithmetic_errors:
			push_error(message)
	var profile := load_json_file(PLAYER_PROFILE_PATH)
	var profile_errors := validate_player_profile(profile)
	validation_errors.append_array(profile_errors)
	if profile_errors.is_empty():
		_configs[profile["id"]] = profile
	else:
		for message in profile_errors:
			push_error(message)
	var story_intro := load_json_file(STORY_INTRO_PATH)
	var story_errors := validate_story_intro(story_intro)
	validation_errors.append_array(story_errors)
	if story_errors.is_empty():
		_configs[story_intro["id"]] = story_intro
	else:
		for message in story_errors:
			push_error(message)


func get_game_config(game_id: String) -> Dictionary:
	return _configs.get(game_id, {}).duplicate(true)


func get_arithmetic_config() -> Dictionary:
	return _configs.get("carrot_arithmetic", {}).duplicate(true)


func get_player_profile_config() -> Dictionary:
	return _configs.get("player_profile", {}).duplicate(true)


func get_story_intro_config() -> Dictionary:
	return _configs.get("garden_intro", {}).duplicate(true)


func child_name_audio_id(display_name: String) -> String:
	var profile := get_player_profile_config()
	for preset_value in profile.get("bundled_names", []):
		if preset_value is Dictionary and str(preset_value.get("display_name")) == display_name:
			return str(preset_value.get("audio_id"))
	return str(profile.get("fallback_audio_id", "common.name_default"))


static func load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


static func validate_count_feeding(config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(config.get("schema_version", 0)) != 1:
		errors.append("count_feeding.schema_version 必须为 1")
	if config.get("id", "") != "count_feeding":
		errors.append("count_feeding.id 不正确")
	var session_value: Variant = config.get("session")
	if not session_value is Dictionary:
		errors.append("count_feeding.session 必须是对象")
		return errors
	var session: Dictionary = session_value
	if int(session.get("round_count", 0)) <= 0:
		errors.append("count_feeding.session.round_count 必须大于 0")
	var levels_value: Variant = session.get("difficulty_levels")
	if not levels_value is Array or levels_value.is_empty():
		errors.append("count_feeding.session.difficulty_levels 不能为空")
		return errors
	var previous_sessions := -1
	for index in range(levels_value.size()):
		var level_value: Variant = levels_value[index]
		if not level_value is Dictionary:
			errors.append("难度 %d 必须是对象" % index)
			continue
		var level: Dictionary = level_value
		var minimum := int(level.get("minimum", 0))
		var maximum := int(level.get("maximum", 0))
		var min_sessions := int(level.get("min_sessions", -1))
		if minimum < 1 or maximum > 10 or minimum > maximum:
			errors.append("难度 %d 的数量范围必须位于 1–10" % index)
		if min_sessions <= previous_sessions:
			errors.append("难度必须按 min_sessions 递增")
		previous_sessions = min_sessions
	var prompts_value: Variant = config.get("prompts")
	if not prompts_value is Dictionary:
		errors.append("count_feeding.prompts 必须是对象")
	else:
		for key in ["intro", "target_template", "short_target_template", "retry", "complete"]:
			if str(prompts_value.get(key, "")).strip_edges().is_empty():
				errors.append("提示语 %s 不能为空" % key)
	return errors


static func validate_carrot_arithmetic(config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(config.get("schema_version", 0)) != 1:
		errors.append("carrot_arithmetic.schema_version 必须为 1")
	if config.get("id", "") != "carrot_arithmetic":
		errors.append("carrot_arithmetic.id 不正确")
	var session_value: Variant = config.get("session")
	if not session_value is Dictionary:
		errors.append("carrot_arithmetic.session 必须是对象")
		return errors
	var session: Dictionary = session_value
	if int(session.get("round_count", 0)) <= 0:
		errors.append("carrot_arithmetic.session.round_count 必须大于 0")
	var maximum := int(session.get("maximum_result", 0))
	if maximum < 5 or maximum > 10:
		errors.append("首版加减法结果必须位于 5–10")
	var prompts_value: Variant = config.get("prompts")
	if not prompts_value is Dictionary:
		errors.append("carrot_arithmetic.prompts 必须是对象")
	else:
		for key in ["addition_template", "subtraction_template", "retry", "complete"]:
			if str(prompts_value.get(key, "")).strip_edges().is_empty():
				errors.append("加减法提示语 %s 不能为空" % key)
	return errors


static func validate_player_profile(config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(config.get("schema_version", 0)) != 1:
		errors.append("player_profile.schema_version 必须为 1")
	if config.get("id", "") != "player_profile":
		errors.append("player_profile.id 不正确")
	if str(config.get("default_name", "")).strip_edges().is_empty():
		errors.append("player_profile.default_name 不能为空")
	var maximum := int(config.get("maximum_name_characters", 0))
	if maximum < 1 or maximum > 16:
		errors.append("player_profile.maximum_name_characters 必须位于 1–16")
	if str(config.get("fallback_audio_id", "")).strip_edges().is_empty():
		errors.append("player_profile.fallback_audio_id 不能为空")
	var bundled_value: Variant = config.get("bundled_names")
	if not bundled_value is Array or bundled_value.is_empty():
		errors.append("player_profile.bundled_names 不能为空")
		return errors
	var names := {}
	for item_value in bundled_value:
		if not item_value is Dictionary:
			errors.append("内置名字必须是对象")
			continue
		var display_name := str(item_value.get("display_name", "")).strip_edges()
		var audio_id := str(item_value.get("audio_id", "")).strip_edges()
		if display_name.is_empty() or audio_id.is_empty():
			errors.append("内置名字和 audio_id 不能为空")
		if names.has(display_name):
			errors.append("内置名字不能重复：%s" % display_name)
		names[display_name] = true
	if not names.has(str(config.get("default_name"))):
		errors.append("默认名字必须位于 bundled_names 中")
	return errors


static func validate_story_intro(config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(config.get("schema_version", 0)) != 1:
		errors.append("garden_intro.schema_version 必须为 1")
	if config.get("id", "") != "garden_intro":
		errors.append("garden_intro.id 不正确")
	var background := str(config.get("background", ""))
	if background.is_empty() or not ResourceLoader.exists(background):
		errors.append("故事背景不存在：%s" % background)
	var lines_value: Variant = config.get("lines")
	if not lines_value is Array or lines_value.size() < 3:
		errors.append("故事对话至少需要三句")
		return errors
	for index in range(lines_value.size()):
		var line_value: Variant = lines_value[index]
		if not line_value is Dictionary:
			errors.append("故事对话 %d 必须是对象" % index)
			continue
		var line: Dictionary = line_value
		if str(line.get("speaker", "")).strip_edges().is_empty():
			errors.append("故事对话 %d 缺少角色" % index)
		if str(line.get("text", "")).strip_edges().is_empty():
			errors.append("故事对话 %d 缺少文案" % index)
		var sequence_value: Variant = line.get("audio_sequence")
		if not sequence_value is Array or sequence_value.is_empty():
			errors.append("故事对话 %d 缺少语音序列" % index)
			continue
		for segment_value in sequence_value:
			var segment := str(segment_value).strip_edges()
			if segment.is_empty():
				errors.append("故事对话 %d 的语音片段不能为空" % index)
			elif segment.begins_with("$") and segment != "$child_name":
				errors.append("故事对话 %d 使用了未知语音占位符：%s" % [index, segment])
	return errors
