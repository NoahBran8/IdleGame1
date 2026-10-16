class_name GardenConfig
extends RefCounted

var plants: Dictionary = {}
var economy: Dictionary = {}
var error: String = ""

func _init() -> void:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/plants.json"))
	var values: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	if not rows is Array or not values is Dictionary:
		error = "Missing or malformed economic configuration."
		return
	economy = values
	for field: String in ["starting_coins", "starting_plots", "max_coins", "offline_cap_seconds", "stand_cost", "stand_interval", "xp_per_level"]:
		if not integer(economy.get(field), 1, 9000000000000000):
			error = "Invalid economy field: " + field
			return
	if not economy.get("plot_costs") is Array or economy.plot_costs.size() != 12:
		error = "Expected twelve plot prices."
		return
	for cost: Variant in economy.plot_costs:
		if not integer(cost, 1, 9000000000000000):
			error = "Invalid plot cost."
			return
	if economy.starting_plots != 4 or economy.starting_coins < 5:
		error = "Invalid starter configuration."
		return
	for row: Variant in rows:
		if not row is Dictionary or not row.get("id") is String or plants.has(row.id):
			error = "Invalid or duplicate species."
			return
		for field: String in ["name", "visual_key"]:
			if not row.get(field) is String or row[field].is_empty():
				error = "Missing plant field: " + field
				return
		for field: String in ["seed_cost", "growth_seconds", "base_sell_value", "level_required", "rarity_tier", "xp_reward"]:
			if not integer(row.get(field), 1, 1000000):
				error = "Invalid plant field: " + field
				return
		if row.base_sell_value <= row.seed_cost:
			error = "Species must be profitable."
			return
		plants[row.id] = row
	if plants.size() != 5 or not plants.has("carrot"):
		error = "Expected five species including starter carrot."

static func integer(value: Variant, low: int, high: int) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high
