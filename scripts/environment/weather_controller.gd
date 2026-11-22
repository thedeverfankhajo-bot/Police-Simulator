extends Node

signal weather_changed(name: String, label_key: String)

var weather_index: int = 0
var elapsed: float = 0.0
var day_time: float = 10.0
var sun: DirectionalLight3D
var environment: WorldEnvironment
var rain_particles: GPUParticles3D
var fog_density: float = 0.003

const WEATHER := [
	{"name":"sunny","key":"weather_sunny","energy":1.05,"fog":0.001,"rain":false},
	{"name":"cloudy","key":"weather_cloudy","energy":0.72,"fog":0.004,"rain":false},
	{"name":"rain","key":"weather_rain","energy":0.48,"fog":0.012,"rain":true},
	{"name":"fog","key":"weather_fog","energy":0.38,"fog":0.028,"rain":false}
]

func configure(light: DirectionalLight3D, world: WorldEnvironment, particles: GPUParticles3D) -> void:
	sun = light
	environment = world
	rain_particles = particles
	_apply_weather()

func _process(delta: float) -> void:
	elapsed += delta
	day_time = fposmod(day_time + delta * 0.025, 24.0)
	if sun:
		var angle := (day_time / 24.0) * TAU - PI * 0.5
		sun.rotation.x = angle
		var daylight := clampf(sin(angle), 0.08, 1.0)
		sun.light_energy = float(WEATHER[weather_index]["energy"]) * daylight
	if environment and environment.environment:
		var darkness := clampf(1.0 - maxf(sin((day_time / 24.0) * TAU), 0.0), 0.0, 1.0)
		environment.environment.ambient_light_energy = lerpf(0.6, 0.18, darkness)

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
