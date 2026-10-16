extends Control

const Model = preload("res://scripts/domain/game_model.gd")
const Save = preload("res://scripts/services/save_service.gd")
const Analytics = preload("res://scripts/services/analytics_service.gd")
const Audio = preload("res://scripts/services/audio_service.gd")
const Board = preload("res://scripts/ui/garden_board.gd")
var save_path: String = "user://garden.json"
var telemetry_path: String = "user://events.jsonl"
var model: GardenModel
var saves: GardenSave
var selected: String = "carrot"
var clock_origin: int
var tick_origin: int
var hud: Label
var hint: Label
var notice: Label
var board: Control
var panel: VBoxContainer
var active_tab: String = "Seeds"
var ui_root: VBoxContainer
var last_second: int = -1
var tab_buttons: Dictionary = {}
var analytics: GardenAnalytics
var audio: AudioStreamPlayer
var last_tutorial: int = 0
var safe_margin: MarginContainer

func _ready() -> void:
	model = Model.new()
	if not model.config.error.is_empty():
		var failure := Label.new()
		failure.text = model.config.error
		add_child(failure)
		return
	saves = Save.new(save_path)
	saves.load_into(model)
	analytics = Analytics.new(telemetry_path)
	analytics.enabled = model.state.settings.local_telemetry
	last_tutorial = int(model.state.onboarding)
	audio = AudioStreamPlayer.new()
	add_child(audio)
	clock_origin = maxi(int(model.state.last_update), int(Time.get_unix_time_from_system()))
	tick_origin = Time.get_ticks_msec()
	get_tree().auto_accept_quit = false
	_build()
	_refresh_panel()
	_refresh()
	var offline: Dictionary = model.advance_to(now())
	notice.text = saves.message if not saves.message.is_empty() else "Your first garden starts with a single seed."
	if int(offline.elapsed) >= 60:
		notice.text = "Welcome back · %d coins sold · %d plants harvested · %ds elapsed%s" % [int(offline.income), int(offline.harvests), int(offline.elapsed), " (8h cap applied)" if offline.capped else ""]
		if not saves.message.is_empty():
			notice.text += "\n" + saves.message
	_refresh()
	_refresh_panel()
	if int(model.state.saved_at) == 0:
		_event("install_first_open")
	_event("session_start")
	_save()

func now() -> int:
	return clock_origin + (Time.get_ticks_msec() - tick_origin) / 1000

func _process(_delta: float) -> void:
	if model == null or hud == null:
		return
	if now() != last_second:
		last_second = now()
		var progress: Dictionary = model.advance_to(last_second)
		if int(progress.income) > 0 or int(progress.harvests) > 0 or last_second % 30 == 0:
			_save()
			_refresh_panel()
		_refresh()

func _notification(what: int) -> void:
	if model == null or saves == null or hud == null:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_event("session_end")
		_save()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		clock_origin = maxi(now(), int(Time.get_unix_time_from_system()))
		tick_origin = Time.get_ticks_msec()
		var offline: Dictionary = model.advance_to(now())
		_event("game_resumed", {"elapsed": int(offline.elapsed)})
		if int(offline.elapsed) >= 60:
			notice.text = "Garden resumed · %d coins sold · %d harvested%s" % [int(offline.income), int(offline.harvests), " · 8h cap applied" if offline.capped else ""]
		_refresh_panel()
		_refresh()
		_save()

func _save() -> void:
	model.advance_to(now())
	model.state.saved_at = now()
	if not saves.store(model) and notice != null:
		notice.text = saves.message
		_event("save_error", {"reason": "local_write_failed"})

