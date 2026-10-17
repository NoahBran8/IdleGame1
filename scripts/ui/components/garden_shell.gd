extends RefCounted

const Design = preload("res://scripts/ui/components/garden_theme.gd")
const Card = preload("res://scripts/ui/components/selector_card.gd")

static func build(game: Control) -> void:
	game.theme = Design.make()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	game.add_child(margin)
	game.safe_margin = margin
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	margin.add_child(body)
	game.ui_root = body
	var hud := PanelContainer.new()
	hud.add_theme_stylebox_override("panel", Design.box(Design.PAPER, Color("#c7b375")))
	body.add_child(hud)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	hud.add_child(row)
	var coin := TextureRect.new()
	coin.texture = load("res://assets/ui/coin.svg")
	coin.custom_minimum_size = Vector2(30, 30)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(coin)
	game.hud = game._label(row, "", 23)
	game.hud.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var xp := VBoxContainer.new()
	xp.custom_minimum_size.x = 115
	row.add_child(xp)
	game.level_label = game._label(xp, "", 16)
	game.level_progress = ProgressBar.new()
	game.level_progress.custom_minimum_size.y = 7
	game.level_progress.max_value = int(game.model.config.economy.xp_per_level)
	game.level_progress.show_percentage = false
	for part: String in ["background", "fill"]:
		var style: StyleBoxFlat = Design.box(Color("#dfe8c7") if part == "background" else Color("#75a653"))
		for edge: String in ["left", "right", "top", "bottom"]:
			style.set("content_margin_" + edge, 0)
		style.shadow_size = 0
		style.set_border_width_all(0)
		style.set_corner_radius_all(3)
		game.level_progress.add_theme_stylebox_override(part, style)
	xp.add_child(game.level_progress)
	game.unlock_hint = game._label(xp, "", 11)
	var world := Control.new()
	world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world.custom_minimum_size.y = 220
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.clip_contents = true
	body.add_child(world)
	game.board = game.Board.new()
	game.board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.board.plot_pressed.connect(game._on_plot)
	game.board.building_pressed.connect(func(kind: String) -> void:
		if kind == "home":
			game._open_panel("Journal")
		elif kind == "stand" and int(game.model.state.upgrades.stand) > 0:
			game._open_panel("Inventory")
		else:
			game._open_panel("Shop")
	)
	world.add_child(game.board)
	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation", 5)
	rail.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	rail.offset_left = -66
	rail.offset_right = -2
	rail.offset_top = 8
	world.add_child(rail)
	for entry: Array in [["Inventory","inventory"],["Requests","requests"],["Journal","journal"],["Settings","settings"]]:
		var key: String = entry[0]
		var button := Card.new()
		button.compact = true
		button.toggle_mode = true
		button.title = key
		button.picture = load("res://assets/ui/" + str(entry[1]) + ".svg")
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(func() -> void: game._open_panel(key))
		rail.add_child(button)
		button.custom_minimum_size = Vector2(62, 48)
		game.tab_buttons[key] = button
	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	banner.offset_top = -50
	banner.offset_bottom = -4
	banner.offset_left = 4
	banner.offset_right = -72
	banner.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var banner_style: StyleBoxFlat = Design.box(Color(1.0,0.98,0.90,0.93))
	banner_style.shadow_size = 0
	banner_style.content_margin_top = 3
	banner_style.content_margin_bottom = 3
	banner_style.content_margin_left = 6
	banner_style.content_margin_right = 6
	banner.add_theme_stylebox_override("panel", banner_style)
	world.add_child(banner)
	game.status_banner = banner
	var message := VBoxContainer.new()
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(message)
	game.hint = game._label(message, "", 12)
	game.hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.notice = game._label(message, "", 12)
	game.notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dock := PanelContainer.new()
	dock.add_theme_stylebox_override("panel", Design.box(Color("#fff4d9"), Color("#c9b990")))
	body.add_child(dock)
	var dock_body := VBoxContainer.new()
	dock_body.add_theme_constant_override("separation", 6)
	dock.add_child(dock_body)
	var actions := HBoxContainer.new()
	dock_body.add_child(actions)
	game.plant_all_button = game._button(actions, "", game._plant_available)
	game.harvest_all_button = game._button(actions, "", game._harvest_ready)
	game.plant_all_button.add_theme_font_size_override("font_size", 13)
	game.harvest_all_button.add_theme_font_size_override("font_size", 13)
	# Primary action gets a stronger material treatment; native focus/disabled states remain.
	for state: String in ["normal","hover","pressed"]:
		var color := Color("#577c42") if state == "normal" else Color("#648b49") if state == "hover" else Color("#426737")
		var style: StyleBoxFlat = Design.box(color,Color("#38572f"),14)
		if state == "pressed":
			style.shadow_size = 1
		game.harvest_all_button.add_theme_stylebox_override(state,style)
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		game.harvest_all_button.add_theme_color_override(state,Color("#fffae8"))
	var tabs := HBoxContainer.new()
	dock_body.add_child(tabs)
	for mode: String in ["Seeds","Buildings","Decor"]:
		var button: Button = game._button(tabs, "Garden" if mode == "Decor" else mode, func() -> void:
			game.dock_mode = mode
			game._close_panel()
			game._refresh_dock()
			game.apply_settings()
		)
		button.add_theme_font_size_override("font_size", 13)
		button.toggle_mode = true
		game.dock_tabs[mode] = button
	game.tab_buttons.Seeds = game.dock_tabs.Seeds
	game.tab_buttons.Shop = game.dock_tabs.Buildings
	var selector_scroll := ScrollContainer.new()
	selector_scroll.custom_minimum_size.y = 103
	selector_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dock_body.add_child(selector_scroll)
	game.dock_scroll = selector_scroll
	game.selector = HBoxContainer.new()
	game.selector.add_theme_constant_override("separation", 7)
	selector_scroll.add_child(game.selector)
	_modal(game)
	game._refresh_dock()
	game.apply_settings()
	game.get_viewport().size_changed.connect(game._apply_safe_area)
	game.get_viewport().size_changed.connect(game._arrange_dock)
	game._apply_safe_area()

static func _modal(game: Control) -> void:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.visible = false
	game.add_child(layer)
	game.modal_layer = layer
	var shade := Button.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade_style := Design.box(Color(0.12,0.25,0.16,0.5),Color.TRANSPARENT,0)
	shade.add_theme_stylebox_override("normal",shade_style)
	shade.add_theme_stylebox_override("hover",shade_style)
	shade.add_theme_stylebox_override("pressed",shade_style)
	shade.pressed.connect(game._close_panel)
	shade.focus_mode = Control.FOCUS_NONE
	layer.add_child(shade)
	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 10
	sheet.offset_right = -10
	sheet.offset_top = 55
	sheet.offset_bottom = -16
	sheet.add_theme_stylebox_override("panel",Design.box())
	layer.add_child(sheet)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	sheet.add_child(content)
	var top := HBoxContainer.new()
	content.add_child(top)
	game.modal_title = game._label(top,"",23)
	var close: Button = game._button(top,"Close",game._close_panel)
	close.custom_minimum_size.x = 72
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	game.close_button = close
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	game.modal_scroll = scroll
	game.panel = VBoxContainer.new()
	game.panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game.panel.add_theme_constant_override("separation",10)
	scroll.add_child(game.panel)
