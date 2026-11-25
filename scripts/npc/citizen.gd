extends CharacterBody3D

enum CitizenState { WALKING, WAITING, TALKING }
var state: CitizenState = CitizenState.WALKING
var citizen_id: String = ""
var _waypoints: Array[Vector3] = []
var _waypoint_index: int = 0
var _wait_timer: float = 0.0
var _agent: NavigationAgent3D
var _visual: Node3D
var _tint: Color = Color(0.48, 0.3, 0.2)

func configure(identifier: String, waypoints: Array[Vector3], tint: Color) -> void:
	citizen_id = identifier
	_waypoints = waypoints
	_tint = tint

func _ready() -> void:
	if _waypoints.is_empty():
		_waypoints = [global_position + Vector3(8, 0, 0), global_position + Vector3(8, 0, 8), global_position]
	_build_visual(_tint)
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 0.8
	add_child(_agent)
	_agent.target_position = _waypoints[_waypoint_index]
	floor_snap_length = 0.2

func _build_visual(tint: Color) -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.28
	capsule.height = 1.25
	body.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.85
	body.material_override = material
	body.position.y = 0.78
	_visual.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.19
	sphere.height = 0.38
	head.mesh = sphere
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.68, 0.48, 0.35)
	head.material_override = skin
	head.position.y = 1.53
	_visual.add_child(head)
	var shape := CollisionShape3D.new()
	var collider := CapsuleShape3D.new()
	collider.radius = 0.27
	collider.height = 1.6
	shape.shape = collider
	shape.position.y = 0.8
	add_child(shape)

func _physics_process(delta: float) -> void:
	if state == CitizenState.TALKING:
		velocity = Vector3.ZERO
		return
	if state == CitizenState.WAITING:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			state = CitizenState.WALKING
			_waypoint_index = (_waypoint_index + 1) % _waypoints.size()
			_agent.target_position = _waypoints[_waypoint_index]
		return
	var target := _waypoints[_waypoint_index]
	var flat := target - global_position
	flat.y = 0.0
	if flat.length() < 0.9:
		state = CitizenState.WAITING
		_wait_timer = randf_range(1.4, 4.2)
		return
	var direction := flat.normalized()
	velocity.x = direction.x * 1.5
	velocity.z = direction.z * 1.5
	velocity.y = -0.6 if is_on_floor() else velocity.y - 18.0 * delta
	if _agent and not _agent.is_navigation_finished():
		var next_path := _agent.get_next_path_position()
		var nav_direction := next_path - global_position
		nav_direction.y = 0.0
		if nav_direction.length() > 0.2:
			velocity.x = nav_direction.normalized().x * 1.5
			velocity.z = nav_direction.normalized().z * 1.5
	move_and_slide()
	if Vector2(velocity.x, velocity.z).length() > 0.1:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-velocity.x, -velocity.z), delta * 6.0)

func begin_talk() -> void:
	state = CitizenState.TALKING

func end_talk() -> void:
	state = CitizenState.WAITING
	_wait_timer = 2.0
