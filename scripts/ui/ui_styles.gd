class_name UIStyles
extends RefCounted

const INK := Color("#3D4A3F")
const GREEN := Color("#55B978")
const GREEN_DARK := Color("#348B58")
const CREAM := Color("#FFF9E8")
const ORANGE := Color("#F59A4A")
const SOFT_ORANGE := Color("#FFE2B8")
const BLUE := Color("#83C8E8")

static func rounded_box(
	color: Color,
	radius: int = 24,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 18.0
	style.content_margin_top = 12.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 12.0
	return style


static func apply_button(
	button: Button,
	base_color: Color,
	hover_color: Color,
	pressed_color: Color,
	disabled_color: Color = Color("#D5DED5")
) -> void:
	button.add_theme_stylebox_override("normal", rounded_box(base_color, 22))
	button.add_theme_stylebox_override("hover", rounded_box(hover_color, 22))
	button.add_theme_stylebox_override("pressed", rounded_box(pressed_color, 22))
	button.add_theme_stylebox_override("focus", rounded_box(base_color, 22, Color.WHITE, 4))
	button.add_theme_stylebox_override("disabled", rounded_box(disabled_color, 22))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#8A968C"))
	OffsetTransformButtonMotion.attach(button)


static func apply_card_motion(button: Button) -> void:
	OffsetTransformButtonMotion.attach(button, OffsetTransformButtonMotion.MotionProfile.CARD)
