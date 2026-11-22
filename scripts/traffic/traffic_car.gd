extends CharacterBody3D

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
	var ahead := global_position + direction * 3.4
	_stopped = _nearby_vehicle_ahead(ahead) or _red_light_nearby(global_position)
	var speed := 0.0 if _stopped else cruise_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = -0.7
	if direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 2.0)
	move_and_slide()

func _nearby_vehicle_ahead(point: Vector3) -> bool:
	for other in get_tree().get_nodes_in_group("traffic_cars"):
		if other == self or not is_instance_valid(other):
			continue
		if other.global_position.distance_to(point) < 4.2:
			return true
	return false

func _red_light_nearby(point: Vector3) -> bool:
	for light in get_tree().get_nodes_in_group("traffic_lights"):
		if is_instance_valid(light) and light.global_position.distance_to(point) < 8.0:
			return bool(light.get_meta("red", false))
	return false
