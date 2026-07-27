extends Node

signal prompt_requested(audio_id: String, fallback_text: String)
signal missing_audio(audio_id: String)

const REGISTRY_PATH := "res://audio/tts/registry.json"

var _registry: Dictionary = {}
var _voice_player: AudioStreamPlayer
var _voice_queue: Array[AudioStream] = []


func _ready() -> void:
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Master"
	add_child(_voice_player)
	_voice_player.finished.connect(_play_next_queued_stream)
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
	_voice_queue.clear()
	prompt_requested.emit(audio_id, fallback_text)
	var stream := _load_registered_stream(audio_id)
	if stream == null:
		return false
	_voice_player.stream = stream
	_voice_player.play()
	return true


func play_sequence(audio_ids: Array, fallback_text: String = "") -> bool:
	stop_voice()
	var readable_ids: Array[String] = []
	for audio_id_value in audio_ids:
		readable_ids.append(str(audio_id_value))
	prompt_requested.emit("sequence:%s" % ",".join(readable_ids), fallback_text)
	for audio_id in readable_ids:
		var stream := _load_registered_stream(audio_id)
		if stream != null:
			_voice_queue.append(stream)
	if _voice_queue.is_empty():
		return false
	_play_next_queued_stream()
	return true


func _load_registered_stream(audio_id: String) -> AudioStream:
	var path := str(_registry.get(audio_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		missing_audio.emit(audio_id)
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		missing_audio.emit(audio_id)
	return stream


func _play_next_queued_stream() -> void:
	if _voice_queue.is_empty():
		return
	_voice_player.stream = _voice_queue.pop_front()
	_voice_player.play()


func stop_voice() -> void:
	_voice_queue.clear()
	if _voice_player != null:
		_voice_player.stop()
		_voice_player.stream = null
