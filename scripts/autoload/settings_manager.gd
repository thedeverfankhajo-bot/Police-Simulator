extends Node

signal settings_changed

const SETTINGS_PATH := "user://police_simulator_settings.cfg"
const SETTINGS_VERSION := 1
const QUALITY_LEVELS: Array[String] = ["performance", "balanced", "quality"]
const QUALITY_PRESETS: Dictionary = {
	"performance": {
		"render_scale": 0.82,
		"shadows_enabled": false,
		"shadow_distance": 55.0
	},
	"balanced": {
		"render_scale": 1.0,
		"shadows_enabled": true,
		"shadow_distance": 90.0
	},
	"quality": {
		"render_scale": 1.12,
		"shadows_enabled": true,
		"shadow_distance": 130.0
	}
}

var graphics_quality: String = "balanced"
var sensitivity_scale: float = 1.0

var _world_environment: WorldEnvironment
var _sun: DirectionalLight3D
var _player_target: Node
var _vehicle_target: Node

func _ready() -> void:
	if FileAccess.file_exists(SETTINGS_PATH) and not load_settings():
		push_warning("User settings could not be loaded; safe defaults remain active.")

func configure_world(world_environment: WorldEnvironment, sun: DirectionalLight3D) -> void:
	_world_environment = world_environment
	_sun = sun
	_apply_graphics_profile()

func configure_camera_targets(player: Node, vehicle: Node) -> void:
	_player_target = player
	_vehicle_target = vehicle
	_apply_camera_sensitivity()

func get_quality_index() -> int:
	return maxi(0, QUALITY_LEVELS.find(graphics_quality))

func get_quality_name(index: int) -> String:
	if index < 0 or index >= QUALITY_LEVELS.size():
		return ""
	return QUALITY_LEVELS[index]

func set_graphics_quality(quality: String) -> bool:
	if not QUALITY_PRESETS.has(quality):
		return false
	if graphics_quality == quality:
		return true
	graphics_quality = quality
	_apply_graphics_profile()
	settings_changed.emit()
	return save_settings()

func set_sensitivity_scale(value: float, persist: bool = true) -> bool:
	if not is_finite(value) or value < 0.5 or value > 1.5:
		return false
	if is_equal_approx(sensitivity_scale, value):
		return true
	sensitivity_scale = value
	_apply_camera_sensitivity()
	settings_changed.emit()
	return save_settings() if persist else true

func save_settings(path: String = SETTINGS_PATH) -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SETTINGS_VERSION)
	config.set_value("graphics", "quality", graphics_quality)
	config.set_value("controls", "sensitivity_scale", sensitivity_scale)
	var error := config.save(path)
	if error != OK:
		push_warning("User settings could not be saved: %s" % error_string(error))
		return false
	return true

func load_settings(path: String = SETTINGS_PATH) -> bool:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		return false
	var version: Variant = config.get_value("meta", "version", null)
	var quality: Variant = config.get_value("graphics", "quality", null)
	var sensitivity: Variant = config.get_value("controls", "sensitivity_scale", null)
	if not (version is int or version is float) or not is_equal_approx(float(version), float(SETTINGS_VERSION)):
		return false
	if not quality is String or not QUALITY_PRESETS.has(quality):
		return false
	if not (sensitivity is int or sensitivity is float):
		return false
	var numeric_sensitivity := float(sensitivity)
	if not is_finite(numeric_sensitivity) or numeric_sensitivity < 0.5 or numeric_sensitivity > 1.5:
		return false
	graphics_quality = quality
	sensitivity_scale = numeric_sensitivity
	_apply_graphics_profile()
	_apply_camera_sensitivity()
	settings_changed.emit()
	return true

func get_graphics_summary(language_code: String = "fa") -> String:
	if language_code == "en":
		return "Graphics settings apply immediately. High Quality uses 1.12x supersampling and longer sun-shadow distance; actual frame rate depends on the PC."
	return "تنظیمات گرافیکی فوراً اعمال می‌شوند. کیفیت بالا از نمونه‌برداری ۱٫۱۲ برابری و فاصلهٔ بیشتر سایهٔ خورشید استفاده می‌کند؛ نرخ فریم به سخت‌افزار PC بستگی دارد."

func _apply_graphics_profile() -> void:
	var profile: Dictionary = QUALITY_PRESETS.get(graphics_quality, QUALITY_PRESETS["balanced"])
	var viewport := get_viewport()
	if viewport != null:
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		viewport.scaling_3d_scale = float(profile["render_scale"])
	if is_instance_valid(_sun):
		_sun.shadow_enabled = bool(profile["shadows_enabled"])
		_sun.directional_shadow_max_distance = float(profile["shadow_distance"])

func _apply_camera_sensitivity() -> void:
	if is_instance_valid(_player_target) and _player_target.has_method("set_camera_sensitivity"):
		_player_target.call("set_camera_sensitivity", 0.0025 * sensitivity_scale)
	if is_instance_valid(_vehicle_target) and _vehicle_target.has_method("set_camera_sensitivity"):
		_vehicle_target.call("set_camera_sensitivity", 0.0022 * sensitivity_scale)
