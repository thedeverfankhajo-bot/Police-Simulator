extends Node

signal weather_changed(name: String, label_key: String)

var weather_index: int = 0
var elapsed: float = 0.0
var day_time: float = 10.0
var sun: DirectionalLight3D
var environment: WorldEnvironment
var rain_particles: GPUParticles3D
var fog_density: float = 0.003
@export_range(0.05, 2.0, 0.05) var wetness_transition_speed: float = 0.8
var surface_wetness: float = 0.0
var _target_surface_wetness: float = 0.0
@export_range(0.0, 23.5, 0.5) var street_lights_on_hour: float = 18.5
@export_range(0.0, 23.5, 0.5) var street_lights_off_hour: float = 6.0
@export_range(0.1, 4.0, 0.05) var street_light_energy: float = 1.35
var _street_lighting_enabled: bool = false

const WEATHER := [
	{"name":"sunny","key":"weather_sunny","energy":1.05,"fog":0.001,"rain":false,"wetness":0.0},
	{"name":"cloudy","key":"weather_cloudy","energy":0.72,"fog":0.004,"rain":false,"wetness":0.08},
	{"name":"rain","key":"weather_rain","energy":0.48,"fog":0.012,"rain":true,"wetness":0.94},
	{"name":"fog","key":"weather_fog","energy":0.38,"fog":0.028,"rain":false,"wetness":0.28}
]

func _ready() -> void:
	add_to_group("weather_managers")

func configure(light: DirectionalLight3D, world: WorldEnvironment, particles: GPUParticles3D) -> void:
	sun = light
	environment = world
	rain_particles = particles
	_apply_weather()
	_update_street_lighting()

func _process(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	elapsed += delta
	day_time = fposmod(day_time + delta * 0.025, 24.0)
	_update_street_lighting()
	var next_wetness := move_toward(surface_wetness, _target_surface_wetness, wetness_transition_speed * delta)
	if not is_equal_approx(next_wetness, surface_wetness):
		surface_wetness = next_wetness
		_apply_surface_wetness(surface_wetness)
	if sun:
		var angle := (day_time / 24.0) * TAU - PI * 0.5
		sun.rotation.x = angle
		var daylight := clampf(sin(angle), 0.08, 1.0)
		sun.light_energy = float(WEATHER[weather_index]["energy"]) * daylight
	if environment and environment.environment:
		var darkness := clampf(1.0 - maxf(sin((day_time / 24.0) * TAU), 0.0), 0.0, 1.0)
		environment.environment.ambient_light_energy = lerpf(0.6, 0.18, darkness)

func _update_street_lighting() -> void:
	if not is_inside_tree():
		return
	var night_duration := fposmod(street_lights_off_hour - street_lights_on_hour, 24.0)
	var elapsed_since_on := fposmod(day_time - street_lights_on_hour, 24.0)
	var should_be_enabled := night_duration > 0.0 and elapsed_since_on < night_duration
	if should_be_enabled == _street_lighting_enabled:
		return
	_street_lighting_enabled = should_be_enabled
	var target_energy := street_light_energy if should_be_enabled else 0.0
	for candidate: Node in get_tree().get_nodes_in_group("street_lights"):
		var lamp := candidate as OmniLight3D
		if lamp != null:
			lamp.light_energy = target_energy

func cycle_weather() -> void:
	weather_index = (weather_index + 1) % WEATHER.size()
	_apply_weather()
	weather_changed.emit(str(WEATHER[weather_index]["name"]), str(WEATHER[weather_index]["key"]))

func _apply_weather() -> void:
	if environment and environment.environment:
		environment.environment.fog_enabled = float(WEATHER[weather_index]["fog"]) > 0.01
		environment.environment.fog_density = float(WEATHER[weather_index]["fog"])
		environment.environment.ambient_light_energy = float(WEATHER[weather_index]["energy"])
	if rain_particles:
		rain_particles.emitting = bool(WEATHER[weather_index]["rain"])
	_target_surface_wetness = clampf(float(WEATHER[weather_index]["wetness"]), 0.0, 1.0)
	if is_equal_approx(surface_wetness, _target_surface_wetness):
		_apply_surface_wetness(surface_wetness)

func register_surface(surface: Node) -> void:
	if not is_instance_valid(surface) or not surface.has_method("set_surface_wetness"):
		return
	surface.call("set_surface_wetness", surface_wetness)

func _apply_surface_wetness(value: float) -> void:
	if not is_inside_tree():
		return
	get_tree().call_group("weather_sensitive_surfaces", "set_surface_wetness", clampf(value, 0.0, 1.0))
