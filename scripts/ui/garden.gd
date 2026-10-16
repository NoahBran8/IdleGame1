extends Control

func _ready() -> void:
	var title := Label.new()
	title.text = "GARDEN EMPIRE"
	title.position = Vector2(40, 80)
	add_child(title)