func _style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _build() -> void:
	var theme := Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", Color("#e9ecdc"))
	theme.set_color("font_color", "Button", Color("#e9ecdc"))
	theme.set_color("font_disabled_color", "Button", Color("#829185"))
	theme.set_stylebox("normal", "Button", _style(Color("#233e32"), Color("#42634a")))
	theme.set_stylebox("hover", "Button", _style(Color("#35543d"), Color("#c3ca8a")))
	theme.set_stylebox("pressed", "Button", _style(Color("#566743"), Color("#ebd391")))
	theme.set_stylebox("focus", "Button", _style(Color(0,0,0,0), Color("#ebd391")))
	theme.set_stylebox("disabled", "Button", _style(Color("#172b23"), Color("#314638")))
	self.theme = theme
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	safe_margin = margin
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	scroll.add_child(margin)
	ui_root = VBoxContainer.new()
	ui_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_root.add_theme_constant_override("separation", 12)
	margin.add_child(ui_root)
	_label(ui_root, "A LITTLE SEED. A GROWING WORLD.", 12, Color("#b9c992"))
	_label(ui_root, "Garden Empire", 36, Color("#f4e5ba"))
	hud = _label(ui_root, "", 20, Color("#efcf87"))
	var divider := HSeparator.new()
	ui_root.add_child(divider)
	var title := HBoxContainer.new()
	ui_root.add_child(title)
	_label(title, "THE HOME GARDEN", 14, Color("#bac99d"))
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 8
	title.add_child(spacer)
	var subtitle := _label(title, "01 / THE BEGINNING", 11, Color("#8fa68e"))
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_END
	subtitle.custom_minimum_size.x = 115
	board = Board.new()
	board.plot_pressed.connect(_on_plot)
	ui_root.add_child(board)
	hint = _label(ui_root, "", 16, Color("#d2d9b9"))
	notice = _label(ui_root, "", 15, Color("#f0cf98"))
	var tabs := GridContainer.new()
	tabs.columns = 3
	ui_root.add_child(tabs)
	for tab: String in ["Seeds", "Inventory", "Shop", "Journal", "Settings"]:
		var button := _button(tabs, tab, func() -> void:
			active_tab = tab
			_refresh_panel()
		)
		button.add_theme_font_size_override("font_size", 14)
		button.toggle_mode = true
		for state_name: String in ["normal", "hover", "pressed", "focus"]:
			var compact_style: StyleBox = theme.get_stylebox(state_name, "Button").duplicate()
			compact_style.content_margin_left = 5
			compact_style.content_margin_right = 5
			button.add_theme_stylebox_override(state_name, compact_style)
		tab_buttons[tab] = button
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 9)
	ui_root.add_child(panel)
	_label(ui_root, "Grows at your pace · Saved on this device", 12, Color("#8fa68e"))
	apply_settings()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()

