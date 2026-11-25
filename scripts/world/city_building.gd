class_name CityBuilding
extends StaticBody3D

const MIN_WIDTH := 6.0
const MIN_HEIGHT := 7.0
const MIN_DEPTH := 6.0
const MAX_WIDTH := 40.0
const MAX_HEIGHT := 48.0
const MAX_DEPTH := 40.0

var _dimensions := Vector3(14.0, 12.0, 14.0)
var _facade_color := Color(0.48, 0.52, 0.55)
var _district_label := "CITY"
var _variant := 0
var _configured := false
var _built := false

func configure(dimensions: Vector3, facade_color: Color, district_label: String, variant: int = 0) -> void:
	if _built:
		push_warning("CityBuilding cannot be reconfigured after geometry has been built.")
		return
	if not _valid_dimensions(dimensions):
		push_error("CityBuilding received invalid dimensions.")
		return
	_dimensions = Vector3(clampf(dimensions.x, MIN_WIDTH, MAX_WIDTH), clampf(dimensions.y, MIN_HEIGHT, MAX_HEIGHT), clampf(dimensions.z, MIN_DEPTH, MAX_DEPTH))
	_facade_color = facade_color
	_district_label = district_label.strip_edges()
	if _district_label.is_empty():
		_district_label = "CITY"
	_variant = posmod(variant, 3)
	_configured = true

func _ready() -> void:
	_build_geometry()

func _valid_dimensions(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z) and value.x > 0.0 and value.y > 0.0 and value.z > 0.0

