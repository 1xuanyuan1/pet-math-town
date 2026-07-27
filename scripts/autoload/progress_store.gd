extends Node

const DEFAULT_PATH := "user://progress.json"
const CURRENT_VERSION := 1

var storage_path := DEFAULT_PATH
var data: Dictionary = {}


func _ready() -> void:
	load_progress()


func default_data() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"sessions_completed": 0,
		"rounds_completed": 0,
		"last_played_game": "",
		"updated_at_unix": 0
	}


func load_progress() -> void:
	data = default_data()
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		data = sanitize(parsed)


func sanitize(value: Dictionary) -> Dictionary:
	var cleaned := default_data()
	cleaned["sessions_completed"] = maxi(0, int(value.get("sessions_completed", 0)))
	cleaned["rounds_completed"] = maxi(0, int(value.get("rounds_completed", 0)))
	cleaned["last_played_game"] = str(value.get("last_played_game", ""))
	cleaned["updated_at_unix"] = maxi(0, int(value.get("updated_at_unix", 0)))
	return cleaned


func save_progress() -> bool:
	data["updated_at_unix"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		push_error("无法保存进度：%s" % storage_path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func complete_round() -> void:
	data["rounds_completed"] = int(data.get("rounds_completed", 0)) + 1


func complete_session(game_id: String) -> void:
	data["sessions_completed"] = int(data.get("sessions_completed", 0)) + 1
	data["last_played_game"] = game_id
	save_progress()


func session_seed() -> int:
	return 20261001 + int(data.get("sessions_completed", 0)) * 7919

