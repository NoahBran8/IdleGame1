extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Config = preload("res://scripts/domain/config.gd")
const SEED: int = 20261016
var failures: int = 0
var output_path: String = "res://docs/REQUEST_SIMULATION_RESULTS.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var runs: int = 1000
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output_path = arg.trim_prefix("--output=")
		if arg.begins_with("--runs="):
			runs = clampi(int(arg.trim_prefix("--runs=")), 1, 1000)
	var config := Config.new()
	var wallets: Array = []
	var deliveries: Array = []
	var first_deliveries: Array = []
	var total_bonus: int = 0
	var total_deliveries: int = 0
	var started: int = Time.get_ticks_msec()
	for trial: int in range(runs):
		var rng := RandomNumberGenerator.new()
		rng.seed = SEED + trial
		var model := Model.new(config)
		var moment: int = 1800000000
		var start: int = moment
		var first: int = -1
		model.advance_to(moment)
		while moment < start + 3600:
			model.advance_to(moment)
			model.harvest_ready(moment)
			var offers: Array = model.state.orders.duplicate(true)
			for offer: Dictionary in offers:
				if model.can_fulfill(int(offer.uid)):
					var before: int = int(model.state.coins)
					var template: Dictionary = model.order_template(int(offer.uid))
					if not model.fulfill_order(int(offer.uid)):
						failures += 1
					total_bonus += int(template.bonus_coins)
					total_deliveries += 1
					if first < 0:
						first = moment - start
					if model.fulfill_order(int(offer.uid)) or int(model.state.coins) <= before:
						failures += 1
			if int(model.state.pinned_order) == 0:
				model.pin_order(int(model.state.orders[rng.randi_range(0, 2)].uid))
			# Reservation must survive sell-all and automated stock sales.
			var reserved: Dictionary = {}
			for species: String in config.plants:
				reserved[species] = model.reserved_quantity(species)
			model.sell_all()
			for species: String in config.plants:
				if int(model.state.inventory[species]) < int(reserved[species]):
					failures += 1
			for id: String in config.quests:
				model.claim_quest(id)
			for upgrade: String in ["stand", "plots", "helper", "compost", "soil", "baskets"]:
				if model.can_upgrade(upgrade) and int(model.state.coins) - model.upgrade_price(upgrade) >= 100:
					model.buy_upgrade(upgrade, moment)
					break
			var template: Dictionary = model.order_template(int(model.state.pinned_order))
			var planned: Dictionary = {}
			for plot: Dictionary in model.state.plots:
				if not plot.is_empty():
					var id: String = plot.species_id
					planned[id] = int(planned.get(id, 0)) + 1
			for index: int in range(int(model.state.plots_unlocked)):
				if model.phase(index, moment) >= 0:
					continue
				var planted: bool = false
				for species: String in template.get("items", {}):
					var missing: int = int(template.items[species]) - int(model.state.inventory[species]) - int(planned.get(species, 0))
					if missing > 0 and model.plant(index, species, moment):
						planned[species] = int(planned.get(species, 0)) + 1
						planted = true
						break
				if not planted:
					model.plant(index, "carrot", moment)
			if not model.validate(model.state) or not model.keeps_seed_path(0):
				failures += 1
			moment += rng.randi_range(20, 90)
		model.advance_to(start + 86400)
		var persisted: Dictionary = JSON.parse_string(JSON.stringify(model.state))
		var restored := Model.new(config)
		restored.state = restored.migrate(persisted)
		if not restored.validate(restored.state) or restored.advance_to(start + 86400).income != 0:
			failures += 1
		restored.advance_to(start + 604800)
		if not restored.validate(restored.state):
			failures += 1
		wallets.append(int(restored.state.coins))
		deliveries.append(int(restored.state.orders_completed))
		if first >= 0:
			first_deliveries.append(first)
		if (trial + 1) % 100 == 0:
			print("Request simulations: %d/%d" % [trial + 1, runs])
			await process_frame
	var report: Dictionary = {"app_version": ProjectSettings.get_setting("application/config/version"), "runs": runs, "seed": SEED, "failures": failures,
		"runtime_seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"method": "One hour of request-focused synthetic play, visits 20-90s apart, then offline returns at day 1/day 7 and JSON save roundtrip. Uses real seed costs, crops, upgrades and quest rewards. Checks reservations, valid states, stale deliveries and repeated offline processing.",
		"total_deliveries": total_deliveries, "total_bonus_coins": total_bonus,
		"deliveries_per_player": summarize(deliveries), "first_delivery_seconds": summarize(first_deliveries), "wallet_after_7d": summarize(wallets)}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print(JSON.stringify(report, "  "))
	quit(0 if failures == 0 else 1)

func summarize(values: Array) -> Dictionary:
	if values.is_empty():
		return {"samples": 0}
	values.sort()
	return {"samples": values.size(), "min": values[0], "median": values[values.size() / 2], "max": values[-1]}
