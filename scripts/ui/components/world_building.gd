extends Button

# Independent world objects; illustrations are shared, imported textures.
const ART: Dictionary = {
	"home": preload("res://assets/painted/cottage.png"),
	"stand": preload("res://assets/painted/market.png"),
	"well": preload("res://assets/painted/well.png")
}
var kind: String = "home"
var built: bool = true
var large_text: bool = false
var stock_count: int = 0
var reserved_stock: int = 0
var stock_species: Array[String] = []
var upgrade_ranks: Dictionary = {}
var presentation_signature: Array = []
const PLANTS = preload("res://scripts/ui/plot.gd").PLANT_ART
const PROPS: Dictionary = {
	"compost": preload("res://assets/world/compost_bin.svg"),
	"irrigation": preload("res://assets/world/watering_can.svg"),
	"baskets": preload("res://assets/world/market_basket.svg"),
	"helper": preload("res://assets/world/gardener.svg"),
	"soil": preload("res://assets/world/field_book.svg"),
	"signage": preload("res://assets/world/market_sign.svg")
}

func present(model: GardenModel) -> void:
	stock_count = 0
	reserved_stock = 0
	stock_species.clear()
	for id: String in model.config.plants:
		var available: int = model.available_to_sell(id)
		stock_count += available
		reserved_stock += model.reserved_quantity(id)
		if available > 0:
			stock_species.append(id)
	upgrade_ranks = model.state.upgrades.duplicate()
	built = int(upgrade_ranks.stand) > 0 if kind == "stand" else true
	var signature: Array = [built,stock_species.duplicate(),stock_count,reserved_stock,upgrade_ranks.duplicate(),large_text]
	if signature != presentation_signature:
		presentation_signature = signature
		queue_redraw()
	if kind == "stand":
		tooltip_text = "Build a flower stand" if not built else "Flower stand: %d sellable, %d reserved. Sells one unreserved crop every %ds." % [stock_count,reserved_stock,model.stand_interval()]
	elif kind == "well":
		tooltip_text = "Tools and upgrades · Compost %d · Irrigation %d" % [upgrade_ranks.compost,upgrade_ranks.irrigation]
	else:
		tooltip_text = "Home: collection and quests" + (" · Harvest helper installed; harvests only, does not plant" if int(upgrade_ranks.helper) > 0 else "")


func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for property: Dictionary in get_property_list():
		if property.name == "accessibility_name":
			set("accessibility_name", tooltip_text)

func _draw() -> void:
	var art: Texture2D = ART[kind]
	draw_texture_rect(art, Rect2(0, -3, size.x, size.y), false, Color.WHITE if built or kind != "stand" else Color(0.84,0.86,0.76))
	_draw_installations()
	if has_focus() or is_hovered():
		draw_arc(size*Vector2(0.5,0.72), size.x*0.43, 0, TAU, 36, Color("#fff4b6"), 2, true)
	var caption: String = status_caption()
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

func _draw_installations() -> void:
	if upgrade_ranks.is_empty():
		return
	var props: Array = []
	if kind == "well":
		props = [["compost",Vector2(0.02,0.61),0.34],["irrigation",Vector2(0.68,0.66),0.30]]
	elif kind == "home":
		props = [["helper",Vector2(0.72,0.55),0.30],["soil",Vector2(0.02,0.77),0.26]]
	elif built:
		props = [["baskets",Vector2(0.03,0.71),0.32],["signage",Vector2(0.66,0.65),0.31]]
		for index: int in range(mini(3,stock_species.size())):
			var extent: float = size.y*0.24
			draw_texture_rect(PLANTS[stock_species[index]],Rect2(size*Vector2(0.23+index*0.17,0.46),Vector2.ONE*extent),false)
	for entry: Array in props:
		if int(upgrade_ranks.get(entry[0],0)) > 0:
			var extent: float = size.y*float(entry[2])
			draw_texture_rect(PROPS[entry[0]],Rect2(size*entry[1],Vector2.ONE*extent),false)

func status_caption() -> String:
	if kind != "stand":
		return "Home" if kind == "home" else "Tools"
	if not built:
		return "Build"
	if stock_count > 0:
		return "Stock · " + GardenModel.compact(stock_count) if size.x >= 100 else "Stock"
	if reserved_stock > 0:
		return "Reserved" if size.x >= 100 else "Held"
	return "Needs crops" if size.x >= 100 else "Empty"
