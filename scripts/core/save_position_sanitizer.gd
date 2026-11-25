class_name SavePositionSanitizer
extends RefCounted

func sanitize_position_data(position_data: Variant, fallback: Vector3) -> Array[float]:
	var fallback_position: Array[float] = [fallback.x, fallback.y, fallback.z]
	if not position_data is Array or position_data.size() != 3:
		return fallback_position
	var sanitized_position: Array[float] = []
	for axis: int in range(3):
		var coordinate: Variant = position_data[axis]
		var coordinate_type := typeof(coordinate)
		if coordinate_type != TYPE_INT and coordinate_type != TYPE_FLOAT:
			return fallback_position
		var value := float(coordinate)
		if not is_finite(value):
			return fallback_position
		sanitized_position.append(clampf(value, -95.0, 95.0))
	return sanitized_position
