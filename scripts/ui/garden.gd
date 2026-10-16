extends Control

const PurchaseConfirm = preload("res://scripts/ui/components/purchase_confirm.gd")
const Shell = preload("res://scripts/ui/components/garden_shell.gd")
const Design = preload("res://scripts/ui/components/garden_theme.gd")
const SelectorCard = preload("res://scripts/ui/components/selector_card.gd")
const Feedback = preload("res://scripts/ui/components/feedback_layer.gd")
const Model = preload("res://scripts/domain/game_model.gd")
const Save = preload("res://scripts/services/save_service.gd")
const Analytics = preload("res://scripts/services/analytics_service.gd")
const Audio = preload("res://scripts/services/audio_service.gd")
const Board = preload("res://scripts/ui/garden_board.gd")
var status_banner: PanelContainer
var dock_scroll: ScrollContainer
var notice_cached: String = ""
var notice_deadline: int = 0
var purchase_dialog: Control
var level_label: Label
var modal_layer: Control
var modal_title: Label
var modal_scroll: ScrollContainer
var close_button: Button
var selector: HBoxContainer
var dock_mode: String = "Seeds"
var dock_tabs: Dictionary = {}
var selector_cards: Dictionary = {}
var feedback: Control
var visual_snapshot: Dictionary = {}
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
var plant_all_button: Button
var harvest_all_button: Button
var level_progress: ProgressBar
var unlock_hint: Label
var request_buttons: Dictionary = {}

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
	_update_notice()
	if now() != last_second:
		last_second = now()
		var progress: Dictionary = model.advance_to(last_second)
		var stock_changed: bool = int(progress.income) > 0 or int(progress.harvests) > 0
		if stock_changed or last_second % 30 == 0:
			_save()
		if stock_changed:
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

