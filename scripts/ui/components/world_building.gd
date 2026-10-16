extends Button

# Independent world objects; illustrations are shared, imported textures.
const ART: Dictionary = {
	"home": preload("res://assets/world/cottage.svg"),
	"stand": preload("res://assets/world/market.svg"),
	"well": preload("res://assets/world/well.svg")
}
var kind: String = "home"
var built: bool = true
var large_text: bool = false

func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for property: Dictionary in get_property_list():
		if property.name == "accessibility_name":
			set("accessibility_name", tooltip_text)

func _draw() -> void:
	var art: Texture2D = ART[kind]
	draw_texture_rect(art, Rect2(0, -3, size.x, size.y), false, Color.WHITE if built or kind != "stand" else Color(0.84,0.86,0.76))
	if has_focus() or is_hovered():
		draw_arc(size*Vector2(0.5,0.72), size.x*0.43, 0, TAU, 36, Color("#fff4b6"), 2, true)
	var caption: String = {"home":"Home", "stand":"Stand" if built else "Build", "well":"Tools"}[kind]
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 13 if large_text else 11
	var width: float = font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var badge := StyleBoxFlat.new()
	badge.bg_color = Color("#ffefd0")
	badge.border_color = Color("#bba06c")
	badge.set_border_width_all(1)
	badge.set_corner_radius_all(6)
	badge.shadow_color = Color(0.19,0.30,0.18,0.15)
	badge.shadow_size = 2
	badge.shadow_offset = Vector2(0,2)
	draw_style_box(badge,Rect2((size.x-width)*0.5-5,size.y-15,width+10,16))
	draw_string(font,Vector2((size.x-width)*0.5,size.y-3),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("#344f37"))
