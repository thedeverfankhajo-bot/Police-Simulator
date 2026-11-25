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
	print("POLICE SIMULATOR 3D smoke test passed: world, managers, mission data, interactables, and map/pause overlays initialized.")
	quit(0)
