class_name GardenSave
extends RefCounted

var path: String
var message: String = ""
var blocked: bool = false

func _init(save_path: String = "user://garden.json") -> void:
	path = save_path

func load_into(model: GardenModel) -> bool:
	blocked = false
	message = ""
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
		return true
	for file: String in [path, path + ".bak"]:
		if not FileAccess.file_exists(file):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(file)) != OK:
			continue
		var candidate: Variant = parser.data
		if model.validate(candidate):
			model.state = candidate
			if file.ends_with(".bak"):
				message = "Recovered your garden from its backup."
				# Quarantine the damaged primary before subsequent writes.
				if FileAccess.file_exists(path):
					DirAccess.rename_absolute(path, path + ".damaged-" + str(Time.get_unix_time_from_system()))
			return true
	message = "Save could not be read. Original files preserved; saving paused. Restore a valid backup before continuing."
	blocked = true
	return false

func store(model: GardenModel) -> bool:
	if blocked or not model.validate(model.state):
		message = "Saving paused: invalid state or unreadable existing save."
		return false
	var temp: String = path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		message = "Could not open save file. Your garden is still in memory."
		return false
	file.store_string(JSON.stringify(model.state))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		message = "Could not write save file."
		return false
	# Keep the previous valid primary while atomically replacing the primary.
	if FileAccess.file_exists(path):
		var backup_error: Error = DirAccess.copy_absolute(path, path + ".bak")
		if backup_error != OK:
			message = "Could not preserve save backup."
			return false
	if DirAccess.rename_absolute(temp, path) != OK:
		message = "Could not replace save file."
		return false
	return true
