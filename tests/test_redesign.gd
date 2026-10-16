extends SceneTree

const Model = preload("res://scripts/domain/game_model.gd")
const Save = preload("res://scripts/services/save_service.gd")
const Design = preload("res://scripts/ui/components/garden_theme.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	create_timer(35).timeout.connect(func() -> void: quit(2))
	call_deferred("_run")

func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)

func same(a: Variant,b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not same(a[key],b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i: int in range(a.size()):
			if not same(a[i],b[i]):
				return false
		return true
	return a == b

func inside(control: Control, viewport: Rect2) -> bool:
	return viewport.grow(1).encloses(control.get_global_rect())

func luminance(color: Color) -> float:
	var channels: Array[float] = []
	for value: float in [color.r,color.g,color.b]:
		channels.append(value/12.92 if value <= 0.04045 else pow((value+0.055)/1.055,2.4))
	return channels[0]*0.2126+channels[1]*0.7152+channels[2]*0.0722

func contrast(a: Color,b: Color) -> float:
	var x: float = luminance(a)
	var y: float = luminance(b)
	return (maxf(x,y)+0.05)/(minf(x,y)+0.05)

func _run() -> void:
	var legacy := Model.new()
	legacy.state.coins = 2345
	legacy.state.xp = 130
	legacy.buy_upgrade("plots",1000)
	legacy.plant(0,"lavender",1000)
	legacy.state.inventory.carrot = 3
	legacy.pin_order(1)
	legacy.state.claimed_quests = ["first_harvest"]
	legacy.state.settings.large_text = true
	var v4: Dictionary = legacy.state.duplicate(true)
	v4.version = 4
	v4.erase("decor")
	var migrated: Dictionary = legacy.migrate(v4)
	check(legacy.validate(migrated) and migrated.decor == "meadow", "v4 migrates to valid cosmetic schema")
	for key: String in v4:
		if key != "version":
			check(same(v4[key],migrated[key]), "migration preserves " + key)
	var file := FileAccess.open("user://redesign-legacy.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(v4))
	file.close()
	var restored := Model.new()
	var save := Save.new("user://redesign-legacy.json")
	check(save.load_into(restored), "real legacy JSON loads")
	for key: String in v4:
		if key != "version":
			check(same(v4[key],restored.state[key]), "JSON load preserves " + key)
	restored.state.decor = "wildflowers"
	check(save.store(restored), "decor saves atomically")
	var reloaded := Model.new()
	check(save.load_into(reloaded) and reloaded.state.decor == "wildflowers", "decor survives restart")
	var invalid: Dictionary = reloaded.state.duplicate(true)
	invalid.decor = "unknown"
	check(not reloaded.validate(invalid), "invalid decor rejected")
	check(contrast(Design.INK,Design.PAPER) >= 4.5, "main text contrast")
	check(contrast(Design.GOLD,Design.PAPER) >= 4.5, "coin/accent contrast")
	check(contrast(Design.MUTED,Design.PAPER) >= 4.5, "secondary text contrast")
	for suffix: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://redesign-ui-test.json"+suffix):
			DirAccess.remove_absolute("user://redesign-ui-test.json"+suffix)
	var scene: PackedScene = load("res://scenes/garden/garden.tscn")
	var game: Control = scene.instantiate()
	game.save_path = "user://redesign-ui-test.json"
	game.telemetry_path = "user://redesign-ui-events.jsonl"
	root.add_child(game)
	game.model.state.settings.sound = false
	game.model.state.settings.reduced_motion = true
	await process_frame
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(320,640),Vector2i(360,720),Vector2i(540,960),Vector2i(600,1000)]:
		for large: bool in [false,true]:
			root.size = dimensions
			root.content_scale_size = dimensions
			game.model.state.settings.large_text = large
			game.apply_settings()
			for frame: int in range(6):
				await process_frame
			var viewport := Rect2(Vector2.ZERO,Vector2(dimensions))
			check(inside(game.hud,viewport) and inside(game.level_label,viewport), "HUD visible at %s large=%s" % [dimensions,large])
			check(game.hud.get_global_rect().end.y <= game.board.global_position.y+1, "world below HUD")
			for control: Control in [game.plant_all_button,game.harvest_all_button,game.dock_tabs.Seeds,game.dock_tabs.Buildings,game.dock_tabs.Decor,game.tab_buttons.Inventory,game.tab_buttons.Requests,game.tab_buttons.Journal,game.tab_buttons.Settings]:
				check(inside(control,viewport) and control.size.x >= 44 and control.size.y >= 44,"essential control visible and >=44 at %s: %s" % [dimensions,control.name])
			for plot: Control in game.board.plots:
				check(inside(plot,game.board.get_global_rect()) and plot.size.x >= 44 and plot.size.y >= 44,"plot geometry %s at %s" % [plot.name,dimensions])
			for object: Control in game.board.buildings.values():
				check(inside(object,game.board.get_global_rect()) and object.size.x >= 44 and object.size.y >= 44,"building control visible")
			game._open_panel("Inventory")
			for frame: int in range(4):
				await process_frame
			check(inside(game.close_button,viewport), "modal close always visible")
			check(game.panel.get_child_count() == 7, "all inventory controls retained")
			game._close_panel()
	game.dock_mode = "Decor"
	game._refresh_dock()
	game.selector_cards.wildflowers.pressed.emit()
	check(game.model.state.decor == "wildflowers" and game.board.decor == "wildflowers", "decor changes world")
	check(Save.new(game.save_path).load_into(reloaded) and reloaded.state.decor == "wildflowers","decor UI persists")
	game.dock_mode = "Buildings"
	game._refresh_dock()
	check(game.selector_cards.size() == 8,"all eight upgrades exposed")
	game.selector_cards.stand.pressed.emit()
	check(game.modal_layer.visible and game.active_tab == "Shop","building card opens real upgrade controls")
	game._close_panel()
	game.board.buildings.home.pressed.emit()
	check(game.active_tab == "Journal" and game.panel.get_child_count() == 17,"home opens collection and five goals")
	game._close_panel()
	game.board.buildings.stand.pressed.emit()
	check(game.active_tab == "Shop","unbuilt stand opens build controls")
	game._close_panel()
	game.model.state.coins = 200
	game.model.buy_upgrade("stand",game.now())
	game._refresh()
	game.board.buildings.stand.pressed.emit()
	check(game.active_tab == "Inventory","built stand opens inventory")
	game._close_panel()
	game.feedback.show_gain("+4 XP",Vector2(30,100),Design.INK,true)
	check(game.feedback.animated_count == 0,"reduced motion has no animated feedback")
	for i: int in range(15):
		game.feedback.show_gain("+1",Vector2(30,100),Design.INK,true)
	check(game.feedback.active_count <= 6,"feedback effects bounded")
	await create_timer(1.2).timeout
	check(game.feedback.active_count == 0,"static feedback cleans up")
	game.queue_free()
	await process_frame
	print("REDESIGN: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
