extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func snapshot(path: String) -> void:
	for frame: int in range(8):
		await process_frame
	var error: Error = root.get_texture().get_image().save_png("res://docs/screenshots/" + path)
	if error != OK:
		push_error("Screenshot failed: " + path)
		quit(1)
	print("Captured " + path)

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var garden: Control = scene.instantiate()
	garden.save_path = "user://preview-garden.json"
	garden.telemetry_path = "user://preview-events.jsonl"
	root.size = Vector2i(540,960)
	root.content_scale_size = root.size
	root.add_child(garden)
	garden.set_process(false)
	garden.feedback.visible = false
	garden.model.state = garden.model.fresh()
	garden.model.advance_to(garden.now())
	garden.notice.text = "Welcome home. Let's grow something."
	garden.visual_snapshot = {}
	garden._refresh()
	garden._refresh_panel()
	await snapshot("garden-start.png")
	garden.dock_mode = "Decor"
	garden._refresh_dock()
	await snapshot("garden-journey-start.png")
	garden.dock_mode = "Seeds"
	garden._refresh_dock()
	# Explicit seeded fixture, not real player progression.
	garden.model.state.coins = 2400
	garden.model.state.xp = 200
	garden.model.state.plots_unlocked = 16
	garden.model.state.upgrades.plots = 12
	garden.model.state.upgrades.stand = 1
	garden.model.state.upgrades.irrigation = 1
	garden.model.state.onboarding = 4
	var species: Array = garden.model.config.plants.keys()
	for index: int in range(10):
		var id: String = species[index % species.size()]
		garden.model.plant(index,id,garden.now()-garden.model.growth_seconds(id))
	garden.model.plant(10,"orchid",garden.now()-65)
	garden.model.plant(11,"sunflower",garden.now()-3)
	garden.notice.text = "A garden in bloom · demo fixture"
	garden.visual_snapshot = {}
	garden._refresh()
	garden._refresh_panel()
	await snapshot("garden-demo.png")
	var base_demo: Dictionary = garden.model.state.duplicate(true)
	garden.model.state.plots_unlocked = 20
	garden.model.state.upgrades.plots = 16
	garden.model.select_area("lakeside")
	for index: int in range(12,20):
		var id: String = species[index%species.size()]
		garden.model.plant(index,id,garden.now()-garden.model.growth_seconds(id))
	for id: String in ["compost","baskets","helper","signage","soil"]:
		garden.model.state.upgrades[id] = 1
	garden.model.state.inventory.carrot = 6
	garden.model.state.inventory.sunflower = 3
	garden.notice.text = "An established garden · demo fixture"
	garden._refresh()
	garden._refresh_panel()
	await snapshot("garden-estate.png")
	garden.model.select_area("market")
	garden._refresh()
	await snapshot("garden-market.png")
	garden.model.select_area("lakeside")
	garden._refresh()
	await snapshot("garden-lakeside.png")
	garden.model.state = base_demo
	garden.notice.text = "A garden in bloom · demo fixture"
	garden._refresh()
	garden._refresh_panel()
	garden.model.state.inventory.carrot = 3
	garden.model.state.inventory.sunflower = 2
	garden.model.pin_order(1)
	garden._open_panel("Requests")
	await snapshot("garden-requests.png")
	garden._close_panel()
	garden.dock_mode = "Decor"
	garden.model.state.decor = "wildflowers"
	garden._refresh()
	garden._refresh_dock()
	await snapshot("garden-decor.png")
	garden._open_panel("Shop")
	garden._request_upgrade("signage")
	await snapshot("garden-confirmation.png")
	garden.purchase_dialog.canceled.emit()
	garden._close_panel()
	root.size = Vector2i(320,640)
	root.content_scale_size = root.size
	garden.model.state.settings.large_text = true
	garden.dock_mode = "Seeds"
	garden._refresh_dock()
	garden.apply_settings()
	await snapshot("garden-320.png")
	garden.dock_mode = "Decor"
	garden._refresh_dock()
	garden.apply_settings()
	await snapshot("garden-areas-320.png")
	garden._open_panel("Inventory")
	await snapshot("garden-inventory-320.png")
	garden.queue_free()
	await process_frame
	quit()
