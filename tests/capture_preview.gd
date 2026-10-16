extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var garden: Control = scene.instantiate()
	garden.save_path = "user://preview-garden.json"
	garden.telemetry_path = "user://preview-events.jsonl"
	root.add_child(garden)
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(540, 960)
	garden.set_process(false)
	garden.model.state = garden.model.fresh()
	garden.model.advance_to(garden.now())
	garden.notice.text = "Your first garden starts with a single seed."
	garden._refresh()
	garden._refresh_panel()
	for frame: int in range(10):
		await process_frame
	root.get_texture().get_image().save_png("res://docs/screenshots/garden-start.png")
	print("Captured fresh garden.")
	# Clearly documented demo fixture to preview all procedural plant varieties.
	garden.model.state.coins = 1268
	garden.model.state.xp = 200
	garden.model.state.plots_unlocked = 16
	garden.model.state.upgrades.plots = 12
	garden.model.state.upgrades.stand = 1
	garden.model.state.onboarding = 4
	var species: Array = garden.model.config.plants.keys()
	for i: int in range(10):
		var id: String = species[i % species.size()]
		garden.model.plant(i, id, garden.now() - garden.model.growth_seconds(id))
	garden.model.plant(10, "orchid", garden.now() - 65)
	garden.model.plant(11, "sunflower", garden.now() - 3)
	garden.notice.text = "A garden in bloom · demo preview"
	garden._refresh()
	garden._refresh_panel()
	for frame: int in range(10):
		await process_frame
	root.get_texture().get_image().save_png("res://docs/screenshots/garden-demo.png")
	print("Captured garden demo.")
	garden.model.state.inventory.carrot = 3
	garden.model.state.inventory.sunflower = 2
	garden.model.pin_order(1)
	garden.active_tab = "Requests"
	garden._refresh_panel()
	for frame: int in range(5):
		await process_frame
	var scroll: ScrollContainer
	for child: Node in garden.get_children():
		if child is ScrollContainer:
			scroll = child
	scroll.ensure_control_visible(garden.panel)
	for frame: int in range(5):
		await process_frame
	root.get_texture().get_image().save_png("res://docs/screenshots/garden-requests.png")
	print("Captured requests demo.")
	garden.active_tab = "Seeds"
	garden._refresh_panel()
	scroll.scroll_vertical = 0
	root.size = Vector2i(320, 960)
	root.content_scale_size = Vector2i(320, 960)
	garden.model.state.settings.large_text = true
	garden.apply_settings()
	for frame: int in range(10):
		await process_frame
	root.get_texture().get_image().save_png("res://docs/screenshots/garden-320.png")
	print("Captured real Godot renderings (start, demo fixture, requests, 320px large text).")
	garden.queue_free()
	await process_frame
	quit()