func _label(parent: Node, text: String, font_size: int = 17, color: Color = Color("#e9ecdc")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _refresh() -> void:
	if hud == null:
		return
	hud.text = "%s coins    ·    Level %d    ·    %d XP" % [Model.compact(int(model.state.coins)), model.level(), int(model.state.xp)]
	board.refresh(model, now(), selected)
	var ready_count: int = 0
	var growing: int = 0
	for i: int in range(int(model.state.plots_unlocked)):
		if model.phase(i, now()) == 3:
			ready_count += 1
		elif model.phase(i, now()) >= 0:
			growing += 1
	hint.text = "%d ready to harvest · %d growing · %d open plots" % [ready_count, growing, int(model.state.plots_unlocked) - ready_count - growing]
	match int(model.state.onboarding):
		0:
			hint.text += "\nChoose Carrot below, then tap a + plot."
		1:
			hint.text += "\nTap a mature plant to harvest. Carrots take 8s."
		2:
			hint.text += "\nOpen Inventory to sell your first harvest."
		3:
			hint.text += "\nExplore the Shop. Every upgrade shows its benefit."

func _on_plot(index: int) -> void:
	model.advance_to(now())
	if index >= int(model.state.plots_unlocked):
		notice.text = "This plot is locked. Expand your garden in the shop."
		return
	var phase: int = model.phase(index, now())
	if phase == 3:
		var species: String = model.state.plots[index].species_id
		if model.harvest(index, now()):
			notice.text = model.config.plants[species].name + " harvested. Sell it from Inventory."
			_event("plant_harvested", {"species": species, "quantity": 1})
			_feedback(880.0, index)
	elif phase == -1:
		if model.plant(index, selected, now()):
			notice.text = "%s planted · ready in %ds" % [model.config.plants[selected].name, model.growth_seconds(selected)]
			_event("seed_planted", {"species": selected})
			_feedback(440.0, index)
		else:
			notice.text = "Not enough coins or this species needs a higher level."
	else:
		var left: int = int(model.state.plots[index].maturity_at_utc) - now()
		notice.text = "%s · stage %d of 3 · %ds to harvest" % [model.config.plants[model.state.plots[index].species_id].name, phase + 1, left]
	_save()
	_refresh()
	_refresh_panel()

func _refresh_panel() -> void:
	if panel == null:
		return
	for child: Node in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	for tab: String in tab_buttons:
		tab_buttons[tab].set_pressed_no_signal(tab == active_tab)
	match active_tab:
		"Seeds":
			_label(panel, "CHOOSE WHAT GROWS NEXT", 13, Color("#bac99d"))
			for id: String in model.config.plants:
				var plant: Dictionary = model.config.plants[id]
				var locked: bool = model.level() < int(plant.level_required)
				var text: String = "%s%s  ·  %d coins  ·  %ds  →  %d coins" % ["✓ " if selected == id else "", plant.name, int(plant.seed_cost), int(model.growth_seconds(id)), model.sell_value(id)]
				if locked:
					text += "  [Lv %d]" % int(plant.level_required)
				var button := _button(panel, text, func() -> void:
					selected = id
					notice.text = plant.name + " selected. Tap an empty plot."
					_refresh_panel()
				)
				button.disabled = locked
				button.add_theme_font_size_override("font_size", 15)
		"Inventory":
			_label(panel, "YOUR HARVEST", 13, Color("#bac99d"))
			for id: String in model.config.plants:
				var amount: int = int(model.state.inventory[id])
				var button := _button(panel, "%s ×%d   ·   Sell one for %d" % [model.config.plants[id].name, amount, model.sell_value(id)], func() -> void:
					var earned: int = model.sell(id, 1)
					notice.text = "Sold for %d coins." % earned
					if earned > 0:
						_event("item_sold", {"species": id, "quantity": 1, "coins": earned})
						_feedback(1100.0)
					_save()
					_refresh()
					_refresh_panel()
				)
				button.disabled = amount <= 0
			_button(panel, "Sell all harvested plants", func() -> void:
				var count_before: int = int(model.state.sales)
				var earned: int = model.sell_all()
				notice.text = "Harvest sold for %d coins." % earned
				if earned > 0:
					_event("item_sold", {"quantity": int(model.state.sales) - count_before, "coins": earned})
					_feedback(1100.0)
				_save()
				_refresh()
				_refresh_panel()
			)
		"Shop":
			_label(panel, "INVEST IN YOUR GARDEN", 13, Color("#bac99d"))
			_label(panel, "Stand: " + ("open · sells inventory every %ds" % model.stand_interval() if int(model.state.upgrades.stand) > 0 else "not yet built"), 15)
			for id: String in ["plots", "stand", "compost", "baskets", "irrigation", "helper", "signage", "soil"]:
				var upgrade: Dictionary = model.config.upgrades[id]
				var price: int = model.upgrade_price(id)
				var text: String = "%s · %s" % [upgrade.name, "%d coins" % price if price > 0 else "MAX"]
				text += " · %d/%d" % [int(model.state.upgrades[id]), int(upgrade.max_level)]
				var button := _button(panel, text, func() -> void: _request_upgrade(id))
				button.disabled = not model.can_upgrade(id)
				_label(panel, upgrade.description + " [Level %d]" % int(upgrade.level_required), 13, Color("#b8c7a5"))
				if price > 0:
					_label(panel, _effect_preview(id), 13, Color("#efcf87"))
			_label(panel, "If your garden and inventory are empty, keep 5 coins for a seed.", 13)
		"Journal":
			_label(panel, "THE COLLECTION BOOK", 13, Color("#bac99d"))
			for id: String in model.config.plants:
				var discovered: bool = id in model.state.discovered
				_label(panel, "%s · %s" % [model.config.plants[id].name, "Discovered · standard variety" if discovered else "Not harvested yet · level %d" % int(model.config.plants[id].level_required)], 16)
			_label(panel, "GARDEN GOALS · NO EXPIRY", 13, Color("#bac99d"))
			for id: String in model.config.quests:
				var quest: Dictionary = model.config.quests[id]
				var progress: int = mini(int(quest.target), model.quest_progress(id))
				_label(panel, "%s · %d/%d\n%s" % [quest.name, progress, int(quest.target), quest.description], 15)
				var claimed: bool = id in model.state.claimed_quests
				var button := _button(panel, "Completed" if claimed else "Claim %d coins" % int(quest.reward), func() -> void:
					if model.claim_quest(id):
						notice.text = quest.name + " completed."
						_event("progression_milestone", {"milestone": id, "coins": int(quest.reward)})
						_feedback(990.0)
						_save()
						_refresh()
						_refresh_panel()
				)
				button.disabled = claimed or progress < int(quest.target)
		"Settings":
			_label(panel, "MAKE YOURSELF AT HOME", 13, Color("#bac99d"))
			for setting: String in ["large_text", "high_contrast", "reduced_motion", "sound", "local_telemetry"]:
				var toggle := CheckButton.new()
				toggle.text = setting.replace("_", " ").capitalize()
				toggle.button_pressed = model.state.settings[setting]
				toggle.custom_minimum_size.y = 48
				panel.add_child(toggle)
				toggle.toggled.connect(func(enabled: bool) -> void:
					model.state.settings[setting] = enabled
					analytics.enabled = model.state.settings.local_telemetry
					_event("settings_changed", {"setting": setting, "enabled": enabled})
					apply_settings()
					_save()
				)
			_label(panel, "Local telemetry stays on this device (rotates at 256 KiB). No persistent player ID or network transmission. Toggle it off above.\nOffline · No account · No ads or purchases\nSave location: " + ProjectSettings.globalize_path(saves.path), 13)

			if OS.is_debug_build() and "--debug-garden" in OS.get_cmdline_user_args():
				_label(panel, "DEVELOPER TOOLS", 13)
				_button(panel, "Add 100 test coins", func() -> void:
					model.state.coins = mini(Model.MAX_COINS, int(model.state.coins) + 100)
					_save()
					_refresh()
				)
	apply_settings()

func apply_settings() -> void:
	theme.default_font_size = 20 if model.state.settings.large_text else 17
	_scale_text(self, 1.2 if model.state.settings.large_text else 1.0)
	RenderingServer.set_default_clear_color(Color("#061009") if model.state.settings.high_contrast else Color("#0c1713"))
	_refresh()

func _request_upgrade(id: String) -> void:
	var price: int = model.upgrade_price(id)
	if price < 100:
		_purchase(id)
		return
	var confirm := ConfirmationDialog.new()
	confirm.title = model.config.upgrades[id].name
	confirm.dialog_text = "%d coins\n%s" % [price, model.config.upgrades[id].description]
	confirm.ok_button_text = "Buy upgrade"
	confirm.confirmed.connect(func() -> void:
		_purchase(id, price)
		confirm.queue_free()
	)
	confirm.canceled.connect(confirm.queue_free)
	add_child(confirm)
	confirm.popup_centered(Vector2i(mini(int(size.x) - 24, 430), 200))

func _purchase(id: String, expected_price: int = -1) -> void:
	if expected_price >= 0 and model.upgrade_price(id) != expected_price:
		notice.text = "The upgrade price changed. Review its current price."
		_refresh_panel()
		return
	model.advance_to(now())
	if model.buy_upgrade(id, now()):
		notice.text = model.config.upgrades[id].name + " purchased."
		_event("upgrade_purchased", {"upgrade": id})
		if id == "stand":
			_event("stand_unlocked")
		_feedback(660.0)
	else:
		notice.text = "Purchase unavailable. Check your coins, level, and seed reserve."
	_save()
	_refresh()
	_refresh_panel()

func _scale_text(node: Node, scale_factor: float) -> void:
	if node is Control and node.has_theme_font_size_override("font_size"):
		if not node.has_meta("base_font_size"):
			node.set_meta("base_font_size", node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size", int(float(node.get_meta("base_font_size")) * scale_factor))
	for child: Node in node.get_children():
		_scale_text(child, scale_factor)

func _feedback(frequency: float, index: int = -1) -> void:
	if model.state.settings.sound:
		audio.stream = Audio.tone(frequency)
		audio.play()
	if not model.state.settings.reduced_motion:
		if index >= 0:
			var tile: Control = board.plots[index]
			tile.modulate = Color("#ffdd94")
			create_tween().tween_property(tile, "modulate", Color.WHITE, 0.3)
		if OS.has_feature("android") or OS.has_feature("ios"):
			Input.vibrate_handheld(25)

func _event(name: String, params: Dictionary = {}) -> void:
	if analytics == null:
		return
	analytics.record(name, params)
	if int(model.state.onboarding) > last_tutorial:
		last_tutorial = int(model.state.onboarding)
		analytics.record("tutorial_step_completed", {"step": last_tutorial})

func _effect_preview(id: String) -> String:
	var preview := Model.new(model.config)
	preview.state = model.state.duplicate(true)
	preview.state.upgrades[id] = int(preview.state.upgrades[id]) + 1
	match id:
		"compost", "irrigation":
			return "%s: %ds → %ds (whole seconds)" % [model.config.plants[selected].name, model.growth_seconds(selected), preview.growth_seconds(selected)]
		"baskets":
			return "%s sale: %d → %d coins" % [model.config.plants[selected].name, model.sell_value(selected), preview.sell_value(selected)]
		"soil":
			return "%s harvest: %d → %d XP" % [model.config.plants[selected].name, model.harvest_xp(selected), preview.harvest_xp(selected)]
		"signage":
			return "Sale interval: %ds → %ds" % [model.stand_interval(), preview.stand_interval()]
		"plots":
			return "Planting capacity: %d → %d" % [int(model.state.plots_unlocked), int(model.state.plots_unlocked) + 1]
		"stand":
			return "One inventory item sold every %ds; no free goods." % model.stand_interval()
		"helper":
			return "Ready plants harvested every 5s; no replanting."
	return ""

func _apply_safe_area() -> void:
	if safe_margin == null or not (OS.has_feature("android") or OS.has_feature("ios")):
		return
	var physical: Vector2i = DisplayServer.screen_get_size()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if physical.x <= 0 or physical.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return
	var ratio: Vector2 = get_viewport_rect().size / Vector2(physical)
	safe_margin.add_theme_constant_override("margin_left", maxi(22, int(safe.position.x * ratio.x)))
	safe_margin.add_theme_constant_override("margin_right", maxi(22, int((physical.x - safe.end.x) * ratio.x)))
	safe_margin.add_theme_constant_override("margin_top", maxi(22, int(safe.position.y * ratio.y)))
	safe_margin.add_theme_constant_override("margin_bottom", maxi(22, int((physical.y - safe.end.y) * ratio.y)))

func _exit_tree() -> void:
	if audio != null:
		audio.stop()
		audio.stream = null
