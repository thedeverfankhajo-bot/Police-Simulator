extends Node

signal mission_changed(mission: Dictionary)
signal mission_completed(mission: Dictionary, report: Dictionary)

const DEFAULT_OBJECTIVE_STEPS := [
	{
		"id": "inspect_location",
		"title_fa": "محل گزارش‌شده را بررسی کنید",
		"title_en": "Inspect the reported location"
	},
	{
		"id": "record_outcome",
		"title_fa": "نتیجهٔ رسیدگی را ثبت کنید",
		"title_en": "Record the outcome"
	}
]

var catalogue: Array[Dictionary] = []
var next_index: int = 0
var active_mission: Dictionary = {}
var active: bool = false

func _ready() -> void:
	_load_catalogue()

func _load_catalogue() -> void:
	catalogue.clear()
	var file := FileAccess.open("res://data/missions/missions.json", FileAccess.READ)
	if file == null:
		push_error("Mission data could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Mission catalogue is invalid.")
		return
	if int(parsed.get("schema_version", -1)) != 1:
		push_error("Unsupported mission catalogue schema version.")
		return
	var entries: Variant = parsed.get("missions", [])
	if not entries is Array:
		push_error("Mission catalogue entries must be an Array.")
		return
	var seen_ids: Dictionary = {}
	for item: Variant in entries:
		if not item is Dictionary:
			push_warning("Skipping a mission entry that is not a Dictionary.")
			continue
		var mission: Dictionary = item
		if not is_valid_mission_data(mission):
			push_warning("Skipping invalid mission entry: %s" % str(mission.get("id", "<missing id>")))
			continue
		var mission_id := str(mission.get("id", "")).strip_edges()
		if seen_ids.has(mission_id):
			push_warning("Skipping duplicate mission id: %s" % mission_id)
			continue
		seen_ids[mission_id] = true
		catalogue.append(mission.duplicate(true))
	if catalogue.is_empty():
		push_warning("Mission catalogue contains no valid entries.")

