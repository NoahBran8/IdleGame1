extends Control

const Design = preload("res://scripts/ui/components/garden_theme.gd")
signal confirmed
signal canceled
var title: String = ""
var description: String = ""
var price: int = 0
var panel: PanelContainer
var ok_button: Button
var cancel_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := Button.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := Design.box(Color(0.12,0.25,0.16,0.55),Color.TRANSPARENT,0)
	for state: String in ["normal","hover","pressed"]:
		shade.add_theme_stylebox_override(state,dim)
	shade.focus_mode = Control.FOCUS_NONE
	shade.pressed.connect(func() -> void: canceled.emit())
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",Design.box())
	center.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	panel.add_child(body)
	_label(body,title,24)
	_label(body,"%d coins" % price,21)
	_label(body,description,16)
	var row := HBoxContainer.new()
	body.add_child(row)
	cancel_button = _button(row,"Cancel")
	ok_button = _button(row,"Buy upgrade")
	cancel_button.pressed.connect(func() -> void: canceled.emit())
	ok_button.pressed.connect(func() -> void: confirmed.emit())
	get_viewport().size_changed.connect(_arrange)
	_arrange()
	cancel_button.grab_focus()

func _arrange() -> void:
	panel.custom_minimum_size.x = minf(420,get_viewport_rect().size.x-32)

func _label(parent: Node,value: String,font_size: int) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)

func _button(parent: Node,value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button

func get_ok_button() -> Button:
	return ok_button

func get_cancel_button() -> Button:
	return cancel_button

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		canceled.emit()
		get_viewport().set_input_as_handled()
