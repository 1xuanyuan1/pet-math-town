class_name MascotView
extends Control

var mood := "happy":
	set(value):
		mood = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(180, 205)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.52)
	var scale_value := minf(size.x / 190.0, size.y / 215.0)
	var fur := Color("#FFF4DF")
	var fur_shadow := Color("#EACFAF")
	var pink := Color("#F3A8A8")
	var ink := Color("#564A45")

	# Ears are built from overlapping circles so the placeholder remains texture-free.
	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		var ear_x: float = center.x + side * 42.0 * scale_value
		draw_circle(Vector2(ear_x, center.y - 78.0 * scale_value), 25.0 * scale_value, fur_shadow)
		draw_circle(Vector2(ear_x, center.y - 98.0 * scale_value), 21.0 * scale_value, fur)
		draw_circle(Vector2(ear_x, center.y - 91.0 * scale_value), 10.0 * scale_value, pink)

	draw_circle(center + Vector2(0, 52.0) * scale_value, 58.0 * scale_value, Color("#F0D2A6"))
	draw_circle(center, 72.0 * scale_value, fur_shadow)
	draw_circle(center + Vector2(0, -5.0) * scale_value, 69.0 * scale_value, fur)
	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		draw_circle(center + Vector2(side * 31.0, 10.0) * scale_value, 8.0 * scale_value, ink)
		draw_circle(center + Vector2(side * 28.5, 7.0) * scale_value, 2.4 * scale_value, Color.WHITE)
		draw_circle(center + Vector2(side * 48.0, 29.0) * scale_value, 10.0 * scale_value, Color(0.95, 0.55, 0.55, 0.45))
	draw_circle(center + Vector2(0, 27.0) * scale_value, 7.0 * scale_value, pink)
	if mood == "thinking":
		draw_arc(center + Vector2(0, 47.0) * scale_value, 13.0 * scale_value, PI, TAU, 20, ink, 3.0 * scale_value)
	else:
		draw_arc(center + Vector2(0, 39.0) * scale_value, 18.0 * scale_value, 0.15, PI - 0.15, 20, ink, 3.5 * scale_value)
	draw_circle(center + Vector2(58.0, -54.0) * scale_value, 9.0 * scale_value, Color("#F8C95C"))
	draw_circle(center + Vector2(74.0, -42.0) * scale_value, 5.0 * scale_value, Color("#F8C95C"))
