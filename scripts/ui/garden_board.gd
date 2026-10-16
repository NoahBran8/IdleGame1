extends Control

const Plot = preload("res://scripts/ui/plot.gd")
signal plot_pressed(index: int)
var plots: Array[Button] = []
var has_stand: bool = false

func _ready() -> void:
	custom_minimum_size.y = 285
	for index: int in range(16):
		var tile := Plot.new()
		tile.pressed.connect(func() -> void: plot_pressed.emit(index))
		add_child(tile)
		plots.append(tile)
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
	queue_redraw()
	for index: int in range(plots.size()):
		var tile: Button = plots[index]
		tile.locked = index >= int(model.state.plots_unlocked)
		tile.stage = model.phase(index, now)
		tile.species = "" if model.state.plots[index].is_empty() else str(model.state.plots[index].species_id)
		tile.contrast = model.state.settings.high_contrast
		tile.highlight = index == 0 and int(model.state.harvests) == 0 and model.state.plots[index].is_empty()
		var status: String = "Locked"
		if not tile.locked:
			status = "Plant " + selected if tile.stage < 0 else "Harvest " + tile.species if tile.stage == 3 else tile.species + " growing"
		tile.tooltip_text = "Plot %d: %s" % [index + 1, status]
		tile.queue_redraw()

func _draw() -> void:
	if not has_stand:
		return
	var origin := Vector2(size.x - 75, size.y - 59)
	draw_rect(Rect2(origin + Vector2(4, 17), Vector2(58, 30)), Color("#ad8954"))
	draw_rect(Rect2(origin + Vector2(8, 19), Vector2(50, 18)), Color("#243f32"))
	draw_colored_polygon(PackedVector2Array([origin + Vector2(-3, 17), origin + Vector2(12, 0), origin + Vector2(54, 0), origin + Vector2(69, 17)]), Color("#e3c68a"))
	for i: int in range(3):
		draw_circle(origin + Vector2(19 + i * 14, 26), 4, Color("#e5b0b1"))
	draw_string(ThemeDB.fallback_font, origin + Vector2(12, 60), "STAND", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e3c68a"))
