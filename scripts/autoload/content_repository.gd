extends Node

const COUNT_FEEDING_PATH := "res://content/math/grade1_sem1/count_feeding.json"

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


func get_game_config(game_id: String) -> Dictionary:
	return _configs.get(game_id, {}).duplicate(true)


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
