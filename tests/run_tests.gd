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
	await _test_game_round()
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


func _test_tts_manifests() -> void:
	var manifest_file := FileAccess.open("res://audio/tts/manifest.json", FileAccess.READ)
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	var registry_file := FileAccess.open("res://audio/tts/registry.json", FileAccess.READ)
	var registry: Dictionary = JSON.parse_string(registry_file.get_as_text())
	var items: Array = manifest.get("items", [])
	_check(items.size() == 25, "首版 TTS 清单应包含 25 条语音")
	_check(registry.size() == items.size() + 2, "Godot 音频注册表应覆盖正式语音与名字片段")
	var seen_ids := {}
	for item_value in items:
		var item: Dictionary = item_value
		var item_id := str(item.get("id"))
		_check(not seen_ids.has(item_id), "TTS id 不能重复：%s" % item_id)
		seen_ids[item_id] = true
		var registry_id := "count_feeding.%s" % item_id
		_check(registry.has(registry_id), "注册表缺少：%s" % registry_id)
		_check(str(item.get("text")).find("%d") == -1, "TTS 文本不能保留格式占位符")
	_check(
		str(items[2].get("text"))
		== "米米想要三个胡萝卜。你可以帮我把胡萝卜放在篮子里吗？",
		"三个胡萝卜的 TTS 文案应与家长确认的引导一致"
	)

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
