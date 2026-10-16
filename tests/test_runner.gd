extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Config = preload("res://scripts/domain/config.gd")
const Save = preload("res://scripts/services/save_service.gd")
var checks: int = 0
var failures: int = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model := Model.new()
	check(model.config.error.is_empty(), "configuration schema valid")
	check(model.state.coins == 20 and model.state.plots_unlocked == 4, "fresh wallet and garden")
	check(model.plant(0, "carrot", 1000), "plant seed")
	check(model.state.coins == 15, "exact seed debit")
	check(not model.plant(0, "carrot", 1000), "duplicate planting rejected")
	check(not model.plant(4, "carrot", 1000), "locked plot rejected")
	check(not model.plant(1, "rose", 1000), "level gate enforced")
	check(model.phase(0, 999) == 0, "negative delta stays at first growth stage")
	check(model.phase(0, 1003) == 1 and model.phase(0, 1006) == 2, "three growth stages")
	check(not model.harvest(0, 1007), "cannot harvest early")
	check(model.harvest(0, 1008), "exact maturity harvest")
	check(not model.harvest(0, 1008), "duplicate harvest rejected")
	check(model.state.inventory.carrot == 1 and model.state.xp == 2, "harvest inventory and XP")
	check(model.sell("carrot", 1) == 9 and model.state.coins == 24, "sale credits exact coins")
	check(model.sell("carrot", 1) == 0, "cannot sell absent inventory")
	check(model.sell("carrot", -1) == 0, "cannot sell negative quantities")
	model.state.coins = Model.MAX_COINS - 5
	model.state.inventory.carrot = 2
	check(model.sell_all() == 0 and model.state.inventory.carrot == 2, "wallet cap preserves unsold inventory")
	model.state.coins = Model.MAX_COINS - 10
	check(model.sell_all() == 9 and model.state.inventory.carrot == 1, "wallet cap sells only fitting quantity")
	model.state.coins = 0
	check(not model.plant(1, "carrot", 1000), "insufficient coins rejected")
	check(model.validate(model.state), "state validates")
	var bad: Dictionary = model.state.duplicate(true)
	bad.coins = -1
	check(not model.validate(bad), "negative balance invalid")
	bad = model.state.duplicate(true)
	bad.inventory.carrot = 0.5
	check(not model.validate(bad), "fractional inventory invalid")
	bad = model.state.duplicate(true)
	bad.version = 999
	check(not model.validate(bad), "future schema rejected")
	bad = model.state.duplicate(true)
	bad.plots = []
	check(not model.validate(bad), "malformed plots rejected")
	var save := Save.new("user://test-garden.json")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save.path + suffix):
			DirAccess.remove_absolute(save.path + suffix)
	check(save.store(model), "save initial state")
	model.state.coins = 25
	check(save.store(model), "save with backup")
	var restored := Model.new()
	check(save.load_into(restored) and restored.state.coins == 25, "restart restores primary")
	var corrupt := FileAccess.open(save.path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	check(save.load_into(restored) and restored.state.coins == 0, "corrupt primary recovers backup")
	check(not save.message.is_empty(), "backup recovery visible")
	corrupt = FileAccess.open(save.path, FileAccess.WRITE)
	corrupt.store_string("{}")
	corrupt.close()
	corrupt = FileAccess.open(save.path + ".bak", FileAccess.WRITE)
	corrupt.store_string("{}")
	corrupt.close()
	check(not save.load_into(restored) and save.blocked, "both corrupt preserves files and blocks writes")
	check(not save.store(restored), "blocked recovery cannot overwrite")
	check(Config.integer(9000000000000000, 0, Model.MAX_COINS), "64-bit currency supported")
	check(not Config.integer(NAN, 0, Model.MAX_COINS), "nonfinite invalid")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://garden.json" + suffix):
			DirAccess.remove_absolute("user://garden.json" + suffix)
	var progression := Model.new()
	progression.advance_to(1000)
	check(not progression.buy_upgrade("plots", 1000), "upgrade keeps seed reserve in empty garden")
	progression.state.coins = 100000
	progression.state.xp = 200
	check(progression.buy_upgrade("plots", 1000) and progression.state.plots_unlocked == 5, "expansion opens plot")
	check(progression.upgrade_price("plots") == 35, "expansion follows price ladder")
	var original_growth: int = progression.growth_seconds("orchid")
	check(progression.buy_upgrade("compost", 1000), "compost bought")
	check(progression.growth_seconds("orchid") < original_growth, "compost reduces growth")
	check(progression.buy_upgrade("baskets", 1000) and progression.sell_value("orchid") == 441, "integer sale bonus")
	check(not progression.buy_upgrade("signage", 1000), "signage requires stand")
	check(progression.buy_upgrade("stand", 1000), "stand unlock")
	check(not progression.buy_upgrade("stand", 1000), "stand cannot buy twice")
	var coins_before: int = progression.state.coins
	progression.advance_to(1010)
	check(progression.state.coins == coins_before, "stand never conjures goods")
	progression.state.inventory.carrot = 2
	var sale_value: int = progression.sell_value("carrot")
	check(progression.advance_to(1020).income == sale_value, "stand consumes one real item per tick")
	check(progression.state.inventory.carrot == 1, "stand decreases inventory")
	check(progression.advance_to(1020).income == 0, "repeated reconciliation is idempotent")
	check(progression.advance_to(1019).income == 0 and progression.state.last_update == 1020, "backward clock ignored")
	check(progression.buy_upgrade("helper", 1020), "helper unlocked")
	check(progression.plant(0, "carrot", 1020), "plant for helper")
	var offline: Dictionary = progression.advance_to(1040)
	check(offline.harvests == 1 and progression.state.plots[0].is_empty(), "helper harvests mature plant offline")
	check(offline.income == sale_value * 2 and progression.state.inventory.carrot == 0, "chronological stand ticks include helper harvest")
	check(progression.buy_upgrade("signage", 1040) and progression.stand_interval() == 8, "stand interval upgrade")
	for i: int in range(20):
		progression.buy_upgrade("compost", 1040)
	check(progression.state.upgrades.compost == 5 and progression.upgrade_price("compost") == -1, "upgrade level cap")
	var capped := Model.new()
	capped.advance_to(1000)
	capped.state.upgrades.stand = 1
	capped.state.stand_at = 1000
	capped.state.inventory.carrot = 10000
	var report: Dictionary = capped.advance_to(1000 + 86400)
	check(report.capped and report.elapsed == 28800, "eight-hour offline cap")
	check(capped.state.inventory.carrot == 7120 and report.income == 2880 * 9, "capped ticks credit exact bounded income")
	check(capped.advance_to(87400).income == 0, "offline cap cannot recredit same return")
	var no_stand := Model.new()
	no_stand.advance_to(1000)
	no_stand.plant(0, "carrot", 1000)
	no_stand.advance_to(1000 + 86400)
	check(no_stand.phase(0, 87400) == 3 and no_stand.state.inventory.carrot == 0, "offline growth without free harvest")
	var legacy: Dictionary = no_stand.state.duplicate(true)
	legacy.version = 1
	for key: String in ["upgrades", "last_update", "stand_at", "helper_at"]:
		legacy.erase(key)
	var migrated: Variant = no_stand.migrate(legacy)
	check(no_stand.validate(migrated) and migrated.coins == legacy.coins, "version-one save migration")
	var persisted := Save.new("user://offline-test.json")
	check(persisted.store(capped), "offline result saved")
	var reloaded := Model.new()
	check(persisted.load_into(reloaded) and reloaded.advance_to(87400).income == 0, "restart cannot recredit offline income")
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var garden: Control = scene.instantiate()
	root.add_child(garden)
	await process_frame
	check(garden.board.plots.size() == 16, "garden scene mounts sixteen plots")
	check(garden.hud.text.contains("coins"), "HUD mounted")
	garden._on_plot(0)
	check(garden.model.state.plots[0].size() > 0, "scene planting handler")
	garden.active_tab = "Inventory"
	garden._refresh_panel()
	check(garden.panel.get_child_count() == 7, "inventory controls mounted")
	garden.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
