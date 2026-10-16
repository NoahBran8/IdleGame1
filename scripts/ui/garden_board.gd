extends Control

const Plot = preload("res://scripts/ui/plot.gd")
signal plot_pressed(index: int)
var plots: Array[Button] = []

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
