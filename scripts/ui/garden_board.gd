extends Control

const GRASS = preload("res://assets/world/grass_detail.svg")
const TREE = preload("res://assets/painted/tree.png")
const POND = preload("res://assets/painted/pond.png")

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
	var building_height: float = 116 if size.y > 400 else 72 if size.y > 290 else 48
	var grid_height: float = tile_height*4
	var top: float = maxf(building_height+4, (size.y-grid_height)*0.45)
	top = minf(top,maxf(0,size.y-grid_height-2))
	grid_origin = Vector2((usable-unit*4)*0.5,top)
	for index: int in range(16):
		var row: int = index / 4
		var col: int = index % 4
		plots[index].size = Vector2(unit,tile_height+30)
		plots[index].position = grid_origin + Vector2((col-row+3)*unit*0.5,(col+row)*tile_height*0.5-30)
	buildings.home.size = Vector2(building_height*1.12,building_height)
	buildings.home.position = Vector2(8, maxf(0,top-building_height-9))
	buildings.stand.size = Vector2(building_height*1.07,building_height)
	buildings.stand.position = Vector2(usable-building_height*1.07-2,maxf(0,top-building_height-4))
	var well_size: float = 62 if size.y > 400 else 48
	buildings.well.size = Vector2.ONE*well_size
	buildings.well.position = Vector2((usable-well_size)*0.5,maxf(0,top-well_size-8))
	queue_redraw()

func refresh(model: GardenModel, now: int, selected: String) -> void:
	var previous: Array = [decor, has_stand, has_irrigation]
	decor = str(model.state.decor)
	has_stand = int(model.state.upgrades.stand) > 0
	has_irrigation = int(model.state.upgrades.irrigation) > 0
	buildings.stand.built = has_stand
	for object: Button in buildings.values():
		if object.large_text != model.state.settings.large_text:
			object.large_text = model.state.settings.large_text
			object.queue_redraw()
		object.present(model)
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
		tile.text_scale = 1.15 if model.state.settings.large_text else 1.0
		tile.highlight = index == 0 and int(model.state.harvests) == 0 and model.state.plots[index].is_empty()
		var status: String = "Locked"
		if not tile.locked:
			status = "Plant " + selected if tile.stage < 0 else "Harvest " + tile.species if tile.stage == 3 else tile.species + " · %ds to harvest" % tile.seconds_left
		tile.tooltip_text = "Plot %d: %s" % [index + 1, status]
		tile.queue_redraw()