func _style(_color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	return Design.box(Design.PAPER, Color("#93ae79") if border.a > 0 else Color("#c9d5ae"))

func _build() -> void:
	Shell.build(self)
	feedback = Feedback.new()
	feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(feedback)

func _label(parent: Node, text: String, font_size: int = 17, color: Color = Color("#e9ecdc")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	var tone: Color = Design.INK
	if color.to_html(false) in ["bac99d", "b9c992", "8fa68e", "b8c7a5"]:
		tone = Design.MUTED
	elif color.to_html(false) in ["efcf87", "f0cf98"]:
		tone = Design.GOLD
	label.add_theme_color_override("font_color", tone)
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
	hud.text = Model.compact(int(model.state.coins))
	hud.tooltip_text = "%d coins" % int(model.state.coins)
	level_label.text = "Lv %s" % Model.compact(model.level())
	_show_state_feedback()
	level_progress.value = int(model.state.xp) % int(model.config.economy.xp_per_level)
	level_progress.tooltip_text = "%d / %d XP to level %d" % [int(level_progress.value), int(level_progress.max_value), model.level() + 1]
	unlock_hint.text = "%d XP to next level" % int(level_progress.max_value - level_progress.value) if get_viewport_rect().size.x >= 400 else "%d XP" % int(level_progress.max_value - level_progress.value)
	unlock_hint.tooltip_text = level_progress.tooltip_text
	for id: String in model.config.plants:
		if int(model.config.plants[id].level_required) > model.level():
			unlock_hint.tooltip_text += " · %s unlocks at level %d" % [model.config.plants[id].name, int(model.config.plants[id].level_required)]
			break
	board.refresh(model, now(), selected)
	var ready_count: int = 0
	var growing: int = 0
	for i: int in range(int(model.state.plots_unlocked)):
		if model.phase(i, now()) == 3:
			ready_count += 1
		elif model.phase(i, now()) >= 0:
			growing += 1
	hint.text = "%d ready · %d growing" % [ready_count, growing]
	if plant_all_button != null:
		var quote: Dictionary = model.planting_quote(selected)
		plant_all_button.text = "Plant %d · %dc" % [int(quote.count), int(quote.cost)]
		plant_all_button.tooltip_text = "Plant %d %s seeds for %d coins" % [int(quote.count), model.config.plants[selected].name, int(quote.cost)]
		plant_all_button.set_meta("quoted_count", int(quote.count))
		plant_all_button.disabled = int(quote.count) == 0
		harvest_all_button.text = "Harvest %d" % ready_count
		harvest_all_button.tooltip_text = "Harvest all ready plants"
		harvest_all_button.disabled = ready_count == 0
	match int(model.state.onboarding):
		0:
			hint.text = "Pick a seed, then tap a + plot."
		1:
			hint.text = "Carrots take 8s. Tap when ready."
		2:
			hint.text = "Open Inventory to sell or deliver."
		3:
			hint.text = "Explore Buildings to grow your garden."

func _on_plot(index: int) -> void:
	model.advance_to(now())
	if index >= int(model.state.plots_unlocked):
		notice.text = "Unlock another plot with Garden expansion."
		_open_panel("Shop")
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
	request_buttons.clear()
	for child: Node in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	for tab: String in tab_buttons:
		tab_buttons[tab].set_pressed_no_signal(tab == active_tab and modal_layer.visible)
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
					_refresh()
					notice.text = plant.name + " selected. Tap an empty plot."
					_refresh_panel()
				)
				button.disabled = locked
				button.add_theme_font_size_override("font_size", 15)
		"Inventory":
			_label(panel, "YOUR HARVEST", 13, Color("#bac99d"))
			for id: String in model.config.plants:
				var amount: int = int(model.state.inventory[id])
				var reserved: int = model.reserved_quantity(id)
				var button := _button(panel, "%s ×%d%s · Sell one for %d" % [model.config.plants[id].name, amount, " (%d reserved)" % reserved if reserved else "", model.sell_value(id)], func() -> void:
					var earned: int = model.sell(id, 1)
					notice.text = "Sold for %d coins." % earned
					if earned > 0:
						_event("item_sold", {"species": id, "quantity": 1, "coins": earned})
						_feedback(1100.0)
					_save()
					_refresh()
					_refresh_panel()
				)
				button.disabled = model.available_to_sell(id) <= 0
			_button(panel, "Sell all unreserved plants", func() -> void:
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
		"Requests":
			_label(panel, "THE NEIGHBOURHOOD NOTICEBOARD", 13, Color("#bac99d"))
			_label(panel, "Grow for your neighbours. Requests never expire. Pin one to keep its crops safe from manual and stand sales.", 15)
			_label(panel, "%d deliveries completed" % int(model.state.orders_completed), 13, Color("#efcf87"))
			for offer: Dictionary in model.state.orders:
				_request_card(int(offer.uid))
		"Shop":
			_label(panel, "INVEST IN YOUR GARDEN", 13, Color("#bac99d"))
			_label(panel, "Stand: " + ("open · sells inventory every %ds" % model.stand_interval() if int(model.state.upgrades.stand) > 0 else "not yet built"), 15)
			for id: String in ["plots", "stand", "compost", "baskets", "irrigation", "helper", "signage", "soil"]:
				var upgrade: Dictionary = model.config.upgrades[id]
				var price: int = model.upgrade_price(id)
				var text: String = "%s · %s" % [upgrade.name, "%d coins" % price if price > 0 else "MAX"]
				text += " · %d/%d" % [int(model.state.upgrades[id]), int(upgrade.max_level)]
				var button := _button(panel, text, func() -> void: _request_upgrade(id))
				button.set_meta("upgrade_id", id)
				button.disabled = not model.can_upgrade(id)
				_label(panel, upgrade.description + " [Level %d]" % int(upgrade.level_required), 13, Color("#b8c7a5"))
				if price > 0:
					_label(panel, _effect_preview(id), 13, Color("#efcf87"))
			_label(panel, "If your garden and inventory are empty, keep 5 coins for a seed.", 13)
		"Journal":
			_label(panel, "COLLECTION · %s total XP" % Model.compact(int(model.state.xp)), 13, Color("#bac99d"))
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
				toggle.name = "Setting_" + setting
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
			if not saves.message.is_empty():
				_label(panel, saves.message, 15)
			_label(panel, "Local telemetry stays on this device (rotates at 256 KiB). No persistent player ID or network transmission. Toggle it off above.\nOffline · No account · No ads or purchases\nSave location: " + ProjectSettings.globalize_path(saves.path), 13)

			if OS.is_debug_build() and "--debug-garden" in OS.get_cmdline_user_args():
				_label(panel, "DEVELOPER TOOLS", 13)
				_button(panel, "Add 100 test coins", func() -> void:
					model.state.coins = mini(Model.MAX_COINS, int(model.state.coins) + 100)
					_save()
					_refresh()
				)
	_refresh_dock()
	apply_settings()

func apply_settings() -> void:
	theme.default_font_size = 20 if model.state.settings.large_text else 17
	_scale_text(self, 1.2 if model.state.settings.large_text else 1.0)
	RenderingServer.set_default_clear_color(Color("#c5dea5") if model.state.settings.high_contrast else Color("#d3e9b0"))
	_refresh()

func _request_upgrade(id: String) -> void:
	var price: int = model.upgrade_price(id)
	if price < 100:
		_purchase(id)
		return
	if is_instance_valid(purchase_dialog):
		return
	var confirm := PurchaseConfirm.new()
	confirm.title = model.config.upgrades[id].name
	confirm.description = model.config.upgrades[id].description + "\n" + _effect_preview(id)
	confirm.price = price
	confirm.confirmed.connect(func() -> void:
		_purchase(id,price)
		confirm.queue_free()
		purchase_dialog = null
	)
	confirm.canceled.connect(func() -> void:
		confirm.queue_free()
		purchase_dialog = null
	)
	add_child(confirm)
	purchase_dialog = confirm
	_scale_text(confirm,1.2 if model.state.settings.large_text else 1.0)

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
		audio.stop()
		audio.stream = Audio.tone(frequency)
		audio.play()
	if feedback != null and index >= 0:
		feedback.show_gain("Planted" if frequency < 600 else "Harvested!", board.plots[index].global_position + Vector2(4, 2), Design.INK, bool(model.state.settings.reduced_motion))
	if not model.state.settings.reduced_motion:
		if index >= 0:
			var tile: Control = board.plots[index]
			tile.modulate = Color("#fff1ad")
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
	safe_margin.add_theme_constant_override("margin_left", maxi(8, int(safe.position.x * ratio.x)))
	safe_margin.add_theme_constant_override("margin_right", maxi(8, int((physical.x - safe.end.x) * ratio.x)))
	safe_margin.add_theme_constant_override("margin_top", maxi(8, int(safe.position.y * ratio.y)))
	safe_margin.add_theme_constant_override("margin_bottom", maxi(8, int((physical.y - safe.end.y) * ratio.y)))

func _exit_tree() -> void:
	if audio != null:
		audio.stop()
		audio.stream = null

func _plant_available() -> void:
	model.advance_to(now())
	var count: int = model.plant_available(selected, now(), int(plant_all_button.get_meta("quoted_count", 0)))
	if count > 0:
		notice.text = "%d %s seeds planted. Your garden is growing." % [count, model.config.plants[selected].name]
		_event("seed_planted", {"species": selected, "quantity": count})
		_feedback(440.0)
	_save()
	_refresh()
	_refresh_panel()

func _harvest_ready() -> void:
	model.advance_to(now())
	var count: int = model.harvest_ready(now())
	if count > 0:
		notice.text = "%d plants harvested. Sell your surplus or deliver a request." % count
		_event("plant_harvested", {"quantity": count})
		_feedback(880.0)
	_save()
	_refresh()
	_refresh_panel()

func _request_card(uid: int) -> void:
	var template: Dictionary = model.order_template(uid)
	var pinned: bool = int(model.state.pinned_order) == uid
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color("#1a3027"), Color("#d9c487") if pinned else Color("#42634a")))
	panel.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	card.add_child(content)
	_label(content, template.name + (" · PINNED" if pinned else ""), 19, Color("#f4e5ba"))
	_label(content, template.customer, 13, Color("#b9c992"))
	for species: String in template.items:
		var have: int = int(model.state.inventory[species])
		var need: int = int(template.items[species])
		_label(content, "%s · %d / %d%s" % [model.config.plants[species].name, mini(have, need), need, " · Ready" if have >= need else " · Grow %d more" % (need - have)], 15)
	var reward: int = model.order_reward(uid)
	_label(content, "%d coins + %d XP · includes %d bonus coins" % [reward, int(template.xp_reward), int(template.bonus_coins)], 14, Color("#efcf87"))
	var pin := _button(content, "Unpin · release reserved crops" if pinned else "Pin · reserve these crops", func() -> void:
		if model.pin_order(0 if int(model.state.pinned_order) == uid else uid):
			notice.text = "Request pinned. Its ingredients are protected from sales." if int(model.state.pinned_order) != 0 else "Crops released for sale."
			_event("order_pinned", {"order_id": uid, "enabled": int(model.state.pinned_order) != 0})
			_save()
			_refresh()
			_refresh_panel()
	)
	var deliver := _button(content, "Deliver for %d coins" % reward, func() -> void: _deliver_order(uid))
	deliver.disabled = not model.can_fulfill(uid)
	request_buttons[uid] = {"pin": pin, "deliver": deliver}

