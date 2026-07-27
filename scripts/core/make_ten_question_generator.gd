class_name MakeTenQuestionGenerator
extends RefCounted


static func generate_sequence(
	question_pool: Array,
	count: int,
	seed_value: int
) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for question_value in question_pool:
		if not question_value is Dictionary:
			continue
		var question := build_question(
			int(question_value.get("left", 0)),
			int(question_value.get("right", 0))
		)
		if not question.is_empty():
			pool.append(question)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_shuffle(pool, rng)
	var result: Array[Dictionary] = []
	for question in pool:
		if result.size() >= count:
			break
		if not result.is_empty():
			var previous: Dictionary = result[-1]
			if int(previous.get("answer")) == int(question.get("answer")):
				continue
			if int(previous.get("gap")) == int(question.get("gap")):
				continue
		result.append(question)
	if result.size() < count:
		for question in pool:
			if result.size() >= count:
				break
			if question not in result:
				result.append(question)
	return result


static func build_question(left: int, right: int) -> Dictionary:
	var gap := 10 - left
	var remainder := right - gap
	var answer := left + right
	if left < 6 or left > 9:
		return {}
	if right < 2 or right > left:
		return {}
	if gap < 1 or remainder < 1:
		return {}
	if answer < 11 or answer > 18:
		return {}
	return {
		"left": left,
		"right": right,
		"gap": gap,
		"remainder": remainder,
		"answer": answer
	}


static func _shuffle(values: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
