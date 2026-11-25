class_name CityStreetLight
extends Node3D

const LIGHT_GROUP := "street_lights"
const COMPONENT_GROUP := "city_street_lamp_components"

@export_range(4.0, 12.0, 0.1) var mast_height: float = 6.2
@export_range(0.5, 2.5, 0.1) var arm_length: float = 1.1
@export_range(4.0, 24.0, 0.5) var illumination_range: float = 10.0
@export var illumination_color: Color = Color(0.95, 0.81, 0.62)

var _light_source: OmniLight3D


func _ready() -> void:
	add_to_group(COMPONENT_GROUP)
	_build_geometry()


func get_light_source() -> OmniLight3D:
	return _light_source


func _build_geometry() -> void:
	var safe_height := clampf(mast_height, 4.0, 12.0) if is_finite(mast_height) else 6.2
	var safe_arm_length := clampf(arm_length, 0.5, 2.5) if is_finite(arm_length) else 1.1
	var safe_light_range := clampf(illumination_range, 4.0, 24.0) if is_finite(illumination_range) else 10.0

	var collision_body := StaticBody3D.new()
	collision_body.name = "StreetLightBody"
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var pole_shape := CapsuleShape3D.new()
	pole_shape.radius = 0.12
	pole_shape.height = safe_height
	collision.shape = pole_shape
	collision.position.y = safe_height * 0.5
	collision_body.add_child(collision)
	add_child(collision_body)

	var structure := Node3D.new()
	structure.name = "Structure"
	add_child(structure)

	var metal := _make_material(Color(0.13, 0.16, 0.18), 0.46, 0.58)
	var housing := _make_material(Color(0.075, 0.095, 0.11), 0.52, 0.42)
	var lens := _make_material(illumination_color, 0.3, 0.0)
	lens.emission_enabled = true
	lens.emission = illumination_color

	var foot_mesh := CylinderMesh.new()
	foot_mesh.top_radius = 0.16
	foot_mesh.bottom_radius = 0.19
	foot_mesh.height = 0.16
	_add_mesh(structure, "Foot", foot_mesh, metal, Vector3(0.0, 0.08, 0.0))

	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.065
	pole_mesh.bottom_radius = 0.1
	pole_mesh.height = safe_height
	_add_mesh(structure, "Pole", pole_mesh, metal, Vector3(0.0, safe_height * 0.5, 0.0))

	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.055
	arm_mesh.bottom_radius = 0.055
	arm_mesh.height = safe_arm_length
	var arm := _add_mesh(
		structure,
		"Arm",
		arm_mesh,
		metal,
		Vector3(safe_arm_length * 0.5, safe_height - 0.22, 0.0)
	)
	arm.rotation.z = -PI * 0.5

	var housing_mesh := BoxMesh.new()
	housing_mesh.size = Vector3(0.46, 0.14, 0.32)
	_add_mesh(
		structure,
		"Luminaire",
		housing_mesh,
		housing,
		Vector3(safe_arm_length, safe_height - 0.37, 0.0)
	)

	var lens_mesh := BoxMesh.new()
	lens_mesh.size = Vector3(0.34, 0.025, 0.23)
	_add_mesh(
		structure,
		"Diffuser",
		lens_mesh,
		lens,
		Vector3(safe_arm_length, safe_height - 0.455, 0.0)
	)

	_light_source = OmniLight3D.new()
	_light_source.name = "LightSource"
	_light_source.position = Vector3(safe_arm_length, safe_height - 0.53, 0.0)
	_light_source.omni_range = safe_light_range
	_light_source.light_color = illumination_color
	_light_source.light_energy = 0.0
	_light_source.shadow_enabled = false
	_light_source.add_to_group(LIGHT_GROUP)
	add_child(_light_source)


func _add_mesh(
	parent: Node3D,
	node_name: String,
	mesh: Mesh,
	material: Material,
	local_position: Vector3
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = local_position
	parent.add_child(instance)
	return instance


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