func _deliver_order(uid: int) -> void:
	# The id is consumed atomically, so stale buttons cannot deliver twice.
	var template: Dictionary = model.order_template(uid)
	var reward: int = model.order_reward(uid)
	if model.fulfill_order(uid):
		notice.text = "%s delivered · +%d coins · +%d XP" % [template.name, reward, int(template.xp_reward)]
		_event("order_fulfilled", {"order_id": uid, "coins": reward, "order": template.id})
		_feedback(1046.5)
	else:
		notice.text = "Delivery unavailable. Check the ingredients and wallet space."
	_save()
	_refresh()
	_refresh_panel()

func _open_panel(tab: String) -> void:
	active_tab = tab
	modal_title.text = {"Inventory":"Your harvest", "Requests":"Neighbourhood requests", "Journal":"Garden journal", "Shop":"Build & upgrade", "Settings":"Settings"}.get(tab, tab)
	modal_layer.visible = true
	_refresh_panel()
	modal_scroll.scroll_vertical = 0
	close_button.grab_focus()

func _close_panel() -> void:
	modal_layer.visible = false
	for key: String in ["Inventory","Requests","Journal","Settings"]:
		tab_buttons[key].set_pressed_no_signal(false)
	board.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and modal_layer.visible:
		_close_panel()
		get_viewport().set_input_as_handled()

