class_name FlatTenQuestionGenerator
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
			if int(previous.get("to_ten")) == int(question.get("to_ten")):
				continue
		result.append(question)
	while result.size() < count:
		var selected: Dictionary = {}
		for question in pool:
			if question in result:
				continue
			var previous: Dictionary = result[-1]
			if int(previous.get("answer")) == int(question.get("answer")):
				continue
			if int(previous.get("to_ten")) == int(question.get("to_ten")):
				continue
			selected = question
			break
		if selected.is_empty():
			for question in pool:
				if question in result:
					continue
				if int(result[-1].get("answer")) != int(question.get("answer")):
					selected = question
					break
		if selected.is_empty():
			break
		result.append(selected)
	return result


static func build_question(left: int, right: int) -> Dictionary:
	var to_ten := left - 10
	var remainder := right - to_ten
	var answer := left - right
	if left < 11 or left > 18:
		return {}
	if right < 2 or right > 9:
		return {}
	if to_ten < 1 or remainder < 1:
		return {}
	if answer < 2 or answer > 9:
		return {}
	return {
		"left": left,
		"right": right,
		"to_ten": to_ten,
		"remainder": remainder,
		"answer": answer
	}


static func _shuffle(values: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
