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
	if int(block_manager.call("get_block_count")) != 4:
		push_error("Smoke test failed: nearby city blocks were not streamed into the world.")
		quit(1)
		return
	if int(block_manager.call("get_building_count")) != 21:
		push_error("Smoke test failed: the active city blocks did not spawn the expected 21 nearby buildings.")
		quit(1)
		return
	if bool(block_manager.call("is_block_loaded", "downtown_towers")):
		push_error("Smoke test failed: the distant downtown block was loaded outside the streaming radius.")
		quit(1)
		return
	var expected_district_buildings := {
		"residential": 6,
		"commercial": 6,
		"downtown": 0,
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
	if int(block_manager.call("get_block_count")) != 4 or int(block_manager.call("get_building_count")) != 21:
		push_error("Smoke test failed: the starting city blocks did not reload after returning.")
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
	instance.queue_free()
	await process_frame
	print("POLICE SIMULATOR 3D smoke test passed: world, managers, multi-stage missions, save recovery, district catalog, modular roads/buildings, traffic lane filtering, directional signal phases, interactables, and UI overlays initialized.")
	quit(0)
