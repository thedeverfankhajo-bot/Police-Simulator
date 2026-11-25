extends Node

const SAVE_PATH := "user://police_simulator_save.json"
const SAVE_BACKUP_PATH := SAVE_PATH + ".bak"
const SAVE_VERSION := 1
const POSITION_SANITIZER_SCRIPT: Script = preload("res://scripts/core/save_position_sanitizer.gd")

var _position_sanitizer: SavePositionSanitizer

func _init() -> void:
	_position_sanitizer = POSITION_SANITIZER_SCRIPT.new()

func save_game(player_position: Vector3) -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"player_position": [player_position.x, player_position.y, player_position.z],
		"score": GameState.score,
		"experience": GameState.experience,
		"level": GameState.level,
		"public_trust": GameState.public_trust,
		"missions_completed": GameState.missions_completed,
		"play_seconds": GameState.play_seconds,
		"reports": GameState.reports,
		"mission_index": GameState.mission_index,
		"current_mission": GameState.current_mission,
		"audio_volume": AudioManager.master_volume,
		"language": LocaleManager.language
	}
	return _write_payload_transactionally(payload, SAVE_PATH)

func load_game() -> Dictionary:
	var data := _load_payload_with_backup(SAVE_PATH, SAVE_BACKUP_PATH)
	if data.is_empty():
		return {}

	var position_data: Variant = data.get("player_position", [])
	data["player_position"] = sanitize_position_data(position_data, Vector3(20.0, 0.0, 28.0))
	GameState.apply_save(data)
	AudioManager.master_volume = clampf(float(data.get("audio_volume", AudioManager.master_volume)), 0.0, 1.0)
	var saved_language := str(data.get("language", "fa"))
	LocaleManager.set_language(saved_language)
	return data

func is_valid_save_payload(value: Variant) -> bool:
	return get_save_payload_validation_error(value).is_empty()

func get_save_payload_validation_error(value: Variant) -> String:
	if not value is Dictionary:
		return "root value must be a Dictionary"
	var payload: Dictionary = value

	var required_fields: Array[String] = [
		"version", "saved_at", "player_position", "score", "experience",
		"level", "public_trust", "missions_completed", "play_seconds",
		"reports", "mission_index", "current_mission", "audio_volume", "language"
	]
	for field_name: String in required_fields:
		if not payload.has(field_name):
			return "required field is missing: %s" % field_name

	var version_value: Variant = payload["version"]
	if not (version_value is int or version_value is float):
		return "version must be numeric"
	var numeric_version := float(version_value)
	if not is_finite(numeric_version) or not is_equal_approx(numeric_version, float(SAVE_VERSION)):
		return "version must equal %d" % SAVE_VERSION

	var timestamp_value: Variant = payload["saved_at"]
	if not timestamp_value is String or timestamp_value.strip_edges().is_empty():
		return "saved_at must be a non-empty String"

	var position_value: Variant = payload["player_position"]
	if not position_value is Array:
		return "player_position must be an Array"
	if position_value.size() != 3:
		return "player_position must contain exactly three coordinates"
	for coordinate: Variant in position_value:
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
			return "player_position contains a non-numeric or non-finite coordinate"

	var integer_ranges := {
		"score": Vector2(0.0, INF),
		"experience": Vector2(0.0, INF),
		"level": Vector2(1.0, INF),
		"public_trust": Vector2(0.0, 100.0),
		"missions_completed": Vector2(0.0, INF),
		"mission_index": Vector2(0.0, 1000.0)
	}
	for field_name: String in integer_ranges:
		var field_value: Variant = payload[field_name]
		if not (field_value is int or field_value is float):
			return "%s must be numeric" % field_name
		var numeric_value := float(field_value)
		var allowed_range: Vector2 = integer_ranges[field_name]
		if not is_finite(numeric_value) or not is_equal_approx(numeric_value, floorf(numeric_value)):
			return "%s must be a finite whole number" % field_name
		if numeric_value < allowed_range.x or numeric_value > allowed_range.y:
			return "%s is outside its allowed range" % field_name

	for field_name: String in ["play_seconds", "audio_volume"]:
		var field_value: Variant = payload[field_name]
		if not (field_value is int or field_value is float):
			return "%s must be numeric" % field_name
		var numeric_value := float(field_value)
		if not is_finite(numeric_value) or numeric_value < 0.0:
			return "%s must be finite and non-negative" % field_name
		if field_name == "audio_volume" and numeric_value > 1.0:
			return "audio_volume must be between 0 and 1"

	var reports_value: Variant = payload["reports"]
	if not reports_value is Array:
		return "reports must be an Array"
	if reports_value.size() > 200:
		return "reports exceeds the 200-entry limit"
	for report: Variant in reports_value:
		if not report is Dictionary:
			return "every report entry must be a Dictionary"

	if not payload["current_mission"] is Dictionary:
		return "current_mission must be a Dictionary"

	var language_value: Variant = payload["language"]
	if not language_value is String:
		return "language must be a String"
	if not ["fa", "en"].has(language_value):
		return "language must be 'fa' or 'en'"

	return ""

