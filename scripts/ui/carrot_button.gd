class_name CarrotButton
extends Button

var unavailable := false:
	set(value):
		unavailable = value
		disabled = value
		queue_redraw()
var compact := false:
	set(value):
		compact = value
		custom_minimum_size = Vector2(54, 72) if value else Vector2(68, 92)
		queue_redraw()


func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(68, 92) if not compact else Vector2(54, 72)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(_update_pivot)
	button_down.connect(_press_in)
	button_up.connect(_press_out)
	mouse_exited.connect(_press_out)
	queue_redraw()


func _update_pivot() -> void:
	pivot_offset = size * 0.5
	queue_redraw()


func _press_in() -> void:
	if not unavailable:
		scale = Vector2(0.92, 0.92)


func _press_out() -> void:
	if scale != Vector2.ONE:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.18)


func _draw() -> void:
	var scale_value := minf(size.x / 72.0, size.y / 96.0)
	var center_x := size.x * 0.5
	if unavailable:
		draw_set_transform(Vector2(center_x, size.y * 0.72), 0.0, Vector2(1.7, 0.48) * scale_value)
		draw_circle(Vector2.ZERO, 13.0, Color(0.45, 0.32, 0.2, 0.18))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	var top_y := 32.0 * scale_value
	var bottom_y := 83.0 * scale_value
	var half_width := 18.0 * scale_value
	draw_circle(Vector2(center_x, top_y), half_width, Color("#F59A45"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - half_width, top_y),
		Vector2(center_x + half_width, top_y),
		Vector2(center_x + 4.0 * scale_value, bottom_y),
		Vector2(center_x - 3.0 * scale_value, bottom_y + 4.0 * scale_value)
	]), Color("#F28B36"))
	var leaf_green := Color("#58A966")
	draw_line(Vector2(center_x, top_y - 8.0 * scale_value), Vector2(center_x, 7.0 * scale_value), leaf_green, 7.0 * scale_value, true)
	draw_line(Vector2(center_x - 3.0 * scale_value, top_y - 5.0 * scale_value), Vector2(center_x - 18.0 * scale_value, 12.0 * scale_value), leaf_green, 7.0 * scale_value, true)
	draw_line(Vector2(center_x + 3.0 * scale_value, top_y - 5.0 * scale_value), Vector2(center_x + 18.0 * scale_value, 12.0 * scale_value), leaf_green, 7.0 * scale_value, true)
	for stripe in range(3):
		var y := (47.0 + stripe * 11.0) * scale_value
		var width := (10.0 - stripe * 2.0) * scale_value
		draw_line(Vector2(center_x - width, y), Vector2(center_x + 2.0 * scale_value, y + 2.0 * scale_value), Color(0.78, 0.34, 0.12, 0.65), 2.0 * scale_value, true)

