extends RefCounted

func sanitize_position_data(position_data: Variant, fallback: Vector3) -> Array[float]:
	var safe_position: Array[float] = [fallback.x, fallback.y, fallback.z]
	if not position_data is Array or position_data.size() != 3:
		return safe_position
	for axis: int in range(3):
		var coordinate: Variant = position_data[axis]
		if not (coordinate is int or coordinate is float):
			return safe_position
		var value := float(coordinate)
		if not is_finite(value):
			return safe_position
		safe_position[axis] = clampf(value, -95.0, 95.0)
	return safe_position
