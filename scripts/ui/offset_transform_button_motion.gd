class_name OffsetTransformButtonMotion
extends Node

enum MotionProfile {
	BUTTON,
	CARD,
	COMPACT
}

const CONTROLLER_META := "offset_transform_motion_controller"
const PROFILE_META := "ui_offset_motion_profile"

var _button: Button
var _profile := MotionProfile.BUTTON
var _hover_position := Vector2(0, -2)
var _hover_scale := Vector2(1.015, 1.015)
var _press_position := Vector2(0, 3)
var _press_scale := Vector2(0.97, 0.97)
var _hovering := false
var _focused := false
var _pressing := false
var _motion_tween: Tween


static func attach(
	button: Button,
	profile: MotionProfile = MotionProfile.BUTTON
) -> OffsetTransformButtonMotion:
	var existing: OffsetTransformButtonMotion
	if button.has_meta(CONTROLLER_META):
		existing = button.get_meta(CONTROLLER_META) as OffsetTransformButtonMotion
	if existing != null and is_instance_valid(existing):
		existing.set_profile(profile)
		return existing
	var controller := OffsetTransformButtonMotion.new()
	controller.name = "OffsetTransformMotion"
	controller._button = button
	controller._profile = profile
	button.set_meta(CONTROLLER_META, controller)
	button.add_child(controller, false, Node.INTERNAL_MODE_BACK)
	return controller


func _ready() -> void:
	if _button == null:
		_button = get_parent() as Button
	if _button == null:
		queue_free()
		return
	_apply_profile()
	_button.mouse_entered.connect(_on_mouse_entered)
	_button.mouse_exited.connect(_on_mouse_exited)
	_button.focus_entered.connect(_on_focus_entered)
	_button.focus_exited.connect(_on_focus_exited)
	_button.button_down.connect(_on_button_down)
	_button.button_up.connect(_on_button_up)


func set_profile(profile: MotionProfile) -> void:
	_profile = profile
	if is_node_ready():
		_apply_profile()


func _apply_profile() -> void:
	match _profile:
		MotionProfile.CARD:
			_hover_position = Vector2(0, -7)
			_hover_scale = Vector2(1.025, 1.025)
			_press_position = Vector2(0, 3)
			_press_scale = Vector2(0.975, 0.975)
			_button.set_meta(PROFILE_META, "card")
		MotionProfile.COMPACT:
			_hover_position = Vector2(0, -2)
			_hover_scale = Vector2(1.035, 1.035)
			_press_position = Vector2(0, 3)
			_press_scale = Vector2(0.92, 0.92)
			_button.set_meta(PROFILE_META, "compact")
		_:
			_hover_position = Vector2(0, -2)
			_hover_scale = Vector2(1.015, 1.015)
			_press_position = Vector2(0, 3)
			_press_scale = Vector2(0.97, 0.97)
			_button.set_meta(PROFILE_META, "button")
	_button.offset_transform_enabled = true
	_button.offset_transform_visual_only = true
	_button.offset_transform_pivot_ratio = Vector2(0.5, 0.5)


func _on_mouse_entered() -> void:
	_hovering = true
	_settle()


func _on_mouse_exited() -> void:
	_hovering = false
	_settle()


func _on_focus_entered() -> void:
	_focused = true
	_settle()


func _on_focus_exited() -> void:
	_focused = false
	_settle()


func _on_button_down() -> void:
	_pressing = true
	_animate(_press_position, _press_scale, 0.08)


func _on_button_up() -> void:
	_pressing = false
	_settle()


func _settle() -> void:
	if _pressing:
		return
	var highlighted := not _button.disabled and (_hovering or _focused)
	_animate(
		_hover_position if highlighted else Vector2.ZERO,
		_hover_scale if highlighted else Vector2.ONE,
		0.16
	)


func _animate(target_position: Vector2, target_scale: Vector2, duration: float) -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween()
	_motion_tween.set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD)
	_motion_tween.set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(_button, "offset_transform_position", target_position, duration)
	_motion_tween.tween_property(_button, "offset_transform_scale", target_scale, duration)


func _exit_tree() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
