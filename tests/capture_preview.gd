extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var garden: Control = scene.instantiate()
	root.add_child(garden)
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(540, 960)
	garden.set_process(false)
	garden.model.state = garden.model.fresh()
	garden.model.advance_to(garden.now())
	garden._refresh()
	garden._refresh_panel()
	for frame: int in range(10):
		await process_frame
	root.get_texture().get_image().save_png("res://docs/screenshots/garden-start.png")
	# Clearly documented demo fixture to preview all procedural plant varieties.
	garden.model.state.coins = 1268
	garden.model.state.xp = 200
	garden.model.state.plots_unlocked = 16
	garden.model.state.upgrades.plots = 12
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
	root.size = Vector2i(320, 960)
	root.content_scale_size = Vector2i(320, 960)
	garden.model.state.settings.large_text = true
	garden.apply_settings()
	for frame: int in range(10):
		await process_frame
	root.get_texture().get_image().save_png("res://docs/screenshots/garden-320.png")
	print("Captured real Godot renderings (start, demo fixture, 320px large text).")
	garden.queue_free()
	await process_frame
	quit()
