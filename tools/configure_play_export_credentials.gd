extends SceneTree

const CREDENTIALS_PATH := "res://.godot/export_credentials.cfg"
const PLAY_PRESET_SECTION := "preset.2"
const PLAY_OPTIONS_SECTION := "preset.2.options"


func _initialize() -> void:
	var keystore_path := OS.get_environment("GODOT_ANDROID_KEYSTORE_RELEASE_PATH")
	var keystore_user := OS.get_environment("GODOT_ANDROID_KEYSTORE_RELEASE_USER")
	var keystore_password := OS.get_environment("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD")
	if keystore_path.is_empty() or keystore_user.is_empty() or keystore_password.is_empty():
		push_error("缺少 Google Play 上传密钥环境变量，未写入导出凭据。")
		quit(1)
		return

	var credentials := ConfigFile.new()
	var absolute_path := ProjectSettings.globalize_path(CREDENTIALS_PATH)
	if FileAccess.file_exists(absolute_path):
		var load_error := credentials.load(absolute_path)
		if load_error != OK:
			push_error("无法读取现有导出凭据：%s" % error_string(load_error))
			quit(1)
			return

	credentials.set_value(PLAY_PRESET_SECTION, "script_encryption_key", "")
	credentials.set_value(PLAY_OPTIONS_SECTION, "keystore/debug", "")
	credentials.set_value(PLAY_OPTIONS_SECTION, "keystore/debug_user", "")
	credentials.set_value(PLAY_OPTIONS_SECTION, "keystore/debug_password", "")
	credentials.set_value(PLAY_OPTIONS_SECTION, "keystore/release", keystore_path)
	credentials.set_value(PLAY_OPTIONS_SECTION, "keystore/release_user", keystore_user)
	credentials.set_value(PLAY_OPTIONS_SECTION, "keystore/release_password", keystore_password)
	var save_error := credentials.save(absolute_path)
	if save_error != OK:
		push_error("无法保存导出凭据：%s" % error_string(save_error))
		quit(1)
		return

	print("已配置 Android Play AAB 导出凭据。")
	quit(0)
