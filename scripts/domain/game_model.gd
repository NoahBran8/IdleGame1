class_name GardenModel
extends RefCounted

const Config = preload("res://scripts/domain/config.gd")
const Requests = preload("res://scripts/domain/request_rules.gd")
const SAVE_VERSION: int = 4
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
	var upgrades: Dictionary = {}
	for id: String in config.upgrades:
		upgrades[id] = 0
	return {"version": SAVE_VERSION, "orders": initial_orders(1), "next_order_uid": 4, "orders_completed": 0, "pinned_order": 0, "claimed_quests": [], "onboarding": 0, "upgrades": upgrades, "last_update": 0, "stand_at": 0, "helper_at": 0, "coins": int(config.economy.get("starting_coins", 20)),
		"xp": 0, "plots_unlocked": 4, "plots": plots, "inventory": inventory,
		"discovered": [], "harvests": 0, "sales": 0, "saved_at": 0,
		"settings": {"reduced_motion": false, "high_contrast": false, "large_text": false, "sound": true, "local_telemetry": true}}

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
	if not config.plants.has(species) or index < 0 or index >= int(state.plots_unlocked) or now < 0 or now > MAX_COINS - 1000000:
		return false
	var row: Dictionary = config.plants[species]
	if not state.plots[index].is_empty() or level() < int(row.level_required) or int(state.coins) < int(row.seed_cost):
		return false
	state.onboarding = maxi(1, int(state.onboarding))
	state.coins = int(state.coins) - int(row.seed_cost)
	state.plots[index] = {"species_id": species, "plot_id": index,
		"planted_at_utc": now, "maturity_at_utc": now + growth_seconds(species)}
	return true

func harvest(index: int, now: int) -> bool:
	if phase(index, now) != 3:
		return false
	var species: String = state.plots[index].species_id
	if int(state.inventory[species]) >= MAX_COINS:
		return false
	state.onboarding = maxi(2, int(state.onboarding))
	state.inventory[species] = int(state.inventory[species]) + 1
	state.xp = mini(MAX_COINS, int(state.xp) + harvest_xp(species))
	state.harvests = mini(MAX_COINS, int(state.harvests) + 1)
	if not species in state.discovered:
		state.discovered.append(species)
	state.plots[index] = {}
	return true

func sell(species: String, quantity: int) -> int:
	if not config.plants.has(species) or quantity <= 0 or int(state.inventory[species]) < quantity:
		return 0
	var value: int = sell_value(species)
	# Clamp quantity before multiplication; capped wallet never destroys unsold goods.
	var affordable: int = (MAX_COINS - int(state.coins)) / value
	var count: int = mini(mini(quantity, affordable), available_to_sell(species))
	if count <= 0:
		return 0
	state.onboarding = maxi(3, int(state.onboarding))
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
	if not candidate is Dictionary or candidate.get("version") != SAVE_VERSION:
		return false
	for field: String in ["coins", "xp", "harvests", "sales", "saved_at", "last_update", "stand_at", "helper_at"]:
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
		if not Config.integer(p.get("plot_id"), 0, 15) or p.plot_id != index:
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
	var discoveries: Array = []
	for species: Variant in candidate.discovered:
		if not species is String or not config.plants.has(species) or species in discoveries:
			return false
		discoveries.append(species)
	if not candidate.get("settings") is Dictionary:
		return false
	for key: String in ["reduced_motion", "high_contrast", "large_text", "sound", "local_telemetry"]:
		if not candidate.settings.get(key) is bool:
			return false
	if not Config.integer(candidate.get("onboarding"), 0, 4) or not candidate.get("claimed_quests") is Array:
		return false
	var seen: Array = []
	for quest: Variant in candidate.claimed_quests:
		if not quest is String or not config.quests.has(quest) or quest in seen:
			return false
		seen.append(quest)
	if not candidate.get("upgrades") is Dictionary:
		return false
	for id: String in config.upgrades:
		if not Config.integer(candidate.upgrades.get(id), 0, int(config.upgrades[id].max_level)):
			return false
	if int(candidate.plots_unlocked) != 4 + int(candidate.upgrades.plots):
		return false
	if int(candidate.upgrades.signage) > 0 and int(candidate.upgrades.stand) == 0:
		return false
	if not Config.integer(candidate.get("orders_completed"), 0, MAX_COINS - 4):
		return false
	if not Config.integer(candidate.get("next_order_uid"), 4, MAX_COINS) or int(candidate.next_order_uid) != 4 + int(candidate.orders_completed):
		return false
	if not candidate.get("orders") is Array or candidate.orders.size() != 3 or not Config.integer(candidate.get("pinned_order"), 0, MAX_COINS):
		return false
	var order_ids: Array = []
	var templates: Array = []
	for offer: Variant in candidate.orders:
		if not offer is Dictionary or not Config.integer(offer.get("uid"), 1, int(candidate.next_order_uid) - 1):
			return false
		if not offer.get("template_id") is String or not config.requests.has(offer.template_id):
			return false
		if offer.uid in order_ids or offer.template_id in templates:
			return false
		if int(config.requests[offer.template_id].level_required) > 1 + int(candidate.xp) / int(config.economy.xp_per_level):
			return false
		order_ids.append(offer.uid)
		templates.append(offer.template_id)
	if int(candidate.pinned_order) != 0 and not candidate.pinned_order in order_ids:
		return false
	return true