func _build_geometry() -> void:
	if _built:
		return
	_built = true
	if not _configured:
		push_warning("CityBuilding is using its safe default configuration.")
	var architecture := Node3D.new()
	architecture.name = "Architecture"
	add_child(architecture)
	var wall := _material(_facade_color, 0.88)
	var base := _material(_facade_color.darkened(0.28), 0.92)
	var trim := _material(_facade_color.darkened(0.42), 0.62, 0.18)
	var glass := _material(Color(0.045, 0.12, 0.17), 0.2, 0.12)
	var door := _material(Color(0.025, 0.065, 0.085), 0.24, 0.08)
	var accent := _material(_facade_color.lightened(0.18), 0.7, 0.12)
	_add_box(architecture, "Foundation", Vector3(0, 0.16, 0), Vector3(_dimensions.x + 0.48, 0.32, _dimensions.z + 0.48), base)
	_add_box(architecture, "MainVolume", Vector3(0, _dimensions.y * 0.5, 0), _dimensions, wall)

	var floor_count := maxi(1, int(floor((_dimensions.y - 1.6) / 2.8)))
	var north: Array[Vector3] = []
	var south: Array[Vector3] = []
	var east: Array[Vector3] = []
	var west: Array[Vector3] = []
	for floor_index in range(floor_count):
		var window_y := 2.0 + float(floor_index) * 2.8
		if window_y > _dimensions.y - 0.8:
			continue
		for column in range(2):
			var x := -_dimensions.x * 0.25 + float(column) * _dimensions.x * 0.5
			var z := -_dimensions.z * 0.25 + float(column) * _dimensions.z * 0.5
			north.append(Vector3(x, window_y, -_dimensions.z * 0.5 - 0.055))
			south.append(Vector3(x, window_y, _dimensions.z * 0.5 + 0.055))
			east.append(Vector3(_dimensions.x * 0.5 + 0.055, window_y, z))
			west.append(Vector3(-_dimensions.x * 0.5 - 0.055, window_y, z))
	_add_windows(architecture, "FacadeWindowsNorth", Vector3(_dimensions.x * 0.18, 1.25, 0.09), north, glass)
	_add_windows(architecture, "FacadeWindowsSouth", Vector3(_dimensions.x * 0.18, 1.25, 0.09), south, glass)
	_add_windows(architecture, "FacadeWindowsEast", Vector3(0.09, 1.25, _dimensions.z * 0.18), east, glass)
	_add_windows(architecture, "FacadeWindowsWest", Vector3(0.09, 1.25, _dimensions.z * 0.18), west, glass)

	var half_x := _dimensions.x * 0.5
	var half_z := _dimensions.z * 0.5
	_add_box(architecture, "NorthSill", Vector3(0, 0.55, -half_z - 0.06), Vector3(_dimensions.x + 0.12, 0.16, 0.14), accent)
	_add_box(architecture, "SouthSill", Vector3(0, 0.55, half_z + 0.06), Vector3(_dimensions.x + 0.12, 0.16, 0.14), accent)
	_add_box(architecture, "EastSill", Vector3(half_x + 0.06, 0.55, 0), Vector3(0.14, 0.16, _dimensions.z + 0.12), accent)
	_add_box(architecture, "WestSill", Vector3(-half_x - 0.06, 0.55, 0), Vector3(0.14, 0.16, _dimensions.z + 0.12), accent)
	_add_box(architecture, "EntranceFrame", Vector3(0, 1.3, -half_z - 0.095), Vector3(1.82, 2.6, 0.18), trim)
	_add_box(architecture, "EntranceDoor", Vector3(0, 1.27, -half_z - 0.2), Vector3(1.42, 2.32, 0.08), door)
	_add_box(architecture, "EntranceGlass", Vector3(0, 1.34, -half_z - 0.245), Vector3(0.82, 1.55, 0.025), glass)

	if _variant == 0:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_add_box(architecture, "CornerPilaster_%s_%s" % [str(sx), str(sz)], Vector3(sx * (half_x - 0.16), _dimensions.y * 0.5, sz * (half_z - 0.16)), Vector3(0.24, _dimensions.y, 0.24), accent)
	elif _variant == 1:
		for floor_index in range(1, floor_count):
			var band_y := 0.9 + float(floor_index) * 2.8
			_add_box(architecture, "NorthBelt_%02d" % floor_index, Vector3(0, band_y, -half_z - 0.07), Vector3(_dimensions.x + 0.14, 0.12, 0.14), accent)
			_add_box(architecture, "SouthBelt_%02d" % floor_index, Vector3(0, band_y, half_z + 0.07), Vector3(_dimensions.x + 0.14, 0.12, 0.14), accent)
			_add_box(architecture, "EastBelt_%02d" % floor_index, Vector3(half_x + 0.07, band_y, 0), Vector3(0.14, 0.12, _dimensions.z + 0.14), accent)
			_add_box(architecture, "WestBelt_%02d" % floor_index, Vector3(-half_x - 0.07, band_y, 0), Vector3(0.14, 0.12, _dimensions.z + 0.14), accent)
	else:
		_add_box(architecture, "StorefrontCanopy", Vector3(0, 2.65, -half_z - 0.34), Vector3(2.6, 0.18, 0.72), accent)
		_add_box(architecture, "CanopySupportLeft", Vector3(-1.12, 1.85, -half_z - 0.25), Vector3(0.09, 1.55, 0.09), trim)
		_add_box(architecture, "CanopySupportRight", Vector3(1.12, 1.85, -half_z - 0.25), Vector3(0.09, 1.55, 0.09), trim)

	var roof_y := _dimensions.y + 0.22
	_add_box(architecture, "RoofParapetNorth", Vector3(0, roof_y, -half_z), Vector3(_dimensions.x + 0.18, 0.44, 0.18), trim)
	_add_box(architecture, "RoofParapetSouth", Vector3(0, roof_y, half_z), Vector3(_dimensions.x + 0.18, 0.44, 0.18), trim)
	_add_box(architecture, "RoofParapetEast", Vector3(half_x, roof_y, 0), Vector3(0.18, 0.44, _dimensions.z + 0.18), trim)
	_add_box(architecture, "RoofParapetWest", Vector3(-half_x, roof_y, 0), Vector3(0.18, 0.44, _dimensions.z + 0.18), trim)
	_add_box(architecture, "RoofVentA", Vector3(-_dimensions.x * 0.22, _dimensions.y + 0.72, _dimensions.z * 0.14), Vector3(1.8, 0.6, 1.35), base)
	_add_box(architecture, "RoofVentB", Vector3(_dimensions.x * 0.2, _dimensions.y + 0.62, -_dimensions.z * 0.16), Vector3(1.2, 0.42, 0.95), base)
	_add_box(architecture, "RoofDuct", Vector3(0, _dimensions.y + 0.52, 0), Vector3(0.24, 0.32, _dimensions.z * 0.48), trim)
	var sign := Label3D.new()
	sign.name = "DistrictSign"
	sign.text = _district_label
	sign.font_size = 22
	sign.pixel_size = 0.008
	sign.position = Vector3(0, minf(_dimensions.y - 1.0, 4.8), -half_z - 0.16)
	architecture.add_child(sign)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(_dimensions.x, _dimensions.y + 0.7, _dimensions.z)
	collision.shape = shape
	collision.position = Vector3(0, _dimensions.y * 0.5 + 0.35, 0)
	add_child(collision)

func _add_windows(parent: Node3D, node_name: String, window_size: Vector3, positions: Array[Vector3], material: Material) -> void:
	if positions.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = window_size
	var batches := MultiMesh.new()
	batches.transform_format = MultiMesh.TRANSFORM_3D
	batches.mesh = mesh
	batches.instance_count = positions.size()
	for index in range(positions.size()):
		batches.set_instance_transform(index, Transform3D(Basis.IDENTITY, positions[index]))
	var windows := MultiMeshInstance3D.new()
	windows.name = node_name
	windows.multimesh = batches
	windows.material_override = material
	windows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(windows)

func _add_box(parent: Node3D, node_name: String, local_position: Vector3, dimensions: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	visual.material_override = material
	visual.position = local_position
	parent.add_child(visual)

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
