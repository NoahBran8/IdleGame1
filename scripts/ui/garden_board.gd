extends Control

const Plot = preload("res://scripts/ui/plot.gd")
const Building = preload("res://scripts/ui/components/world_building.gd")
signal plot_pressed(index: int)
signal building_pressed(kind: String)
var plots: Array[Button] = []
var buildings: Dictionary = {}
var has_stand: bool = false
var has_irrigation: bool = false
var decor: String = "meadow"
var unit: float = 80
var tile_height: float = 56
var grid_origin := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL
	for index: int in range(16):
		var tile := Plot.new()
		tile.pressed.connect(func() -> void: plot_pressed.emit(index))
		add_child(tile)
		plots.append(tile)
	var depth_order: Array = range(16)
	depth_order.sort_custom(func(a: int,b: int) -> bool: return a / 4 + a % 4 < b / 4 + b % 4)
	for index: int in depth_order:
		move_child(plots[index], get_child_count()-1)
	for kind: String in ["home","stand","well"]:
		var object := Building.new()
		object.kind = kind
		object.tooltip_text = {"home":"Home: collection and quests", "stand":"Flower stand: inventory or upgrades", "well":"Watering tools and upgrades"}[kind]
		object.pressed.connect(func() -> void: building_pressed.emit(kind))
		add_child(object)
		buildings[kind] = object
	resized.connect(_arrange)
	_arrange()

func _arrange() -> void:
	if plots.size() != 16:
		return
	var usable: float = size.x - 76
	unit = minf((usable - 12) / 4.0,110)
	tile_height = maxf(44,unit*0.70)
	var building_height: float = 94 if size.y > 400 else 72 if size.y > 290 else 48
	var grid_height: float = tile_height*4
	var top: float = maxf(building_height+4, (size.y-grid_height)*0.45)
	top = minf(top,maxf(0,size.y-grid_height-2))
	grid_origin = Vector2((usable-unit*4)*0.5,top)
	for index: int in range(16):
		var row: int = index / 4
		var col: int = index % 4
		plots[index].size = Vector2(unit,tile_height)
		plots[index].position = grid_origin + Vector2((col-row+3)*unit*0.5,(col+row)*tile_height*0.5)
	buildings.home.size = Vector2(building_height*1.12,building_height)
	buildings.home.position = Vector2(8, maxf(0,top-building_height-9))
	buildings.stand.size = Vector2(building_height*1.07,building_height)
	buildings.stand.position = Vector2(usable-building_height*1.07-2,maxf(0,top-building_height-4))
	buildings.well.size = Vector2(48,48)
	buildings.well.position = Vector2((usable-48)*0.5,maxf(0,top-56))
	queue_redraw()

func refresh(model: GardenModel, now: int, selected: String) -> void:
	var previous: Array = [decor, has_stand, has_irrigation]
	decor = str(model.state.decor)
	has_stand = int(model.state.upgrades.stand) > 0
	has_irrigation = int(model.state.upgrades.irrigation) > 0
	buildings.stand.built = has_stand
	if previous != [decor, has_stand, has_irrigation]:
		queue_redraw()
		buildings.stand.queue_redraw()
	for index: int in range(plots.size()):
		var tile: Button = plots[index]
		tile.locked = index >= int(model.state.plots_unlocked)
		tile.stage = model.phase(index, now)
		tile.seconds_left = 0 if model.state.plots[index].is_empty() else maxi(0, int(model.state.plots[index].maturity_at_utc) - now)
		tile.progress = 0.0
		if not model.state.plots[index].is_empty():
			var plot: Dictionary = model.state.plots[index]
			tile.progress = clampf(float(now - int(plot.planted_at_utc)) / float(int(plot.maturity_at_utc) - int(plot.planted_at_utc)), 0.0, 1.0)
		tile.species = "" if model.state.plots[index].is_empty() else str(model.state.plots[index].species_id)
		tile.focus_mode = Control.FOCUS_ALL
		tile.contrast = model.state.settings.high_contrast
		tile.highlight = index == 0 and int(model.state.harvests) == 0 and model.state.plots[index].is_empty()
		var status: String = "Locked"
		if not tile.locked:
			status = "Plant " + selected if tile.stage < 0 else "Harvest " + tile.species if tile.stage == 3 else tile.species + " · %ds to harvest" % tile.seconds_left
		tile.tooltip_text = "Plot %d: %s" % [index + 1, status]
		tile.queue_redraw()

