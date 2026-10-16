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
	draw_colored_polygon(bottom, Color("#825c39"))
	var fill := Color("#ac774b") if not locked else Color("#90b56b")
	if stage == 3:
		fill = Color("#c28e53")
	if contrast:
		fill = Color("#63432a") if not locked else Color("#17241e")
	draw_colored_polygon(diamond, fill)
	if not contrast:
		var inset := PackedVector2Array()
		for vertex: Vector2 in diamond:
			inset.append(center+(vertex-center)*0.86)
		draw_colored_polygon(inset,Color("#c28d57") if not locked else Color("#a6c77c"))
		draw_line(diamond[0],diamond[1],Color("#f1ce8d") if not locked else Color("#c8de99"),2,true)
		draw_line(diamond[1],diamond[2],Color("#e5bc78") if not locked else Color("#b9d68b"),2,true)
		for speck: int in range(13):
			var offset := Vector2(sin(speck*17.1)*half.x*0.72,cos(speck*11.7)*half.y*0.72)
			if absf(offset.x/half.x)+absf(offset.y/half.y) < 0.80:
				draw_circle(center+offset,0.7,Color("#e2b77b") if not locked else Color("#7fa65e"))
	var outline := diamond.duplicate()
	outline.append(diamond[0])
	var bright: bool = stage == 3 or highlight or has_focus() or is_hovered()
	draw_polyline(outline, Color("#fff1b3") if bright else Color("#a57e50") if not locked else Color("#799663"), 2, true)
	if locked:
		for weed: int in range(3):
			var grass := center+Vector2((weed-1)*size.x*0.20,3-weed*3)
			draw_polyline(PackedVector2Array([grass+Vector2(-4,-6),grass,grass+Vector2(2,-9)]),Color("#608e50"),2,true)
		for offset: int in [-1, 1]:
			var stone := center + Vector2(offset * size.x * 0.15, 2)
			draw_circle(stone, 4, Color("#d6cfad"))
		_text("×", center + Vector2(0, 5), 18, Color("#e4eacb") if contrast else Color("#4f6e42"))
		return
	for offset: int in [-1, 0, 1]:
		var start := center+Vector2(-size.x*0.22,offset*tile_size.y*0.10+4)
		var end := center+Vector2(size.x*0.22,offset*tile_size.y*0.10-8)
		draw_line(start,end,Color("#97663d") if not contrast else Color("#a87c51"),3,true)
		draw_line(start+Vector2(0,2),end+Vector2(0,2),Color("#d6a56a") if not contrast else Color("#805638"),1,true)
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
		var badge := StyleBoxFlat.new()
		badge.bg_color = Color("#fff0bc") if not contrast else Color("#17241e")
		badge.border_color = Color("#b88b45")
		badge.set_border_width_all(1)
		badge.set_corner_radius_all(5)
		if size.x < 75:
			var point := text_position-Vector2(0,3)
			draw_circle(point,6,Color("#fff1b3"))
			draw_polyline(PackedVector2Array([point+Vector2(-3,0),point+Vector2(-1,2),point+Vector2(3,-3)]),Color("#436337"),1.8,true)
		else:
			var badge_width: float = 34*text_scale
			draw_style_box(badge,Rect2(text_position-Vector2(badge_width*0.5,11*text_scale),Vector2(badge_width,14*text_scale)))
			_text("Ready", text_position, 11, Color("#4b4629") if not contrast else Color("#fff1c6"))
		draw_circle(center + Vector2(size.x * 0.27, -9), 3, Color("#fff1b3"))
	else:
		var countdown: String = "%ds" % seconds_left if seconds_left < 60 else "%d:%02d" % [seconds_left / 60, seconds_left % 60]
		_text(countdown, text_position, 11, Color("#382f20") if not contrast else Color("#f4e5ba"))
		var meter := Rect2(center + Vector2(-14, minf(26, tile_size.y * 0.40)), Vector2(28, 3))
		draw_rect(meter, Color("#332c23"))
		draw_rect(Rect2(meter.position, Vector2(meter.size.x * progress, 3)), Color("#c6d59b"))

func _flower(_tip: Vector2, _base: Vector2) -> void:
	var texture: Texture2D = PLANT_ART.get(species)
	if texture == null:
		return
	for rect: Rect2 in plant_rects():
		draw_texture_rect(texture,rect,false)

func plant_rects() -> Array[Rect2]:
	var main: Rect2 = art_rect()
	var result: Array[Rect2] = []
	# Wider beds bloom as small clusters. Narrow screens retain a clear single silhouette.
	if stage == 3 and size.x >= 75:
		for side: int in [-1,1]:
			var extent: Vector2 = main.size*0.68
			result.append(Rect2(main.get_center()+Vector2(side*size.x*0.20,-2)-extent*0.5,extent))
	result.append(main)
	return result

func _text(value: String, point: Vector2, font_size: int, color: Color) -> void:
	font_size = int(font_size * text_scale)
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, point - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func art_rect() -> Rect2:
	var height: float = minf(21+stage*9,size.x*0.65+8)
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
	if not alpha_masks.has(species):
		alpha_masks[species] = PLANT_ART[species].get_image()
	var mask: Image = alpha_masks[species]
	for rect: Rect2 in plant_rects():
		if not rect.has_point(point):
			continue
		var pixel: Vector2 = (point-rect.position)/rect.size*Vector2(mask.get_width(),mask.get_height())
		if mask.get_pixel(clampi(int(pixel.x),0,mask.get_width()-1),clampi(int(pixel.y),0,mask.get_height()-1)).a > 0.1:
			return true
	return false
