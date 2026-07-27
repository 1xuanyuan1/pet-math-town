extends Node

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
		push_error("TEST FAILED: %s" % message)


func _run() -> void:
	_test_content()
	_test_question_generator()
	_test_tts_manifests()
	_test_progress_store()
	await _test_story_flow()
	await _test_game_round()
	await _test_arithmetic_round("addition")
	await _test_arithmetic_round("subtraction")
	if _failures.is_empty():
		print("TESTS PASSED: %d checks" % _checks)
		get_tree().quit(0)
	else:
		print("TESTS FAILED: %d of %d checks" % [_failures.size(), _checks])
		for failure in _failures:
			print(" - %s" % failure)
		get_tree().quit(1)


func _test_content() -> void:
	var repository_script := load("res://scripts/autoload/content_repository.gd")
	var config: Dictionary = repository_script.load_json_file(
		"res://content/math/grade1_sem1/count_feeding.json"
	)
	_check(not config.is_empty(), "课程 JSON 应能加载")
	var errors: PackedStringArray = repository_script.validate_count_feeding(config)
	_check(errors.is_empty(), "课程 JSON 应通过校验：%s" % ", ".join(errors))
	_check(
		str(config.get("prompts", {}).get("target_template"))
		== "米米想要%d个胡萝卜。你可以帮我把胡萝卜放在篮子里吗？",
		"题目引导应先说明米米的需要，再发出友好请求"
	)

	var invalid := config.duplicate(true)
	invalid["session"]["difficulty_levels"][0]["maximum"] = 11
	var invalid_errors: PackedStringArray = repository_script.validate_count_feeding(invalid)
	_check(not invalid_errors.is_empty(), "超出 1–10 的范围必须被拒绝")
	var profile: Dictionary = repository_script.load_json_file("res://content/player_profile.json")
	var profile_errors: PackedStringArray = repository_script.validate_player_profile(profile)
	_check(profile_errors.is_empty(), "玩家称呼配置应通过校验：%s" % ", ".join(profile_errors))
	_check(ContentRepository.child_name_audio_id("香香") == "common.name_xiangxiang", "香香应命中内置名字音频")
	_check(ContentRepository.child_name_audio_id("自定义名字") == "common.name_default", "未知名字应回退默认音频")
	var story: Dictionary = repository_script.load_json_file(
		"res://content/story/garden_intro.json"
	)
	var story_errors: PackedStringArray = repository_script.validate_story_intro(story)
	_check(story_errors.is_empty(), "剧情序章应通过校验：%s" % ", ".join(story_errors))
	_check(story.get("lines", []).size() == 4, "剧情序章应包含四句对话")
	var first_story_sequence: Array = story.get("lines", [])[0].get("audio_sequence", [])
	_check(first_story_sequence[0] == "$child_name", "剧情中的小主人名必须是独立语音占位符")
	_check(first_story_sequence[1] == "story.garden_welcome", "剧情正文应与小主人名分开")

	var arithmetic: Dictionary = repository_script.load_json_file(
		"res://content/math/grade1_sem1/carrot_arithmetic.json"
	)
	var arithmetic_errors: PackedStringArray = repository_script.validate_carrot_arithmetic(arithmetic)
	_check(arithmetic_errors.is_empty(), "加减法课程 JSON 应通过校验：%s" % ", ".join(arithmetic_errors))
	_check(int(arithmetic.get("session", {}).get("maximum_result")) == 10, "首版加减法结果应限制在 10 以内")


