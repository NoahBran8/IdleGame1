class_name GardenConfig
extends RefCounted

var plants: Dictionary = {}
var economy: Dictionary = {}
var upgrades: Dictionary = {}
var quests: Dictionary = {}
var requests: Dictionary = {}
var error: String = ""

func _init(data_root: String = "res://data") -> void:
	var rows: Variant = _read_json(data_root + "/plants.json")
	var values: Variant = _read_json(data_root + "/economy.json")
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
	if economy.starting_plots != 4 or economy.starting_coins < 5 or economy.max_coins != 9000000000000000 or economy.offline_cap_seconds > 28800 or economy.stand_interval < 7:
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
		if not row.id in ["carrot", "sunflower", "rose", "lavender", "orchid"]:
			error = "Unknown species ID."
			return
		plants[row.id] = row
	if plants.size() != 5 or not plants.has("carrot"):
		error = "Expected five species including starter carrot."

	var upgrade_rows: Variant = _read_json(data_root + "/upgrades.json")
	if not upgrade_rows is Array:
		error = "Missing or malformed upgrades."
		return
	for row: Variant in upgrade_rows:
		if not row is Dictionary or not row.get("id") is String or upgrades.has(row.id):
			error = "Invalid upgrade identifier."
			return
		for field: String in ["base_cost", "max_level", "level_required"]:
			if not integer(row.get(field), 1, 1000000):
				error = "Invalid upgrade field: " + field
				return
		if not (row.get("multiplier") is float or row.get("multiplier") is int) or row.multiplier < 1 or row.multiplier > 3:
			error = "Invalid upgrade scaling."
			return
		for field: String in ["name", "description"]:
			if not row.get(field) is String:
				error = "Missing upgrade description."
				return
		if not row.id in ["plots", "compost", "irrigation", "baskets", "stand", "helper", "signage", "soil"]:
			error = "Unknown upgrade ID."
			return
		if row.id == "stand" and row.base_cost != economy.stand_cost:
			error = "Stand cost must match economy."
			return
		upgrades[row.id] = row
	if upgrades.size() != 8:
		error = "Expected eight upgrades."

	var quest_rows: Variant = _read_json(data_root + "/quests.json")
	if not quest_rows is Array or quest_rows.size() != 5:
		error = "Expected five quests."
		return
	for row: Variant in quest_rows:
		if not row is Dictionary or not row.get("id") is String or quests.has(row.id):
			error = "Invalid quest identifier."
			return
		if not row.get("metric") in ["harvests", "sales", "plots_unlocked", "discovered", "stand"]:
			error = "Unknown quest metric."
			return
		if not integer(row.get("target"), 1, 1000) or not integer(row.get("reward"), 1, 1000000):
			error = "Invalid quest target/reward."
			return
		for field: String in ["name", "description"]:
			if not row.get(field) is String:
				error = "Missing quest text."
				return
		quests[row.id] = row

	var request_rows: Variant = _read_json(data_root + "/requests.json")
	if not request_rows is Array or request_rows.size() < 3 or request_rows.size() > 50:
		error = "Expected three to fifty garden requests."
		return
	var starter_requests: int = 0
	for row: Variant in request_rows:
		if not row is Dictionary or not row.get("id") is String or requests.has(row.id):
			error = "Invalid request identifier."
			return
		for field: String in ["name", "customer"]:
			if not row.get(field) is String or row[field].is_empty():
				error = "Missing request text."
				return
		for field: String in ["level_required", "bonus_coins", "xp_reward"]:
			if not integer(row.get(field), 1, 1000000):
				error = "Invalid request reward or level."
				return
		if not row.get("items") is Dictionary or row.items.is_empty():
			error = "Request needs a recipe."
			return
		for species: Variant in row.items:
			if not species is String or not plants.has(species) or not integer(row.items[species], 1, 16):
				error = "Invalid request ingredient."
				return
			if int(row.level_required) < int(plants[species].level_required):
				error = "Request asks for a locked plant."
				return
		if row.level_required == 1:
			starter_requests += 1
		requests[row.id] = row
	if starter_requests < 3:
		error = "Three starter requests are needed."

static func integer(value: Variant, low: int, high: int) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data
