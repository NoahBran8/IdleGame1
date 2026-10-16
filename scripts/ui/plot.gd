extends Button

const PLANT_ART: Dictionary = {
	"carrot": preload("res://assets/ui/carrot.svg"),
	"sunflower": preload("res://assets/ui/sunflower.svg"),
	"rose": preload("res://assets/ui/rose.svg"),
	"lavender": preload("res://assets/ui/lavender.svg"),
	"orchid": preload("res://assets/ui/orchid.svg")
}

const ART_PADDING: float = 30.0
static var alpha_masks: Dictionary = {}

var text_scale: float = 1.0
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
	var tile_size := Vector2(size.x,size.y-ART_PADDING)
	var center := Vector2(size.x*0.5,ART_PADDING+tile_size.y*0.5)
	var half := Vector2(tile_size.x * 0.48, tile_size.y * 0.42)
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
	if stage == 0:
		draw_line(base, tip, Color("#88b66e"), 3, true)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 9), tip + Vector2(-15, 1), tip + Vector2(-12, 12)]), Color("#94c47a"))
		draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 12), tip + Vector2(14, 3), tip + Vector2(12, 14)]), Color("#5c9a60"))
	if stage > 0:
		_flower(tip, base)
	var text_position := center + Vector2(0, minf(23, tile_size.y * 0.34))
	if stage == 3:
		_text("Ready", text_position, 11, Color("#382f20") if not contrast else Color("#fff1c6"))
		draw_circle(center + Vector2(size.x * 0.27, -9), 3, Color("#fff1b3"))
	else:
		var countdown: String = "%ds" % seconds_left if seconds_left < 60 else "%d:%02d" % [seconds_left / 60, seconds_left % 60]
		_text(countdown, text_position, 11, Color("#382f20") if not contrast else Color("#f4e5ba"))
		var meter := Rect2(center + Vector2(-14, minf(26, tile_size.y * 0.40)), Vector2(28, 3))
		draw_rect(meter, Color("#332c23"))
		draw_rect(Rect2(meter.position, Vector2(meter.size.x * progress, 3)), Color("#c6d59b"))

func _flower(_tip: Vector2, base: Vector2) -> void:
	# Imported once and shared across the world/selector: one textured quad per plant.
	var texture: Texture2D = PLANT_ART.get(species)
	if texture == null:
		return
	var height: float = 21 + stage * 9
	draw_texture_rect(texture, Rect2(base + Vector2(-height * 0.5, 10 - height),Vector2.ONE * height), false)

func _text(value: String, point: Vector2, font_size: int, color: Color) -> void:
	font_size = int(font_size * text_scale)
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, point - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func art_rect() -> Rect2:
	var height: float = 21 + stage * 9
	var center := Vector2(size.x*0.5,ART_PADDING+(size.y-ART_PADDING)*0.5)
	return Rect2(center+Vector2(-height*0.5,11-height),Vector2.ONE*height)

func _has_point(point: Vector2) -> bool:
	var tile_size := Vector2(size.x,size.y-ART_PADDING)
	var center := Vector2(size.x*0.5,ART_PADDING+tile_size.y*0.5)
	var normalized: Vector2 = (point-center)/(tile_size*Vector2(0.5,0.48))
	if absf(normalized.x)+absf(normalized.y) <= 1.05:
		return true
	if locked or stage < 1 or not PLANT_ART.has(species):
		return false
	var rect: Rect2 = art_rect()
	if not rect.has_point(point):
		return false
	if not alpha_masks.has(species):
		alpha_masks[species] = PLANT_ART[species].get_image()
	var mask: Image = alpha_masks[species]
	var pixel: Vector2 = (point-rect.position)/rect.size*Vector2(mask.get_width(),mask.get_height())
	return mask.get_pixel(clampi(int(pixel.x),0,mask.get_width()-1),clampi(int(pixel.y),0,mask.get_height()-1)).a > 0.1