func _test_question_generator() -> void:
	var first := CountQuestionGenerator.generate_sequence(20, 1, 5, 42)
	var second := CountQuestionGenerator.generate_sequence(20, 1, 5, 42)
	_check(first == second, "相同种子必须生成相同题目")
	_check(first.size() == 20, "题目数量必须与 round_count 一致")
	for index in range(first.size()):
		_check(first[index] >= 1 and first[index] <= 5, "题目必须位于配置范围")
		if index > 0:
			_check(first[index] != first[index - 1], "相邻题目不应重复")

	var config: Dictionary = ContentRepository.get_game_config("count_feeding")
	var first_level := CountQuestionGenerator.difficulty_for_sessions(config, 0)
	var second_level := CountQuestionGenerator.difficulty_for_sessions(config, 1)
	_check(int(first_level.get("maximum")) == 5, "首次游戏应使用 1–5")
	_check(int(second_level.get("maximum")) == 10, "完成一局后应解锁到 10")

	for operation in ["addition", "subtraction"]:
		var arithmetic_first := ArithmeticQuestionGenerator.generate_sequence(operation, 12, 10, 2026)
		var arithmetic_second := ArithmeticQuestionGenerator.generate_sequence(operation, 12, 10, 2026)
		_check(arithmetic_first == arithmetic_second, "%s 相同种子必须生成相同题目" % operation)
		_check(arithmetic_first.size() == 12, "%s 应生成指定数量的题目" % operation)
		for question in arithmetic_first:
			var left := int(question.get("left"))
			var right := int(question.get("right"))
			var answer := int(question.get("answer"))
			_check(answer >= 1 and answer <= 10, "%s 答案必须位于 1–10" % operation)
			_check(
				answer == (left + right if operation == "addition" else left - right),
				"%s 题目答案必须与算式一致" % operation
			)
			var choices := ArithmeticQuestionGenerator.answer_choices(question, 10, 99)
			_check(choices.size() == 3, "%s 每题应有三个答案选项" % operation)
			_check(answer in choices, "%s 答案选项必须包含正确答案" % operation)