func _refresh_dock() -> void:
	if selector == null:
		return
	selector_cards.clear()
	for child: Node in selector.get_children():
		selector.remove_child(child)
		child.queue_free()
	for mode: String in dock_tabs:
		dock_tabs[mode].set_pressed_no_signal(mode == dock_mode)
	if dock_mode == "Seeds":
		for id: String in model.config.plants:
			var row: Dictionary = model.config.plants[id]
			var locked: bool = model.level() < int(row.level_required)
			var card: Button = _selector_card(id, row.name, "Lv %d" % int(row.level_required) if locked else "%d coins · %ds" % [int(row.seed_cost), model.growth_seconds(id)], id, func() -> void:
				selected = id
				notice.text = "%s selected. Tap a plot." % row.name
				_refresh()
				_refresh_dock()
				apply_settings()
			)
			card.disabled = locked
			card.set_pressed_no_signal(selected == id)
	elif dock_mode == "Buildings":
		var names: Dictionary = {"plots":"Expand", "stand":"Flower stand", "irrigation":"Irrigation", "helper":"Helper", "compost":"Compost", "baskets":"Baskets", "signage":"Signage", "soil":"Learning"}
		for id: String in ["plots","stand","compost","baskets","irrigation","helper","signage","soil"]:
			var price: int = model.upgrade_price(id)
			var card: Button = _selector_card(id, names[id], "MAX" if price < 0 else "%d coins" % price, "stand" if id == "stand" else "home" if id == "plots" else "decor", func() -> void: _open_panel("Shop"))
			card.tooltip_text = model.config.upgrades[id].description + " · " + _effect_preview(id)
	else:
		for entry: Array in [["meadow","Meadow","sunflower"],["wildflowers","Flower border","rose"],["stone","Stone walk","home"]]:
			var id: String = entry[0]
			var card: Button = _selector_card(id, entry[1], "Selected" if model.state.decor == id else "Free garden look", entry[2], func() -> void:
				model.state.decor = id
				notice.text = entry[1] + " applied."
				_save()
				_refresh()
				_refresh_dock()
				apply_settings()
			)
			card.set_pressed_no_signal(model.state.decor == id)

	_arrange_dock()

