extends Node


func reload_current_scene() -> void:
	get_tree().reload_current_scene()


func go_to(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("场景不存在：%s" % scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

