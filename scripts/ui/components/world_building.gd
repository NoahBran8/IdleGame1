extends Button

var kind: String = "home"
var built: bool = true

func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for property: Dictionary in get_property_list():
		if property.name == "accessibility_name":
			set("accessibility_name", tooltip_text)

func _draw() -> void:
	var factor: Vector2 = size / Vector2(108, 104)
	draw_set_transform(Vector2.ZERO, 0, factor)
	_ellipse(Vector2(54, 84), Vector2(46, 12), Color(0.2,0.35,0.16,0.16))
	if kind == "stand":
		draw_style_box(_box(Color("#dfb783")), Rect2(17, 42, 74, 45))
		draw_rect(Rect2(23, 46, 62, 22), Color("#668e5e"))
		draw_colored_polygon(PackedVector2Array([Vector2(7,43), Vector2(23,18), Vector2(84,18), Vector2(102,43)]), Color("#e88b84") if built else Color("#bbbf9c"))
		for i: int in range(4):
			draw_line(Vector2(27+i*17,19),Vector2(17+i*23,43),Color("#fff2d2"),8,true)
		for i: int in range(4):
			draw_circle(Vector2(31+i*15,57),6,Color("#edbad3") if i % 2 == 0 else Color("#f5ce76"))
	elif kind == "well":
		draw_circle(Vector2(51,62),27,Color("#b5c3bd"))
		draw_circle(Vector2(51,59),19,Color("#83bfc6"))
		draw_line(Vector2(27,62),Vector2(27,20),Color("#aa8967"),5,true)
		draw_line(Vector2(77,62),Vector2(77,20),Color("#aa8967"),5,true)
		draw_colored_polygon(PackedVector2Array([Vector2(16,24),Vector2(52,5),Vector2(88,24)]),Color("#7eaa87"))
		draw_line(Vector2(52,24),Vector2(52,51),Color("#9e785b"),2,true)
	else:
		draw_style_box(_box(Color("#ffe8bc")), Rect2(17, 36, 75, 51))
		draw_colored_polygon(PackedVector2Array([Vector2(8,40),Vector2(52,5),Vector2(102,40)]),Color("#d9826a"))
		draw_polyline(PackedVector2Array([Vector2(8,40),Vector2(52,5),Vector2(102,40)]),Color("#ad6655"),3,true)
		draw_rect(Rect2(24,44,18,24),Color("#a5cdd0"))
		draw_line(Vector2(33,45),Vector2(33,66),Color("#fff4db"),2,true)
		draw_line(Vector2(25,55),Vector2(41,55),Color("#fff4db"),2,true)
		draw_style_box(_box(Color("#89ac8b")),Rect2(54,51,24,36))
		draw_circle(Vector2(72,70),2,Color("#ffe6a5"))
		draw_rect(Rect2(76,3,10,21),Color("#c79873"))
	if has_focus() or is_hovered():
		draw_arc(Vector2(54,54),47,0,TAU,36,Color("#fff4b6"),3,true)
	draw_set_transform(Vector2.ZERO)
	var caption: String = {"home":"Home", "stand":"Stand" if built else "Build", "well":"Tools"}[kind]
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_style_box(_box(Color("#fff7dc")),Rect2((size.x-width)*0.5-4,size.y-15,width+8,16))
	draw_string(font,Vector2((size.x-width)*0.5,size.y-3),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#344f37"))

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in range(32):
		var angle: float = TAU * i / 32.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)

func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(5)
	return box

func _text(value: String, y: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	draw_style_box(_box(Color("#fff7dc")),Rect2(54-width*0.5-5,y-13,width+10,18))
	draw_string(font,Vector2(54-width*0.5,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#344f37"))
