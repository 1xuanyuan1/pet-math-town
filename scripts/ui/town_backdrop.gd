class_name TownBackdrop
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#E8F7EA"))
	var horizon := size.y * 0.72
	draw_circle(Vector2(size.x * 0.08, horizon + 110.0), 260.0, Color("#BEE8C8"))
	draw_circle(Vector2(size.x * 0.32, horizon + 150.0), 300.0, Color("#A8DDB8"))
	draw_circle(Vector2(size.x * 0.78, horizon + 125.0), 330.0, Color("#B6E5C2"))
	draw_circle(Vector2(size.x * 1.02, horizon + 140.0), 290.0, Color("#9ED6AF"))
	_draw_cloud(Vector2(size.x * 0.13, size.y * 0.13), 0.9)
	_draw_cloud(Vector2(size.x * 0.78, size.y * 0.09), 0.7)
	_draw_house(Vector2(size.x * 0.035, horizon - 88.0), Color("#FFD38E"), Color("#E87A62"))
	_draw_house(Vector2(size.x * 0.88, horizon - 72.0), Color("#A9D8EE"), Color("#6D87B5"))


func _draw_cloud(origin: Vector2, scale_value: float) -> void:
	var cloud := Color(1.0, 1.0, 1.0, 0.72)
	draw_circle(origin + Vector2(0, 10) * scale_value, 26.0 * scale_value, cloud)
	draw_circle(origin + Vector2(28, 0) * scale_value, 34.0 * scale_value, cloud)
	draw_circle(origin + Vector2(62, 12) * scale_value, 24.0 * scale_value, cloud)
	draw_rect(Rect2(origin + Vector2(0, 10) * scale_value, Vector2(62, 28) * scale_value), cloud)


func _draw_house(origin: Vector2, wall: Color, roof: Color) -> void:
	draw_rect(Rect2(origin + Vector2(8, 34), Vector2(86, 68)), wall)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(0, 40),
		origin + Vector2(50, 0),
		origin + Vector2(102, 40)
	]), roof)
	draw_rect(Rect2(origin + Vector2(38, 62), Vector2(25, 40)), Color("#8E6D57"))

