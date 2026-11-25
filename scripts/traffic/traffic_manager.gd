extends Node3D

var traffic_enabled: bool = true
var _cars: Array[Node3D] = []

func populate(parent: Node3D, routes: Array[Array]) -> void:
	var palette: Array[Color] = [
		Color(0.72, 0.18, 0.12), Color(0.18, 0.27, 0.35),
		Color(0.78, 0.72, 0.55), Color(0.22, 0.38, 0.27),
		Color(0.55, 0.55, 0.58), Color(0.12, 0.15, 0.19)
	]
	var index := 0
	for route_value: Variant in routes:
		if not route_value is Array:
			push_warning("Skipping a traffic route that is not an Array.")
			continue
		var route: Array[Vector3] = []
		for point: Variant in route_value:
			if point is Vector3:
				route.append(point)
		if route.size() < 2:
			push_warning("Skipping a traffic route with fewer than two Vector3 points.")
			continue
		var car_script: Script = load("res://scripts/traffic/traffic_car.gd")
		if car_script == null:
			push_error("Traffic car script could not be loaded.")
			return
		var car: CharacterBody3D = CharacterBody3D.new()
		car.set_script(car_script)
		car.call("configure", route, palette[index % palette.size()], 7.2 + float(index % 3) * 1.1)
		car.position = route[0]
		parent.add_child(car)
		car.add_to_group("traffic_cars")
		_cars.append(car)
		index += 1

func set_traffic_enabled(value: bool) -> void:
	traffic_enabled = value
	for car in _cars:
		car.set_physics_process(value)
