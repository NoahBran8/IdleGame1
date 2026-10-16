extends Control

var active_count: int = 0
var animated_count: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_gain(value: String, point: Vector2, color: Color, reduced: bool) -> void:
	if active_count >= 6:
		return
	active_count += 1
	var label := Label.new()
	label.text = value
	label.position = point
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#fff9e9"))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 19)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	if reduced:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if is_instance_valid(label):
				label.queue_free()
			active_count -= 1
		)
	else:
		animated_count += 1
		var tween := create_tween()
		tween.set_parallel()
		tween.tween_property(label,"position",point - Vector2(0,38),0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(label,"modulate:a",0.0,0.8).set_delay(0.2)
		tween.chain().tween_callback(func() -> void:
			label.queue_free()
			active_count -= 1
			animated_count -= 1
		)
