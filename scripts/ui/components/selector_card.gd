extends Button

var title: String = ""
var caption: String = ""
var picture: Texture2D
var compact: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(62, 60) if compact else Vector2(108, 92)
	tooltip_text = title + (" · " + caption if not caption.is_empty() else "")
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for property: Dictionary in get_property_list():
		if property.name == "accessibility_name":
			set("accessibility_name", title)

func _draw() -> void:
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var image_size: float = 26 if compact else 26 if size.y < 88 else 36
	if not compact:
		var center := Vector2(size.x*0.5,6+image_size*0.5)
		draw_circle(center+Vector2(0,1),image_size*0.59,Color("#d5dfac") if button_pressed else Color("#f0e6c9"))
		draw_arc(center,image_size*0.59,PI,TAU,20,Color("#fffdf0"),1,true)
	if picture != null:
		draw_texture_rect(picture, Rect2(Vector2((size.x - image_size) * 0.5, 6), Vector2.ONE * image_size), false, Color(1,1,1,0.55) if disabled else Color.WHITE)
	var ink := Color("#294b39") if not disabled else Color("#60715b")
	_text(title, size.y - 9 if compact else size.y - 29, font, font_size, ink)
	if not compact:
		_text(caption, size.y - 10, font, maxi(11, font_size - 2), ink)

func _text(value: String, y: float, font: Font, font_size: int, color: Color) -> void:
	var width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
