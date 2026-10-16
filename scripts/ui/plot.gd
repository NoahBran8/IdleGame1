extends Button

var species: String = ""
var stage: int = -1
var locked: bool = false
var contrast: bool = false
var highlight: bool = false

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
	draw_colored_polygon(bottom, Color("#1b3029"))
	var fill := Color("#73543a") if not locked else Color("#20392f")
	if stage == 3:
		fill = Color("#82643d")
	if contrast:
		fill = Color("#63432a") if not locked else Color("#17241e")
	draw_colored_polygon(diamond, fill)
	var outline := diamond.duplicate()
	outline.append(diamond[0])
	draw_polyline(outline, Color("#f4d48b") if stage == 3 or highlight else Color("#8e7956") if not locked else Color("#3d5344"), 2, true)
	if locked:
		draw_string(ThemeDB.fallback_font, center + Vector2(-10, 6), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#6d8574"))
		return
	for offset: int in [-1, 0, 1]:
		draw_line(center + Vector2(-22, offset * 7), center + Vector2(22, offset * 7 - 10), Color("#5c402f"), 1, true)
	if stage < 0:
		draw_string(ThemeDB.fallback_font, center + Vector2(-6, 4), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c39a"))
		return
	var height: float = 12.0 + stage * 6.0
	var base := center + Vector2(0, 4)
	var tip := base + Vector2(0, -height)
	draw_line(base, tip, Color("#82b46a"), 3, true)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 9), tip + Vector2(-15, 1), tip + Vector2(-12, 12)]), Color("#94c47a"))
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 12), tip + Vector2(14, 3), tip + Vector2(12, 14)]), Color("#5c9a60"))
	if stage == 0:
		return
	var colors: Dictionary = {"carrot": Color("#ef995b"), "sunflower": Color("#e8c760"), "rose": Color("#e99197"), "lavender": Color("#b6a0d9"), "orchid": Color("#dfb1d4")}
	var color: Color = colors.get(species, Color.WHITE)
	if species == "carrot":
		draw_colored_polygon(PackedVector2Array([base + Vector2(-6, -3), base + Vector2(6, -3), base + Vector2(0, 12)]), color)
	else:
		for petal: int in range(5):
			var angle: float = TAU * petal / 5.0
			draw_circle(tip + Vector2(cos(angle), sin(angle)) * 7, 6 if stage == 3 else 4, color)
		draw_circle(tip, 4, Color("#6b492e"))
	draw_string(ThemeDB.fallback_font, center + Vector2(-15, 23), "Ready" if stage == 3 else "%d/3" % (stage + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f4e5ba"))
	if stage == 3:
		draw_circle(center + Vector2(28, -10), 4, Color("#f4d48b"))

func _has_point(point: Vector2) -> bool:
	var normalized: Vector2 = (point - size * 0.5) / (size * Vector2(0.5, 0.48))
	return absf(normalized.x) + absf(normalized.y) <= 1.05
