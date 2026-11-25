extends CharacterBody3D

const FOLLOW_DISTANCE: float = 8.0
const LANE_HALF_WIDTH: float = 2.4
const MIN_HEADING_ALIGNMENT: float = 0.75

var route: Array[Vector3] = []
var route_index: int = 0
var cruise_speed: float = 8.0
var _stopped: bool = false

func configure(points: Array[Vector3], color: Color, speed: float) -> void:
	route = points
	cruise_speed = speed
	_build(color)

func _ready() -> void:
	if route.is_empty():
		route = [global_position + Vector3(0, 0, -30), global_position + Vector3(0, 0, 30)]
	floor_snap_length = 0.2

func _build(color: Color) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 0.85, 3.4)
	collision.shape = shape
	collision.position.y = 0.65
	add_child(collision)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.7, 0.68, 3.4)
	body.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.45
	body.material_override = material
	body.position.y = 0.64
	add_child(body)
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.35, 0.62, 1.75)
	cabin.mesh = cabin_mesh
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.055, 0.16, 0.21)
	cabin.material_override = glass
	cabin.position = Vector3(0, 1.25, -0.12)
	add_child(cabin)

func _physics_process(delta: float) -> void:
	if route.size() < 2:
		return
	var target := route[route_index]
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 2.0:
		route_index = (route_index + 1) % route.size()
		target = route[route_index]
		offset = target - global_position
		offset.y = 0.0
	var direction := offset.normalized()
	_stopped = _nearby_vehicle_ahead(direction) or _red_light_nearby(global_position, direction)
	var speed := 0.0 if _stopped else cruise_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = -0.7
	if direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 2.0)
	move_and_slide()

func is_vehicle_ahead_in_lane(observer_position: Vector3, observer_forward: Vector3, other_position: Vector3, other_forward: Vector3) -> bool:
	var forward_2d := Vector2(observer_forward.x, observer_forward.z)
	var other_forward_2d := Vector2(other_forward.x, other_forward.z)
	if forward_2d.length_squared() <= 0.0001 or other_forward_2d.length_squared() <= 0.0001:
		return false

	forward_2d = forward_2d.normalized()
	other_forward_2d = other_forward_2d.normalized()
	if forward_2d.dot(other_forward_2d) < MIN_HEADING_ALIGNMENT:
		return false

	var offset_2d := Vector2(other_position.x - observer_position.x, other_position.z - observer_position.z)
	var longitudinal_distance := offset_2d.dot(forward_2d)
	if longitudinal_distance <= 0.0 or longitudinal_distance > FOLLOW_DISTANCE:
		return false

	var lateral_distance := absf(forward_2d.x * offset_2d.y - forward_2d.y * offset_2d.x)
	return lateral_distance <= LANE_HALF_WIDTH

func _nearby_vehicle_ahead(forward: Vector3) -> bool:
	for other in get_tree().get_nodes_in_group("traffic_cars"):
		if other == self or not is_instance_valid(other) or not other is Node3D:
			continue
		var other_forward: Vector3 = -other.global_transform.basis.z
		if is_vehicle_ahead_in_lane(global_position, forward, other.global_position, other_forward):
			return true
	return false

func _red_light_nearby(point: Vector3, forward: Vector3) -> bool:
	for light in get_tree().get_nodes_in_group("traffic_lights"):
		if not is_instance_valid(light) or not light.has_method("should_stop_for"):
			continue
		if bool(light.call("should_stop_for", point, forward)):
			return true
	return false
