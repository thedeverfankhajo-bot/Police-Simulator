extends Node

const SAVE_PATH := "user://police_simulator_save.json"
const SAVE_VERSION := 1
const POSITION_SANITIZER_SCRIPT: Script = preload("res://scripts/core/save_position_sanitizer.gd")

var _position_sanitizer: RefCounted

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
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Save could not be opened: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Save file could not be read.")
		return {}
	var raw := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_warning("Save file is invalid JSON; starting a new patrol.")
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != SAVE_VERSION:
		push_warning("Unsupported save version; starting a new patrol.")
		return {}
	var position_data: Variant = data.get("player_position", [])
	data["player_position"] = sanitize_position_data(position_data, Vector3(20.0, 0.0, 28.0))
	GameState.apply_save(data)
	AudioManager.master_volume = clampf(float(data.get("audio_volume", AudioManager.master_volume)), 0.0, 1.0)
	var saved_language := str(data.get("language", "fa"))
	LocaleManager.set_language(saved_language)
	return data

func saved_position(data: Dictionary, fallback: Vector3) -> Vector3:
	var safe_position: Array[float] = sanitize_position_data(data.get("player_position", []), fallback)
	return Vector3(safe_position[0], safe_position[1], safe_position[2])

func sanitize_position_data(position_data: Variant, fallback: Vector3) -> Array[float]:
	var safe_position: Array[float] = _position_sanitizer.call("sanitize_position_data", position_data, fallback)
	return safe_position
