extends Control

const Plot = preload("res://scripts/ui/plot.gd")
signal plot_pressed(index: int)
var plots: Array[Button] = []
var has_stand: bool = false
var has_irrigation: bool = false

func _ready() -> void:
	custom_minimum_size.y = 285
	for index: int in range(16):
		var tile := Plot.new()
		tile.pressed.connect(func() -> void: plot_pressed.emit(index))
		add_child(tile)
		plots.append(tile)
	var depth_order: Array = range(16)
	depth_order.sort_custom(func(a: int, b: int) -> bool: return a / 4 + a % 4 < b / 4 + b % 4)
	for index: int in depth_order:
		move_child(plots[index], get_child_count() - 1)
	resized.connect(_arrange)
	_arrange()

func _arrange() -> void:
	if plots.size() != 16:
		return
	var unit: float = minf(size.x / 4.15, 115)
	for index: int in range(16):
		var row: int = index / 4
		var col: int = index % 4
		plots[index].size = Vector2(unit, unit * 0.66)
		plots[index].position = Vector2(size.x * 0.5 + (col - row) * unit * 0.5 - unit * 0.5, 2 + (col + row) * unit * 0.25)
	custom_minimum_size.y = unit * 2.15

func refresh(model: GardenModel, now: int, selected: String) -> void:
	has_stand = int(model.state.upgrades.stand) > 0
	has_irrigation = int(model.state.upgrades.irrigation) > 0
	queue_redraw()
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
	var unit: float = minf(size.x / 4.15, 115)
	var center := Vector2(size.x * 0.5, 2 + unit * 1.08)
	var island := PackedVector2Array([center + Vector2(-unit * 2.05, 0), center + Vector2(0, -unit * 1.08), center + Vector2(unit * 2.05, 0), center + Vector2(0, unit * 1.08)])
	var shadow: PackedVector2Array = island.duplicate()
	for i: int in range(shadow.size()):
		shadow[i] += Vector2(0, 8)
	draw_colored_polygon(shadow, Color("#10251b"))
	draw_colored_polygon(island, Color("#456341"))
	var rim: PackedVector2Array = island.duplicate()
	rim.append(island[0])
	draw_polyline(rim, Color("#799466"), 2, true)
	# Fence rails and posts trace the back edge of the garden.
	for edge: int in range(2):
		var start: Vector2 = island[edge]
		var finish: Vector2 = island[edge + 1]
		draw_line(start + Vector2(0, -9), finish + Vector2(0, -9), Color("#a48c64"), 3, true)
		for post: int in range(5):
			var point: Vector2 = start.lerp(finish, float(post) / 4.0)
			draw_line(point, point + Vector2(0, -17), Color("#c4ab7a"), 4, true)
			draw_circle(point + Vector2(0, -17), 2, Color("#ead4a0"))
	# A little path and watering can mark a visible irrigation improvement.
	if has_irrigation:
		var can := Vector2(30, size.y - 27)
		draw_rect(Rect2(can, Vector2(23, 18)), Color("#84a8a0"))
		draw_arc(can + Vector2(23, 8), 9, -PI * 0.5, PI * 0.5, 12, Color("#84a8a0"), 3, true)
		draw_line(can + Vector2(2, 6), can + Vector2(-12, -1), Color("#a6c4b7"), 4, true)
	if not has_stand:
		return
	var origin := Vector2(size.x - 75, size.y - 59)
	draw_rect(Rect2(origin + Vector2(4, 17), Vector2(58, 30)), Color("#ad8954"))
	draw_rect(Rect2(origin + Vector2(8, 19), Vector2(50, 18)), Color("#243f32"))
	draw_colored_polygon(PackedVector2Array([origin + Vector2(-3, 17), origin + Vector2(12, 0), origin + Vector2(54, 0), origin + Vector2(69, 17)]), Color("#e3c68a"))
	for i: int in range(3):
		draw_circle(origin + Vector2(19 + i * 14, 26), 4, Color("#e5b0b1"))
	draw_string(ThemeDB.fallback_font, origin + Vector2(12, 60), "STAND", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e3c68a"))