func growth_seconds(species: String) -> int:
	var discount: int = (int(state.upgrades.compost) + int(state.upgrades.irrigation)) * 5
	return maxi(1, (int(config.plants[species].growth_seconds) * (100 - discount) + 99) / 100)

func sell_value(species: String) -> int:
	return int(config.plants[species].base_sell_value) * (100 + int(state.upgrades.baskets) * 5) / 100

func harvest_xp(species: String) -> int:
	return int(config.plants[species].xp_reward) * (100 + int(state.upgrades.soil) * 25) / 100

func upgrade_price(id: String) -> int:
	if not config.upgrades.has(id):
		return -1
	var rank: int = int(state.upgrades[id])
	var row: Dictionary = config.upgrades[id]
	if rank >= int(row.max_level):
		return -1
	if id == "plots":
		return int(config.economy.plot_costs[rank])
	return int(round(int(row.base_cost) * pow(float(row.multiplier), rank)))

func can_upgrade(id: String) -> bool:
	var price: int = upgrade_price(id)
	return price > 0 and int(state.coins) >= price and keeps_seed_path(price) and level() >= int(config.upgrades[id].level_required) and (id != "signage" or int(state.upgrades.stand) > 0)

func keeps_seed_path(price: int) -> bool:
	if int(state.coins) - price >= int(config.plants.carrot.seed_cost):
		return true
	for plot: Dictionary in state.plots:
		if not plot.is_empty():
			return true
	for count: Variant in state.inventory.values():
		if int(count) > 0:
			return true
	return false

func buy_upgrade(id: String, now: int) -> bool:
	if now < 0 or now > MAX_COINS - 1000000 or not can_upgrade(id):
		return false
	state.onboarding = maxi(4, int(state.onboarding))
	state.coins = int(state.coins) - upgrade_price(id)
	state.upgrades[id] = int(state.upgrades[id]) + 1
	if id == "plots":
		state.plots_unlocked = int(state.plots_unlocked) + 1
	elif id == "stand":
		state.stand_at = now
	elif id == "helper":
		state.helper_at = now
	elif id == "signage":
		state.stand_at = now
	return true

func stand_interval() -> int:
	return int(config.economy.stand_interval) - 2 * int(state.upgrades.signage)

