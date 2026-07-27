extends Node

signal prompt_requested(audio_id: String, fallback_text: String)
signal missing_audio(audio_id: String)

const REGISTRY_PATH := "res://audio/tts/registry.json"

var _registry: Dictionary = {}
var _voice_player: AudioStreamPlayer


func _ready() -> void:
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Master"
	add_child(_voice_player)
	_reload_registry()


func _reload_registry() -> void:
	_registry.clear()
	if not FileAccess.file_exists(REGISTRY_PATH):
		return
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_registry = parsed


func play_prompt(audio_id: String, fallback_text: String = "") -> bool:
	prompt_requested.emit(audio_id, fallback_text)
	var path := str(_registry.get(audio_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		missing_audio.emit(audio_id)
		return false
	var stream := load(path) as AudioStream
	if stream == null:
		missing_audio.emit(audio_id)
		return false
	_voice_player.stream = stream
	_voice_player.play()
	return true


func stop_voice() -> void:
	if _voice_player != null:
		_voice_player.stop()

