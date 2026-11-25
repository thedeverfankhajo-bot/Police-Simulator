extends RefCounted
## Builds static ground, navigation surface and public-park dressing.

static func build(world: Node3D) -> void:
	_add_box(world, "CityGround", Vector3(0, -0.28, 0), Vector3(220, 0.5, 220), _material(Color(0.17, 0.29, 0.19), 0.98), true)
	var navigation_region := NavigationRegion3D.new()
	navigation_region.name = "CityNavigationRegion"
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.vertices = PackedVector3Array([Vector3(-105, 0, -105), Vector3(105, 0, -105), Vector3(105, 0, 105), Vector3(-105, 0, 105)])
	navigation_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	navigation_region.navigation_mesh = navigation_mesh
	world.add_child(navigation_region)
	_build_public_park(world)

static func _build_public_park(world: Node3D) -> void:
	_add_box(world, "PublicParkLawn", Vector3(-25, 0.04, 25), Vector3(37, 0.18, 37), _material(Color(0.24, 0.38, 0.24), 0.98))
	var concrete := _material(Color(0.5, 0.53, 0.52), 0.9)
	_add_box(world, "ParkWalkwayNorthSouth", Vector3(-25, 0.15, 25), Vector3(2, 0.2, 31), concrete)
	_add_box(world, "ParkWalkwayEastWest", Vector3(-25, 0.16, 25), Vector3(31, 0.2, 2), concrete)
	_add_box(world, "ParkWaterFeature", Vector3(-25, 0.28, 25), Vector3(5, 0.22, 5), _material(Color(0.12, 0.4, 0.49), 0.2))
	for tree_position: Vector3 in [Vector3(-38, 0, 11), Vector3(-13, 0, 11), Vector3(-38, 0, 39), Vector3(-13, 0, 39), Vector3(-25, 0, 8), Vector3(-8, 0, 25)]:
		_add_tree(world, tree_position)
	_add_bench(world, Vector3(-31, 0.2, 25))
	_add_bench(world, Vector3(-19, 0.2, 25))
	_add_sign(world, Vector3(-25, 2.4, 6), "NORTH PARK", Color(0.3, 0.6, 0.39))

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

static func _add_tree(parent: Node3D, position: Vector3) -> void:
	_add_box(parent, "ParkTreeTrunk", position + Vector3(0, 1, 0), Vector3(0.38, 2, 0.38), _material(Color(0.23, 0.15, 0.09), 0.9))
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.45
	sphere.height = 2.7
	crown.mesh = sphere
	crown.material_override = _material(Color(0.14, 0.3, 0.17), 0.94)
	crown.position = position + Vector3(0, 2.65, 0)
	parent.add_child(crown)

static func _add_bench(parent: Node3D, position: Vector3) -> void:
	var wood := _material(Color(0.35, 0.22, 0.12), 0.78)
	var metal := _material(Color(0.11, 0.15, 0.17), 0.58)
	_add_box(parent, "ParkBenchSeat", position + Vector3(0, 0.65, 0), Vector3(2.1, 0.14, 0.52), wood)
	_add_box(parent, "ParkBenchBack", position + Vector3(0, 1.05, -0.2), Vector3(2.1, 0.78, 0.12), wood)
	_add_box(parent, "ParkBenchLegLeft", position + Vector3(-0.8, 0.32, 0), Vector3(0.14, 0.7, 0.48), metal)
	_add_box(parent, "ParkBenchLegRight", position + Vector3(0.8, 0.32, 0), Vector3(0.14, 0.7, 0.48), metal)

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
