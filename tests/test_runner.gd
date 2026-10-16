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
