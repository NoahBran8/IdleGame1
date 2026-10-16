class_name GardenAnalytics
extends RefCounted

const EVENTS: Array[String] = ["install_first_open", "tutorial_step_completed", "seed_planted", "plant_harvested", "item_sold", "upgrade_purchased", "stand_unlocked", "session_start", "session_end", "game_resumed", "save_error", "progression_milestone", "settings_changed", "order_fulfilled", "order_pinned"]
const PARAMS: Array[String] = ["species", "quantity", "coins", "upgrade", "step", "milestone", "setting", "enabled", "reason", "elapsed", "order_id", "order"]
var enabled: bool = true
var path: String
var session_id: String
var events: Array[Dictionary] = []
var write_error: bool = false

func _init(log_path: String = "user://events.jsonl") -> void:
	path = log_path
	# Session-scoped only. No persistent install ID, advertising ID or PII.
	session_id = str(Time.get_ticks_usec())

func record(event: String, params: Dictionary = {}) -> bool:
	if not enabled or not event in EVENTS:
		return false
	for key: Variant in params:
		if not key is String or not key in PARAMS:
			return false
		var value: Variant = params[key]
		if not (value is String or value is int or value is bool):
			return false
		if value is String and value.length() > 100:
			return false
	var entry: Dictionary = {"event": event, "schema_version": 1, "app_version": str(ProjectSettings.get_setting("application/config/version", "0.4.0")),
		"platform": OS.get_name(), "session_id": session_id,
		"timestamp": int(Time.get_unix_time_from_system()), "parameters": params}
	events.append(entry)
	if events.size() > 100:
		events.pop_front()
	var file: FileAccess
	if FileAccess.file_exists(path) and FileAccess.get_file_as_bytes(path).size() < 262144:
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		write_error = true
		return false
	file.store_line(JSON.stringify(entry))
	file.close()
	return true
