extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Save = preload("res://scripts/services/save_service.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	create_timer(50).timeout.connect(func() -> void: quit(2))
	call_deferred("_run")

func check(value: bool,text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)

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
		if FileAccess.file_exists("user://redesign-pointer.json"+suffix):
			DirAccess.remove_absolute("user://redesign-pointer.json"+suffix)
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var game: Control = scene.instantiate()
	game.save_path = "user://redesign-pointer.json"
	game.telemetry_path = "user://redesign-pointer-events.jsonl"
	root.add_child(game)
	game.model.state.coins = 5000
	game.model.state.xp = 200
	game.model.state.plots_unlocked = 16
	game.model.state.upgrades.plots = 12
	game.model.state.settings.sound = false
	game.model.state.settings.reduced_motion = true
	game._refresh()
	game._refresh_panel()
	for frame: int in range(6):
		await process_frame
	var initial: int = int(game.model.state.coins)
	for index: int in range(16):
		await click(game.board.plots[index])
		check(not game.model.state.plots[index].is_empty(), "plot %d receives its own real pointer click" % index)
		check(game.model.state.coins == initial-(index+1)*5,"plot %d charges exactly once" % index)
	# Time injection here is a test fixture; the existing interaction smoke waits in real time.
	game.clock_origin += 8
	game._refresh()
	for index: int in range(16):
		var plot: Control = game.board.plots[index]
		await click(plot,plot.art_rect().position+plot.art_rect().size*Vector2(0.5,0.25))
		check(game.model.state.plots[index].is_empty(),"visible plant artwork harvests plot %d" % index)
	await click(game.harvest_all_button)
	check(game.model.state.inventory.carrot == 16,"all sixteen plots can be harvested")
	check(game.model.state.xp == 232,"batch harvest XP retained")
	await click(game.tab_buttons.Inventory)
	check(game.modal_layer.visible,"inventory opens overlay")
	var coins: int = int(game.model.state.coins)
	await click(game.panel.get_child(6))
	check(game.model.state.coins == coins+144 and game.model.state.inventory.carrot == 0,"sell-all reachable inside modal")
	await click(game.close_button)
	check(not game.modal_layer.visible,"close restores interactive garden")
	await click(game.board.buildings.home)
	check(game.active_tab == "Journal" and game.modal_layer.visible,"cottage is visible interactive object")
	coins = int(game.model.state.coins)
	await click(game.panel.get_child(8))
	check(game.model.state.coins == coins+10,"quest reward reachable from cottage")
	await click(game.close_button)
	await click(game.board.buildings.stand)
	check(game.active_tab == "Shop","unbuilt stand opens upgrade controls")
	await click(game.close_button)
	var stand_button: Button
	for child: Node in game.panel.get_children():
		if child is Button and child.get_meta("upgrade_id","") == "stand":
			stand_button = child
	# Reopen the functional shop, then exercise the real confirmation/cancel flow.
	game._open_panel("Shop")
	for child: Node in game.panel.get_children():
		if child is Button and child.get_meta("upgrade_id","") == "stand":
			stand_button = child
	var before_purchase: int = int(game.model.state.coins)
	await click(stand_button)
	var dialog: Control = game.purchase_dialog
	check(dialog != null and dialog.visible,"expensive purchase opens confirmation")
	check(dialog.panel.get_theme_stylebox("panel").bg_color.get_luminance() > 0.7,"confirmation uses readable light panel")
	await click(dialog.get_cancel_button())
	check(game.model.state.coins == before_purchase and game.model.state.upgrades.stand == 0,"cancel preserves wallet")
	for child: Node in game.panel.get_children():
		if child is Button and child.get_meta("upgrade_id","") == "stand":
			stand_button = child
	await click(stand_button)
	dialog = game.purchase_dialog
	await click(dialog.get_ok_button())
	check(game.model.state.coins == before_purchase-150 and game.model.state.upgrades.stand == 1,"confirmed purchase debits real wallet once")
	game._close_panel()
	game._refresh()
	await click(game.board.buildings.stand)
	check(game.active_tab == "Inventory","built stand opens real inventory")
	await click(game.close_button)
	await click(game.board.buildings.well)
	check(game.active_tab == "Shop","watering station opens upgrades")
	await click(game.close_button)
	await click(game.dock_tabs.Buildings)
	check(game.selector_cards.size() == 8,"bottom building selector retains all upgrades")
	await click(game.selector_cards.irrigation)
	check(game.modal_layer.visible and game.active_tab == "Shop","building card routes to functional shop")
	await click(game.close_button)
	await click(game.dock_tabs.Decor)
	await click(game.selector_cards.wildflowers)
	check(game.model.state.decor == "wildflowers" and game.board.decor == "wildflowers","decor applied through real selector")
	var restored := Model.new()
	check(Save.new(game.save_path).load_into(restored) and restored.state.decor == "wildflowers","decor selector saved")
	var expected_coins: int = int(game.model.state.coins)
	var expected_xp: int = int(game.model.state.xp)
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	game.save_path = "user://redesign-pointer.json"
	game.telemetry_path = "user://redesign-pointer-events.jsonl"
	root.add_child(game)
	game.model.state.settings.sound = false
	for frame: int in range(5):
		await process_frame
	check(game.model.state.coins == expected_coins and game.model.state.xp == expected_xp and game.model.state.decor == "wildflowers","whole scene restart preserves progress and look")
	await click(game.tab_buttons.Settings)
	var contrast_toggle: CheckButton = game.panel.get_node("Setting_high_contrast")
	await click(contrast_toggle)
	check(game.model.state.settings.high_contrast and game.board.plots[0].contrast,"high contrast control changes world")
	await click(game.close_button)
	var started: int = game.feedback.animated_count
	await click(game.board.plots[0])
	check(game.feedback.animated_count == started,"reduced-motion planting uses no animation")
	await _wide_bloom_hits(game)
	if "--skip-benchmark" in OS.get_cmdline_user_args():
		check(game.feedback.active_count <= 6,"effects remain bounded")
		game.queue_free()
		await process_frame
		print("REDESIGN POINTER: %d checks, %d failures" % [checks,failures])
		quit(0 if failures == 0 else 1)
		return
	# Desktop benchmark fixture: fully grown garden, no input/continuous world effects.
	game.set_process(false)
	game.feedback.visible = false
	game.model.state.settings.high_contrast = false
	for index: int in range(16):
		game.model.state.plots[index] = {}
		game.model.plant(index,"sunflower",game.now()-game.model.growth_seconds("sunflower"))
	game.visual_snapshot = {}
	game._refresh()
	var samples: Array[float] = []
	for frame: int in range(30):
		await process_frame
	var previous: int = Time.get_ticks_usec()
	for frame: int in range(180):
		await process_frame
		var current: int = Time.get_ticks_usec()
		samples.append((current-previous)/1000.0)
		previous = current
	samples.sort()
	var report: Dictionary = {"engine":Engine.get_version_info().string,"viewport":"320x640","frames":180,
		"median_frame_ms":snappedf(samples[samples.size()/2],0.01),
		"p95_frame_ms":snappedf(samples[int(samples.size()*0.95)],0.01),
		"scene_nodes":get_node_count(),"environment":"Xorg virtual display + Mesa llvmpipe software renderer",
		"android_validated":false,"notes":"Desktop frame timing sample with 16 grown plants. Not a device FPS/battery claim."}
	var file := FileAccess.open("res://docs/UI_RENDER_METRICS.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	file.close()
	check(game.feedback.active_count <= 6,"effects remain bounded")
	game.queue_free()
	await process_frame
	print("REDESIGN POINTER: %d checks, %d failures" % [checks,failures])
	print(JSON.stringify(report))
	quit(0 if failures == 0 else 1)

func _wide_bloom_hits(game: Control) -> void:
	# Verify the added side blossoms through actual root-viewport pointer dispatch.
	var previous: Dictionary = game.model.state.duplicate(true)
	game.set_process(false)
	game.model.state = game.model.fresh()
	game.model.state.coins = 5000
	game.model.state.xp = 200
	game.model.state.plots_unlocked = 16
	game.model.state.upgrades.plots = 12
	game.model.state.settings.sound = false
	game.model.state.settings.reduced_motion = true
	root.size = Vector2i(540,960)
	root.content_scale_size = root.size
	for side: int in [0,1]:
		for index: int in range(16):
			game.model.state.plots[index] = {}
			game.model.plant(index,"sunflower",game.now()-game.model.growth_seconds("sunflower"))
		game._refresh()
		for frame: int in range(6):
			await process_frame
		for index: int in range(16):
			var tile: Control = game.board.plots[index]
			var blossoms: Array[Rect2] = tile.plant_rects()
			check(blossoms.size() == 3,"wide bed has three independently hittable blossoms")
			var rect: Rect2 = blossoms[side]
			await click(tile,rect.position+rect.size*Vector2(0.5,0.25))
			check(game.model.state.plots[index].is_empty(),"side blossom %d harvests exactly bed %d" % [side,index])
	check(game.model.state.inventory.sunflower == 32,"bloom clusters award one crop per bed")
	game.model.state = previous
	root.size = Vector2i(320,640)
	root.content_scale_size = root.size
	game._refresh()
	game._refresh_panel()
	game.set_process(true)
	for frame: int in range(6):
		await process_frame