func _selector_card(id: String, title: String, caption: String, icon: String, action: Callable) -> Button:
	var card := SelectorCard.new()
	card.title = title
	card.caption = caption
	card.picture = load("res://assets/ui/" + icon + ".svg")
	card.toggle_mode = true
	card.add_theme_font_size_override("font_size", 13)
	card.pressed.connect(action)
	selector.add_child(card)
	selector_cards[id] = card
	return card

func _show_state_feedback() -> void:
	var upgrades: int = 0
	for rank: Variant in model.state.upgrades.values():
		upgrades += int(rank)
	if not visual_snapshot.is_empty() and feedback != null:
		var reduced: bool = model.state.settings.reduced_motion
		if int(model.state.coins) > int(visual_snapshot.coins):
			feedback.show_gain("+%s coins" % Model.compact(int(model.state.coins) - int(visual_snapshot.coins)), hud.global_position + Vector2(0,40), Design.GOLD, reduced)
		if int(model.state.xp) > int(visual_snapshot.xp):
			feedback.show_gain("+%d XP" % (int(model.state.xp) - int(visual_snapshot.xp)), level_label.global_position + Vector2(-10,40), Color("#39678a"), reduced)
		if upgrades > int(visual_snapshot.upgrades):
			feedback.show_gain("Garden upgraded!", board.global_position + board.size * Vector2(0.2,0.45), Design.INK, reduced)
	visual_snapshot = {"coins":int(model.state.coins), "xp":int(model.state.xp), "upgrades":upgrades}

func _arrange_dock() -> void:
	if dock_scroll == null:
		return
	var compact: bool = get_viewport_rect().size.y < 720
	dock_scroll.custom_minimum_size.y = 83 if compact else 103
	for card: Control in selector.get_children():
		card.custom_minimum_size.y = 72 if compact else 92
		card.queue_redraw()
	for control: Control in [plant_all_button,harvest_all_button,dock_tabs.Seeds,dock_tabs.Buildings,dock_tabs.Decor]:
		control.custom_minimum_size.y = 44 if compact else 48

func _update_notice() -> void:
	if notice.text != notice_cached:
		notice_cached = notice.text
		notice_deadline = Time.get_ticks_msec()+5000
		notice.visible = not notice.text.is_empty()
		status_banner.offset_top = -28 if notice.text.is_empty() else -50
	elif not notice.text.is_empty() and Time.get_ticks_msec() > notice_deadline and saves.message.is_empty():
		notice.text = ""
