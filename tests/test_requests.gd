extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Config = preload("res://scripts/domain/config.gd")
const Save = preload("res://scripts/services/save_service.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	create_timer(20).timeout.connect(func() -> void: quit(2))
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var model := Model.new()
	check(model.validate(model.state), "fresh request state valid")
	check(model.state.orders.size() == 3, "three non-expiring requests")
	check(model.state.orders == Model.new().state.orders, "deterministic initial board")
	check(model.order_template(1).id == "pantry", "starter request grows affordable carrots")
	var initial: Dictionary = model.state.duplicate(true)
	check(not model.fulfill_order(1) and model.state == initial, "missing ingredients cannot partially deliver")
	check(not model.fulfill_order(-1), "unknown request rejected")
	check(not model.pin_order(999), "unknown reservation rejected")
	check(model.pin_order(1), "pin starter request")
	model.state.inventory.carrot = 5
	check(model.reserved_quantity("carrot") == 3 and model.available_to_sell("carrot") == 2, "reserve exact recipe quantity")
	check(model.sell_all() == 18 and model.state.inventory.carrot == 3, "sell-all preserves request ingredients")
	check(model.sell("carrot", 1) == 0, "manual sell-one preserves reservation")
	var reward: int = model.order_reward(1)
	check(reward == 35, "reward equals market value plus explicit bonus")
	var before: int = int(model.state.coins)
	check(model.fulfill_order(1), "complete delivery")
	check(model.state.coins == before + 35 and model.state.inventory.carrot == 0, "delivery consumes real stock and credits exact reward")
	check(model.state.xp == 4 and model.state.orders_completed == 1, "delivery XP and count")
	check(model.state.pinned_order == 0 and model.state.orders.size() == 3, "reservation released and board replenished")
	var delivered: Dictionary = model.state.duplicate(true)
	check(not model.fulfill_order(1) and model.state == delivered, "stale delivery id cannot pay twice")
	check(model.validate(model.state), "completed delivery state valid")
	check(model.pin_order(int(model.state.orders[0].uid)) and model.pin_order(0), "unpin releases stock")
	model.state.inventory.carrot = 3
	model.state.upgrades.baskets = 5
	var pantry_uid: int = 0
	for offer: Dictionary in model.state.orders:
		if offer.template_id == "pantry":
			pantry_uid = int(offer.uid)
	check(pantry_uid > 1 and model.order_reward(pantry_uid) == 41, "replacement uses unique id and respects basket value")
	model.state.coins = Model.MAX_COINS - 1
	var cap_state: Dictionary = model.state.duplicate(true)
	check(not model.fulfill_order(pantry_uid) and model.state == cap_state, "full wallet preserves delivery ingredients and id")

	var mixed := Model.new()
	mixed.state.inventory.carrot = 2
	var mixed_before: Dictionary = mixed.state.duplicate(true)
	check(not mixed.fulfill_order(2) and mixed.state == mixed_before, "mixed recipe missing one species consumes nothing")
	# A malformed recipe must fail configuration before gameplay starts.
	DirAccess.make_dir_recursive_absolute("user://request-config")
	for name: String in ["plants", "economy", "upgrades", "quests", "requests"]:
		DirAccess.copy_absolute("res://data/" + name + ".json", "user://request-config/" + name + ".json")
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/requests.json"))
	rows[0].items = {"unknown": 3}
	var bad_config := FileAccess.open("user://request-config/requests.json", FileAccess.WRITE)
	bad_config.store_string(JSON.stringify(rows))
	bad_config.close()
	check(not Config.new("user://request-config").error.is_empty(), "unknown request ingredient fails configuration")
	rows[0].items = {"carrot": 0}
	bad_config = FileAccess.open("user://request-config/requests.json", FileAccess.WRITE)
	bad_config.store_string(JSON.stringify(rows))
	bad_config.close()
	check(not Config.new("user://request-config").error.is_empty(), "zero request quantity fails configuration")
	rows[0].items = {"orchid": 1}
	bad_config = FileAccess.open("user://request-config/requests.json", FileAccess.WRITE)
	bad_config.store_string(JSON.stringify(rows))
	bad_config.close()
	check(not Config.new("user://request-config").error.is_empty(), "request cannot ask for a species before its unlock")
	var stand := Model.new()
	stand.advance_to(1000)
	stand.state.upgrades.stand = 1
	stand.state.upgrades.helper = 1
	stand.state.inventory.carrot = 4
	stand.pin_order(1)
	stand.advance_to(1010)
	check(stand.state.inventory.carrot == 3 and stand.state.coins == 29, "stand sells only unreserved surplus")
	stand.advance_to(2000)
	check(stand.state.inventory.carrot == 3 and stand.state.coins == 29, "stand never sells reserved ingredients during absence")
	stand.pin_order(0)
	stand.advance_to(2030)
	check(stand.state.inventory.carrot == 0 and stand.state.coins == 56, "unpin restores normal automatic sales")

	var helper := Model.new()
	helper.advance_to(1000)
	helper.state.upgrades.stand = 1
	helper.state.upgrades.helper = 1
	helper.pin_order(1)
	check(helper.plant_available("carrot", 1000) == 4, "batch plant fills affordable unlocked plots")
	helper.advance_to(1100)
	check(helper.state.inventory.carrot == 3 and helper.state.coins == 9, "offline helper fills pinned request before stand sells surplus")
	check(helper.fulfill_order(1) and helper.state.coins == 44, "offline reserved harvest can be delivered")
	var partial := Model.new()
	partial.state.coins = 12
	check(partial.planting_quote("carrot") == {"count": 2, "cost": 10}, "batch quote respects affordability")
	check(partial.plant_available("carrot", 1000) == 2 and partial.state.coins == 2, "batch charges exact quantity")
	check(partial.plant_available("carrot", 1000) == 0, "repeat batch planting cannot overdraft")
	check(partial.harvest_ready(1007) == 0 and partial.harvest_ready(1008) == 2, "batch harvest respects maturity")
	check(partial.harvest_ready(1008) == 0 and partial.state.inventory.carrot == 2, "batch harvest cannot duplicate crops")
	check(partial.planting_quote("rose").count == 0 and partial.planting_quote("unknown").count == 0, "batch respects species and level gates")

	var limited := Model.new()
	check(limited.plant_available("carrot", 1000, 2) == 2 and limited.state.coins == 10, "batch respects confirmed quantity limit")
	check(limited.plant_available("carrot", 1000, 0) == 0 and limited.state.coins == 10, "zero-quantity quote cannot purchase")
	var legacy := Model.new()
	legacy.plant(0, "carrot", 1000)
	legacy.harvest(0, 1008)
	legacy.claim_quest("first_harvest")
	legacy.state.settings.large_text = true
	var v3: Dictionary = legacy.state.duplicate(true)
	v3.version = 3
	for field: String in ["orders", "next_order_uid", "orders_completed", "pinned_order"]:
		v3.erase(field)
	var migrated: Variant = legacy.migrate(v3)
	check(legacy.validate(migrated), "version-three save migrates to request schema")
	for field: String in ["coins", "xp", "plots", "inventory", "settings", "claimed_quests", "upgrades"]:
		check(migrated[field] == v3[field], "migration preserves " + field)
	var legacy_file := Save.new("user://test-legacy-v3.json")
	var file := FileAccess.open(legacy_file.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(v3))
	file.close()
	var restored := Model.new()
	check(legacy_file.load_into(restored) and restored.state.inventory.carrot == 1 and restored.state.settings.large_text, "real v3 save loads without reset")
	model.state.coins = 80
	model.pin_order(int(model.state.orders[0].uid))
	var saved := Save.new("user://test-requests.json")
	check(saved.store(model) and saved.load_into(restored), "request board save roundtrip")
	var offers_preserved: bool = restored.state.orders.size() == model.state.orders.size()
	for offer: Dictionary in model.state.orders:
		var restored_offer: Dictionary = restored.get_order(int(offer.uid))
		offers_preserved = offers_preserved and not restored_offer.is_empty() and restored_offer.template_id == offer.template_id
	check(offers_preserved and int(restored.state.pinned_order) == int(model.state.pinned_order), "request ids and reservation persist")
	check(not restored.fulfill_order(1), "completed request remains completed after restart")

	var invalid: Dictionary = model.state.duplicate(true)
	invalid.orders[1].uid = invalid.orders[0].uid
	check(not model.validate(invalid), "duplicate request id rejected")
	invalid = model.state.duplicate(true)
	invalid.pinned_order = 999
	check(not model.validate(invalid), "orphan reservation rejected")
	invalid = model.state.duplicate(true)
	invalid.orders[0].template_id = "unknown"
	check(not model.validate(invalid), "unknown recipe rejected")
	invalid = model.state.duplicate(true)
	invalid.next_order_uid = 4
	check(not model.validate(invalid), "invalid delivery cursor rejected")

	# Random sequences of real crops, reservations, sales and deliveries.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261016
	for trial: int in range(40):
		var bulk := Model.new()
		bulk.state.coins = 3000
		bulk.state.xp = 200
		bulk.state.upgrades.stand = 1
		bulk.state.upgrades.helper = 1
		bulk.advance_to(1000)
		bulk.pin_order(int(bulk.state.orders[rng.randi_range(0, 2)].uid))
		var species: Array = bulk.config.plants.keys()
		for index: int in range(4):
			bulk.plant(index, species[rng.randi_range(0, 4)], 1000)
		var stepped := Model.new(bulk.config)
		stepped.state = bulk.state.duplicate(true)
		bulk.advance_to(4600)
		for moment: int in range(1017, 4600, 17):
			stepped.advance_to(moment)
		stepped.advance_to(4600)
		check(bulk.state == stepped.state and bulk.validate(bulk.state), "reserved offline/incremental equivalence %d" % trial)
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://request-ui-test.json" + suffix):
			DirAccess.remove_absolute("user://request-ui-test.json" + suffix)
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var garden: Control = scene.instantiate()
	garden.save_path = "user://request-ui-test.json"
	garden.telemetry_path = "user://request-ui-events.jsonl"
	root.add_child(garden)
	# Audio itself is covered by test_runner; keep transaction tests silent.
	garden.model.state.settings.sound = false
	await process_frame
	garden.active_tab = "Requests"
	garden._refresh_panel()
	check(garden.request_buttons.size() == 3, "request cards mounted")
	garden.request_buttons[1].pin.pressed.emit()
	check(garden.model.state.pinned_order == 1, "pin UI action protects inventory")
	garden.model.state.inventory.carrot = 3
	garden._refresh_panel()
	check(not garden.request_buttons[1].deliver.disabled, "delivery enabled for complete recipe")
	garden.request_buttons[1].deliver.pressed.emit()
	check(garden.model.state.orders_completed == 1 and garden.model.state.coins == 55, "delivery UI credits request")
	garden._deliver_order(1)
	check(garden.model.state.coins == 55, "stale UI delivery rejected")
	garden._plant_available()
	check(garden.model.state.coins == 35, "batch UI uses real seed cost")
	check(garden.board.plots[0].seconds_left == 8, "growing plot shows countdown")
	check(garden.level_progress.value == 4, "order XP updates level progress")
	garden.model.state = garden.model.fresh()
	garden.model.state.coins = 5
	garden.model.state.settings.sound = false
	garden._refresh()
	garden.model.state.coins = 20
	garden._plant_available()
	check(garden.model.state.coins == 15, "income arriving after quote cannot increase batch spending")
	garden.audio.stop()
	garden.audio.stream = null
	await create_timer(0.2).timeout
	garden.queue_free()
	await process_frame
	print("REQUESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
