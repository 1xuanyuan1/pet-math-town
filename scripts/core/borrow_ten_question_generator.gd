class_name BorrowTenQuestionGenerator
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
			if int(previous.get("tens")) == int(question.get("tens")):
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
			selected = question
			break
		if selected.is_empty():
			break
		result.append(selected)
	return result


static func build_question(left: int, right: int) -> Dictionary:
	@warning_ignore("integer_division")
	var tens := left / 10
	var ones := left % 10
	var tens_left := tens - 1
	var borrowed_ones := 10 + ones
	var ones_left := borrowed_ones - right
	var answer := left - right
	if left < 21 or left > 39:
		return {}
	if tens < 2 or ones < 1 or ones > 8:
		return {}
	if right < 2 or right > 9 or right <= ones:
		return {}
	if tens_left < 1 or ones_left < 1 or ones_left > 9:
		return {}
	if answer != tens_left * 10 + ones_left:
		return {}
	return {
		"left": left,
		"right": right,
		"tens": tens,
		"ones": ones,
		"tens_left": tens_left,
		"borrowed_ones": borrowed_ones,
		"ones_left": ones_left,
		"answer": answer
	}


static func _shuffle(values: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
