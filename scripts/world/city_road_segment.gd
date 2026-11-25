class_name CityRoadSegment
extends Node3D

enum Axis { NORTH_SOUTH, EAST_WEST }

const ASPHALT_SHADER: Shader = preload("res://shaders/asphalt_surface.gdshader")

@export_range(4.0, 20.0, 0.5) var road_width: float = 8.0
@export_range(40.0, 400.0, 1.0) var segment_length: float = 220.0
@export_range(2.0, 5.0, 0.25) var sidewalk_width: float = 3.0
@export_range(6.0, 24.0, 1.0) var dash_spacing: float = 12.0
@export var axis: Axis = Axis.NORTH_SOUTH

var _built: bool = false
var _asphalt_material: ShaderMaterial

func configure(width: float, length: float, orientation: Axis) -> void:
	if _built or is_inside_tree():
		push_warning("CityRoadSegment cannot be reconfigured after it enters the scene tree.")
		return
	if not is_finite(width) or not is_finite(length) or width <= 0.0 or length <= 0.0:
		push_error("CityRoadSegment requires finite, positive dimensions.")
		return
	road_width = clampf(width, 4.0, 20.0)
	segment_length = clampf(length, 40.0, 400.0)
	axis = orientation

func _ready() -> void:
	add_to_group("weather_sensitive_surfaces")
	_build_geometry()
	for candidate: Node in get_tree().get_nodes_in_group("weather_managers"):
		if is_instance_valid(candidate) and candidate.has_method("register_surface"):
			candidate.call("register_surface", self)
			break

func set_surface_wetness(value: float) -> void:
	if not is_finite(value) or _asphalt_material == null:
		return
	_asphalt_material.set_shader_parameter("wetness", clampf(value, 0.0, 1.0))

func _build_geometry() -> void:
	if _built:
		return
	_built = true

	if axis == Axis.EAST_WEST:
		rotation.y = PI * 0.5

	var road_mesh := PlaneMesh.new()
	road_mesh.size = Vector2(road_width, segment_length)
	road_mesh.subdivide_width = 1
	road_mesh.subdivide_depth = maxi(1, int(ceil(segment_length / 40.0)))

	_asphalt_material = ShaderMaterial.new()
	_asphalt_material.shader = ASPHALT_SHADER
	_asphalt_material.set_shader_parameter("surface_dimensions", Vector2(road_width, segment_length))
	_asphalt_material.set_shader_parameter("asphalt_color", Vector3(0.105, 0.12, 0.135))
	_asphalt_material.set_shader_parameter("wetness", 0.0)

	var surface := MeshInstance3D.new()
	surface.name = "RoadSurface"
	surface.mesh = road_mesh
	surface.material_override = _asphalt_material
	surface.position.y = 0.045
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)

	_build_curb_and_sidewalks()
	_build_lane_markings()

func _build_curb_and_sidewalks() -> void:
	var curb_material := _material(Color(0.28, 0.31, 0.32), 0.88)
	var sidewalk_material := _material(Color(0.43, 0.46, 0.46), 0.94)

	for side: float in [-1.0, 1.0]:
		var side_name := "Left" if side < 0.0 else "Right"
		_add_box(
			"Curb" + side_name,
			Vector3(side * (road_width * 0.5 + 0.08), 0.11, 0.0),
			Vector3(0.16, 0.20, segment_length),
			curb_material
		)
		_add_box(
			"Sidewalk" + side_name,
			Vector3(side * (road_width * 0.5 + sidewalk_width * 0.5), 0.08, 0.0),
			Vector3(sidewalk_width, 0.22, segment_length),
			sidewalk_material
		)

func _build_lane_markings() -> void:
	var center_material := _material(Color(0.82, 0.77, 0.62), 0.82)
	var edge_material := _material(Color(0.78, 0.81, 0.79), 0.84)

	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(0.13, 0.025, 4.2)
	var dash_batch := MultiMesh.new()
	dash_batch.transform_format = MultiMesh.TRANSFORM_3D
	dash_batch.mesh = dash_mesh
	dash_batch.instance_count = maxi(1, int(floor(segment_length / dash_spacing)))

	for index in range(dash_batch.instance_count):
		var local_z := -segment_length * 0.5 + dash_spacing * 0.5 + float(index) * dash_spacing
		dash_batch.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, local_z)))

	var center_line := MultiMeshInstance3D.new()
	center_line.name = "CenterLineDashes"
	center_line.multimesh = dash_batch
	center_line.material_override = center_material
	center_line.position.y = 0.078
	center_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(center_line)

	for side: float in [-1.0, 1.0]:
		_add_box(
			"EdgeLine" + ("Left" if side < 0.0 else "Right"),
			Vector3(side * (road_width * 0.5 - 0.30), 0.071, 0.0),
			Vector3(0.10, 0.025, segment_length),
			edge_material
		)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

func _add_box(node_name: String, local_position: Vector3, dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = material
	instance.position = local_position
	add_child(instance)
