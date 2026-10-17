extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Save = preload("res://scripts/services/save_service.gd")
const Areas = preload("res://scripts/domain/garden_areas.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func equal(a: Variant,b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not equal(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i: int in range(a.size()):
			if not equal(a[i],b[i]): return false
		return true
	return a == b

func _run() -> void:
	var model := Model.new()
	check(model.config.error.is_empty() and model.state.plots.size() == 20 and model.state.plots_unlocked == 4,"5x4 property begins with four open beds")
	model.state.coins = 12345
	model.state.xp = 200
	model.state.plots_unlocked = 16
	model.state.upgrades.plots = 12
	model.plant(15,"orchid",1000)
	model.state.inventory.carrot = 3
	model.pin_order(1)
	model.state.claimed_quests = ["first_harvest"]
	model.state.settings.large_text = true
	var legacy: Dictionary = model.state.duplicate(true)
	legacy.version = 5
	legacy.erase("garden_area")
	legacy.plots.resize(16)
	var original: Dictionary = legacy.duplicate(true)
	var migrated: Dictionary = model.migrate(legacy)
	check(model.validate(migrated) and migrated.version == 6 and migrated.garden_area == "cottage","real 16-bed v5 migrates to area schema")
	check(equal(legacy,original),"migration does not mutate the original save")
	for key: String in legacy:
		if key == "version": continue
		check(equal(legacy[key],migrated.plots.slice(0,16) if key == "plots" else migrated[key]),"migration preserves earned field " + key)
	check(migrated.plots.size() == 20 and migrated.plots.slice(16,20) == [{},{},{},{}],"migration only appends four empty beds")
	var file := FileAccess.open("user://area-v5.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var restored := Model.new()
	check(Save.new("user://area-v5.json").load_into(restored) and equal(restored.state.plots[15],legacy.plots[15]),"JSON migration preserves old plot IDs and crop times")
	check(Save.new("user://area-v5.json").store(restored),"migrated save can be written atomically")
	var again := Model.new()
	check(Save.new("user://area-v5.json").load_into(again) and again.state.plots.size() == 20,"migration is idempotent across a second reload")
	model.state = model.fresh()
	model.state.coins = 100000
	var snapshot: String = JSON.stringify(model.state)
	check(not model.select_area("market") and not model.select_area("bogus") and JSON.stringify(model.state) == snapshot,"locked/unknown areas cannot mutate state")
	var prices: Array = [20,35,60,95,150,240,380,600,950,1500,2400,3800,6000,9500,15000,24000]
	for rank: int in range(16):
		check(model.upgrade_price("plots") == prices[rank],"expansion price %d stays on the explicit ladder" % rank)
		var coins: int = int(model.state.coins)
		check(model.buy_upgrade("plots",1000) and model.state.coins == coins-prices[rank],"paid expansion %d debits once" % rank)
		check(model.validate(model.state),"expanded state remains valid")
		if model.state.plots_unlocked == 8:
			check(not model.select_area("market"),"market stays locked below nine beds")
		if model.state.plots_unlocked == 9:
			check(model.state.garden_area == "market","ninth bed opens and selects Market Courtyard")
		if model.state.plots_unlocked == 15:
			check(not model.select_area("lakeside"),"lakeside stays locked below sixteen beds")
		if model.state.plots_unlocked == 16:
			check(model.state.garden_area == "lakeside","sixteenth bed opens and selects Lakeside")
	check(model.state.plots_unlocked == 20 and model.upgrade_price("plots") == -1 and not model.buy_upgrade("plots",1000),"twentieth bed is a safe expansion cap")
	check(model.plant_available("carrot",1000) == 20,"batch planting includes all twenty beds")
	var crops: Array = model.state.plots.duplicate(true)
	for id: String in Areas.ORDER:
		check(model.select_area(id) and equal(crops,model.state.plots),"visiting " + id + " preserves every planted bed")
	check(model.harvest_ready(1008) == 20 and model.state.inventory.carrot == 20,"all twenty beds harvest exactly once")
	check(model.harvest_ready(1008) == 0,"duplicate harvest cannot credit extra crops")
	check(Save.new("user://area-roundtrip.json").store(model) and Save.new("user://area-roundtrip.json").load_into(restored) and restored.state.garden_area == "lakeside","selected area and new capacity survive reload")
	var automatic := Model.new()
	automatic.state = model.state.duplicate(true)
	automatic.state.inventory.carrot = 0
	automatic.state.xp = 200
	automatic.advance_to(2000)
	check(automatic.buy_upgrade("helper",2000) and automatic.buy_upgrade("stand",2000),"automation can be purchased on the expanded property")
	check(automatic.plant_available("carrot",2000) == 20,"expanded automation fixture plants every bed")
	var wallet: int = int(automatic.state.coins)
	var report: Dictionary = automatic.advance_to(2010)
	check(report.harvests == 20 and automatic.state.plots[19].is_empty(),"offline helper includes all four added beds")
	check(automatic.state.inventory.carrot == 19 and automatic.state.coins == wallet+9,"stand sells only one real crop after expanded helper tick")
	check(automatic.advance_to(2010).income == 0 and automatic.state.garden_area == "lakeside","expanded offline reconciliation remains idempotent and preserves area")
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var game: Control = scene.instantiate()
	game.save_path = "user://area-ui.json"
	game.telemetry_path = "user://area-ui-events.jsonl"
	root.add_child(game)
	game.set_process(false)
	game.model.state = model.state.duplicate(true)
	game.model.state.settings.sound = false
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(320,640),Vector2i(540,960)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for id: String in Areas.ORDER:
			game.model.select_area(id)
			game._refresh()
			for frame: int in range(6): await process_frame
			check(game.board.plots.size() == 20 and game.board.COLUMNS == 5 and game.board.ROWS == 4,"each area renders five by four")
			check(not game.board.road_bounds().intersects(game.board.bed_bounds()),"road stays clear of the garden in " + id + " at " + str(dimensions))
			var positions: Array = []
			for tile: Control in game.board.plots:
				check(tile.size.x >= 44 and Rect2(Vector2.ZERO,game.board.size).grow(1).encloses(tile.get_rect()),"small beds retain usable in-bounds controls")
				check(not positions.has(tile.position),"each persistent bed has a unique position")
				positions.append(tile.position)
	game.dock_mode = "Decor"
	game._refresh_dock()
	check(game.selector_cards.has("area_cottage") and game.selector_cards.has("area_market") and game.selector_cards.has("area_lakeside") and game.selector_cards.has("wildflowers"),"Garden selector retains maps and all cosmetic looks")
	game.queue_free()
	await process_frame
	print("AREAS: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
