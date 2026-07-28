class_name TenBundleButton
extends Button

const CARROT_TEXTURE := preload("res://assets/art/items/carrot_icon.png")

var borrowed := false:
	set(value):
		borrowed = value
		queue_redraw()


func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(112, 150)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	OffsetTransformButtonMotion.attach(self, OffsetTransformButtonMotion.MotionProfile.COMPACT)
	queue_redraw()


func _draw() -> void:
	var carrot_size := Vector2(23, 46)
	var start := Vector2((size.x - carrot_size.x * 5.0) * 0.5, 22)
	var tint := Color(1, 1, 1, 0.35) if borrowed else Color.WHITE
	for row in range(2):
		for column in range(5):
			var carrot_position := start + Vector2(column * 22.5, row * 38.0)
			draw_texture_rect(CARROT_TEXTURE, Rect2(carrot_position, carrot_size), false, tint)
	var ribbon_color := Color(0.78, 0.51, 0.24, 0.38) if borrowed else Color("#C7863F")
	var ribbon_y := size.y * 0.55
	draw_rect(Rect2(4, ribbon_y, size.x - 8, 10), ribbon_color, true)
	draw_circle(Vector2(size.x * 0.5, ribbon_y + 5), 10, ribbon_color)
	if borrowed:
		var badge_center := Vector2(size.x - 20, 22)
		draw_circle(badge_center, 14, Color("#EF805C"))
		draw_line(
			badge_center - Vector2(7, 0),
			badge_center + Vector2(7, 0),
			Color.WHITE,
			4,
			true
		)
