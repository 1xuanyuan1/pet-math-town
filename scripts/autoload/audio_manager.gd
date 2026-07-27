extends Node

signal prompt_requested(audio_id: String, fallback_text: String)
signal missing_audio(audio_id: String)

const REGISTRY_PATH := "res://audio/tts/registry.json"
const SEQUENCE_EDGE_TRIM_SECONDS := 0.28

var _registry: Dictionary = {}
var _voice_player: AudioStreamPlayer
var _sequence_timer: Timer
var _voice_queue: Array[AudioStream] = []
var _sequence_active := false


func _ready() -> void:
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Master"
	add_child(_voice_player)
	_voice_player.finished.connect(_play_next_queued_stream)
	_sequence_timer = Timer.new()
	_sequence_timer.one_shot = true
	_sequence_timer.timeout.connect(_play_next_queued_stream)
	add_child(_sequence_timer)
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
	stop_voice()
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
	var streams: Array[AudioStream] = []
	for audio_id in readable_ids:
		var stream := _load_registered_stream(audio_id)
		if stream == null:
			_voice_queue.clear()
			return false
		streams.append(stream)
	if streams.is_empty():
		return false
	_voice_queue.assign(streams)
	_sequence_active = true
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
	if _sequence_timer != null:
		_sequence_timer.stop()
	if _voice_queue.is_empty():
		_sequence_active = false
		return
	_voice_player.stream = _voice_queue.pop_front()
	var stream_length := _voice_player.stream.get_length()
	var edge_trim := minf(SEQUENCE_EDGE_TRIM_SECONDS, stream_length * 0.2)
	_voice_player.play(edge_trim)
	_sequence_timer.start(maxf(0.05, stream_length - edge_trim * 2.0))


func stop_voice() -> void:
	_voice_queue.clear()
	_sequence_active = false
	if _sequence_timer != null:
		_sequence_timer.stop()
	if _voice_player != null:
		_voice_player.stop()
		_voice_player.stream = null
