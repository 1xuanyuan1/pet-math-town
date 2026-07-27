class_name ArithmeticQuestionGenerator
extends RefCounted


static func generate_sequence(
	operation: String,
	count: int,
	maximum_result: int,
	seed_value: int
) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	if operation == "addition":
		for left in range(1, maximum_result):
			for right in range(1, maximum_result):
				if left + right <= maximum_result:
					pool.append({"left": left, "right": right, "answer": left + right})
	elif operation == "subtraction":
		for left in range(2, maximum_result + 1):
			for right in range(1, left):
				pool.append({"left": left, "right": right, "answer": left - right})
	else:
		return []
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
		result.append(question)
	return result


static func answer_choices(question: Dictionary, maximum_result: int, seed_value: int) -> Array[int]:
	var answer := int(question.get("answer", 0))
	var choices: Array[int] = [answer]
	for offset in [1, -1, 2, -2, 3, -3]:
		var candidate: int = answer + int(offset)
		if candidate >= 0 and candidate <= maximum_result and candidate not in choices:
			choices.append(candidate)
		if choices.size() == 3:
			break
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index in range(choices.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := choices[index]
		choices[index] = choices[swap_index]
		choices[swap_index] = value
	return choices


static func _shuffle(values: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
