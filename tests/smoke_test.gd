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
	for mission_data: Dictionary in catalogue:
		if not bool(manager.call("is_valid_mission_data", mission_data)):
			push_error("Smoke test failed: a production mission failed schema validation.")
			quit(1)
			return

	var valid_mission_probe := {
		"id": "TEST-001",
		"type": "help_citizen",
		"title_fa": "آزمون مأموریت",
		"title_en": "Mission validation test",
		"description_fa": "شرح آزمون",
		"description_en": "Test description",
		"priority": "normal",
		"target_label": "Test target",
		"location": [1.0, 0.0, -2.0],
		"reward": 100,
		"trust": 2
	}
	if not bool(manager.call("is_valid_mission_data", valid_mission_probe)):
		push_error("Smoke test failed: a complete mission definition was rejected.")
		quit(1)
		return

	var invalid_mission_probes: Array[Dictionary] = []
	var missing_translation := valid_mission_probe.duplicate(true)
	missing_translation["title_en"] = " "
	invalid_mission_probes.append(missing_translation)
	var negative_reward := valid_mission_probe.duplicate(true)
	negative_reward["reward"] = -1
	invalid_mission_probes.append(negative_reward)
	var non_finite_location := valid_mission_probe.duplicate(true)
	non_finite_location["location"] = [INF, 0.0, 0.0]
	invalid_mission_probes.append(non_finite_location)
	var out_of_range_trust := valid_mission_probe.duplicate(true)
	out_of_range_trust["trust"] = 101
	invalid_mission_probes.append(out_of_range_trust)
	for invalid_probe: Dictionary in invalid_mission_probes:
		if bool(manager.call("is_valid_mission_data", invalid_probe)):
			push_error("Smoke test failed: an invalid mission definition was accepted.")
			quit(1)
			return
	var fallback_spawn := Vector3(20.0, 0.0, 28.0)
	var position_sanitizer := SavePositionSanitizer.new()
	var clamped_position: Array[float] = position_sanitizer.sanitize_position_data([120.0, 1.5, -130.0], fallback_spawn)
	if not is_equal_approx(clamped_position[0], 95.0) or not is_equal_approx(clamped_position[1], 1.5) or not is_equal_approx(clamped_position[2], -95.0):
		push_error("Smoke test failed: saved coordinates were not clamped to world bounds.")
		quit(1)
		return
	var non_finite_position: Array[float] = position_sanitizer.sanitize_position_data([INF, 0.0, 0.0], fallback_spawn)
	if not is_equal_approx(non_finite_position[0], fallback_spawn.x) or not is_equal_approx(non_finite_position[1], fallback_spawn.y) or not is_equal_approx(non_finite_position[2], fallback_spawn.z):
		push_error("Smoke test failed: non-finite saved coordinates did not use the safe spawn.")
		quit(1)
		return
	var malformed_position: Array[float] = position_sanitizer.sanitize_position_data([1.0, "invalid", 3.0], fallback_spawn)
	if not is_equal_approx(malformed_position[0], fallback_spawn.x) or not is_equal_approx(malformed_position[1], fallback_spawn.y) or not is_equal_approx(malformed_position[2], fallback_spawn.z):
		push_error("Smoke test failed: malformed saved coordinates did not use the safe spawn.")
		quit(1)
		return
	var malformed_last_position: Array[float] = position_sanitizer.sanitize_position_data([5.0, 6.0, "invalid"], fallback_spawn)
	if not is_equal_approx(malformed_last_position[0], fallback_spawn.x) or not is_equal_approx(malformed_last_position[1], fallback_spawn.y) or not is_equal_approx(malformed_last_position[2], fallback_spawn.z):
		push_error("Smoke test failed: a malformed final coordinate partially changed the fallback position.")
		quit(1)
		return
	var restored_values: Array[float] = position_sanitizer.sanitize_position_data([3.0, 2.0, -4.0], fallback_spawn)
	var restored_position := Vector3(restored_values[0], restored_values[1], restored_values[2])
	if not restored_position.is_equal_approx(Vector3(3.0, 2.0, -4.0)):
		push_error("Smoke test failed: valid saved coordinates were not restored.")
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

	var building_scene := load("res://scenes/city/city_building.tscn") as PackedScene
	if building_scene == null:
		push_error("Smoke test failed: reusable city building scene could not be loaded.")
		quit(1)
		return
	var building := building_scene.instantiate() as CityBuilding
	if building == null:
		push_error("Smoke test failed: reusable city building script was not attached.")
		quit(1)
		return
	building.configure(Vector3(14.0, 18.0, 14.0), Color(0.42, 0.48, 0.52), "COMMERCIAL", 1)
	root.add_child(building)
	await process_frame
	var building_collision := building.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var north_windows := building.get_node_or_null("Architecture/FacadeWindowsNorth") as MultiMeshInstance3D
	var district_sign := building.get_node_or_null("Architecture/DistrictSign") as Label3D
	if building_collision == null or building_collision.shape == null:
		push_error("Smoke test failed: modular building collision was not created.")
		quit(1)
		return
	if north_windows == null or north_windows.multimesh == null or north_windows.multimesh.instance_count < 4:
		push_error("Smoke test failed: modular building facade windows were not batched.")
		quit(1)
		return
	if district_sign == null or district_sign.text != "COMMERCIAL":
		push_error("Smoke test failed: modular building district sign was not configured.")
		quit(1)
		return
	building.queue_free()
	await process_frame

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
	print("POLICE SIMULATOR 3D smoke test passed: world, managers, mission data, save-position sanitization, district catalog, traffic lane filtering, interactables, and UI overlays initialized.")
	quit(0)
