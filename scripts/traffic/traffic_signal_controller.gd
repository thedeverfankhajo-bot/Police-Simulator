class_name TrafficSignalController
extends Node3D

enum Phase {
	NORTH_SOUTH_GREEN,
	NORTH_SOUTH_AMBER,
	ALL_RED_TO_EAST_WEST,
	EAST_WEST_GREEN,
	EAST_WEST_AMBER,
	ALL_RED_TO_NORTH_SOUTH
}

signal phase_changed(phase: int)

@export_range(2.0, 60.0, 0.5) var green_duration: float = 12.0
@export_range(0.5, 10.0, 0.5) var amber_duration: float = 2.0
@export_range(0.5, 5.0, 0.5) var all_red_duration: float = 1.0
@export_range(4.0, 20.0, 0.5) var stop_distance: float = 12.0
@export_range(2.0, 8.0, 0.5) var approach_half_width: float = 5.5

var current_phase: int = Phase.NORTH_SOUTH_GREEN
var _phase_elapsed: float = 0.0
var _north_south_lamp: MeshInstance3D
var _east_west_lamp: MeshInstance3D

func _ready() -> void:
	add_to_group("traffic_lights")
	_build_visuals()
	var cycle_duration := _cycle_duration()
	_phase_elapsed = fposmod(absf(global_position.x * 0.37 + global_position.z * 0.23), cycle_duration)
	while _phase_elapsed >= _duration_for_phase(current_phase):
		_phase_elapsed -= _duration_for_phase(current_phase)
		_advance_phase()
	_refresh_lamps()

func _process(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	_phase_elapsed += delta
	var phase_advanced := false
	while _phase_elapsed >= _duration_for_phase(current_phase):
		_phase_elapsed -= _duration_for_phase(current_phase)
		_advance_phase()
		phase_advanced = true
	if phase_advanced:
		_refresh_lamps()

func should_stop_for(vehicle_position: Vector3, vehicle_forward: Vector3) -> bool:
	var forward_2d := Vector2(vehicle_forward.x, vehicle_forward.z)
	if forward_2d.length_squared() <= 0.0001:
		return false
	forward_2d = forward_2d.normalized()

	var intersection_offset := Vector2(
		global_position.x - vehicle_position.x,
		global_position.z - vehicle_position.z
	)
	var approach_distance := intersection_offset.dot(forward_2d)
	if approach_distance <= 0.5 or approach_distance > stop_distance:
		return false

	var lateral_distance := absf(
		forward_2d.x * intersection_offset.y -
		forward_2d.y * intersection_offset.x
	)
	if lateral_distance > approach_half_width:
		return false

	var is_north_south := absf(forward_2d.y) >= absf(forward_2d.x)
	var permitted_phase: int = Phase.NORTH_SOUTH_GREEN if is_north_south else Phase.EAST_WEST_GREEN
	return current_phase != permitted_phase

func _cycle_duration() -> float:
	return maxf(green_duration, 0.5) * 2.0 + maxf(amber_duration, 0.5) * 2.0 + maxf(all_red_duration, 0.5) * 2.0

func _duration_for_phase(phase: int) -> float:
	match phase:
		Phase.NORTH_SOUTH_GREEN, Phase.EAST_WEST_GREEN:
			return maxf(green_duration, 0.5)
		Phase.NORTH_SOUTH_AMBER, Phase.EAST_WEST_AMBER:
			return maxf(amber_duration, 0.5)
		Phase.ALL_RED_TO_EAST_WEST, Phase.ALL_RED_TO_NORTH_SOUTH:
			return maxf(all_red_duration, 0.5)
	return maxf(green_duration, 0.5)

func _advance_phase() -> void:
	current_phase = (current_phase + 1) % 6
	phase_changed.emit(current_phase)

func _build_visuals() -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.07
	pole_mesh.bottom_radius = 0.11
	pole_mesh.height = 6.0
	pole.mesh = pole_mesh
	pole.position = Vector3(5.8, 3.0, 5.8)
	pole.material_override = _material(Color(0.075, 0.09, 0.10), 0.7)
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pole)

	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(1.05, 1.55, 0.42)
	head.mesh = head_mesh
	head.position = Vector3(5.8, 5.3, 5.8)
	head.material_override = _material(Color(0.025, 0.035, 0.04), 0.55)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(head)

	_north_south_lamp = _create_lamp("NorthSouthLamp", Vector3(5.52, 5.48, 5.55))
	_east_west_lamp = _create_lamp("EastWestLamp", Vector3(6.08, 5.48, 5.55))

func _create_lamp(lamp_name: String, local_position: Vector3) -> MeshInstance3D:
	var lamp := MeshInstance3D.new()
	lamp.name = lamp_name
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	lamp.mesh = sphere
	lamp.position = local_position
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lamp)
	return lamp

func _refresh_lamps() -> void:
	var north_south_color := Color(0.12, 0.78, 0.25)
	if current_phase == Phase.NORTH_SOUTH_AMBER:
		north_south_color = Color(1.0, 0.55, 0.08)
	elif current_phase != Phase.NORTH_SOUTH_GREEN:
		north_south_color = Color(0.88, 0.08, 0.07)

	var east_west_color := Color(0.12, 0.78, 0.25)
	if current_phase == Phase.EAST_WEST_AMBER:
		east_west_color = Color(1.0, 0.55, 0.08)
	elif current_phase != Phase.EAST_WEST_GREEN:
		east_west_color = Color(0.88, 0.08, 0.07)

	_north_south_lamp.material_override = _emission_material(north_south_color)
	_east_west_lamp.material_override = _emission_material(east_west_color)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _emission_material(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.28)
	material.emission_enabled = true
	material.emission = color
	return material