func _test_tts_manifests() -> void:
	var manifest_file := FileAccess.open("res://audio/tts/manifest.json", FileAccess.READ)
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	var registry_file := FileAccess.open("res://audio/tts/registry.json", FileAccess.READ)
	var registry: Dictionary = JSON.parse_string(registry_file.get_as_text())
	var items: Array = manifest.get("items", [])
	_check(items.size() == 8, "拼接后的数数关只应保留八个固定语音片段")
	var common_manifest_file := FileAccess.open("res://audio/tts/common_tokens.json", FileAccess.READ)
	var common_manifest: Dictionary = JSON.parse_string(common_manifest_file.get_as_text())
	var common_items: Array = common_manifest.get("items", [])
	_check(common_items.size() == 58, "共享词库应包含角色名、数量词、0–40 和运算符")
	var arithmetic_manifest_file := FileAccess.open("res://audio/tts/arithmetic.json", FileAccess.READ)
	var arithmetic_manifest: Dictionary = JSON.parse_string(arithmetic_manifest_file.get_as_text())
	var arithmetic_items: Array = arithmetic_manifest.get("items", [])
	_check(arithmetic_items.size() == 10, "加减法应包含十个固定语音片段")
	var story_manifest_file := FileAccess.open("res://audio/tts/story_intro.json", FileAccess.READ)
	var story_manifest: Dictionary = JSON.parse_string(story_manifest_file.get_as_text())
	var story_items: Array = story_manifest.get("items", [])
	_check(story_items.size() == 4, "剧情序章 TTS 应包含四句对话")
	var hub_manifest_file := FileAccess.open("res://audio/tts/hub.json", FileAccess.READ)
	var hub_manifest: Dictionary = JSON.parse_string(hub_manifest_file.get_as_text())
	var hub_items: Array = hub_manifest.get("items", [])
	_check(hub_items.size() == 1, "小镇选关应包含一条语音引导")
	_check(
		registry.size()
		== items.size() + common_items.size() + arithmetic_items.size() + story_items.size() + hub_items.size() + 2,
		"Godot 音频注册表应覆盖所有可复用片段、剧情与小主人名"
	)
	var seen_ids := {}
	for item_value in items:
		var item: Dictionary = item_value
		var item_id := str(item.get("id"))
		_check(not seen_ids.has(item_id), "TTS id 不能重复：%s" % item_id)
		seen_ids[item_id] = true
		var registry_id := "count_feeding.%s" % item_id
		_check(registry.has(registry_id), "注册表缺少：%s" % registry_id)
		_check(str(item.get("text")).find("%d") == -1, "TTS 文本不能保留格式占位符")
		for name in ["米米", "点点", "团团", "香香", "小宝贝"]:
			_check(name not in str(item.get("text")), "固定对白不能录死名称：%s" % name)
	for item_value in common_items:
		var item: Dictionary = item_value
		_check(registry.has("common.%s" % str(item.get("id"))), "注册表缺少共享片段：%s" % item.get("id"))
	for item_value in arithmetic_items:
		var item: Dictionary = item_value
		var spoken_text := str(item.get("text"))
		_check(registry.has("arithmetic.%s" % str(item.get("id"))), "注册表缺少加减法片段：%s" % item.get("id"))
		for name in ["米米", "点点", "团团", "香香", "小宝贝"]:
			_check(name not in spoken_text, "加减法固定对白不能录死名称：%s" % name)

	var samples_file := FileAccess.open("res://audio/tts/samples.json", FileAccess.READ)
	var samples: Dictionary = JSON.parse_string(samples_file.get_as_text())
	var sample_items: Array = samples.get("items", [])
	_check(sample_items.size() == 3, "旁白试听清单应包含三种音色")
	var sample_text := str(sample_items[0].get("text"))
	for sample_value in sample_items:
		var sample: Dictionary = sample_value
		_check(str(sample.get("text")) == sample_text, "三音色试听必须使用相同文案")
	var personalization_file := FileAccess.open("res://audio/tts/personalization.json", FileAccess.READ)
	var personalization: Dictionary = JSON.parse_string(personalization_file.get_as_text())
	var personalization_items: Array = personalization.get("items", [])
	_check(personalization_items.size() == 2, "个性化 TTS 应包含默认名字和香香")
	_check(registry.has("common.name_default"), "注册表应包含默认名字")
	_check(registry.has("common.name_xiangxiang"), "注册表应包含香香")
	for story_item_value in story_items:
		var story_item: Dictionary = story_item_value
		var story_registry_id := "story.%s" % str(story_item.get("id"))
		_check(registry.has(story_registry_id), "注册表缺少剧情语音：%s" % story_registry_id)
	_check(registry.has("hub.choose_game"), "注册表应包含小镇选关引导")
	for audio_path_value in registry.values():
		var audio_path := str(audio_path_value)
		_check(ResourceLoader.exists(audio_path), "注册表音频必须存在：%s" % audio_path)


func _test_progress_store() -> void:
	var progress_script := load("res://scripts/autoload/progress_store.gd")
	var test_path := "user://progress-test-%d.json" % Time.get_ticks_usec()
	var first_store = progress_script.new()
	first_store.storage_path = test_path
	first_store.load_progress()
	first_store.complete_round()
	first_store.complete_session("count_feeding")
	_check(FileAccess.file_exists(test_path), "进度文件应写入 user://")

	var second_store = progress_script.new()
	second_store.storage_path = test_path
	second_store.load_progress()
	_check(int(second_store.data.get("rounds_completed")) == 1, "应恢复完成回合数")
	_check(int(second_store.data.get("sessions_completed")) == 1, "应恢复完成局数")
	_check(second_store.data.get("last_played_game") == "count_feeding", "应恢复最后游戏")
	_check(second_store.get_child_name() == "小宝贝", "默认小主人称呼应为小宝贝")
	_check(second_store.set_child_name("香香", false) == "香香", "应支持设置香香")
	_check(second_store.set_child_name("", false) == "小宝贝", "空名字应回退小宝贝")
	_check(second_store.set_child_name("一二三四五六七八九", false).length() == 8, "自定义名字最长八个字符")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	first_store.free()
	second_store.free()


