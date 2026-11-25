extends CharacterBody3D

signal vehicle_state_changed(speed_kmh: float, siren_on: bool)

@export var acceleration: float = 16.0
@export var reverse_acceleration: float = 8.0
@export var max_speed: float = 35.0
@export var steering_rate: float = 1.7
@export var drag: float = 5.5

var driven: bool = false
var siren_on: bool = false
var headlights_on: bool = true
var speed_kmh: float = 0.0
var camera_sensitivity: float = 0.0022
var _longitudinal_speed: float = 0.0
var _camera: Camera3D
var _camera_pivot: Node3D
var _camera_pitch: float = -0.12
var _lightbar: OmniLight3D
var _light_phase: float = 0.0
var _wheel_visuals: Array[MeshInstance3D] = []

func _ready() -> void:
	_build_vehicle()
	_build_camera()
	set_physics_process(true)

func _build_vehicle() -> void:
	var body_shape := CollisionShape3D.new()
	var body_box := BoxShape3D.new()
	body_box.size = Vector3(2.15, 1.0, 4.5)
	body_shape.shape = body_box
	body_shape.position.y = 0.78
	add_child(body_shape)

	var white := _mat(Color(0.82, 0.86, 0.87), 0.38)
	var navy := _mat(Color(0.035, 0.09, 0.16), 0.4)
	var glass := _mat(Color(0.055, 0.16, 0.22), 0.2)
	var tire := _mat(Color(0.018, 0.021, 0.025), 0.96)
	var chrome := _mat(Color(0.65, 0.7, 0.72), 0.25)
	_add_box(Vector3(0, 0.76, 0), Vector3(2.05, 0.65, 4.25), white)
	_add_box(Vector3(0, 1.29, -0.12), Vector3(1.72, 0.7, 2.15), navy)
	_add_box(Vector3(0, 1.28, -0.12), Vector3(1.63, 0.55, 2.12), glass)
	_add_box(Vector3(0, 0.91, 1.43), Vector3(2.04, 0.25, 1.12), navy)
	_add_box(Vector3(0, 0.91, -1.54), Vector3(2.04, 0.24, 0.95), navy)
	_add_box(Vector3(0, 0.44, -2.02), Vector3(1.85, 0.15, 0.08), chrome)
	_add_box(Vector3(0, 0.45, 2.02), Vector3(1.85, 0.15, 0.08), chrome)
	for x in [-0.99, 0.99]:
		for z in [-1.42, 1.42]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.42
			cylinder.bottom_radius = 0.42
			cylinder.height = 0.22
			wheel.mesh = cylinder
			wheel.material_override = tire
			wheel.position = Vector3(x, 0.43, z)
			wheel.rotation.z = PI * 0.5
			add_child(wheel)
			_wheel_visuals.append(wheel)
			var hub := MeshInstance3D.new()
			var hub_mesh := CylinderMesh.new()
			hub_mesh.top_radius = 0.18
			hub_mesh.bottom_radius = 0.18
			hub_mesh.height = 0.23
			hub.mesh = hub_mesh
			hub.material_override = chrome
			hub.position = wheel.position
			hub.rotation.z = PI * 0.5
			add_child(hub)
	_add_box(Vector3(-0.47, 1.69, -0.12), Vector3(0.65, 0.13, 0.28), _mat(Color(0.12, 0.36, 0.91)))
	_add_box(Vector3(0.47, 1.69, -0.12), Vector3(0.65, 0.13, 0.28), _mat(Color(0.91, 0.12, 0.12)))
	_lightbar = OmniLight3D.new()
	_lightbar.position = Vector3(0, 1.85, -0.12)
	_lightbar.omni_range = 8.0
	_lightbar.light_energy = 0.0
	add_child(_lightbar)

func _build_camera() -> void:
	var pivot := Node3D.new()
	_camera_pivot = pivot
	pivot.position = Vector3(0, 1.5, 0)
	add_child(pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 7.0
	arm.margin = 0.3
	pivot.add_child(arm)
	_camera = Camera3D.new()
	_camera.fov = 74.0
	arm.add_child(_camera)

func _unhandled_input(event: InputEvent) -> void:
	if not driven or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_camera_pivot.rotation.y -= event.relative.x * camera_sensitivity
		_camera_pitch = clampf(_camera_pitch - event.relative.y * camera_sensitivity * 0.82, -0.55, 0.25)
		_camera_pivot.rotation.x = _camera_pitch

func _physics_process(delta: float) -> void:
	if driven:
		var throttle := Input.get_axis("move_back", "move_forward")
		var steering := Input.get_axis("move_left", "move_right")
		if throttle > 0.0:
			_longitudinal_speed = move_toward(_longitudinal_speed, max_speed, acceleration * throttle * delta)
		elif throttle < 0.0:
			if _longitudinal_speed > 1.0:
				_longitudinal_speed = move_toward(_longitudinal_speed, 0.0, acceleration * 2.2 * delta)
			else:
				_longitudinal_speed = move_toward(_longitudinal_speed, -9.0, reverse_acceleration * delta)
		else:
			_longitudinal_speed = move_toward(_longitudinal_speed, 0.0, drag * delta)
		if Input.is_action_pressed("handbrake"):
			_longitudinal_speed = move_toward(_longitudinal_speed, 0.0, 28.0 * delta)
		var grip := clampf(absf(_longitudinal_speed) / 5.0, 0.0, 1.0)
		rotation.y -= steering * steering_rate * grip * signf(_longitudinal_speed) * delta
		var forward := -global_transform.basis.z
		velocity.x = forward.x * _longitudinal_speed
		velocity.z = forward.z * _longitudinal_speed
		velocity.y = -0.8
		move_and_slide()
		if get_slide_collision_count() > 0:
			_longitudinal_speed *= 0.82
		for wheel in _wheel_visuals:
			wheel.rotation.x += _longitudinal_speed * delta * 0.9
		if Input.is_action_just_pressed("toggle_siren"):
			set_siren(not siren_on)
		if Input.is_action_just_pressed("horn"):
			AudioManager.play_horn()
	else:
		_longitudinal_speed = move_toward(_longitudinal_speed, 0.0, drag * delta)
	_light_phase += delta
	_lightbar.light_energy = (2.5 if int(_light_phase * 4.0) % 2 == 0 else 0.5) if siren_on else 0.0
	speed_kmh = absf(_longitudinal_speed) * 3.6
	AudioManager.set_engine_intensity(clampf(absf(_longitudinal_speed) / max_speed, 0.0, 1.0) if driven else 0.0)
	vehicle_state_changed.emit(speed_kmh, siren_on)

func set_camera_sensitivity(value: float) -> void:
	if not is_finite(value):
		return
	camera_sensitivity = clampf(value, 0.001, 0.006)

func set_driven(value: bool) -> void:
	driven = value
	_camera.current = value

func set_siren(value: bool) -> void:
	siren_on = value
	AudioManager.set_siren(value)

func get_camera() -> Camera3D:
	return _camera

func get_speed() -> float:
	return speed_kmh

func _mat(color: Color, roughness: float = 0.7) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _add_box(pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = pos
	add_child(mesh)
