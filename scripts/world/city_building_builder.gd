extends RefCounted
## Owns police headquarters shell construction; interiors can be composed as child scenes.

static func build_police_station(world: Node3D) -> void:
	var wall := _material(Color(0.57, 0.62, 0.64), 0.82)
	var trim := _material(Color(0.055, 0.14, 0.22), 0.54)
	_add_box(world, "PoliceStationFoundation", Vector3(20, 0.12, 28), Vector3(25, 0.28, 24), _material(Color(0.37, 0.4, 0.41), 0.9))
	_add_box(world, "PoliceStationWallWest", Vector3(7.8, 4, 28), Vector3(0.8, 8, 24), wall, true)
	_add_box(world, "PoliceStationWallEast", Vector3(32.2, 4, 28), Vector3(0.8, 8, 24), wall, true)
	_add_box(world, "PoliceStationWallNorth", Vector3(20, 4, 16), Vector3(25, 8, 0.8), wall, true)
	_add_box(world, "PoliceStationWallSouthWest", Vector3(12.1, 3.8, 40), Vector3(9.2, 7.6, 0.8), wall, true)
	_add_box(world, "PoliceStationWallSouthEast", Vector3(27.9, 3.8, 40), Vector3(9.2, 7.6, 0.8), wall, true)
	_add_box(world, "PoliceStationFrontTrim", Vector3(20, 0.25, 15.6), Vector3(26, 0.35, 1.2), trim)
	_add_box(world, "PoliceStationRearTrim", Vector3(20, 0.25, 40.4), Vector3(26, 0.35, 1.2), trim)
	_add_box(world, "PoliceStationRoof", Vector3(20, 7.9, 28), Vector3(25, 0.4, 24), trim)
	_add_sign(world, Vector3(20, 6.2, 15.1), "NORTH DISTRICT POLICE", Color(0.08, 0.28, 0.43))
	_add_box(world, "PoliceStationInteriorPartition", Vector3(20, 1.5, 20), Vector3(8, 3, 0.35), wall, true)
	_add_box(world, "PoliceStationDispatchDesk", Vector3(20, 0.75, 27), Vector3(4.2, 1.25, 1.5), trim)
	_add_box(world, "PoliceStationTerminalFrame", Vector3(20, 1.55, 27.3), Vector3(1.2, 0.9, 0.15), _material(Color(0.04, 0.11, 0.14), 0.25))
	_add_box(world, "PoliceStationTerminalScreen", Vector3(20, 1.66, 27.16), Vector3(1.06, 0.72, 0.04), _emission_material(Color(0.12, 0.55, 0.65)))
	_add_box(world, "PoliceStationParking", Vector3(27, 0.08, 49), Vector3(30, 0.18, 18), _material(Color(0.19, 0.23, 0.26), 0.92))
	for x: float in [18.0, 26.0, 34.0]:
		_add_box(world, "PoliceStationParkingLine", Vector3(x, 0.19, 48), Vector3(0.14, 0.04, 11), _material(Color(0.88, 0.82, 0.61), 0.86))

static func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
	parent.add_child(visual)
	if solid:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		body.position = position
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
		parent.add_child(body)
	return visual

static func _add_sign(parent: Node3D, position: Vector3, value: String, tint: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.font_size = 30
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint.lightened(0.55)
	label.position = position
	parent.add_child(label)

static func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

static func _emission_material(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.3)
	material.emission_enabled = true
	material.emission = color
	return material
