extends Button

var species: String = ""
var stage: int = -1
var locked: bool = false
var contrast: bool = false
var highlight: bool = false
var seconds_left: int = 0
var progress: float = 0.0

func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _draw() -> void:
	var center := size * 0.5
	var half := Vector2(size.x * 0.48, size.y * 0.42)
	var diamond := PackedVector2Array([center + Vector2(-half.x, 0), center + Vector2(0, -half.y), center + Vector2(half.x, 0), center + Vector2(0, half.y)])
	var bottom := diamond.duplicate()
	for i: int in range(bottom.size()):
		bottom[i] += Vector2(0, 6)
	draw_colored_polygon(bottom, Color("#987350"))
	var fill := Color("#c39a64") if not locked else Color("#9dbb78")
	if stage == 3:
		fill = Color("#d4ad6c")
	if contrast:
		fill = Color("#63432a") if not locked else Color("#17241e")
	draw_colored_polygon(diamond, fill)
	var outline := diamond.duplicate()
	outline.append(diamond[0])
	var bright: bool = stage == 3 or highlight or has_focus() or is_hovered()
	draw_polyline(outline, Color("#fff1b3") if bright else Color("#a57e50") if not locked else Color("#799663"), 2, true)
	if locked:
		for offset: int in [-1, 1]:
			var stone := center + Vector2(offset * size.x * 0.15, 2)
			draw_circle(stone, 4, Color("#d6cfad"))
		_text("×", center + Vector2(0, 5), 18, Color("#e4eacb") if contrast else Color("#4f6e42"))
		return
	for offset: int in [-1, 0, 1]:
		draw_line(center + Vector2(-22, offset * 7), center + Vector2(22, offset * 7 - 10), Color("#a77b4c"), 1, true)
	if stage < 0:
		_text("+", center + Vector2(0, 5), 20, Color("#fff1c6") if contrast else Color("#674c33"))
		return
	var base := center + Vector2(0, 1)
	var tip := base + Vector2(0, -12 - stage * 6)
	draw_line(base, tip, Color("#88b66e"), 3, true)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 9), tip + Vector2(-15, 1), tip + Vector2(-12, 12)]), Color("#94c47a"))
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 12), tip + Vector2(14, 3), tip + Vector2(12, 14)]), Color("#5c9a60"))
	if stage > 0:
		_flower(tip, base)
	var text_position := center + Vector2(0, minf(23, size.y * 0.34))
	if stage == 3:
		_text("Ready", text_position, 11, Color("#382f20") if not contrast else Color("#fff1c6"))
		draw_circle(center + Vector2(size.x * 0.27, -9), 3, Color("#fff1b3"))
	else:
		var countdown: String = "%ds" % seconds_left if seconds_left < 60 else "%d:%02d" % [seconds_left / 60, seconds_left % 60]
		_text(countdown, text_position, 11, Color("#382f20") if not contrast else Color("#f4e5ba"))
		var meter := Rect2(center + Vector2(-14, minf(26, size.y * 0.40)), Vector2(28, 3))
		draw_rect(meter, Color("#332c23"))
		draw_rect(Rect2(meter.position, Vector2(meter.size.x * progress, 3)), Color("#c6d59b"))

func _flower(tip: Vector2, base: Vector2) -> void:
	var scale_factor: float = 1.0 if stage == 3 else 0.75 if stage == 2 else 0.5
	match species:
		"carrot":
			draw_colored_polygon(PackedVector2Array([base + Vector2(-7, -3), base + Vector2(7, -3), base + Vector2(0, 14 * scale_factor)]), Color("#f0a15d"))
			draw_line(base + Vector2(-3, 2), base + Vector2(3, 3), Color("#bd683c"), 1, true)
			for leaf: int in [-1, 0, 1]:
				draw_line(base, base + Vector2(leaf * 9, -17 - (1 - absi(leaf)) * 7), Color("#b6cc79"), 3, true)
		"sunflower":
			for petal: int in range(9):
				var angle: float = TAU * petal / 9.0
				draw_circle(tip + Vector2(cos(angle), sin(angle)) * 9 * scale_factor, 5 * scale_factor, Color("#efce65"))
			draw_circle(tip, 6 * scale_factor, Color("#705234"))
			draw_circle(tip + Vector2(-2, -1) * scale_factor, 1.5 * scale_factor, Color("#aa8650"))
		"rose":
			for petal: int in range(6):
				var angle: float = TAU * petal / 6.0
				draw_circle(tip + Vector2(cos(angle), sin(angle)) * 6 * scale_factor, 6 * scale_factor, Color("#d97d8d"))
			draw_circle(tip, 6 * scale_factor, Color("#f1b5b2"))
			draw_arc(tip, 3 * scale_factor, 0.0, PI * 1.6, 12, Color("#b75d79"), 1.5, true)
		"lavender":
			for stem: int in [-1, 0, 1]:
				var top := tip + Vector2(stem * 8, absi(stem) * 5)
				draw_line(base, top, Color("#82a86a"), 2, true)
				for bud: int in range(4):
					draw_circle(top + Vector2((1 if bud % 2 == 0 else -1) * 2, bud * 4) * scale_factor, 3 * scale_factor, Color("#bca3e0") if bud % 2 else Color("#917bb5"))
		"orchid":
			for petal: int in range(5):
				var angle: float = TAU * petal / 5.0 - PI * 0.5
				var point := tip + Vector2(cos(angle) * 10, sin(angle) * 8) * scale_factor
				draw_circle(point, 7 * scale_factor, Color("#e0bddb"))
				draw_circle(point + Vector2(0, 1), 3 * scale_factor, Color("#c58bbb"))
			draw_circle(tip + Vector2(0, 4) * scale_factor, 4 * scale_factor, Color("#f5d79a"))

func _text(value: String, point: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, point - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _has_point(point: Vector2) -> bool:
	var normalized: Vector2 = (point - size * 0.5) / (size * Vector2(0.5, 0.48))
	return absf(normalized.x) + absf(normalized.y) <= 1.05