func advance_to(target: int) -> Dictionary:
	var before: int = int(state.coins)
	var harvests_before: int = int(state.harvests)
	var previous: int = int(state.last_update)
	var result: Dictionary = {"income": 0, "harvests": 0, "elapsed": 0, "capped": false}
	if target < 0 or target > MAX_COINS - 1000000:
		return result
	if previous == 0:
		state.last_update = target
		state.stand_at = target
		state.helper_at = target
		return result
	if target <= previous:
		return result
	var elapsed: int = mini(target - previous, int(config.economy.offline_cap_seconds))
	var end: int = previous + elapsed
	var next_stand: int = int(state.stand_at) + stand_interval() if int(state.upgrades.stand) > 0 else MAX_COINS
	var next_helper: int = int(state.helper_at) + 5 if int(state.upgrades.helper) > 0 else MAX_COINS
	while mini(next_stand, next_helper) <= end:
		# Skip idle automation ticks without changing each machine's tick phase.
		var has_crops: bool = false
		for plot: Dictionary in state.plots:
			if not plot.is_empty():
				has_crops = true
				break
		if not has_crops and next_helper != MAX_COINS:
			state.helper_at = int(state.helper_at) + maxi(0, (end - int(state.helper_at)) / 5) * 5
			next_helper = MAX_COINS
		var has_inventory: bool = false
		for species: String in config.plants:
			if available_to_sell(species) > 0:
				has_inventory = true
				break
		if not has_inventory and next_helper == MAX_COINS and next_stand != MAX_COINS:
			state.stand_at = int(state.stand_at) + maxi(0, (end - int(state.stand_at)) / stand_interval()) * stand_interval()
			next_stand = MAX_COINS
		if mini(next_stand, next_helper) > end:
			break
		if next_helper <= next_stand:
			for index: int in range(int(state.plots_unlocked)):
				harvest(index, next_helper)
			state.helper_at = next_helper
			next_helper += 5
		else:
			for species: String in config.plants:
				if sell(species, 1) > 0:
					break
			state.stand_at = next_stand
			next_stand += stand_interval()
	# Shift deadlines beyond the capped duration. Excess clock jumps grant no extra growth.
	var excess: int = target - end
	if excess > 0:
		for plot: Dictionary in state.plots:
			if not plot.is_empty():
				plot.planted_at_utc = int(plot.planted_at_utc) + excess
				plot.maturity_at_utc = int(plot.maturity_at_utc) + excess
		state.stand_at = int(state.stand_at) + excess
		state.helper_at = int(state.helper_at) + excess
	state.last_update = target
	result.income = int(state.coins) - before
	result.harvests = int(state.harvests) - harvests_before
	result.elapsed = elapsed
	result.capped = excess > 0
	return result

# Explicit v1 → v2 migration preserves all existing garden contents.
func migrate(candidate: Variant) -> Variant:
	if not candidate is Dictionary:
		return candidate
	if candidate.get("version") == 1:
		candidate = candidate.duplicate(true)
		candidate.version = 2
		candidate.upgrades = {}
		for id: String in config.upgrades:
			candidate.upgrades[id] = 0
		candidate.upgrades.plots = int(candidate.get("plots_unlocked", 4)) - 4
		candidate.last_update = candidate.get("saved_at", 0)
		candidate.stand_at = candidate.last_update
		candidate.helper_at = candidate.last_update
	if candidate.get("version") == 2:
		candidate = candidate.duplicate(true)
		candidate.version = 3
		candidate.claimed_quests = []
		candidate.onboarding = 0
		if candidate.get("settings") is Dictionary:
			candidate.settings.sound = true
			candidate.settings.local_telemetry = true
	if candidate.get("version") == 3:
		candidate = candidate.duplicate(true)
		candidate.version = SAVE_VERSION
		if Config.integer(candidate.get("xp"), 0, MAX_COINS):
			candidate.orders = initial_orders(1 + int(candidate.xp) / int(config.economy.xp_per_level))
		else:
			candidate.orders = []
		candidate.next_order_uid = 4
		candidate.orders_completed = 0
		candidate.pinned_order = 0
	return candidate

func quest_progress(id: String) -> int:
	if not config.quests.has(id):
		return 0
	var metric: String = config.quests[id].metric
	if metric == "discovered":
		return state.discovered.size()
	if metric == "stand":
		return int(state.upgrades.stand)
	return int(state[metric])

func claim_quest(id: String) -> bool:
	if not config.quests.has(id) or id in state.claimed_quests:
		return false
	var row: Dictionary = config.quests[id]
	if quest_progress(id) < int(row.target) or int(state.coins) > MAX_COINS - int(row.reward):
		return false
	state.coins = int(state.coins) + int(row.reward)
	state.claimed_quests.append(id)
	return true