func _test_story_flow() -> void:
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var story_view := main.get("_current_view") as Control
	_check(story_view != null and story_view.name == "GardenIntro", "启动后应先进入剧情序章")
	var dialogue := story_view.get("_dialogue_label") as Label
	_check(
		dialogue != null and ProgressStore.get_child_name() in dialogue.text,
		"剧情首句应包含小主人称呼"
	)
	var story_sequence: Array[String] = story_view.call(
		"_resolve_audio_sequence",
		story_view.get("_config").get("lines", [])[0].get("audio_sequence", [])
	)
	_check(story_sequence[0] == ContentRepository.child_name_audio_id(ProgressStore.get_child_name()), "剧情应独立解析小主人名音频")
	_check(story_sequence[1] == "story.garden_welcome", "剧情名字后应播放不含名字的正文")
	main.call("_show_town_hub")
	await get_tree().process_frame
	var hub_view := main.get("_current_view") as Control
	_check(hub_view != null and hub_view.name == "TownHub", "剧情结束后应进入小镇选关")
	var route_buttons: Dictionary = hub_view.get("_route_buttons")
	_check(not bool((route_buttons["count_feeding"] as Button).disabled), "数数配餐应可选")
	_check(not bool((route_buttons["addition"] as Button).disabled), "合起来加法关应已解锁")
	_check(not bool((route_buttons["subtraction"] as Button).disabled), "拿走了减法关应已解锁")
	main.call("_show_count_feeding")
	await get_tree().process_frame
	var game_view := main.get("_current_view") as Control
	_check(game_view != null and game_view.name == "CountFeeding", "剧情结束后应进入数数配餐")
	AudioManager.stop_voice()
	await get_tree().create_timer(0.1).timeout
	main.free()
	await get_tree().process_frame


func _test_game_round() -> void:
	var progress_backup: Dictionary = ProgressStore.data.duplicate(true)
	var storage_path_backup: String = ProgressStore.storage_path
	var game_test_path := "user://game-progress-test-%d.json" % Time.get_ticks_usec()
	ProgressStore.data = ProgressStore.default_data()
	ProgressStore.storage_path = game_test_path
	var game_scene := load("res://scenes/games/count_feeding/count_feeding.tscn") as PackedScene
	var game := game_scene.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	var target := int(game.get("_target_count"))
	_check(target >= 1 and target <= 5, "首回合目标应位于 1–5")
	var target_sequence: Array[String] = game.call("_target_audio_sequence")
	_check(target_sequence[0] == "common.character_mimi", "数数对白中的米米必须是独立名字片段")
	_check(target_sequence[1] == "count_feeding.wants", "角色名后应播放不含名字的‘想要’片段")
	_check(target_sequence[2] == "common.quantity_%02d" % target, "题目数量必须是独立数量词片段")
	var idle_timer := game.get("_idle_timer") as Timer
	_check(idle_timer != null and is_equal_approx(idle_timer.wait_time, 9.0), "无操作短提示应在九秒后触发")
	var wrong_count := 2 if target == 1 else 1
	for index in range(wrong_count):
		game.call("_on_supply_pressed", index)
	game.call("_on_confirm_pressed")
	_check(not bool(game.get("_round_locked")), "错误答案不应结束回合")
	var feedback := game.get("_feedback_label") as Label
	_check("再数一数" in feedback.text, "错误答案应给出温和重试提示")

	var selected: Array = game.get("_selected_sources")
	for source_index in selected.duplicate():
		game.call("_on_basket_pressed", source_index)
	for index in range(target):
		game.call("_on_supply_pressed", index)
	game.call("_on_confirm_pressed")
	_check(bool(game.get("_round_locked")), "正确答案提交后应锁定当前回合")
	await get_tree().create_timer(1.25).timeout
	_check(int(game.get("_round_index")) == 1, "正确答案后应进入下一回合")
	for expected_round in range(1, 5):
		var next_target := int(game.get("_target_count"))
		for index in range(next_target):
			game.call("_on_supply_pressed", index)
		game.call("_on_confirm_pressed")
		await get_tree().create_timer(1.25).timeout
	_check(int(ProgressStore.data.get("sessions_completed")) == 1, "完成五回合后应记录一局")
	_check(int(ProgressStore.data.get("rounds_completed")) == 5, "完整一局应记录五个回合")
	_check(game.get("_session_overlay") != null, "完成五回合后应显示庆祝重玩界面")

	AudioManager.stop_voice()
	await get_tree().create_timer(0.1).timeout
	game.free()
	await get_tree().process_frame
	if FileAccess.file_exists(game_test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game_test_path))
	ProgressStore.storage_path = storage_path_backup
	ProgressStore.data = progress_backup


