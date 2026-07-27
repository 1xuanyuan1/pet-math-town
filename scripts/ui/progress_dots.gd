class_name ProgressDots
extends Control

var round_count := 5:
	set(value):
		round_count = maxi(1, value)
		queue_redraw()
var completed := 0:
	set(value):
		completed = clampi(value, 0, round_count)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(300, 52)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var spacing := minf(54.0, size.x / float(round_count + 1))
	var total_width := spacing * float(round_count - 1)
	var start_x := (size.x - total_width) * 0.5
	for index in range(round_count):
		var center := Vector2(start_x + index * spacing, size.y * 0.5)
		var fill := Color("#68BF80") if index < completed else Color("#D5E8D8")
		draw_circle(center, 13.0, fill)
		draw_arc(center, 13.0, 0.0, TAU, 28, Color("#FFFFFF"), 3.0)
		if index < completed:
			draw_line(center + Vector2(-5, 0), center + Vector2(-1, 5), Color.WHITE, 3.0, true)
			draw_line(center + Vector2(-1, 5), center + Vector2(7, -5), Color.WHITE, 3.0, true)