func _write_payload_transactionally(payload: Dictionary, target_path: String) -> bool:
	if not is_valid_save_payload(payload):
		push_warning("Save rejected because its payload failed validation.")
		return false

	var temp_path := target_path + ".tmp"
	var backup_path := target_path + ".bak"
	if not _remove_file_if_exists(temp_path):
		push_warning("Stale temporary save file could not be removed.")
		return false

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Temporary save could not be opened: %s" % error_string(FileAccess.get_open_error()))
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_remove_file_if_exists(temp_path)
		push_warning("Temporary save could not be flushed: %s" % error_string(write_error))
		return false

	var staged_payload := _read_save_payload(temp_path)
	if staged_payload.is_empty():
		_remove_file_if_exists(temp_path)
		push_warning("Temporary save failed validation; the previous save was preserved.")
		return false

	if not _read_save_payload(target_path).is_empty():
		var backup_error := DirAccess.copy_absolute(target_path, backup_path)
		if backup_error != OK:
			_remove_file_if_exists(temp_path)
			push_warning("Previous save could not be backed up: %s" % error_string(backup_error))
			return false

	var replace_error := DirAccess.rename_absolute(temp_path, target_path)
	if replace_error != OK:
		_remove_file_if_exists(temp_path)
		push_warning("Validated save could not replace the primary file: %s" % error_string(replace_error))
		return false

	return true

func _load_payload_with_backup(primary_path: String, backup_path: String) -> Dictionary:
	var primary_payload := _read_save_payload(primary_path)
	if not primary_payload.is_empty():
		return primary_payload

	var backup_payload := _read_save_payload(backup_path)
	if backup_payload.is_empty():
		return {}

	push_warning("Primary save is unavailable or invalid; a validated backup is being restored.")
	var restore_error := DirAccess.copy_absolute(backup_path, primary_path)
	if restore_error != OK:
		push_warning("Backup data was loaded, but restoring the primary save file failed: %s" % error_string(restore_error))
	return backup_payload

func _read_save_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Save file could not be opened: %s" % path)
		return {}

	var raw := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	var validation_error := get_save_payload_validation_error(parsed)
	if not validation_error.is_empty():
		push_warning("Save file failed JSON or schema validation (%s): %s" % [validation_error, path])
		return {}
	return parsed

func _remove_file_if_exists(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var remove_error := DirAccess.remove_absolute(path)
	if remove_error != OK:
		push_warning("Temporary save file could not be removed: %s" % path)
		return false
	return true

func saved_position(data: Dictionary, fallback: Vector3) -> Vector3:
	var safe_position: Array[float] = sanitize_position_data(data.get("player_position", []), fallback)
	return Vector3(safe_position[0], safe_position[1], safe_position[2])

func sanitize_position_data(position_data: Variant, fallback: Vector3) -> Array[float]:
	var safe_position: Array[float] = _position_sanitizer.sanitize_position_data(position_data, fallback)
	return safe_position
