extends SceneTree

const Save = preload("res://scripts/services/save_service.gd")
const Model = preload("res://scripts/domain/game_model.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	create_timer(40).timeout.connect(func() -> void: quit(2))
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func click(control: Control) -> void:
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
			for frame: int in range(3):
				await process_frame
			break
		ancestor = ancestor.get_parent()
	var position: Vector2 = control.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = position
		root.push_input(event)
		await process_frame

func _run() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://pointer-test-scene.json" + suffix):
			DirAccess.remove_absolute("user://pointer-test-scene.json" + suffix)
	root.size = Vector2i(540, 960)
	root.content_scale_size = root.size
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var garden: Control = scene.instantiate()
	garden.save_path = "user://pointer-test-scene.json"
	garden.telemetry_path = "user://pointer-test-events.jsonl"
	root.add_child(garden)
	for frame: int in range(5):
		await process_frame
	check(garden.model.state.coins == 20, "fresh wallet")
	await click(garden.board.plots[0])
	check(garden.model.state.coins == 15, "real pointer click plants at exact cost")
	await click(garden.board.plots[0])
	check(garden.model.state.coins == 15, "second pointer tap does not double debit")
	await create_timer(8.1).timeout
	await click(garden.board.plots[0])
	check(garden.model.state.inventory.carrot == 1, "real-time maturity harvest by pointer")
	await click(garden.tab_buttons.Inventory)
	for frame: int in range(3):
		await process_frame
	await click(garden.panel.get_child(1))
	check(garden.model.state.coins == 24 and garden.model.state.inventory.carrot == 0, "real inventory sale button credits coins")
	var restored := Model.new()
	check(Save.new("user://pointer-test-scene.json").load_into(restored) and restored.state.coins == 24, "full pointer loop persists on restart")
	await click(garden.plant_all_button)
	check(garden.model.state.coins == 4, "batch plant via real pointer charges four seeds")
	await create_timer(8.1).timeout
	await click(garden.harvest_all_button)
	check(garden.model.state.inventory.carrot == 4, "batch harvest via real pointer")
	await click(garden.tab_buttons.Requests)
	await click(garden.request_buttons[1].pin)
	check(garden.model.state.pinned_order == 1, "real pin button reserves request")
	await click(garden.tab_buttons.Inventory)
	await click(garden.panel.get_child(1))
	check(garden.model.state.inventory.carrot == 3 and garden.model.state.coins == 13, "real sale button sells only surplus")
	check(garden.panel.get_child(1).disabled, "reserved inventory sale button disabled")
	await click(garden.tab_buttons.Requests)
	await click(garden.request_buttons[1].deliver)
	check(garden.model.state.orders_completed == 1 and garden.model.state.coins == 48, "real delivery button pays once")
	check(garden.model.get_order(1).is_empty() and garden.model.state.pinned_order == 0, "completed request replaced with a new id")
	check(Save.new("user://pointer-test-scene.json").load_into(restored) and restored.state.orders_completed == 1 and restored.state.coins == 48, "request completion survives restart")
	root.size = Vector2i(320, 960)
	root.content_scale_size = root.size
	garden.model.state.settings.large_text = true
	garden.apply_settings()
	for frame: int in range(5):
		await process_frame
	for tab: String in garden.tab_buttons:
		var button: Button = garden.tab_buttons[tab]
		var text_width: float = button.get_theme_font("font").get_string_size(tab, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
		check(button.size.x >= text_width + 10 and button.size.y >= 44 and button.size.y <= 60, "320px large-text navigation fits: " + tab)
	garden.model.state.settings.sound = true
	garden._feedback(660.0)
	check(garden.audio.playing, "rendered feedback sends generated audio to player")
	garden.audio.stop()
	garden.audio.stream = null
	await create_timer(0.2).timeout
	garden.queue_free()
	await process_frame
	print("POINTER SMOKE: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
