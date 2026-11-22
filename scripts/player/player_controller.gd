extends CharacterBody3D

signal interaction_requested
signal position_changed(position: Vector3)

@export var walk_speed: float = 5.2
@export var run_speed: float = 8.2
@export var acceleration: float = 18.0
@export var camera_sensitivity: float = 0.0025

var control_enabled: bool = true
var camera_pivot: Node3D
var camera: Camera3D
var spring_arm: SpringArm3D
var visual: Node3D
var _pitch: float = -0.22
var _step_clock: float = 0.0
var _animation_player: AnimationPlayer
var _movement_animation: String = ""

func _ready() -> void:
	_build_character()
	_build_camera()
	_build_animations()
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)

func _build_character() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	collider.shape = capsule
	collider.position.y = 0.88
	add_child(collider)

	visual = Node3D.new()
	visual.name = "OfficerVisual"
	add_child(visual)
	var uniform := _material(Color(0.055, 0.105, 0.17), 0.72)
	var dark := _material(Color(0.025, 0.035, 0.052), 0.8)
	var skin := _material(Color(0.72, 0.48, 0.34), 0.8)
	_add_capsule(visual, Vector3(0, 1.05, 0), Vector3(0.47, 0.78, 0.27), uniform)
	_add_box(visual, Vector3(0, 1.46, 0.015), Vector3(0.4, 0.13, 0.28), dark)
	_add_sphere(visual, Vector3(0, 1.68, 0), Vector3(0.23, 0.27, 0.22), skin)
	_add_box(visual, Vector3(0, 1.48, -0.12), Vector3(0.12, 0.08, 0.035), _material(Color(0.78, 0.67, 0.31)))
	_add_box(visual, Vector3(-0.16, 0.44, 0), Vector3(0.19, 0.78, 0.23), dark)
	_add_box(visual, Vector3(0.16, 0.44, 0), Vector3(0.19, 0.78, 0.23), dark)
	_add_box(visual, Vector3(-0.26, 1.03, -0.01), Vector3(0.16, 0.65, 0.18), uniform)
	_add_box(visual, Vector3(0.26, 1.03, -0.01), Vector3(0.16, 0.65, 0.18), uniform)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.45, 0)
	add_child(camera_pivot)
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 5.2
	spring_arm.margin = 0.18
	camera_pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.fov = 72.0
	camera.current = true
	spring_arm.add_child(camera)

func _build_animations() -> void:
	_animation_player = AnimationPlayer.new()
	_animation_player.root_node = NodePath("..")
	add_child(_animation_player)
	var library := AnimationLibrary.new()
	for animation_name in ["idle", "walk", "run"]:
		var animation := Animation.new()
		animation.length = 0.9 if animation_name == "idle" else (0.55 if animation_name == "walk" else 0.38)
		animation.loop_mode = Animation.LOOP_LINEAR
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("OfficerVisual:position:y"))
		var amplitude := 0.012 if animation_name == "idle" else (0.035 if animation_name == "walk" else 0.06)
		animation.track_insert_key(track, 0.0, 0.0)
		animation.track_insert_key(track, animation.length * 0.5, amplitude)
		animation.track_insert_key(track, animation.length, 0.0)
		library.add_animation(animation_name, animation)
	_animation_player.add_animation_library("", library)
	_animation_player.play("idle")
	_movement_animation = "idle"

func _unhandled_input(event: InputEvent) -> void:
	if not control_enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * camera_sensitivity
		_pitch = clampf(_pitch - event.relative.y * camera_sensitivity, -0.85, 0.32)
		camera_pivot.rotation.x = _pitch

func _physics_process(delta: float) -> void:
	if not control_enabled:
		return
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_transform.basis * Vector3(input_2d.x, 0, input_2d.y)).normalized()
	var target_speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
	var desired := direction * target_speed
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.4
	if direction.length() > 0.08:
		var target_yaw := atan2(-direction.x, -direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw - rotation.y, delta * 10.0)
	_step_clock += delta * (2.5 if target_speed == walk_speed else 4.0)
	var next_animation := "run" if Input.is_action_pressed("sprint") and direction.length() > 0.08 else ("walk" if direction.length() > 0.08 else "idle")
	if _animation_player and next_animation != _movement_animation:
		_movement_animation = next_animation
		_animation_player.play(next_animation, 0.18)
	move_and_slide()
	position_changed.emit(global_position)

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	set_physics_process(enabled)
	set_process_unhandled_input(enabled)
	if camera:
		camera.current = enabled
	visible = enabled

func get_active_camera() -> Camera3D:
	return camera

func get_interaction_origin() -> Vector3:
	return camera.global_position

func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _add_box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)

func _add_capsule(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = size.x * 0.5
	capsule.height = size.y
	mesh.mesh = capsule
	mesh.material_override = material
	mesh.position = pos
	mesh.scale.z = size.z / size.x
	parent.add_child(mesh)

func _add_sphere(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size.x
	sphere.height = size.y * 2.0
	mesh.mesh = sphere
	mesh.material_override = material
	mesh.position = pos
	mesh.scale.z = size.z / size.x
	parent.add_child(mesh)