func _test_arithmetic_round(test_operation: String) -> void:
	var progress_backup: Dictionary = ProgressStore.data.duplicate(true)
	var storage_path_backup: String = ProgressStore.storage_path
	var game_test_path := "user://arithmetic-progress-test-%s-%d.json" % [
		test_operation,
		Time.get_ticks_usec()
	]
	ProgressStore.data = ProgressStore.default_data()
	ProgressStore.storage_path = game_test_path
	var game_scene := load("res://scenes/games/carrot_arithmetic/carrot_arithmetic.tscn") as PackedScene
	var game := game_scene.instantiate()
	game.operation = test_operation
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	var questions: Array = game.get("_questions")
	_check(questions.size() == 5, "%s 一局应有五回合" % test_operation)
	var audio_sequence: Array[String] = game.call("_question_audio_sequence")
	_check(audio_sequence[0] == "common.character_mimi", "%s 对白中的米米必须独立播放" % test_operation)
	if test_operation == "addition":
		_check("common.character_diandian" in audio_sequence, "加法对白中的点点必须独立播放")
	_check(audio_sequence.count("common.object_carrots") == 2, "%s 两组数量都应带胡萝卜片段" % test_operation)

	var first_question: Dictionary = questions[0]
	var first_answer := int(first_question.get("answer"))
	var wrong_button: Button
	for candidate in game.get("_answer_row").get_children():
		if int((candidate as Button).get_meta("answer_value")) != first_answer:
			wrong_button = candidate as Button
			break
	game.call("_on_answer_pressed", first_answer + 20, wrong_button)
	_check(not bool(game.get("_round_locked")), "%s 答错后不应结束回合" % test_operation)
	_check("慢慢数一数" in (game.get("_feedback_label") as Label).text, "%s 答错应温和提示" % test_operation)

	for expected_round in range(5):
		var question: Dictionary = game.call("_current_question")
		var answer := int(question.get("answer"))
		var correct_button: Button
		for candidate in game.get("_answer_row").get_children():
			if int((candidate as Button).get_meta("answer_value")) == answer:
				correct_button = candidate as Button
				break
		_check(correct_button != null, "%s 每回合必须显示正确答案按钮" % test_operation)
		game.call("_on_answer_pressed", answer, correct_button)
		await get_tree().create_timer(1.15).timeout
	_check(int(ProgressStore.data.get("rounds_completed")) == 5, "%s 完成一局应记录五个回合" % test_operation)
	_check(int(ProgressStore.data.get("sessions_completed")) == 1, "%s 完成一局应记录一次会话" % test_operation)
	_check(game.get("_session_overlay") != null, "%s 完成后应显示庆祝界面" % test_operation)

	AudioManager.stop_voice()
	game.free()
	await get_tree().process_frame
	if FileAccess.file_exists(game_test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game_test_path))
	ProgressStore.storage_path = storage_path_backup
	ProgressStore.data = progress_backup
