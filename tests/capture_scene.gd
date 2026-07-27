extends Node


func _ready() -> void:
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := main_scene.instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() > 1:
		var requested_view := str(arguments[1])
		if requested_view == "hub":
			main.call("_show_town_hub")
			await get_tree().process_frame
			await get_tree().process_frame
		elif requested_view in ["addition", "subtraction"]:
			main.call("_show_arithmetic", requested_view)
			await get_tree().process_frame
			await get_tree().process_frame
		else:
			var selected_count := clampi(int(requested_view), 0, 10)
			var game := main.get_child(0)
			for index in range(selected_count):
				game.call("_on_supply_pressed", index)
			await get_tree().process_frame
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("当前显示驱动不支持截图；请不要使用 --headless")
		get_tree().quit(2)
		return
	var output_path := arguments[0] if not arguments.is_empty() else "/tmp/pet-math-town.png"
	var result := image.save_png(output_path)
	if result != OK:
		push_error("无法保存截图：%s" % output_path)
		get_tree().quit(1)
		return
	print("SCREENSHOT: %s (%dx%d)" % [output_path, image.get_width(), image.get_height()])
	get_tree().quit(0)
