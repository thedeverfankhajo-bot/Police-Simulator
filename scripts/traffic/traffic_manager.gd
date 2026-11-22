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
	for route in routes:
		var car_script: Script = load("res://scripts/traffic/traffic_car.gd")
		var car: CharacterBody3D = CharacterBody3D.new()
		car.set_script(car_script)
		car.call("configure", route, palette[index % palette.size()], 7.2 + float(index % 3) * 1.1)
		car.global_position = route[0]
		parent.add_child(car)
		car.add_to_group("traffic_cars")
		_cars.append(car)
		index += 1

func set_traffic_enabled(value: bool) -> void:
	traffic_enabled = value
	for car in _cars:
		car.set_physics_process(value)
