class_name CountQuestionGenerator
extends RefCounted


static func difficulty_for_sessions(config: Dictionary, sessions_completed: int) -> Dictionary:
	var levels: Array = config.get("session", {}).get("difficulty_levels", [])
	var selected: Dictionary = {}
	for level_value in levels:
		if not level_value is Dictionary:
			continue
		var level: Dictionary = level_value
		if sessions_completed >= int(level.get("min_sessions", 0)):
			selected = level
	if selected.is_empty() and not levels.is_empty() and levels[0] is Dictionary:
		selected = levels[0]
	return selected.duplicate(true)


static func generate_sequence(
	round_count: int,
	minimum: int,
	maximum: int,
	seed_value: int
) -> Array[int]:
	var result: Array[int] = []
	if round_count <= 0 or minimum > maximum:
		return result
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var previous := minimum - 1
	for index in range(round_count):
		var candidate := rng.randi_range(minimum, maximum)
		if maximum > minimum and candidate == previous:
			var offset := rng.randi_range(1, maximum - minimum)
			candidate = minimum + ((candidate - minimum + offset) % (maximum - minimum + 1))
		result.append(candidate)
		previous = candidate
	return result


static func generate_for_session(config: Dictionary, sessions_completed: int, seed_value: int) -> Array[int]:
	var difficulty := difficulty_for_sessions(config, sessions_completed)
	return generate_sequence(
		int(config.get("session", {}).get("round_count", 5)),
		int(difficulty.get("minimum", 1)),
		int(difficulty.get("maximum", 5)),
		seed_value
	)

