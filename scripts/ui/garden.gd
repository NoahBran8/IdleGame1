extends Control

const Model = preload("res://scripts/domain/game_model.gd")
const Save = preload("res://scripts/services/save_service.gd")
const Board = preload("res://scripts/ui/garden_board.gd")
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

func _ready() -> void:
	model = Model.new()
	if not model.config.error.is_empty():
		var failure := Label.new()
		failure.text = model.config.error
		add_child(failure)
		return
	saves = Save.new()
	saves.load_into(model)
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
		_save()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		clock_origin = maxi(now(), int(Time.get_unix_time_from_system()))
		tick_origin = Time.get_ticks_msec()
		var offline: Dictionary = model.advance_to(now())
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
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(spacer)
	_label(title, "01 / THE BEGINNING", 11, Color("#8fa68e"))
	board = Board.new()
	board.plot_pressed.connect(_on_plot)
	ui_root.add_child(board)
	hint = _label(ui_root, "", 16, Color("#d2d9b9"))
	notice = _label(ui_root, "", 15, Color("#f0cf98"))
	var tabs := HFlowContainer.new()
	ui_root.add_child(tabs)
	for tab: String in ["Seeds", "Inventory", "Shop", "Settings"]:
		var button := _button(tabs, tab, func() -> void:
			active_tab = tab
			_refresh_panel()
		)
		tab_buttons[tab] = button
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 9)
	ui_root.add_child(panel)
	_label(ui_root, "Grows at your pace · Saved on this device", 12, Color("#8fa68e"))
	apply_settings()

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
	if int(model.state.harvests) == 0:
		hint.text += "\nTap a + plot to plant. Carrots grow in 8 seconds."

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
	elif phase == -1:
		if model.plant(index, selected, now()):
			notice.text = "%s planted · ready in %ds" % [model.config.plants[selected].name, model.growth_seconds(selected)]
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
		tab_buttons[tab].text = ("• " if tab == active_tab else "") + tab
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
					_save()
					_refresh()
					_refresh_panel()
				)
				button.disabled = amount <= 0
			_button(panel, "Sell all harvested plants", func() -> void:
				notice.text = "Harvest sold for %d coins." % model.sell_all()
				_save()
				_refresh()
				_refresh_panel()
			)
		"Shop":
			_label(panel, "INVEST IN YOUR GARDEN", 13, Color("#bac99d"))
			_label(panel, "Stand: " + ("open · sells inventory every %ds" % model.stand_interval() if int(model.state.upgrades.stand) > 0 else "not yet built"), 15)
			for id: String in model.config.upgrades:
				var upgrade: Dictionary = model.config.upgrades[id]
				var price: int = model.upgrade_price(id)
				var text: String = "%s · %s" % [upgrade.name, "%d coins" % price if price > 0 else "MAX"]
				text += " · %d/%d" % [int(model.state.upgrades[id]), int(upgrade.max_level)]
				var button := _button(panel, text, func() -> void: _request_upgrade(id))
				button.disabled = not model.can_upgrade(id)
				_label(panel, upgrade.description + " [Level %d]" % int(upgrade.level_required), 13, Color("#b8c7a5"))
			_label(panel, "If your garden and inventory are empty, keep 5 coins for a seed.", 13)
		"Settings":
			_label(panel, "MAKE YOURSELF AT HOME", 13, Color("#bac99d"))
			for setting: String in ["large_text", "high_contrast", "reduced_motion"]:
				var toggle := CheckButton.new()
				toggle.text = setting.replace("_", " ").capitalize()
				toggle.button_pressed = model.state.settings[setting]
				toggle.custom_minimum_size.y = 48
				panel.add_child(toggle)
				toggle.toggled.connect(func(enabled: bool) -> void:
					model.state.settings[setting] = enabled
					apply_settings()
					_save()
				)
			_label(panel, "Offline · No account · No ads or purchases\nSave location: " + ProjectSettings.globalize_path(saves.path), 13)

func apply_settings() -> void:
	theme.default_font_size = 20 if model.state.settings.large_text else 17
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
		_purchase(id)
		confirm.queue_free()
	)
	confirm.canceled.connect(confirm.queue_free)
	add_child(confirm)
	confirm.popup_centered(Vector2i(mini(int(size.x) - 24, 430), 200))

func _purchase(id: String) -> void:
	model.advance_to(now())
	if model.buy_upgrade(id, now()):
		notice.text = model.config.upgrades[id].name + " purchased."
	else:
		notice.text = "Purchase unavailable. Check your coins, level, and seed reserve."
	_save()
	_refresh()
	_refresh_panel()
