extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Config = preload("res://scripts/domain/config.gd")
const Analytics = preload("res://scripts/services/analytics_service.gd")
const Audio = preload("res://scripts/services/audio_service.gd")
const Save = preload("res://scripts/services/save_service.gd")
var checks: int = 0
var failures: int = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	create_timer(15).timeout.connect(func() -> void: quit(2))
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
		if FileAccess.file_exists("user://test-scene.json" + suffix):
			DirAccess.remove_absolute("user://test-scene.json" + suffix)
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261015
	for trial: int in range(50):
		var bulk := Model.new()
		bulk.state.coins = 10000
		bulk.state.xp = 200
		bulk.advance_to(1000)
		bulk.state.upgrades.stand = rng.randi_range(0, 1)
		bulk.state.upgrades.helper = rng.randi_range(0, 1)
		bulk.state.upgrades.signage = rng.randi_range(0, 3) if bulk.state.upgrades.stand else 0
		var species: Array = bulk.config.plants.keys()
		for index: int in range(4):
			bulk.plant(index, species[rng.randi_range(0, 4)], 1000)
		var stepped := Model.new()
		stepped.state = bulk.state.duplicate(true)
		bulk.advance_to(4600)
		for time: int in range(1013, 4600, 13):
			stepped.advance_to(time)
		stepped.advance_to(4600)
		check(bulk.state == stepped.state, "offline equals incremental progress (randomized trial %d)" % trial)
	var extremes := Model.new()
	check(not extremes.plant(0, "carrot", -1) and extremes.state.coins == 20, "invalid planting clock cannot debit")
	extremes.advance_to(-1)
	check(extremes.state.last_update == 0, "negative initial clock ignored")
	extremes.advance_to(Model.MAX_COINS)
	check(extremes.state.last_update == 0, "unrepresentable initial clock ignored")
	extremes.plant(0, "carrot", 1000)
	extremes.state.inventory.carrot = Model.MAX_COINS
	check(not extremes.harvest(0, 1008) and not extremes.state.plots[0].is_empty(), "full inventory preserves mature crop")
	var goals := Model.new()
	check(not goals.claim_quest("first_harvest"), "incomplete quest rejected")
	goals.plant(0, "carrot", 1000)
	goals.harvest(0, 1008)
	check(goals.claim_quest("first_harvest") and goals.state.coins == 25, "quest exact reward")
	check(not goals.claim_quest("first_harvest"), "quest reward cannot repeat")
	check(goals.state.discovered == ["carrot"], "collection discovery recorded")
	goals.sell_all()
	check(goals.state.onboarding == 3, "onboarding advances through sale")
	check(goals.claim_quest("first_sale") and goals.state.coins == 49, "sales quest eligible")
	var v2: Dictionary = goals.state.duplicate(true)
	v2.version = 2
	v2.erase("claimed_quests")
	v2.erase("onboarding")
	v2.settings.erase("sound")
	v2.settings.erase("local_telemetry")
	check(goals.validate(goals.migrate(v2)), "version-two migration adds quest and settings defaults")
	var duplicated: Dictionary = goals.state.duplicate(true)
	duplicated.claimed_quests.append("first_harvest")
	check(not goals.validate(duplicated), "duplicate claimed quest invalid")
	var log := Analytics.new("user://test-events.jsonl")
	check(log.record("seed_planted", {"species": "carrot"}), "local event record")
	check(not log.record("unknown_event"), "unknown event rejected")
	check(not log.record("seed_planted", {"email": "test@example.com"}), "PII parameter rejected")
	log.enabled = false
	check(not log.record("session_start"), "telemetry disabled")
	log.enabled = true
	for index: int in range(105):
		log.record("session_start")
	check(log.events.size() == 100, "event memory bounded")
	check(not log.events[0].has("install_id"), "no persistent install identifier")
	var tone: AudioStreamWAV = Audio.tone()
	check(tone.data.size() == 6614 and tone.mix_rate == 22050, "original procedural sound generated")
	var future := Save.new("user://future-test.json")
	var future_state: Dictionary = goals.state.duplicate(true)
	future_state.version = 99
	var f := FileAccess.open(future.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(future_state))
	f.close()
	check(not future.load_into(goals) and future.blocked, "future save preserved rather than rolled back")
	DirAccess.make_dir_recursive_absolute("user://bad-config")
	for name: String in ["plants", "economy", "upgrades", "quests"]:
		DirAccess.copy_absolute("res://data/" + name + ".json", "user://bad-config/" + name + ".json")
	var config_path: String = "user://bad-config/plants.json"
	var malformed := FileAccess.open(config_path, FileAccess.WRITE)
	malformed.store_string("{invalid")
	malformed.close()
	check(not Config.new("user://bad-config").error.is_empty(), "malformed config fails explicitly")
	check(not Config.new("user://nonexistent-config").error.is_empty(), "missing config fails explicitly")
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var garden: Control = scene.instantiate()
	garden.save_path = "user://test-scene.json"
	garden.telemetry_path = "user://test-scene-events.jsonl"
	root.add_child(garden)
	# Transaction checks are silent; rendered smoke covers active audio playback.
	garden.model.state.settings.sound = false
	await process_frame
	check(garden.board.plots.size() == 20, "garden scene mounts twenty plots")
	check(garden.hud.text == "20", "HUD mounted")
	garden._on_plot(0)
	check(garden.model.state.plots[0].size() > 0, "scene planting handler")
	garden.active_tab = "Inventory"
	garden._refresh_panel()
	check(garden.panel.get_child_count() == 7, "inventory controls mounted")
	garden.active_tab = "Journal"
	garden._refresh_panel()
	check(garden.panel.get_child_count() == 17, "journal collection and five quest controls")
	garden.active_tab = "Settings"
	garden._refresh_panel()
	var before_font: int = garden.hud.get_theme_font_size("font_size")
	garden.model.state.settings.large_text = true
	garden.apply_settings()
	check(garden.hud.get_theme_font_size("font_size") > before_font, "large text scales HUD")
	var scaled_font: int = garden.hud.get_theme_font_size("font_size")
	garden.apply_settings()
	check(garden.hud.get_theme_font_size("font_size") == scaled_font, "text scaling is idempotent")
	garden.model.state.settings.reduced_motion = true
	garden.model.state.settings.sound = false
	garden.audio.stop()
	garden._feedback(660.0)
	check(not garden.audio.playing, "mute blocks sound")
	garden.audio.stop()
	garden.audio.stream = null
	await create_timer(0.2).timeout
	garden.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
