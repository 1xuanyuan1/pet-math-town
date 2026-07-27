class_name CarrotButton
extends Button

const CARROT_TEXTURE := preload("res://assets/art/items/carrot_icon.png")

var unavailable := false:
	set(value):
		unavailable = value
		disabled = value
		queue_redraw()
var removed := false:
	set(value):
		removed = value
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
	OffsetTransformButtonMotion.attach(self, OffsetTransformButtonMotion.MotionProfile.COMPACT)
	queue_redraw()


func _draw() -> void:
	var scale_value := minf(size.x / 72.0, size.y / 96.0)
	var center_x := size.x * 0.5
	if unavailable:
		draw_set_transform(Vector2(center_x, size.y * 0.72), 0.0, Vector2(1.7, 0.48) * scale_value)
		draw_circle(Vector2.ZERO, 13.0, Color(0.45, 0.32, 0.2, 0.18))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	var texture_size := CARROT_TEXTURE.get_size()
	var fit_scale := minf(size.x * 0.72 / texture_size.x, size.y * 0.88 / texture_size.y)
	var draw_size := texture_size * fit_scale
	var draw_position := Vector2(center_x - draw_size.x * 0.5, (size.y - draw_size.y) * 0.5)
	var carrot_color := Color(1.0, 1.0, 1.0, 0.42) if removed else Color.WHITE
	draw_texture_rect(CARROT_TEXTURE, Rect2(draw_position, draw_size), false, carrot_color)
	if removed:
		var badge_center := Vector2(center_x + draw_size.x * 0.36, draw_position.y + draw_size.y * 0.24)
		var badge_radius := 14.0 * scale_value
		draw_circle(badge_center, badge_radius, Color("#EF805C"))
		draw_line(
			badge_center - Vector2(badge_radius * 0.48, 0),
			badge_center + Vector2(badge_radius * 0.48, 0),
			Color.WHITE,
			4.0 * scale_value,
			true
		)
