extends Node

signal stats_changed
signal report_added(report: Dictionary)

var score: int = 0
var experience: int = 0
var level: int = 1
var public_trust: int = 65
var missions_completed: int = 0
var reports: Array[Dictionary] = []
var unlocked_vehicles: Array[String] = ["patrol_sedan"]
var current_mission: Dictionary = {}
var mission_index: int = 0
var play_seconds: float = 0.0

func add_mission_result(reward: int, trust_delta: int) -> void:
	score += maxi(0, reward)
	experience += maxi(0, reward)
	level = 1 + int(experience / 500)
	public_trust = clampi(public_trust + trust_delta, 0, 100)
	missions_completed += 1
	stats_changed.emit()

func add_report(report: Dictionary) -> void:
	var safe_report := report.duplicate(true)
	safe_report["case_id"] = str(safe_report.get("case_id", "CITY-%06d" % (reports.size() + 1)))
	safe_report["timestamp"] = str(safe_report.get("timestamp", Time.get_datetime_string_from_system()))
	reports.append(safe_report)
	if reports.size() > 200:
		reports.pop_front()
	report_added.emit(safe_report)

func register_citizen_contact() -> void:
	public_trust = clampi(public_trust + 1, 0, 100)
	stats_changed.emit()

func apply_save(data: Dictionary) -> void:
	score = maxi(0, int(data.get("score", score)))
	experience = maxi(0, int(data.get("experience", experience)))
	level = clampi(int(data.get("level", 1)), 1, 99)
	public_trust = clampi(int(data.get("public_trust", 65)), 0, 100)
	missions_completed = maxi(0, int(data.get("missions_completed", 0)))
	mission_index = clampi(int(data.get("mission_index", 0)), 0, 1000)
	var saved_mission: Variant = data.get("current_mission", {})
	current_mission = saved_mission.duplicate(true) if saved_mission is Dictionary else {}
	play_seconds = maxf(0.0, float(data.get("play_seconds", 0.0)))
	reports.clear()
	var saved_reports: Variant = data.get("reports", [])
	if saved_reports is Array:
		for item: Variant in saved_reports:
			if item is Dictionary and reports.size() < 200:
				reports.append(item.duplicate(true))
	stats_changed.emit()