func _draw() -> void:
	# Scenery is made from original paths/shapes; every functional object is a child control.
	draw_rect(Rect2(Vector2.ZERO,size),Color("#cce5a6"))
	_ellipse(Vector2(size.x*0.3,12),Vector2(size.x*0.72,75),Color("#e1efbe"))
	_ellipse(Vector2(size.x*0.75,28),Vector2(size.x*0.5,70),Color("#bed99a"))
	var usable: float = size.x-76
	var path := PackedVector2Array([Vector2(usable*0.35,-10),Vector2(usable*0.45,grid_origin.y-13),Vector2(usable*0.16,size.y*0.55),Vector2(usable*0.7,size.y+10)])
	draw_polyline(path,Color("#baa77b"),32,true)
	draw_polyline(path,Color("#ead9ac"),26,true)
	var center := grid_origin + Vector2(unit*2,tile_height*2)
	var island := PackedVector2Array([center+Vector2(-unit*2-4,0),center+Vector2(0,-tile_height*2-4),center+Vector2(unit*2+4,0),center+Vector2(0,tile_height*2+4)])
	var shadow: PackedVector2Array = island.duplicate()
	for i: int in range(shadow.size()):
		shadow[i] += Vector2(0,7)
	draw_colored_polygon(shadow,Color("#95b774"))
	draw_colored_polygon(island,Color("#d6c290"))
	var rim: PackedVector2Array = island.duplicate()
	rim.append(island[0])
	draw_polyline(rim,Color("#f9e8b9"),5,true)
	for edge: int in range(2):
		var start: Vector2 = island[edge]
		var finish: Vector2 = island[edge+1]
		draw_line(start+Vector2(0,-10),finish+Vector2(0,-10),Color("#ab855f"),4,true)
		draw_line(start+Vector2(0,-9),finish+Vector2(0,-9),Color("#f8e6b7"),2,true)
		for i: int in range(5):
			var point: Vector2 = start.lerp(finish,float(i)/4)
			draw_line(point,point-Vector2(0,19),Color("#b68a5e"),5,true)
			draw_circle(point-Vector2(0,19),3,Color("#fff0c9"))
	# Background tree canopies and pond are decorative, not hidden button targets.
	_tree(Vector2(19,34),0.70)
	_tree(Vector2(size.x-24,size.y-48),0.85)
	_tree(Vector2(size.x-31,34),0.70)
	var pond := Vector2(usable*0.68,size.y-43)
	_ellipse(pond,Vector2(43,23),Color("#e8dcb2"))
	_ellipse(pond,Vector2(36,17),Color("#86c5c8"))
	draw_arc(pond+Vector2(3,0),17,0.1,PI*0.9,18,Color("#d5f2df"),2,true)
	for i: int in range(14):
		var point := Vector2(12+fmod(i*73.0,maxf(1,usable-20)),size.y-15-fmod(i*17.0,35))
		if decor == "wildflowers":
			for p: int in range(5):
				draw_circle(point+Vector2(cos(p*TAU/5),sin(p*TAU/5))*3,2.8,Color("#efb9cf") if i%2 else Color("#ffe6a0"))
			draw_circle(point,2,Color("#d7a855"))
		elif decor == "stone":
			_ellipse(point,Vector2(7,3.5),Color("#e2dfc8"))
		else:
			draw_line(point,point+Vector2(-3,-5),Color("#8ebd6c"),1.5,true)
			draw_line(point,point+Vector2(3,-6),Color("#8ebd6c"),1.5,true)
	if has_irrigation:
		draw_circle(Vector2(74,size.y-41),7,Color("#8fbec3"))
		draw_line(Vector2(74,size.y-42),Vector2(62,size.y-52),Color("#80abb0"),4,true)

func _ellipse(center: Vector2,radius: Vector2,color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in range(32):
		var angle: float = TAU*i/32.0
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	draw_colored_polygon(points,color)

func _tree(point: Vector2,scale_factor: float) -> void:
	draw_line(point+Vector2(0,15)*scale_factor,point-Vector2(0,22)*scale_factor,Color("#a27f52"),8*scale_factor,true)
	_ellipse(point+Vector2(0,18)*scale_factor,Vector2(24,9)*scale_factor,Color("#a8c787"))
	draw_circle(point+Vector2(-12,-17)*scale_factor,20*scale_factor,Color("#76a45c"))
	draw_circle(point+Vector2(14,-20)*scale_factor,22*scale_factor,Color("#8bb76a"))
	draw_circle(point+Vector2(0,-35)*scale_factor,24*scale_factor,Color("#a9cd7c"))
	draw_circle(point+Vector2(-6,-42)*scale_factor,8*scale_factor,Color("#bcd98e"))
