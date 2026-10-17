extends SceneTree

const Save = preload("res://scripts/services/save_service.gd")
const Model = preload("res://scripts/domain/game_model.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _run() -> void:
	root.size = Vector2i(540,960)
	root.content_scale_size = root.size
	var game: Control = load("res://scenes/garden/garden.tscn").instantiate()
	game.save_path = "user://presentation-test.json"
	game.telemetry_path = "user://presentation-events.jsonl"
	root.add_child(game)
	game.set_process(false)
	for frame: int in range(6):
		await process_frame
	game.model.state = game.model.fresh()
	game.model.state.settings.sound = false
	game.model.state.settings.reduced_motion = true
	game._refresh()
	check(game.board.buildings.stand.status_caption() == "Build","unbuilt stand invites construction")
	check(game.tab_buttons.Inventory.badge.is_empty() and game.tab_buttons.Requests.badge.is_empty(),"fresh game has no misleading stock or delivery badge")
	game.model.state.upgrades.stand = 1
	game._refresh()
	check(game.board.buildings.stand.status_caption() == "Needs crops","built empty stand asks for real stock")
	game.model.state.inventory.carrot = 3
	game._refresh()
	check(game.board.buildings.stand.stock_count == 3 and game.board.buildings.stand.stock_species == ["carrot"],"stand display follows actual surplus species")
	check(game.tab_buttons.Inventory.badge == "3" and game.tab_buttons.Requests.badge == "1","harvest and ready delivery badges reflect inventory")
	check(game.model.pin_order(1),"fixture reserves breakfast ingredients")
	game._refresh()
	check(game.board.buildings.stand.stock_count == 0 and game.board.buildings.stand.reserved_stock == 3,"reserved crops are excluded from displayed sellable stock")
	check(game.board.buildings.stand.status_caption() == "Reserved" and game.board.buildings.stand.stock_species.is_empty(),"all-held stand has reserved status and no surplus bouquet")
	check(game.tab_buttons.Requests.badge == "1","reserved ingredients can still be delivered")
	game.model.state.inventory.carrot = 4
	game._refresh()
	check(game.board.buildings.stand.stock_count == 1 and game.tab_buttons.Inventory.badge == "4","surplus stand count and total inventory count remain distinct")
	check(game.model.fulfill_order(1),"fixture delivers reserved request")
	game._refresh()
	check(game.tab_buttons.Inventory.badge == "1" and game.tab_buttons.Requests.badge.is_empty(),"badges clear immediately after delivery consumes ingredients")
	check(game.model.claim_quest("first_sale"),"delivery qualifies for existing first-sale goal")
	game.model.state.inventory.carrot = 120
	game._refresh()
	check(game.tab_buttons.Inventory.badge == "99+","large inventory badge stays bounded")
	game.model.state.inventory.carrot = 0
	game.model.state.upgrades.stand = 0
	game.model.state.harvests = 1
	game._refresh()
	check(game.tab_buttons.Inventory.badge.is_empty() and game.tab_buttons.Journal.badge == "1","empty stock badge clears and earned quest appears")
	check(game.model.claim_quest("first_harvest"),"fixture claims earned quest")
	game._refresh()
	check(game.tab_buttons.Journal.badge.is_empty(),"claimed goal badge clears")
	game.model.state.upgrades.stand = 1
	for id: String in ["compost","irrigation","baskets","helper","signage","soil"]:
		game.model.state.upgrades[id] = 1
	game._refresh()
	for object: Button in game.board.buildings.values():
		for id: String in ["compost","irrigation","baskets","helper","signage","soil"]:
			check(object.upgrade_ranks[id] == 1,"visible installation follows saved upgrade: " + id)
	for texture: Texture2D in game.Board.Plot.PLANT_ART.values():
		check(texture.get_width() <= 128 and texture.get_height() <= 128,"imported crop texture obeys mobile size budget")
	for texture: Texture2D in game.board.buildings.home.ART.values():
		check(texture.get_width() <= 256 and texture.get_height() <= 256,"imported building texture obeys mobile size budget")
	var before: String = JSON.stringify(game.model.state)
	for iteration: int in range(3):
		game._refresh()
	check(JSON.stringify(game.model.state) == before,"presentation refreshes never mutate earned state")
	check(Save.new(game.save_path).store(game.model),"presentation fixture saves normally")
	var restored := Model.new()
	check(Save.new(game.save_path).load_into(restored) and restored.state.upgrades.helper == 1 and restored.state.version == 5,"presentation uses unchanged schema and upgrade state")
	for object: Button in game.board.buildings.values():
		object.size = Vector2(51,48)
		object.large_text = true
		var caption: String = object.status_caption()
		check(object.get_theme_font("font").get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+10 <= object.size.x,"building caption fits smallest large-text control")
	game.queue_free()
	await process_frame
	print("PRESENTATION: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