func _draw() -> void:
	# Static landscape redraws only on resize, decoration or building changes.
	# Functional beds and buildings remain independent child controls above it.
	draw_rect(Rect2(Vector2.ZERO,size),Color("#a9bd80"))
	var usable: float = size.x-76
	_ellipse(Vector2(size.x*0.2,0),Vector2(size.x*0.85,97),Color("#c6d79b"))
	_ellipse(Vector2(size.x*0.86,27),Vector2(size.x*0.57,75),Color("#b5ca8c"))
	_ellipse(Vector2(usable*0.45,size.y*0.55),Vector2(usable*0.70,size.y*0.49),Color("#bbce92"))
	draw_texture_rect(GRASS,Rect2(Vector2.ZERO,size),true)
	# Deterministic grass patches: no random state, simulation or per-frame effects.
	for i: int in range(45):
		var point := Vector2(fmod(i*73.7+11,size.x),fmod(i*127.3+37,size.y))
		_ellipse(point,Vector2(6+i%4,2),Color("#abc184") if i%3 else Color("#c6d59d"))
		if i%4 == 0:
			draw_polyline(PackedVector2Array([point+Vector2(-3,-3),point,point+Vector2(2,-5)]),Color("#92ad72"),1,true)
	var route := Curve2D.new()
	route.add_point(Vector2(usable*0.46,-15),Vector2.ZERO,Vector2(-9,90))
	route.add_point(Vector2(usable*0.28,grid_origin.y-8),Vector2(20,-35),Vector2(-70,65))
	route.add_point(Vector2(usable*0.18,size.y*0.68),Vector2(-40,-40),Vector2(30,55))
	route.add_point(Vector2(usable*0.61,size.y+15),Vector2(-25,-48))
	var path: PackedVector2Array = route.get_baked_points()
	draw_polyline(path,Color("#91b369"),38,true)
	draw_polyline(path,Color("#c6ad77"),31,true)
	draw_polyline(path,Color("#edda9e"),26,true)
	draw_polyline(path,Color("#f8e6b0"),19,true)
	for i: int in range(11):
		var point: Vector2 = route.sample_baked(route.get_baked_length()*float(i)/11)
		_ellipse(point+Vector2(5,-2),Vector2(2.5,1),Color("#ceb985"))
	var center := grid_origin + Vector2(unit*2,tile_height*2)
	var island := PackedVector2Array([center+Vector2(-unit*2-4,0),center+Vector2(0,-tile_height*2-4),center+Vector2(unit*2+4,0),center+Vector2(0,tile_height*2+4)])
	var shadow: PackedVector2Array = island.duplicate()
	for i: int in range(shadow.size()):
		shadow[i] += Vector2(0,10)
	draw_colored_polygon(shadow,Color("#73905b"))
	for edge: Array in [[0,3,"#b6a379"],[3,2,"#c9ba90"]]:
		var start: Vector2 = island[edge[0]]
		var finish: Vector2 = island[edge[1]]
		var depth := Vector2(0,10)
		draw_colored_polygon(PackedVector2Array([start,finish,finish+depth,start+depth]),Color(edge[2]))
		draw_line(start+Vector2(0,5),finish+Vector2(0,5),Color("#e0d3a9"),1,true)
		for stone: int in range(1,10):
			var joint: Vector2 = start.lerp(finish,stone/10.0)
			draw_line(joint,joint+depth,Color("#958762"),1,true)
	draw_colored_polygon(island,Color("#c7b47e"))
	var rim: PackedVector2Array = island.duplicate()
	rim.append(island[0])
	draw_polyline(rim,Color("#f6e7b3"),5,true)
	for edge: int in range(2):
		var start: Vector2 = island[edge]
		var finish: Vector2 = island[edge+1]
		draw_line(start+Vector2(0,-10),finish+Vector2(0,-10),Color("#98744e"),5,true)
		draw_line(start+Vector2(0,-12),finish+Vector2(0,-12),Color("#f8d99c"),3,true)
		for i: int in range(5):
			var point: Vector2 = start.lerp(finish,float(i)/4)
			draw_line(point+Vector2(1,2),point-Vector2(0,20),Color("#9c7850"),6,true)
			draw_line(point,point-Vector2(0,21),Color("#eac58a"),3,true)
			draw_circle(point-Vector2(0,21),3,Color("#fff1c6"))
	# Edge vegetation frames the play area without obscuring controls.
	_tree(Vector2(22,48),0.63)
	_tree(Vector2(size.x-18,54),0.72)
	_tree(Vector2(size.x-16,size.y-32),0.91)
	var free_height: float = size.y-(grid_origin.y+tile_height*4)
	if free_height > 100:
		var pond_size := Vector2(minf(usable*0.43,165),minf(free_height*0.95,142))
		var pond_position := Vector2(usable-pond_size.x-4,size.y-pond_size.y-27)
		draw_texture_rect(POND,Rect2(pond_position,pond_size),false)
		_bench(Vector2(usable*0.14,size.y-68),minf(1.0,usable/400))
		# A little stone seating court and informal planted border.
		for stone: int in range(7):
			var position := Vector2(usable*0.24+stone*11,size.y-66-stone*2)
			_ellipse(position+Vector2(0,2),Vector2(7,3),Color("#8b9e6c"))
			_ellipse(position,Vector2(7,3),Color("#d7cfaa"))
		for flower: int in range(13):
			var position := Vector2(usable*0.12+flower*6,size.y-95+sin(flower*1.8)*5)
			draw_line(position,position-Vector2(1,7),Color("#718f53"),2,true)
			_blossom(position-Vector2(1,7),Color("#e6b3bb") if flower%3 else Color("#f5e4b5"),1.7)
		_tree(Vector2(18,size.y-70),0.67)
	for i: int in range(20):
		var point := Vector2(12+fmod(i*73.0,maxf(1,usable-20)),size.y-10-fmod(i*17.0,28))
		if decor == "stone":
			_ellipse(point+Vector2(0,2),Vector2(8,4),Color("#8da46d"))
			_ellipse(point,Vector2(7,3.5),Color("#e7dfb4"))
		else:
			draw_line(point,point+Vector2(-3,-6),Color("#689b51"),2,true)
			draw_line(point,point+Vector2(3,-7),Color("#7eac5b"),2,true)
			if decor == "wildflowers" or i%4 == 0:
				_blossom(point-Vector2(0,7),Color("#f4b7bb") if i%2 else Color("#fff0b0"),2.3)
	if has_irrigation:
		var point := Vector2(usable*0.20,size.y-47)
		_ellipse(point+Vector2(0,5),Vector2(12,4),Color("#719d66"))
		draw_circle(point,8,Color("#6cabb0"))
		draw_line(point,point+Vector2(-16,-11),Color("#9fd2c6"),5,true)
		draw_arc(point+Vector2(6,-2),7,-PI*0.7,PI*0.6,12,Color("#528e92"),3,true)

func _ellipse(center: Vector2,radius: Vector2,color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in range(24):
		var angle: float = TAU*i/24.0
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	draw_colored_polygon(points,color)

func _tree(point: Vector2,scale_factor: float) -> void:
	var extent := Vector2(106,122)*scale_factor
	draw_texture_rect(TREE,Rect2(point-extent*Vector2(0.5,0.83),extent),false)

func _blossom(point: Vector2,color: Color,radius: float) -> void:
	for petal: int in range(5):
		draw_circle(point+Vector2(cos(petal*TAU/5),sin(petal*TAU/5))*radius,radius,color)
	draw_circle(point,radius*0.6,Color("#d6a64e"))

func _bench(point: Vector2,factor: float) -> void:
	draw_set_transform(point,0,Vector2.ONE*factor)
	_ellipse(Vector2(22,12),Vector2(35,9),Color(0.25,0.4,0.2,0.16))
	for x: int in [0,40]:
		draw_line(Vector2(x,5),Vector2(x,17),Color("#6e6b4b"),4,true)
		draw_line(Vector2(x,-4),Vector2(x,-19),Color("#6e6b4b"),3,true)
	for y: int in [-17,-10,0,5]:
		draw_line(Vector2(-6,y),Vector2(46,y),Color("#a27b4d"),6,true)
		draw_line(Vector2(-6,y-1),Vector2(46,y-1),Color("#e8be7b"),3,true)
	draw_set_transform(Vector2.ZERO)
