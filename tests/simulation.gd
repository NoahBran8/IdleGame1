extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Config = preload("res://scripts/domain/config.gd")
const STRATEGIES: Array[String] = ["fast_profit", "high_margin", "collector", "thrifty"]
const BASE_SEED: int = 20261015
var config: GardenConfig
var failures: int = 0
var output_path: String = "res://docs/SIMULATION_RESULTS.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	config = Config.new()
	var trials: int = 10000
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output_path = arg.trim_prefix("--output=")
		if arg.begins_with("--runs="):
			trials = clampi(int(arg.trim_prefix("--runs=")), 1, 10000)
	var groups: Dictionary = {}
	for strategy: String in STRATEGIES:
		groups[strategy] = {"runs": 0, "1h": [], "1d": [], "7d": [], "stand_seconds": [], "dead_ends": 0, "plots": [], "levels": []}
	var started: int = Time.get_ticks_msec()
	for index: int in range(trials):
		var strategy: String = STRATEGIES[index % STRATEGIES.size()]
		var rng := RandomNumberGenerator.new()
		rng.seed = BASE_SEED + index
		var model := Model.new(config)
		var epoch: int = 1800000000
		model.advance_to(epoch)
		var elapsed: int = 0
		var unlocked_stand: int = -1
		var end_active: int = 3600
		var stats: Dictionary = groups[strategy]
		stats.runs += 1
		while elapsed < end_active:
			var moment: int = epoch + elapsed
			model.advance_to(moment)
			visit(model, moment, strategy, rng)
			if unlocked_stand < 0 and int(model.state.upgrades.stand) > 0:
				unlocked_stand = elapsed
			var gap: int = rng.randi_range(8, 20) if elapsed < 60 else rng.randi_range(30, 180)
			elapsed = mini(end_active, elapsed + gap)
		model.advance_to(epoch + end_active)
		model.sell_all()
		stats["1h"].append(int(model.state.coins))
		for horizon: int in [86400, 604800]:
			# Model one return at day 1 and day 7, not continuous active play.
			model.advance_to(epoch + horizon)
			visit(model, epoch + horizon, strategy, rng)
			stats["1d" if horizon == 86400 else "7d"].append(int(model.state.coins))
		if unlocked_stand >= 0:
			stats.stand_seconds.append(unlocked_stand)
		stats.plots.append(int(model.state.plots_unlocked))
		stats.levels.append(model.level())
		if not model.keeps_seed_path(0):
			stats.dead_ends += 1
			failures += 1
		if not model.validate(model.state) or int(model.state.coins) < 0:
			failures += 1
		if (index + 1) % 1000 == 0:
			print("Simulated %d/%d players" % [index + 1, trials])
			await process_frame
	var summaries: Dictionary = {}
	for strategy: String in STRATEGIES:
		var stats: Dictionary = groups[strategy]
		summaries[strategy] = {"runs": stats.runs, "dead_ends": stats.dead_ends,
			"wallet_1h": summarize(stats["1h"]), "wallet_1d": summarize(stats["1d"]), "wallet_7d": summarize(stats["7d"]),
			"stand_unlock_seconds": summarize(stats.stand_seconds), "plots": summarize(stats.plots), "levels": summarize(stats.levels)}
	var report: Dictionary = {"app_version":ProjectSettings.get_setting("application/config/version"),"seed": BASE_SEED, "runs": trials, "failures": failures,
		"runtime_seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"method": "One hour with 8-20s visits in the first minute then 30-180s visits, returns at day 1 and day 7. Offline cap applies to each absence. Four deterministic strategies; seed varies per player. Measures model invariants and synthetic economy, not human retention.",
		"strategies": summaries}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print(JSON.stringify(report, "  "))
	quit(0 if failures == 0 else 1)

func visit(model: GardenModel, moment: int, strategy: String, rng: RandomNumberGenerator) -> void:
	for plot: int in range(int(model.state.plots_unlocked)):
		model.harvest(plot, moment)
	model.sell_all()
	for id: String in config.quests:
		model.claim_quest(id)
	var investments: Array[String] = ["plots", "compost", "baskets", "stand", "soil", "irrigation", "helper", "signage"]
	if strategy == "thrifty":
		investments = ["plots", "stand", "baskets"]
	elif strategy == "collector":
		investments = ["soil", "plots", "stand", "helper", "compost", "baskets"]
	for upgrade: String in investments:
		var price: int = model.upgrade_price(upgrade)
		var reserve: int = int(model.state.plots_unlocked) * 12
		if price > 0 and int(model.state.coins) - price >= reserve and model.can_upgrade(upgrade):
			model.buy_upgrade(upgrade, moment)
			break
	var candidates: Array[String] = []
	for id: String in config.plants:
		if model.level() >= int(config.plants[id].level_required) and int(model.state.coins) >= int(config.plants[id].seed_cost):
			candidates.append(id)
	if candidates.is_empty():
		return
	var chosen: String = candidates[0]
	var score: float = -1.0
	for id: String in candidates:
		var row: Dictionary = config.plants[id]
		var profit: int = model.sell_value(id) - int(row.seed_cost)
		var value: float = float(profit) / model.growth_seconds(id)
		if strategy == "high_margin":
			value = profit
		elif strategy == "collector" and not id in model.state.discovered:
			value += 1000.0
		elif strategy == "thrifty":
			value = 1.0 / int(row.seed_cost)
		if value > score:
			score = value
			chosen = id
	for plot: int in range(int(model.state.plots_unlocked)):
		var id: String = chosen
		if strategy == "collector" and rng.randf() < 0.25:
			id = candidates[rng.randi_range(0, candidates.size() - 1)]
		if not model.plant(plot, id, moment) and model.phase(plot, moment) == -1:
			model.plant(plot, "carrot", moment)

func summarize(values: Array) -> Dictionary:
	if values.is_empty():
		return {"samples": 0}
	values.sort()
	var total: float = 0.0
	for number: Variant in values:
		total += float(number)
	return {"samples": values.size(), "min": values[0], "median": values[values.size() / 2],
		"p90": values[mini(values.size() - 1, int(values.size() * 0.9))], "max": values[-1], "mean": snappedf(total / values.size(), 0.01)}
