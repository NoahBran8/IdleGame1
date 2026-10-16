class_name GardenModel
extends RefCounted

const Config = preload("res://scripts/domain/config.gd")
const MAX_COINS: int = 9000000000000000
var config: GardenConfig
var state: Dictionary

func _init(source: GardenConfig = null) -> void:
	config = source if source != null else Config.new()
	state = fresh()

func fresh() -> Dictionary:
	var plots: Array = []
	for index: int in range(16):
		plots.append({})
	var inventory: Dictionary = {}
	for id: String in config.plants:
		inventory[id] = 0
	return {"version": 1, "coins": int(config.economy.get("starting_coins", 20)),
		"xp": 0, "plots_unlocked": 4, "plots": plots, "inventory": inventory,
		"discovered": [], "harvests": 0, "sales": 0, "saved_at": 0,
		"settings": {"reduced_motion": false, "high_contrast": false, "large_text": false}}

func level() -> int:
	return 1 + int(state.xp) / int(config.economy.xp_per_level)

func phase(index: int, now: int) -> int:
	if index < 0 or index >= int(state.plots_unlocked) or state.plots[index].is_empty():
		return -1
	var plot: Dictionary = state.plots[index]
	var total: int = int(plot.maturity_at_utc) - int(plot.planted_at_utc)
	if now >= int(plot.maturity_at_utc):
		return 3
	return clampi(int(3.0 * max(0, now - int(plot.planted_at_utc)) / total), 0, 2)

func plant(index: int, species: String, now: int) -> bool:
	if not config.plants.has(species) or index < 0 or index >= int(state.plots_unlocked):
		return false
	var row: Dictionary = config.plants[species]
	if not state.plots[index].is_empty() or level() < int(row.level_required) or int(state.coins) < int(row.seed_cost):
		return false
	state.coins = int(state.coins) - int(row.seed_cost)
	state.plots[index] = {"species_id": species, "plot_id": index,
		"planted_at_utc": now, "maturity_at_utc": now + int(row.growth_seconds)}
	return true

func harvest(index: int, now: int) -> bool:
	if phase(index, now) != 3:
		return false
	var species: String = state.plots[index].species_id
	state.inventory[species] = int(state.inventory[species]) + 1
	state.xp = mini(MAX_COINS, int(state.xp) + int(config.plants[species].xp_reward))
	state.harvests = mini(MAX_COINS, int(state.harvests) + 1)
	if not species in state.discovered:
		state.discovered.append(species)
	state.plots[index] = {}
	return true

func sell(species: String, quantity: int) -> int:
	if not config.plants.has(species) or quantity <= 0 or int(state.inventory[species]) < quantity:
		return 0
	var value: int = int(config.plants[species].base_sell_value)
	# Clamp quantity before multiplication; capped wallet never destroys unsold goods.
	var affordable: int = (MAX_COINS - int(state.coins)) / value
	var count: int = mini(quantity, affordable)
	if count <= 0:
		return 0
	var income: int = count * value
	state.inventory[species] = int(state.inventory[species]) - count
	state.coins = int(state.coins) + income
	state.sales = mini(MAX_COINS, int(state.sales) + count)
	return income

func sell_all() -> int:
	var income: int = 0
	for species: String in config.plants:
		income += sell(species, int(state.inventory[species]))
	return income

func validate(candidate: Variant) -> bool:
	if not candidate is Dictionary or candidate.get("version") != 1:
		return false
	for field: String in ["coins", "xp", "harvests", "sales", "saved_at"]:
		if not Config.integer(candidate.get(field), 0, MAX_COINS):
			return false
	if not Config.integer(candidate.get("plots_unlocked"), 4, 16):
		return false
	if not candidate.get("plots") is Array or candidate.plots.size() != 16:
		return false
	for index: int in range(16):
		var p: Variant = candidate.plots[index]
		if not p is Dictionary:
			return false
		if p.is_empty():
			continue
		if index >= int(candidate.plots_unlocked) or not config.plants.has(p.get("species_id", "")):
			return false
		if p.get("plot_id") != index:
			return false
		if not Config.integer(p.get("planted_at_utc"), 0, MAX_COINS) or not Config.integer(p.get("maturity_at_utc"), 1, MAX_COINS):
			return false
		if p.maturity_at_utc <= p.planted_at_utc or p.maturity_at_utc - p.planted_at_utc > 1000000:
			return false
	if not candidate.get("inventory") is Dictionary:
		return false
	for species: String in config.plants:
		if not Config.integer(candidate.inventory.get(species), 0, MAX_COINS):
			return false
	if not candidate.get("discovered") is Array:
		return false
	for species: Variant in candidate.discovered:
		if not species is String or not config.plants.has(species):
			return false
	if not candidate.get("settings") is Dictionary:
		return false
	for key: String in ["reduced_motion", "high_contrast", "large_text"]:
		if not candidate.settings.get(key) is bool:
			return false
	return true

static func compact(value: int) -> String:
	if value < 1000:
		return str(value)
	for pair: Array in [[1000000000000, "T"], [1000000000, "B"], [1000000, "M"], [1000, "K"]]:
		if value >= int(pair[0]):
			return "%.1f%s" % [float(value) / float(pair[0]), pair[1]]
	return str(value)
