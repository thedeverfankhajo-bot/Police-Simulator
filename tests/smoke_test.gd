extends SceneTree

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/boot/main.tscn")
	if packed == null:
		push_error("Smoke test failed: the main scene could not be loaded.")
		quit(1)
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	if instance.get_node_or_null("MissionManager") == null:
		push_error("Smoke test failed: MissionManager did not initialize.")
		quit(1)
		return
	if instance.get_node_or_null("WeatherController") == null:
		push_error("Smoke test failed: WeatherController did not initialize.")
		quit(1)
		return
	if instance.get_node_or_null("GameHUD") == null:
		push_error("Smoke test failed: HUD did not initialize.")
		quit(1)
		return
	var manager: Node = instance.get_node("MissionManager")
	var catalogue: Variant = manager.get("catalogue")
	if not catalogue is Array or catalogue.size() < 8:
		push_error("Smoke test failed: mission catalogue is missing entries.")
		quit(1)
		return
	var city_manager: Node = instance.get_node_or_null("CityManager")
	if city_manager == null or int(city_manager.call("get_district_count")) != 7:
		push_error("Smoke test failed: the seven city district resources did not load.")
		quit(1)
		return
	if str(city_manager.call("get_district_id_at", Vector3(20, 0, 28))) != "police_headquarters":
		push_error("Smoke test failed: police headquarters district lookup failed.")
		quit(1)
		return
	if str(city_manager.call("get_district_id_at", Vector3(-25, 0, 25))) != "public_park":
		push_error("Smoke test failed: public park district lookup failed.")
		quit(1)
		return
	if str(city_manager.call("get_district_id_at", Vector3(45, 0, -72))) != "civic_services":
		push_error("Smoke test failed: higher-priority civic services district did not win an overlap.")
		quit(1)
		return
	if str(city_manager.call("get_district_id_at", Vector3(-45, 0, 25))) != "public_park":
		push_error("Smoke test failed: higher-priority public park district did not win an overlap.")
		quit(1)
		return
	if str(city_manager.call("get_district_label_at", Vector3(45, 0, -72), "en")) != "Civic Services":
		push_error("Smoke test failed: English district labels were not resolved.")
		quit(1)
		return
	if str(city_manager.call("get_district_id_at", Vector3(300, 0, 300))) != "":
		push_error("Smoke test failed: an out-of-bounds position matched a city district.")
		quit(1)
		return

	var traffic_script := load("res://scripts/traffic/traffic_car.gd") as Script
	if traffic_script == null:
		push_error("Smoke test failed: traffic car script could not be loaded for lane checks.")
		quit(1)
		return
	var traffic_probe: Node = traffic_script.new()
	var observer_position := Vector3.ZERO
	var forward := Vector3.FORWARD
	if not bool(traffic_probe.call("is_vehicle_ahead_in_lane", observer_position, forward, Vector3(0, 0, -5), forward)):
		traffic_probe.free()
		push_error("Smoke test failed: a same-lane vehicle ahead was not detected.")
		quit(1)
		return
	if bool(traffic_probe.call("is_vehicle_ahead_in_lane", observer_position, forward, Vector3(0, 0, -5), Vector3.RIGHT)):
		traffic_probe.free()
		push_error("Smoke test failed: perpendicular cross traffic incorrectly blocked the lane.")
		quit(1)
		return
	if bool(traffic_probe.call("is_vehicle_ahead_in_lane", observer_position, forward, Vector3(4, 0, -5), forward)):
		traffic_probe.free()
		push_error("Smoke test failed: an adjacent-lane vehicle incorrectly blocked the lane.")
		quit(1)
		return
	if bool(traffic_probe.call("is_vehicle_ahead_in_lane", observer_position, forward, Vector3(0, 0, 5), forward)):
		traffic_probe.free()
		push_error("Smoke test failed: a vehicle behind incorrectly blocked the lane.")
		quit(1)
		return
	traffic_probe.free()

	var interactables := instance.get_tree().get_nodes_in_group("interactables")
	if interactables.size() < 9:
		push_error("Smoke test failed: player services, vehicle, or citizens were not registered.")
		quit(1)
		return
	var hud: Node = instance.get_node("GameHUD")
	hud.call("show_overlay", "map")
	if not bool(hud.call("is_panel_open")):
		push_error("Smoke test failed: map overlay did not open.")
		quit(1)
		return
	hud.call("close_panels")
	hud.call("show_overlay", "pause")
	if not bool(hud.call("is_panel_open")):
		push_error("Smoke test failed: pause overlay did not open.")
		quit(1)
		return
	hud.call("close_panels")
	instance.queue_free()
	await process_frame
	print("POLICE SIMULATOR 3D smoke test passed: world, managers, mission data, district catalog, traffic lane filtering, interactables, and UI overlays initialized.")
	quit(0)
