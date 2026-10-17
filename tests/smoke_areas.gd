extends SceneTree

const Save = preload("res://scripts/services/save_service.gd")
const Model = preload("res://scripts/domain/game_model.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	create_timer(70).timeout.connect(func() -> void: quit(2))
	call_deferred("_run")

func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func click(control: Control, local_point: Vector2 = Vector2(-1,-1)) -> void:
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
			for frame: int in range(3):
				await process_frame
			break
		ancestor = ancestor.get_parent()
	var point: Vector2 = control.get_global_rect().get_center() if local_point.x < 0 else control.global_position+local_point
	for pressed: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		control.get_viewport().push_input(event)
		await process_frame

func _run() -> void:
	root.size = Vector2i(320,640)
	root.content_scale_size = root.size
	for suffix: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://area-pointer.json"+suffix):
			DirAccess.remove_absolute("user://area-pointer.json"+suffix)
	var game: Control = load("res://scenes/garden/garden.tscn").instantiate()
	game.save_path = "user://area-pointer.json"
	game.telemetry_path = "user://area-pointer-events.jsonl"
	root.add_child(game)
	game.model.state.coins = 100000
	game.model.state.xp = 200
	game.model.state.settings.sound = false
	game.model.state.settings.reduced_motion = true
	game._refresh()
	game._refresh_panel()
	for frame: int in range(6): await process_frame
	await click(game.dock_tabs.Decor)
	check(game.selector_cards.area_market.disabled and game.selector_cards.area_lakeside.disabled,"future areas clearly locked for a starter garden")
	await click(game.selector_cards.area_market)
	check(game.model.state.garden_area == "cottage","locked area cannot change the active garden")
	game._open_panel("Shop")
	for rank: int in range(16):
		var upgrade: Button
		for child: Node in game.panel.get_children():
			if child is Button and child.get_meta("upgrade_id","") == "plots": upgrade = child
		var before: int = int(game.model.state.coins)
		var price: int = game.model.upgrade_price("plots")
		await click(upgrade)
		if is_instance_valid(game.purchase_dialog):
			await click(game.purchase_dialog.get_ok_button())
		check(game.model.state.plots_unlocked == rank+5 and game.model.state.coins == before-price,"real expansion %d opens exactly one bed" % rank)
		if rank == 4:
			check(game.model.state.garden_area == "market" and game.board.area == "market","ninth bed visibly unlocks Market Courtyard")
		if rank == 11:
			check(game.model.state.garden_area == "lakeside" and game.board.area == "lakeside","sixteenth bed visibly unlocks Lakeside")
	await click(game.close_button)
	for id: String in ["cottage","market","lakeside"]:
		await click(game.dock_tabs.Decor)
		await click(game.selector_cards["area_"+id])
		check(game.model.state.garden_area == id and game.board.area == id,"actual area card visits " + id)
		check(not game.board.bed_bounds().intersects(game.board.road_bounds()),"road remains separate after visiting " + id)
		await click(game.dock_tabs.Seeds)
		await click(game.plant_all_button)
		var planted: int = 0
		for plot: Dictionary in game.model.state.plots:
			if not plot.is_empty(): planted += 1
		check(planted == 20,"real batch control plants all twenty beds in " + id)
		game.clock_origin += 8
		game._refresh()
		for index: int in range(20):
			var tile: Control = game.board.plots[index]
			var rect: Rect2 = tile.art_rect()
			await click(tile,rect.position+rect.size*Vector2(0.5,0.25))
			check(game.model.state.plots[index].is_empty(),"real crop click harvests bed %d in %s" % [index,id])
	check(game.model.state.inventory.carrot == 60,"three area visits harvest exactly sixty crops")
	var restored := Model.new()
	check(Save.new(game.save_path).load_into(restored) and restored.state.garden_area == "lakeside" and restored.state.inventory.carrot == 60 and restored.state.plots_unlocked == 20,"map, capacity and harvest inventory persist together")
	game.queue_free()
	await process_frame
	print("AREA POINTER: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