func get_objective_steps(mission: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source: Variant = mission.get("objective_steps", DEFAULT_OBJECTIVE_STEPS)
	if not source is Array:
		return result
	for candidate: Variant in source:
		if candidate is Dictionary:
			result.append(candidate.duplicate(true))
	return result

func is_valid_mission_data(mission: Dictionary) -> bool:
	var id_value: Variant = mission.get("id", null)
	var type_value: Variant = mission.get("type", null)
	if not id_value is String or not type_value is String:
		return false
	if id_value.strip_edges().is_empty() or id_value != id_value.strip_edges():
		return false
	if type_value.strip_edges().is_empty() or type_value != type_value.strip_edges():
		return false

	var required_text_fields: Array[String] = [
		"title_fa",
		"title_en",
		"description_fa",
		"description_en",
		"priority",
		"target_label"
	]
	for field_name: String in required_text_fields:
		var field_value: Variant = mission.get(field_name, null)
		if not field_value is String or field_value.strip_edges().is_empty():
			return false

	var location: Variant = mission.get("location", null)
	if not location is Array or location.size() != 3:
		return false
	for coordinate: Variant in location:
		if not (coordinate is int or coordinate is float):
			return false
		if not is_finite(float(coordinate)):
			return false

	var reward_value: Variant = mission.get("reward", null)
	if not (reward_value is int or reward_value is float):
		return false
	if not is_finite(float(reward_value)) or float(reward_value) < 0.0:
		return false

	var trust_value: Variant = mission.get("trust", null)
	if not (trust_value is int or trust_value is float):
		return false
	if not is_finite(float(trust_value)) or float(trust_value) < -100.0 or float(trust_value) > 100.0:
		return false

	var raw_objective_steps: Variant = mission.get("objective_steps", DEFAULT_OBJECTIVE_STEPS)
	if not raw_objective_steps is Array:
		return false
	if raw_objective_steps.is_empty() or raw_objective_steps.size() > 8:
		return false
	for raw_step: Variant in raw_objective_steps:
		if not raw_step is Dictionary:
			return false
	var objective_steps := get_objective_steps(mission)
	if objective_steps.size() != raw_objective_steps.size():
		return false
	var objective_ids: Dictionary = {}
	for step: Dictionary in objective_steps:
		var step_id: Variant = step.get("id", null)
		if not step_id is String or step_id.strip_edges().is_empty() or step_id != step_id.strip_edges():
			return false
		for title_key: String in ["title_fa", "title_en"]:
			var title_value: Variant = step.get(title_key, null)
			if not title_value is String or title_value.strip_edges().is_empty():
				return false
		if objective_ids.has(step_id):
			return false
		objective_ids[step_id] = true

	var objective_index := 0
	if mission.has("objective_index"):
		var index_value: Variant = mission["objective_index"]
		if not (index_value is int or index_value is float):
			return false
		var numeric_index := float(index_value)
		if not is_finite(numeric_index) or not is_equal_approx(numeric_index, floorf(numeric_index)):
			return false
		objective_index = int(numeric_index)
		if objective_index < 0 or objective_index >= objective_steps.size():
			return false

	var has_objective_index := mission.has("objective_index")
	if mission.has("completed_objectives") or has_objective_index:
		var completed_value: Variant = mission.get("completed_objectives", null)
		if not completed_value is Array:
			return false
		if not has_objective_index:
			return completed_value.is_empty()
		if completed_value.size() != objective_index:
			return false
		for completed_index in range(completed_value.size()):
			var completed_id: Variant = completed_value[completed_index]
			if not completed_id is String:
				return false
			var expected_id := str(objective_steps[completed_index].get("id", ""))
			if completed_id != expected_id:
				return false

	return true

func get_next_mission() -> Dictionary:
	if next_index >= catalogue.size():
		return {}
	return catalogue[next_index].duplicate(true)

func accept_next_mission() -> bool:
	if active:
		return false
	var mission := get_next_mission()
	if mission.is_empty():
		return false
	next_index += 1
	active_mission = mission
	active_mission["accepted_at"] = Time.get_datetime_string_from_system()
	active_mission["status"] = "active"
	active_mission["objective_index"] = 0
	active_mission["completed_objectives"] = []
	active = true
	GameState.current_mission = active_mission.duplicate(true)
	GameState.mission_index = next_index
	mission_changed.emit(active_mission.duplicate(true))
	return true

func is_near_objective(position: Vector3, radius: float = 4.0) -> bool:
	if not active:
		return false
	var location: Variant = active_mission.get("location", [])
	if not location is Array or location.size() != 3:
		return false
	var target := Vector3(float(location[0]), float(location[1]), float(location[2]))
	return Vector2(position.x - target.x, position.z - target.z).length() <= radius

func get_active_objective_title(language_code: String = "fa") -> String:
	if not active:
		return ""
	var steps := get_objective_steps(active_mission)
	if steps.is_empty():
		return ""
	var current_index := clampi(int(active_mission.get("objective_index", 0)), 0, steps.size() - 1)
	var title_key := "title_en" if language_code == "en" else "title_fa"
	return str(steps[current_index].get(title_key, steps[current_index].get("title_fa", "")))

func get_objective_progress(language_code: String = "fa") -> Dictionary:
	if not active:
		return {}
	var steps := get_objective_steps(active_mission)
	if steps.is_empty():
		return {}
	var current_index := clampi(int(active_mission.get("objective_index", 0)), 0, steps.size() - 1)
	return {
		"index": current_index + 1,
		"total": steps.size(),
		"title": get_active_objective_title(language_code)
	}

func advance_active_objective(position: Vector3, language_code: String = "fa") -> Dictionary:
	if not active or not is_near_objective(position):
		return {}
	var steps := get_objective_steps(active_mission)
	if steps.is_empty():
		push_warning("Active mission has no valid objective steps.")
		return {}
	var current_index := int(active_mission.get("objective_index", 0))
	if current_index < 0 or current_index >= steps.size():
		push_warning("Active mission objective index is outside its step list.")
		return {}

	var current_step: Dictionary = steps[current_index]
	var completed_ids: Array[String] = []
	var stored_completed: Variant = active_mission.get("completed_objectives", [])
	if stored_completed is Array:
		for completed_id: Variant in stored_completed:
			if completed_id is String and not completed_ids.has(completed_id):
				completed_ids.append(completed_id)
	var objective_id := str(current_step.get("id", ""))
	if objective_id.is_empty() or completed_ids.has(objective_id):
		push_warning("Active mission objective state is invalid or already completed.")
		return {}
	completed_ids.append(objective_id)
	active_mission["completed_objectives"] = completed_ids

	var total_steps := steps.size()
	if current_index + 1 < total_steps:
		active_mission["objective_index"] = current_index + 1
		GameState.current_mission = active_mission.duplicate(true)
		mission_changed.emit(active_mission.duplicate(true))
		return {
			"completed": false,
			"objective": current_step.duplicate(true),
			"index": current_index + 1,
			"total": total_steps
		}

	active_mission["status"] = "completed"
	active_mission["completed_at"] = Time.get_datetime_string_from_system()
	var title_key := "title_en" if language_code == "en" else "title_fa"
	var actions: Array[String] = []
	for step: Dictionary in steps:
		actions.append(str(step.get(title_key, step.get("title_fa", ""))))
	var description_key := "description_en" if language_code == "en" else "description_fa"
	var report := {
		"case_id": "CITY-%06d" % (GameState.reports.size() + 1),
		"event_type": str(active_mission.get("type", "city_service")),
		"location": active_mission.get("location", []),
		"description": str(active_mission.get(description_key, "")),
		"actions": actions,
		"objective_ids": completed_ids,
		"result": "resolved",
		"mission_id": active_mission.get("id", ""),
		"timestamp": active_mission.get("completed_at", "")
	}
	GameState.add_report(report)
	GameState.add_mission_result(int(active_mission.get("reward", 100)), int(active_mission.get("trust", 2)))
	active = false
	GameState.current_mission.clear()
	var finished := active_mission.duplicate(true)
	mission_completed.emit(finished, report)
	active_mission.clear()
	return {
		"completed": true,
		"objective": current_step.duplicate(true),
		"index": current_index + 1,
		"total": total_steps,
		"report": report
	}

func complete_active_mission(position: Vector3) -> Dictionary:
	var result := advance_active_objective(position)
	if bool(result.get("completed", false)):
		var report: Variant = result.get("report", {})
		return report if report is Dictionary else {}
	return {}
