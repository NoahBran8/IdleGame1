extends RefCounted

const INK := Color("#294b39")
const PAPER := Color("#fff9e9")
const MUTED := Color("#536b4c")
const GOLD := Color("#81551d")
const GREEN := Color("#527447")

static func box(color: Color = PAPER, border: Color = Color("#b8c48c"), radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0.16, 0.27, 0.14, 0.20)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	return style

static func make() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	for control: String in ["Label", "Button", "CheckButton"]:
		theme.set_color("font_color", control, INK)
		theme.set_color("font_hover_color", control, INK)
		theme.set_color("font_pressed_color", control, INK)
		theme.set_color("font_focus_color", control, INK)
		theme.set_color("font_disabled_color", control, Color("#60715b"))
	for control: String in ["PanelContainer","PopupPanel","AcceptDialog"]:
		theme.set_stylebox("panel",control,box())
	theme.set_stylebox("normal", "Button", box())
	theme.set_stylebox("hover", "Button", box(Color("#edf2ce"), Color("#78975b")))
	var pressed := box(Color("#dfebba"), Color("#6b8b4b"))
	pressed.shadow_size = 1
	pressed.shadow_offset = Vector2(0,1)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", box(Color("#e3e8d8"), Color("#b8c3a7")))
	var focus := box(Color(0,0,0,0), Color("#376e8e"))
	focus.set_border_width_all(3)
	theme.set_stylebox("focus", "Button", focus)
	return theme
