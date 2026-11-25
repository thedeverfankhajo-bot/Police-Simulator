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

	# Streaming decisions must use the nearest building footprint edge, not its origin.
	var streaming_manager := instance.get_node_or_null("CityBlockManager") as CityBlockManager
	if streaming_manager == null:
		push_error("Smoke test failed: CityBlockManager did not initialize.")
		quit(1)
		return
	var streaming_probe := CityBlockDefinition.new()
	streaming_probe.block_id = "TEST_STREAM_BOUNDS"
	streaming_probe.district_id = "downtown"
	streaming_probe.building_positions = PackedVector3Array([Vector3.ZERO])
	streaming_probe.footprint = Vector2(20.0, 40.0)
	streaming_probe.minimum_height = 8.0
	streaming_probe.maximum_height = 16.0
	streaming_probe.facade_palette = [Color.WHITE]
	if not streaming_probe.is_valid_definition():
		push_error("Smoke test failed: the city streaming footprint fixture is invalid.")
		quit(1)
		return
	var inside_distance := float(streaming_manager.call("_distance_to_block", streaming_probe, Vector2(8.0, 18.0)))
	var edge_distance := float(streaming_manager.call("_distance_to_block", streaming_probe, Vector2(15.0, 0.0)))
	var outside_distance := float(streaming_manager.call("_distance_to_block", streaming_probe, Vector2(25.0, 0.0)))
	var load_boundary_distance := float(streaming_manager.call("_distance_to_block", streaming_probe, Vector2(streaming_manager.load_radius + 5.0, 0.0)))
	if not is_zero_approx(inside_distance):
		push_error("Smoke test failed: a player inside a building footprint did not receive zero streaming distance.")
		quit(1)
		return
	if not is_equal_approx(edge_distance, 5.0):
		push_error("Smoke test failed: city streaming distance did not measure from the building footprint edge.")
		quit(1)
		return
	if not is_equal_approx(outside_distance, 15.0):
		push_error("Smoke test failed: city streaming distance outside the footprint is incorrect.")
		quit(1)
		return
	if load_boundary_distance > streaming_manager.load_radius:
		push_error("Smoke test failed: a large building entering the load radius was treated as outside.")
		quit(1)
		return

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

	var malformed_objectives := valid_mission_probe.duplicate(true)
	malformed_objectives["objective_steps"] = [
		{"id": "inspect", "title_fa": "بررسی", "title_en": "Inspect"},
		"not_a_step"
	]
	if bool(manager.call("is_valid_mission_data", malformed_objectives)):
		push_error("Smoke test failed: a mission with a non-dictionary objective step was accepted.")
		quit(1)
		return

	var active_progress_probe := valid_mission_probe.duplicate(true)
	active_progress_probe["objective_steps"] = [
		{"id": "inspect", "title_fa": "بررسی محل", "title_en": "Inspect location"},
		{"id": "record", "title_fa": "ثبت نتیجه", "title_en": "Record outcome"}
	]
	active_progress_probe["objective_index"] = 1
	active_progress_probe["completed_objectives"] = ["inspect"]
	if not bool(manager.call("is_valid_mission_data", active_progress_probe)):
		push_error("Smoke test failed: a valid sequential mission progress state was rejected.")
		quit(1)
		return

	var out_of_order_progress := active_progress_probe.duplicate(true)
	out_of_order_progress["completed_objectives"] = ["record"]
	if bool(manager.call("is_valid_mission_data", out_of_order_progress)):
		push_error("Smoke test failed: out-of-order completed mission objectives were accepted.")
		quit(1)
		return

	var missing_progress_history := active_progress_probe.duplicate(true)
	missing_progress_history.erase("completed_objectives")
	if bool(manager.call("is_valid_mission_data", missing_progress_history)):
		push_error("Smoke test failed: mission progress without its completed-objective history was accepted.")
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


	var save_manager: Node = root.get_node_or_null("SaveManager")
	if save_manager == null:
		push_error("Smoke test failed: SaveManager autoload was not found.")
		quit(1)
		return
	var save_payload := {
		"version": 1,
		"saved_at": "2026-11-25T17:00:00",
		"player_position": [3.0, 2.0, -4.0],
		"score": 50,
		"experience": 50,
		"level": 1,
		"public_trust": 65,
		"missions_completed": 0,
		"play_seconds": 12.0,
		"reports": [],
		"mission_index": 0,
		"current_mission": {},
		"audio_volume": 0.7,
		"language": "fa"
	}
	var save_validation_error := str(save_manager.call("get_save_payload_validation_error", save_payload))
	if not save_validation_error.is_empty():
		push_error("Smoke test failed: a valid version-one save payload was rejected: %s" % save_validation_error)
		quit(1)
		return

	var serialized_payload: Variant = JSON.parse_string(JSON.stringify(save_payload))
	var serialized_validation_error := str(save_manager.call("get_save_payload_validation_error", serialized_payload))
	if not serialized_validation_error.is_empty():
		push_error("Smoke test failed: a JSON round-trip save payload was rejected: %s" % serialized_validation_error)
		quit(1)
		return
	var invalid_save := save_payload.duplicate(true)
	invalid_save["audio_volume"] = 2.0
	if bool(save_manager.call("is_valid_save_payload", invalid_save)):
		push_error("Smoke test failed: an out-of-range saved audio volume was accepted.")
		quit(1)
		return
	invalid_save = save_payload.duplicate(true)
	invalid_save["player_position"] = [1.0, INF, 2.0]
	if bool(save_manager.call("is_valid_save_payload", invalid_save)):
		push_error("Smoke test failed: a non-finite saved coordinate was accepted.")
		quit(1)
		return
	invalid_save = save_payload.duplicate(true)
	invalid_save.erase("reports")
	if bool(save_manager.call("is_valid_save_payload", invalid_save)):
		push_error("Smoke test failed: a save with a missing required field was accepted.")
		quit(1)
		return

	var test_save_path := "user://police_simulator_smoke_save.json"
	var test_backup_path := test_save_path + ".bak"
	var test_temp_path := test_save_path + ".tmp"
	for test_path: String in [test_save_path, test_backup_path, test_temp_path]:
		if FileAccess.file_exists(test_path):
			var cleanup_error := DirAccess.remove_absolute(test_path)
			if cleanup_error != OK:
				push_error("Smoke test failed: stale save test data could not be cleared.")
				quit(1)
				return
	if not bool(save_manager.call("_write_payload_transactionally", save_payload, test_save_path)):
		push_error("Smoke test failed: the first transactional save could not be written.")
		quit(1)
		return
	save_payload["score"] = 100
	if not bool(save_manager.call("_write_payload_transactionally", save_payload, test_save_path)):
		push_error("Smoke test failed: the second save could not be written.")
		quit(1)
		return
	var backup_payload: Variant = save_manager.call("_read_save_payload", test_backup_path)
	if not backup_payload is Dictionary:
		push_error("Smoke test failed: the previous valid save backup could not be read.")
		quit(1)
		return
	if int(backup_payload.get("score", -1)) != 50:
		push_error("Smoke test failed: the previous valid save was not preserved as a backup.")
		quit(1)
		return
	save_payload["score"] = 150
	if not bool(save_manager.call("_write_payload_transactionally", save_payload, test_save_path)):
		push_error("Smoke test failed: a third consecutive save could not replace the backup.")
		quit(1)
		return
	backup_payload = save_manager.call("_read_save_payload", test_backup_path)
	if not backup_payload is Dictionary:
		push_error("Smoke test failed: the rotating backup could not be read after a third save.")
		quit(1)
		return
	if int(backup_payload.get("score", -1)) != 100:
		push_error("Smoke test failed: the backup did not rotate to the immediately previous save.")
		quit(1)
		return
	invalid_save = save_payload.duplicate(true)
	invalid_save["audio_volume"] = 4.0
	if bool(save_manager.call("_write_payload_transactionally", invalid_save, test_save_path)):
		push_error("Smoke test failed: an invalid save payload replaced the primary save.")
		quit(1)
		return
	var preserved_payload: Variant = save_manager.call("_read_save_payload", test_save_path)
	if not preserved_payload is Dictionary:
		push_error("Smoke test failed: rejecting an invalid save damaged the existing save.")
		quit(1)
		return
	if int(preserved_payload.get("score", -1)) != 150:
		push_error("Smoke test failed: the last valid primary save was not preserved.")
		quit(1)
		return
	var corrupt_file := FileAccess.open(test_save_path, FileAccess.WRITE)
	if corrupt_file == null:
		push_error("Smoke test failed: the primary save could not be prepared for the recovery test.")
		quit(1)
		return
	corrupt_file.store_string("{corrupt json")
	corrupt_file.flush()
	corrupt_file.close()
	var recovered_payload: Variant = save_manager.call("_load_payload_with_backup", test_save_path, test_backup_path)
	if not recovered_payload is Dictionary:
		push_error("Smoke test failed: a corrupt primary save did not recover from the backup.")
		quit(1)
		return
	if int(recovered_payload.get("score", -1)) != 100:
		push_error("Smoke test failed: the rotating backup did not restore the previous save state.")
		quit(1)
		return
	var restored_payload: Variant = save_manager.call("_read_save_payload", test_save_path)
	if not restored_payload is Dictionary:
		push_error("Smoke test failed: the recovered primary save could not be read.")
		quit(1)
		return
	if int(restored_payload.get("score", -1)) != 100:
		push_error("Smoke test failed: the recovered backup was not restored as the primary save.")
		quit(1)
		return
	if FileAccess.file_exists(test_temp_path):
		push_error("Smoke test failed: a completed save left a temporary file behind.")
		quit(1)
		return
	for test_path: String in [test_save_path, test_backup_path, test_temp_path]:
		if FileAccess.file_exists(test_path):
			DirAccess.remove_absolute(test_path)

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

	var loaded_block_catalog := load("res://data/city/city_block_catalog.tres") as CityBlockCatalog
	if loaded_block_catalog == null or loaded_block_catalog.blocks.size() != 5:
		push_error("Smoke test failed: typed city block catalog resource did not load five block definitions.")
		quit(1)
		return
	for block_definition: CityBlockDefinition in loaded_block_catalog.blocks:
		if block_definition == null or not block_definition.is_valid_definition():
			push_error("Smoke test failed: city block catalog contains an invalid typed definition.")
			quit(1)
			return

	var block_manager: Node = instance.get_node_or_null("CityBlockManager")
	if block_manager == null:
		push_error("Smoke test failed: the data-driven city block manager was not added to the world.")
		quit(1)
		return
	if int(block_manager.call("get_definition_count")) != 5:
		push_error("Smoke test failed: the five city block definitions were not registered.")
		quit(1)
		return
	if int(block_manager.call("get_block_count")) != 5:
		push_error("Smoke test failed: nearby city blocks were not streamed into the world.")
		quit(1)
		return
	if int(block_manager.call("get_building_count")) != 25:
		push_error("Smoke test failed: the active city blocks did not spawn the expected 21 nearby buildings.")
		quit(1)
		return
	if not bool(block_manager.call("is_block_loaded", "downtown_towers")):
		push_error("Smoke test failed: a downtown building footprint intersecting the load radius was not streamed.")
		quit(1)
		return
	var expected_district_buildings := {
		"residential": 6,
		"commercial": 6,
		"downtown": 4,
		"industrial": 5,
		"civic_services": 4
	}
	for district_id: String in expected_district_buildings:
		var actual_count := int(block_manager.call("get_district_building_count", district_id))
		if actual_count != int(expected_district_buildings[district_id]):
			push_error("Smoke test failed: building count for district %s was %d." % [district_id, actual_count])
			quit(1)
			return

	# Verify lazy loading, hysteresis and unloading as the officer moves between districts.
	block_manager.call("_unload_block", "downtown_towers")
	block_manager.call("update_player_position", Vector3(-17.0, 0.2, -64.0))
	if not bool(block_manager.call("is_block_loaded", "downtown_towers")):
		push_error("Smoke test failed: downtown block did not load when the officer approached it.")
		quit(1)
		return
	if int(block_manager.call("get_district_building_count", "downtown")) != 4:
		push_error("Smoke test failed: streamed downtown buildings were not counted correctly.")
		quit(1)
		return
	block_manager.call("update_player_position", Vector3(-17.0, 0.2, 56.0))
	if not bool(block_manager.call("is_block_loaded", "downtown_towers")):
		push_error("Smoke test failed: a loaded block was unloaded inside the hysteresis band.")
		quit(1)
		return
	block_manager.call("update_player_position", Vector3(500.0, 0.2, 500.0))
	if int(block_manager.call("get_block_count")) != 0 or int(block_manager.call("get_building_count")) != 0:
		push_error("Smoke test failed: distant city blocks were not unloaded.")
		quit(1)
		return
	block_manager.call("update_player_position", Vector3(20.0, 0.2, 45.0))
	if int(block_manager.call("get_block_count")) != 5 or int(block_manager.call("get_building_count")) != 25:
		push_error("Smoke test failed: the starting city blocks did not reload after returning.")
		quit(1)
		return

	var weather_surfaces: Array = instance.get_tree().get_nodes_in_group("weather_sensitive_surfaces")
	if weather_surfaces.size() != 10:
		push_error("Smoke test failed: all ten live city road segments were not registered for weather updates.")
		quit(1)
		return
	var weather_road := weather_surfaces[0] as CityRoadSegment
	var weather_road_surface := weather_road.get_node_or_null("RoadSurface") as MeshInstance3D if weather_road != null else null
	var weather_road_material := weather_road_surface.material_override as ShaderMaterial if weather_road_surface != null else null
	if weather_road_material == null or not is_equal_approx(float(weather_road_material.get_shader_parameter("wetness")), 0.0):
		push_error("Smoke test failed: city asphalt did not initialize in its dry state.")
		quit(1)
		return
	var weather_controller: Node = instance.get_node("WeatherController")
	var street_lamp_components: Array = instance.get_tree().get_nodes_in_group("city_street_lamp_components")
	if street_lamp_components.size() != 6:
		push_error("Smoke test failed: all six modular street light components were not instantiated.")
		quit(1)
		return
	for lamp_component: Node3D in street_lamp_components:
		var pole := lamp_component.get_node_or_null("Structure/Pole") as MeshInstance3D
		var arm := lamp_component.get_node_or_null("Structure/Arm") as MeshInstance3D
		var luminaire := lamp_component.get_node_or_null("Structure/Luminaire") as MeshInstance3D
		var diffuser := lamp_component.get_node_or_null("Structure/Diffuser") as MeshInstance3D
		var collision := lamp_component.get_node_or_null("StreetLightBody/CollisionShape3D") as CollisionShape3D
		var light_source := lamp_component.get_node_or_null("LightSource") as OmniLight3D
		if pole == null or arm == null or luminaire == null or diffuser == null or collision == null or collision.shape == null:
			push_error("Smoke test failed: a modular street light is missing structural geometry or collision.")
			quit(1)
			return
		if light_source == null or not light_source.is_in_group("street_lights") or not is_zero_approx(light_source.light_energy):
			push_error("Smoke test failed: a modular street light has no registered, day-safe light source.")
			quit(1)
			return
	var street_lights: Array = instance.get_tree().get_nodes_in_group("street_lights")
	if street_lights.size() != 6:
		push_error("Smoke test failed: all six city street lamps were not registered.")
		quit(1)
		return
	for street_light: Node in street_lights:
		var initial_lamp := street_light as OmniLight3D
		if initial_lamp == null or not is_zero_approx(initial_lamp.light_energy):
			push_error("Smoke test failed: street lamps should initialize switched off during daytime.")
			quit(1)
			return
	weather_controller.set("day_time", 0.0)
	weather_controller.call("_process", 0.01)
	for street_light: Node in street_lights:
		var night_lamp := street_light as OmniLight3D
		if night_lamp == null or not is_equal_approx(night_lamp.light_energy, 1.35):
			push_error("Smoke test failed: street lamps did not illuminate during the night cycle.")
			quit(1)
			return
	weather_controller.set("day_time", 12.0)
	weather_controller.call("_process", 0.01)
	for street_light: Node in street_lights:
		var daytime_lamp := street_light as OmniLight3D
		if daytime_lamp == null or not is_zero_approx(daytime_lamp.light_energy):
			push_error("Smoke test failed: street lamps did not switch off during daytime.")
			quit(1)
			return
	weather_controller.set("day_time", 10.0)
	weather_controller.call("_process", 0.01)
	weather_controller.call("cycle_weather")
	weather_controller.call("cycle_weather")
	weather_controller.call("_process", 2.0)
	if not is_equal_approx(float(weather_road_material.get_shader_parameter("wetness")), 0.94):
		push_error("Smoke test failed: rainy weather did not transition city asphalt to its wet state.")
		quit(1)
		return
	weather_controller.call("cycle_weather")
	weather_controller.call("_process", 2.0)
	if not is_equal_approx(float(weather_road_material.get_shader_parameter("wetness")), 0.28):
		push_error("Smoke test failed: fog did not apply its damp-road surface response.")
		quit(1)
		return
	weather_controller.call("cycle_weather")
	weather_controller.call("_process", 2.0)
	if not is_equal_approx(float(weather_road_material.get_shader_parameter("wetness")), 0.0):
		push_error("Smoke test failed: dry weather did not restore the asphalt roughness state.")
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

	var road_scene := load("res://scenes/city/city_road_segment.tscn") as PackedScene
	if road_scene == null:
		push_error("Smoke test failed: modular city road scene could not be loaded.")
		quit(1)
		return
	var vertical_road := road_scene.instantiate() as CityRoadSegment
	if vertical_road == null:
		push_error("Smoke test failed: modular city road script was not attached.")
		quit(1)
		return
	vertical_road.configure(10.0, 220.0, CityRoadSegment.Axis.NORTH_SOUTH)
	root.add_child(vertical_road)
	var horizontal_road := road_scene.instantiate() as CityRoadSegment
	if horizontal_road == null:
		push_error("Smoke test failed: horizontal city road could not be instantiated.")
		quit(1)
		return
	horizontal_road.configure(7.5, 220.0, CityRoadSegment.Axis.EAST_WEST)
	root.add_child(horizontal_road)
	await process_frame
	var road_surface := vertical_road.get_node_or_null("RoadSurface") as MeshInstance3D
	var road_plane := road_surface.mesh as PlaneMesh if road_surface != null else null
	var asphalt_material := road_surface.material_override as ShaderMaterial if road_surface != null else null
	var road_markings := vertical_road.get_node_or_null("CenterLineDashes") as MultiMeshInstance3D
	if road_plane == null or not road_plane.size.is_equal_approx(Vector2(10.0, 220.0)):
		push_error("Smoke test failed: configured road surface dimensions were not applied.")
		quit(1)
		return
	if asphalt_material == null or asphalt_material.shader == null or not asphalt_material.shader.code.contains("uniform float wetness"):
		push_error("Smoke test failed: asphalt wetness shader uniform was not added.")
		quit(1)
		return
	vertical_road.set_surface_wetness(1.5)
	if not is_equal_approx(float(asphalt_material.get_shader_parameter("wetness")), 1.0):
		push_error("Smoke test failed: road wetness setter did not clamp its upper bound.")
		quit(1)
		return
	vertical_road.set_surface_wetness(-0.5)
	if not is_equal_approx(float(asphalt_material.get_shader_parameter("wetness")), 0.0):
		push_error("Smoke test failed: road wetness setter did not clamp its lower bound.")
		quit(1)
		return
	if asphalt_material == null or asphalt_material.shader == null or not asphalt_material.shader.code.contains("ROUGHNESS"):
		push_error("Smoke test failed: procedural asphalt shader did not load its PBR roughness output.")
		quit(1)
		return
	if road_markings == null or road_markings.multimesh == null or road_markings.multimesh.instance_count < 10:
		push_error("Smoke test failed: road center-line markings were not batched.")
		quit(1)
		return
	if vertical_road.get_node_or_null("SidewalkLeft") == null or vertical_road.get_node_or_null("SidewalkRight") == null:
		push_error("Smoke test failed: modular road sidewalks were not created.")
		quit(1)
		return
	if not is_equal_approx(horizontal_road.rotation.y, PI * 0.5):
		push_error("Smoke test failed: east-west road orientation was not applied.")
		quit(1)
		return
	vertical_road.queue_free()
	horizontal_road.queue_free()
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

	var traffic_signal_scene := load("res://scenes/city/traffic_signal.tscn") as PackedScene
	if traffic_signal_scene == null:
		push_error("Smoke test failed: reusable traffic signal scene could not be loaded.")
		quit(1)
		return
	var signal_probe := traffic_signal_scene.instantiate()
	if signal_probe == null or not signal_probe.has_method("should_stop_for"):
		push_error("Smoke test failed: traffic signal controller was not attached.")
		quit(1)
		return
	signal_probe.set("green_duration", 2.0)
	signal_probe.set("amber_duration", 0.5)
	signal_probe.set("all_red_duration", 0.25)
	signal_probe.position = Vector3.ZERO
	root.add_child(signal_probe)
	await process_frame
	if int(signal_probe.get("current_phase")) != 0:
		push_error("Smoke test failed: a zero-offset signal did not start in its north-south green phase.")
		quit(1)
		return
	if bool(signal_probe.call("should_stop_for", Vector3(0, 0, -8), Vector3.BACK)):
		push_error("Smoke test failed: a green north-south approach was incorrectly stopped.")
		quit(1)
		return
	if not bool(signal_probe.call("should_stop_for", Vector3(-8, 0, 0), Vector3.RIGHT)):
		push_error("Smoke test failed: a red east-west approach was not stopped.")
		quit(1)
		return
	if bool(signal_probe.call("should_stop_for", Vector3(10, 0, -8), Vector3.BACK)):
		push_error("Smoke test failed: a vehicle outside the approach corridor was stopped.")
		quit(1)
		return
	if bool(signal_probe.call("should_stop_for", Vector3(0, 0, 8), Vector3.BACK)):
		push_error("Smoke test failed: a vehicle that had passed the intersection was stopped.")
		quit(1)
		return
	signal_probe.set("current_phase", 3)
	if bool(signal_probe.call("should_stop_for", Vector3(-8, 0, 0), Vector3.RIGHT)):
		push_error("Smoke test failed: a green east-west approach was incorrectly stopped.")
		quit(1)
		return
	if not bool(signal_probe.call("should_stop_for", Vector3(0, 0, -8), Vector3.BACK)):
		push_error("Smoke test failed: a red north-south approach was not stopped.")
		quit(1)
		return
	signal_probe.set("current_phase", 0)
	signal_probe.set("_phase_elapsed", 0.0)
	signal_probe.call("_process", 2.1)
	if int(signal_probe.get("current_phase")) != 1:
		push_error("Smoke test failed: the green phase did not transition to amber.")
		quit(1)
		return
	signal_probe.call("_process", 0.6)
	if int(signal_probe.get("current_phase")) != 2:
		push_error("Smoke test failed: amber did not transition through all-red clearance.")
		quit(1)
		return
	signal_probe.call("_process", 0.3)
	if int(signal_probe.get("current_phase")) != 3:
		push_error("Smoke test failed: the opposing green phase did not activate after all-red.")
		quit(1)
		return
	signal_probe.queue_free()
	await process_frame

	# Legacy missions without objective_steps retain a safe default workflow.
	var legacy_steps: Array = manager.call("get_objective_steps", valid_mission_probe)
	if legacy_steps.size() != 2:
		push_error("Smoke test failed: legacy mission data did not receive the default two-step workflow.")
		quit(1)
		return
	var duplicate_step_ids := valid_mission_probe.duplicate(true)
	duplicate_step_ids["objective_steps"] = [
		{"id": "same_step", "title_fa": "مرحله اول", "title_en": "First step"},
		{"id": "same_step", "title_fa": "مرحله دوم", "title_en": "Second step"}
	]
	if bool(manager.call("is_valid_mission_data", duplicate_step_ids)):
		push_error("Smoke test failed: duplicate objective step identifiers were accepted.")
		quit(1)
		return
	for production_mission: Dictionary in catalogue:
		var production_steps: Array = manager.call("get_objective_steps", production_mission)
		if production_steps.size() != 2:
			push_error("Smoke test failed: a production mission does not have two objective steps.")
			quit(1)
			return

	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		push_error("Smoke test failed: GameState autoload was not found.")
		quit(1)
		return

	# Exercise acceptance, distance gating, partial progress, JSON persistence and final reporting.
	manager.set("active", false)
	manager.set("active_mission", {})
	manager.set("next_index", 0)
	game_state.set("current_mission", {})
	game_state.set("mission_index", 0)
	var completed_before: int = int(game_state.get("missions_completed"))
	if not bool(manager.call("accept_next_mission")):
		push_error("Smoke test failed: the first production mission could not be accepted.")
		quit(1)
		return
	var accepted_mission: Dictionary = manager.get("active_mission")
	var target_coordinates: Array = accepted_mission.get("location", [])
	var mission_target := Vector3(
		float(target_coordinates[0]),
		float(target_coordinates[1]),
		float(target_coordinates[2])
	)
	var too_far_result: Dictionary = manager.call(
		"advance_active_objective",
		mission_target + Vector3(8.0, 0.0, 0.0),
		"en"
	)
	if not too_far_result.is_empty():
		push_error("Smoke test failed: mission progress advanced outside the objective radius.")
		quit(1)
		return
	var first_step_result: Dictionary = manager.call("advance_active_objective", mission_target, "en")
	if first_step_result.is_empty() or bool(first_step_result.get("completed", true)):
		push_error("Smoke test failed: the first objective step did not leave the mission active.")
		quit(1)
		return
	var progressed_mission: Dictionary = manager.get("active_mission")
	if int(progressed_mission.get("objective_index", -1)) != 1:
		push_error("Smoke test failed: the next objective index was not advanced.")
		quit(1)
		return
	var current_mission_after_progress: Dictionary = game_state.get("current_mission")
	if current_mission_after_progress.is_empty() or int(current_mission_after_progress.get("objective_index", -1)) != 1:
		push_error("Smoke test failed: intermediate mission progress was not copied to the game state store.")
		quit(1)
		return
	if not bool(manager.call("is_valid_mission_data", current_mission_after_progress)):
		push_error("Smoke test failed: active mission progress failed mission schema validation.")
		quit(1)
		return
	var mission_save_payload: Dictionary = save_payload.duplicate(true)
	mission_save_payload["mission_index"] = int(game_state.get("mission_index"))
	mission_save_payload["current_mission"] = current_mission_after_progress.duplicate(true)
	var mission_save_error := str(save_manager.call("get_save_payload_validation_error", mission_save_payload))
	if not mission_save_error.is_empty():
		push_error("Smoke test failed: in-progress objective state failed save validation: %s" % mission_save_error)
		quit(1)
		return
	var mission_round_trip: Variant = JSON.parse_string(JSON.stringify(mission_save_payload))
	if not mission_round_trip is Dictionary:
		push_error("Smoke test failed: objective progress did not survive JSON serialization.")
		quit(1)
		return
	var round_trip_mission: Variant = mission_round_trip.get("current_mission", {})
	if not round_trip_mission is Dictionary or int(round_trip_mission.get("objective_index", -1)) != 1:
		push_error("Smoke test failed: serialized save did not retain the active objective index.")
		quit(1)
		return
	var final_step_result: Dictionary = manager.call("advance_active_objective", mission_target, "en")
	if not bool(final_step_result.get("completed", false)):
		push_error("Smoke test failed: the final objective did not complete the mission.")
		quit(1)
		return
	var mission_report: Variant = final_step_result.get("report", {})
	if not mission_report is Dictionary:
		push_error("Smoke test failed: final objective did not return a case report.")
		quit(1)
		return
	var recorded_actions: Variant = mission_report.get("actions", [])
	if not recorded_actions is Array or recorded_actions.size() != 2:
		push_error("Smoke test failed: the case report did not preserve both completed objective actions.")
		quit(1)
		return
	var current_mission_after_completion: Dictionary = game_state.get("current_mission")
	if manager.get("active") or not current_mission_after_completion.is_empty():
		push_error("Smoke test failed: mission completion left stale active mission state.")
		quit(1)
		return
	if int(game_state.get("missions_completed")) != completed_before + 1:
		push_error("Smoke test failed: mission completion and rewards were not applied exactly once.")
		quit(1)
		return

	var interactables := instance.get_tree().get_nodes_in_group("interactables")
	if interactables.size() < 9:
		push_error("Smoke test failed: player services, vehicle, or citizens were not registered.")
		quit(1)
		return
	var hud: Node = instance.get_node("GameHUD")
	hud.call("update_hud", 0.0, "", "Industrial District", "10:00", -1.0, false, Vector3.ZERO)
	var district_label := hud.get("hud_district") as Label
	if district_label == null or district_label.text != "Industrial District":
		push_error("Smoke test failed: HUD did not display the active city district.")
		quit(1)
		return
	hud.call("update_hud", 0.0, "", "Residential District", "10:01", -1.0, false, Vector3.ZERO)
	if district_label.text != "Residential District":
		push_error("Smoke test failed: HUD district label did not update when the player changed districts.")
		quit(1)
		return
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

	# Runtime graphics and input settings must apply and survive a ConfigFile round trip.
	var settings_manager: Node = root.get_node_or_null("SettingsManager")
	if settings_manager == null:
		push_error("Smoke test failed: SettingsManager autoload was not found.")
		quit(1)
		return
	var original_quality := str(settings_manager.get("graphics_quality"))
	var original_sensitivity := float(settings_manager.get("sensitivity_scale"))
	var root_viewport := get_root().get_viewport()
	var sun_light := instance.get("sun") as DirectionalLight3D
	var officer := instance.get("player") as Node
	var patrol_vehicle := instance.get("patrol_car") as Node
	if sun_light == null or officer == null or patrol_vehicle == null:
		push_error("Smoke test failed: graphics or camera targets were not registered in the world (sun=%s, player=%s, vehicle=%s)." % [str(sun_light != null), str(officer != null), str(patrol_vehicle != null)])
		quit(1)
		return
	if not bool(settings_manager.call("set_graphics_quality", "performance")):
		push_error("Smoke test failed: the performance graphics profile could not be applied.")
		quit(1)
		return
	if not is_equal_approx(root_viewport.scaling_3d_scale, 0.82) or sun_light.shadow_enabled:
		push_error("Smoke test failed: performance profile did not lower render scale and disable sun shadows.")
		quit(1)
		return
	if not bool(settings_manager.call("set_graphics_quality", "balanced")):
		push_error("Smoke test failed: the balanced graphics profile could not be applied.")
		quit(1)
		return
	if not is_equal_approx(root_viewport.scaling_3d_scale, 1.0) or not sun_light.shadow_enabled:
		push_error("Smoke test failed: balanced profile did not restore native render scale and sun shadows.")
		quit(1)
		return
	if not bool(settings_manager.call("set_graphics_quality", "quality")):
		push_error("Smoke test failed: the high-quality graphics profile could not be applied.")
		quit(1)
		return
	if not is_equal_approx(root_viewport.scaling_3d_scale, 1.12):
		push_error("Smoke test failed: high-quality profile did not enable the configured supersampling scale.")
		quit(1)
		return
	if bool(settings_manager.call("set_graphics_quality", "ultra")):
		push_error("Smoke test failed: an unknown graphics profile was accepted.")
		quit(1)
		return
	if not bool(settings_manager.call("set_sensitivity_scale", 1.25)):
		push_error("Smoke test failed: camera sensitivity scale could not be changed.")
		quit(1)
		return
	if not is_equal_approx(float(officer.get("camera_sensitivity")), 0.003125):
		push_error("Smoke test failed: officer camera sensitivity was not updated.")
		quit(1)
		return
	if not is_equal_approx(float(patrol_vehicle.get("camera_sensitivity")), 0.00275):
		push_error("Smoke test failed: patrol vehicle camera sensitivity was not updated.")
		quit(1)
		return
	if bool(settings_manager.call("set_sensitivity_scale", INF)):
		push_error("Smoke test failed: non-finite camera sensitivity was accepted.")
		quit(1)
		return
	var settings_test_path := "user://police_simulator_settings_smoke.cfg"
	if not bool(settings_manager.call("save_settings", settings_test_path)):
		push_error("Smoke test failed: graphics settings could not be written to ConfigFile.")
		quit(1)
		return
	settings_manager.call("set_graphics_quality", "performance")
	settings_manager.call("set_sensitivity_scale", 0.75)
	if not bool(settings_manager.call("load_settings", settings_test_path)):
		push_error("Smoke test failed: saved graphics settings could not be loaded.")
		quit(1)
		return
	if str(settings_manager.get("graphics_quality")) != "quality" or not is_equal_approx(float(settings_manager.get("sensitivity_scale")), 1.25):
		push_error("Smoke test failed: graphics settings did not survive a ConfigFile round trip.")
		quit(1)
		return
	if not bool(settings_manager.call("set_graphics_quality", original_quality)):
		push_error("Smoke test failed: original graphics quality could not be restored.")
		quit(1)
		return
	if not bool(settings_manager.call("set_sensitivity_scale", original_sensitivity)):
		push_error("Smoke test failed: original camera sensitivity could not be restored.")
		quit(1)
		return
	var settings_test_absolute_path := ProjectSettings.globalize_path(settings_test_path)
	if FileAccess.file_exists(settings_test_path):
		var settings_cleanup_error := DirAccess.remove_absolute(settings_test_absolute_path)
		if settings_cleanup_error != OK:
			push_error("Smoke test failed: temporary settings test file could not be removed.")
			quit(1)
			return

	instance.queue_free()
	await process_frame
	print("POLICE SIMULATOR 3D smoke test passed: world, managers, multi-stage missions, save recovery, district catalog, modular roads/buildings, traffic lane filtering, directional signal phases, interactables, and UI overlays initialized.")
	quit(0)