static func compact(value: int) -> String:
	if value < 1000:
		return str(value)
	for pair: Array in [[1000000000000, "T"], [1000000000, "B"], [1000000, "M"], [1000, "K"]]:
		if value >= int(pair[0]):
			return "%.1f%s" % [float(value) / float(pair[0]), pair[1]]
	return str(value)

func initial_orders(player_level: int) -> Array:
	var offers: Array = []
	var excluded: Array = []
	for uid: int in range(1, 4):
		var offer: Dictionary = Requests.make_offer(config, uid, player_level, excluded)
		if offer.is_empty():
			return []
		offers.append(offer)
		excluded.append(offer.template_id)
	return offers

func get_order(uid: int) -> Dictionary:
	for offer: Dictionary in state.orders:
		if int(offer.uid) == uid:
			return offer
	return {}

func order_template(uid: int) -> Dictionary:
	var offer: Dictionary = get_order(uid)
	return {} if offer.is_empty() else config.requests[offer.template_id]

func order_reward(uid: int) -> int:
	var template: Dictionary = order_template(uid)
	if template.is_empty():
		return 0
	var prices: Dictionary = {}
	for species: String in config.plants:
		prices[species] = sell_value(species)
	return Requests.reward(template, prices)

func can_fulfill(uid: int) -> bool:
	var template: Dictionary = order_template(uid)
	if template.is_empty() or int(state.next_order_uid) >= MAX_COINS or int(state.coins) > MAX_COINS - order_reward(uid):
		return false
	for species: String in template.items:
		if int(state.inventory[species]) < int(template.items[species]):
			return false
	return true

func fulfill_order(uid: int) -> bool:
	if not can_fulfill(uid):
		return false
	var template: Dictionary = order_template(uid)
	var reward: int = order_reward(uid)
	var quantity: int = 0
	for species: String in template.items:
		var count: int = int(template.items[species])
		state.inventory[species] = int(state.inventory[species]) - count
		quantity += count
	state.coins = int(state.coins) + reward
	state.xp = mini(MAX_COINS, int(state.xp) + int(template.xp_reward))
	state.sales = mini(MAX_COINS, int(state.sales) + quantity)
	state.onboarding = maxi(3, int(state.onboarding))
	state.orders_completed = int(state.orders_completed) + 1
	if int(state.pinned_order) == uid:
		state.pinned_order = 0
	var excluded: Array = []
	for index: int in range(state.orders.size() - 1, -1, -1):
		if int(state.orders[index].uid) == uid:
			state.orders.remove_at(index)
		else:
			excluded.append(state.orders[index].template_id)
	state.orders.append(Requests.make_offer(config, int(state.next_order_uid), level(), excluded))
	state.next_order_uid = int(state.next_order_uid) + 1
	return true

func pin_order(uid: int) -> bool:
	if uid != 0 and get_order(uid).is_empty():
		return false
	state.pinned_order = uid
	return true

func reserved_quantity(species: String) -> int:
	var template: Dictionary = order_template(int(state.pinned_order))
	if template.is_empty():
		return 0
	return mini(int(state.inventory.get(species, 0)), int(template.items.get(species, 0)))

func available_to_sell(species: String) -> int:
	return maxi(0, int(state.inventory.get(species, 0)) - reserved_quantity(species))

func planting_quote(species: String) -> Dictionary:
	var quote: Dictionary = {"count": 0, "cost": 0}
	if not config.plants.has(species) or level() < int(config.plants[species].level_required):
		return quote
	var empty: int = 0
	for index: int in range(int(state.plots_unlocked)):
		if state.plots[index].is_empty():
			empty += 1
	var price: int = int(config.plants[species].seed_cost)
	quote.count = mini(empty, int(state.coins) / price)
	quote.cost = int(quote.count) * price
	return quote

func plant_available(species: String, moment: int, limit: int = 16) -> int:
	var planted: int = 0
	for index: int in range(int(state.plots_unlocked)):
		if planted >= limit:
			break
		if plant(index, species, moment):
			planted += 1
	return planted

func harvest_ready(moment: int) -> int:
	var harvested: int = 0
	for index: int in range(int(state.plots_unlocked)):
		if harvest(index, moment):
			harvested += 1
	return harvested
