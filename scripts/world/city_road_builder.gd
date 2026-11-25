extends RefCounted
## Builds the reusable road, intersection-control and street-light components.

const ROAD_SCENE: PackedScene = preload("res://scenes/city/city_road_segment.tscn")
const SIGNAL_SCENE: PackedScene = preload("res://scenes/city/traffic_signal.tscn")
const STREET_LIGHT_SCENE: PackedScene = preload("res://scenes/city/city_street_light.tscn")

static func build(world: Node3D) -> void:
	_build_road_grid(world)
	_build_intersection_signals(world)
	_build_street_lights(world)
	_build_roadside_posts(world)

static func _build_road_grid(world: Node3D) -> void:
	for coordinate: float in [-100.0, -50.0, 0.0, 50.0, 100.0]:
		var width := 10.0 if is_zero_approx(coordinate) else 7.5
		_add_road(world, Vector3(coordinate, 0, 0), width, CityRoadSegment.Axis.NORTH_SOUTH)
		_add_road(world, Vector3(0, 0, coordinate), width, CityRoadSegment.Axis.EAST_WEST)

static func _add_road(world: Node3D, position: Vector3, width: float, orientation: CityRoadSegment.Axis) -> void:
	var segment := ROAD_SCENE.instantiate() as CityRoadSegment
	if segment == null:
		push_error("City road segment scene could not be instantiated.")
		return
	segment.name = "RoadSegment_%s_%s" % [str(orientation), str(int(absf(position.x + position.z)))]
	segment.position = position
	segment.configure(width, 220.0, orientation)
	segment.add_to_group("city_road_segments")
	world.add_child(segment)

static func _build_intersection_signals(world: Node3D) -> void:
	var positions: Array[Vector3] = [Vector3(0, 0.2, 0), Vector3(50, 0.2, 0), Vector3(-50, 0.2, 0), Vector3(0, 0.2, 50), Vector3(0, 0.2, -50)]
	for index in range(positions.size()):
		var node := SIGNAL_SCENE.instantiate() as TrafficSignalController
		if node == null:
			push_error("Traffic signal scene could not be instantiated.")
			continue
		node.name = "TrafficSignal_%03d" % (index + 1)
		node.position = positions[index]
		node.add_to_group("city_traffic_signals")
		world.add_child(node)

static func _build_street_lights(world: Node3D) -> void:
	var positions: Array[Vector3] = [Vector3(-10, 0, 17), Vector3(10, 0, 17), Vector3(49, 0, -16), Vector3(-49, 0, 16), Vector3(15, 0, -50), Vector3(-15, 0, 50)]
	for index in range(positions.size()):
		var node := STREET_LIGHT_SCENE.instantiate() as CityStreetLight
		if node == null:
			push_error("City street light scene could not be instantiated.")
			continue
		node.name = "StreetLight_%02d" % (index + 1)
		node.position = positions[index]
		node.add_to_group("city_street_lights")
		world.add_child(node)

static func _build_roadside_posts(world: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.24, 0.25)
	material.roughness = 0.82
	for position: Vector3 in [Vector3(12, 0, 12), Vector3(-12, 0, -12), Vector3(58, 0, -12), Vector3(-58, 0, 12)]:
		var post := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.65, 1, 0.65)
		post.mesh = mesh
		post.material_override = material
		post.position = position + Vector3(0, 0.5, 0)
		world.add_child(post)
