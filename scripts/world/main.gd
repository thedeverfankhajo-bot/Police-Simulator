extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player/player_controller.gd")
const CAR_SCRIPT = preload("res://scripts/vehicles/police_vehicle.gd")
const CITIZEN_SCRIPT = preload("res://scripts/npc/citizen.gd")
const HUD_SCRIPT = preload("res://scripts/ui/hud.gd")
const MISSION_SCRIPT = preload("res://scripts/missions/mission_manager.gd")
const WEATHER_SCRIPT = preload("res://scripts/environment/weather_controller.gd")
const TRAFFIC_SCRIPT = preload("res://scripts/traffic/traffic_manager.gd")
const CITY_MANAGER_SCENE: PackedScene = preload("res://scenes/city/city_manager.tscn")
const CITY_BLOCK_MANAGER_SCENE: PackedScene = preload("res://scenes/city/city_block_manager.tscn")
const CITY_ROAD_SEGMENT_SCENE: PackedScene = preload("res://scenes/city/city_road_segment.tscn")
const TRAFFIC_SIGNAL_SCENE: PackedScene = preload("res://scenes/city/traffic_signal.tscn")

var player: Variant
var patrol_car: Variant
var hud: Variant
var missions: Variant
var weather: Variant
var traffic: Variant
var city_manager: Node
var city_block_manager: CityBlockManager
var sun: DirectionalLight3D
var environment_node: WorldEnvironment
var rain: GPUParticles3D
var objective_marker: Node3D
var active_citizen: Node3D
var driving := false

func _ready() -> void:
	_build_environment()
	_build_city_manager()
	_build_city()
	_build_station()
	_spawn_player()
	_spawn_citizens()
	_spawn_traffic()
	_build_systems()
	_build_hud()
	_restore_save()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	missions.mission_completed.connect(_mission_completed)
	GameState.report_added.connect(_report_added)

func _process(delta: float) -> void:
	GameState.play_seconds += delta
	if rain and player:
		rain.global_position = player.global_position + Vector3(0,10,0)
	if is_instance_valid(city_manager):
		city_manager.call("update_player_position", _current_position(), LocaleManager.language)
	if is_instance_valid(city_block_manager):
		city_block_manager.update_player_position(_current_position())
	_update_hud()
	_update_prompt()
	if Input.is_action_just_pressed("interact") and not hud.is_panel_open():
		_interact()
	if Input.is_action_just_pressed("toggle_map"):
		hud.show_overlay("map")
	if Input.is_action_just_pressed("toggle_report"):
		_register_patrol_report()
		hud.show_overlay("reports")
	if Input.is_action_just_pressed("ui_cancel"):
		if hud.is_panel_open():
			hud.close_panels()
		else:
			hud.show_overlay("pause")

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12,0.25,0.39)
	sky_mat.sky_horizon_color = Color(0.58,0.68,0.72)
	sky_mat.ground_bottom_color = Color(0.075,0.085,0.09)
	sky_mat.ground_horizon_color = Color(0.38,0.44,0.47)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.2
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.ssr_enabled = false
	env.fog_enabled = true
	env.fog_light_color = Color(0.51,0.6,0.68)
	env.fog_density = 0.001
	environment_node = WorldEnvironment.new()
	environment_node.environment = env
	add_child(environment_node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-28,0)
	sun.light_color = Color(1.0,0.91,0.78)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110.0
	add_child(sun)
	rain = GPUParticles3D.new()
	rain.amount = 360
	rain.lifetime = 2.2
	rain.emitting = false
	var particle := BoxMesh.new()
	particle.size = Vector3(0.035,0.4,0.035)
	rain.draw_pass_1 = particle
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.04,-1,0)
	process_material.initial_velocity_min = 13
	process_material.initial_velocity_max = 18
	process_material.gravity = Vector3(0,-3,0)
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(20,8,20)
	process_material.color = Color(0.72,0.82,0.9,0.55)
	rain.process_material = process_material
	add_child(rain)

func _build_city() -> void:
	var grass := _mat(Color(0.17,0.29,0.19),0.98)
	_box(self,Vector3(0,-0.28,0),Vector3(220,0.5,220),grass,true)
	var navigation_region := NavigationRegion3D.new()
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.vertices = PackedVector3Array([Vector3(-105,0,-105),Vector3(105,0,-105),Vector3(105,0,105),Vector3(-105,0,105)])
	navigation_mesh.add_polygon(PackedInt32Array([0,1,2,3]))
	navigation_region.navigation_mesh = navigation_mesh
	add_child(navigation_region)
	for road in [-100.0, -50.0, 0.0, 50.0, 100.0]:
		var width := 10.0 if road == 0.0 else 7.5
		_add_road_segment(Vector3(road, 0.0, 0.0), width, CityRoadSegment.Axis.NORTH_SOUTH)
		_add_road_segment(Vector3(0.0, 0.0, road), width, CityRoadSegment.Axis.EAST_WEST)

	var park := _mat(Color(0.24,0.38,0.24),0.98)
	_box(self,Vector3(-25,0.04,25),Vector3(37,0.18,37),park)
	var concrete := _mat(Color(0.5,0.53,0.52),0.9)
	_box(self,Vector3(-25,0.15,25),Vector3(2,0.2,31),concrete)
	_box(self,Vector3(-25,0.16,25),Vector3(31,0.2,2),concrete)
	_box(self,Vector3(-25,0.28,25),Vector3(5,0.22,5),_mat(Color(0.12,0.4,0.49),0.2))
	for tree_pos in [Vector3(-38,0,11),Vector3(-13,0,11),Vector3(-38,0,39),Vector3(-13,0,39),Vector3(-25,0,8),Vector3(-8,0,25)]:
		_tree(tree_pos)
	_bench(Vector3(-31,0.2,25))
	_bench(Vector3(-19,0.2,25))
	_sign(Vector3(-25,2.4,6),"NORTH PARK",Color(0.3,0.6,0.39))

	city_block_manager = CITY_BLOCK_MANAGER_SCENE.instantiate() as CityBlockManager
	if city_block_manager == null:
		push_error("City block manager scene could not be instantiated.")
	else:
		city_block_manager.name = "CityBlockManager"
		add_child(city_block_manager)
	for p in [Vector3(0,0.2,0),Vector3(50,0.2,0),Vector3(-50,0.2,0),Vector3(0,0.2,50),Vector3(0,0.2,-50)]:
		_traffic_light(p)
	for p in [Vector3(-10,0,17),Vector3(10,0,17),Vector3(49,0,-16),Vector3(-49,0,16),Vector3(15,0,-50),Vector3(-15,0,50)]:
		_street_lamp(p)
	for p in [Vector3(12,0,12),Vector3(-12,0,-12),Vector3(58,0,-12),Vector3(-58,0,12)]:
		_box(self,p+Vector3(0,0.5,0),Vector3(0.65,1,0.65),_mat(Color(0.12,0.24,0.25)))

func _build_station() -> void:
	var wall := _mat(Color(0.57,0.62,0.64),0.82)
	var trim := _mat(Color(0.055,0.14,0.22),0.54)
	_box(self,Vector3(20,0.12,28),Vector3(25,0.28,24),_mat(Color(0.37,0.4,0.41)))
	_box(self,Vector3(7.8,4,28),Vector3(0.8,8,24),wall,true)
	_box(self,Vector3(32.2,4,28),Vector3(0.8,8,24),wall,true)
	_box(self,Vector3(20,4,16),Vector3(25,8,0.8),wall,true)
	_box(self,Vector3(12.1,3.8,40),Vector3(9.2,7.6,0.8),wall,true)
	_box(self,Vector3(27.9,3.8,40),Vector3(9.2,7.6,0.8),wall,true)
	_box(self,Vector3(20,0.25,15.6),Vector3(26,0.35,1.2),trim)
	_box(self,Vector3(20,0.25,40.4),Vector3(26,0.35,1.2),trim)
	_box(self,Vector3(20,7.9,28),Vector3(25,0.4,24),trim)
	_sign(Vector3(20,6.2,15.1),"NORTH DISTRICT POLICE",Color(0.08,0.28,0.43))
	_box(self,Vector3(20,1.5,20),Vector3(8,3,0.35),wall,true)
	_box(self,Vector3(20,0.75,27),Vector3(4.2,1.25,1.5),trim)
	_box(self,Vector3(20,1.55,27.3),Vector3(1.2,0.9,0.15),_mat(Color(0.04,0.11,0.14),0.25))
	_box(self,Vector3(20,1.66,27.16),Vector3(1.06,0.72,0.04),_emission_material(Color(0.12,0.55,0.65)))
	_box(self,Vector3(27,0.08,49),Vector3(30,0.18,18),_mat(Color(0.19,0.23,0.26)))
	for x in [18.0,26.0,34.0]:
		_box(self,Vector3(x,0.19,48),Vector3(0.14,0.04,11),_mat(Color(0.88,0.82,0.61)))

func _spawn_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "PlayerOfficer"
	player.position = Vector3(20,0.2,45)
	add_child(player)
	patrol_car = CAR_SCRIPT.new()
	patrol_car.name = "PatrolSedan"
	patrol_car.position = Vector3(29,0.2,47)
	add_child(patrol_car)
	patrol_car.add_to_group("interactables")
	patrol_car.set_meta("interaction_type","vehicle")
	patrol_car.set_meta("prompt","خودروی گشت  •  E ورود")

func _spawn_citizens() -> void:
	var colors := [Color(0.36,0.4,0.56),Color(0.54,0.3,0.2),Color(0.25,0.46,0.39),Color(0.65,0.54,0.32)]
	var starts := [Vector3(-31,0.2,14),Vector3(-48,0.2,24),Vector3(58,0.2,-22),Vector3(65,0.2,34),Vector3(-24,0.2,-43),Vector3(14,0.2,-25),Vector3(-45,0.2,63),Vector3(43,0.2,68)]
	for i in range(starts.size()):
		var citizen: Variant = CITIZEN_SCRIPT.new()
		citizen.position = starts[i]
		var route: Array[Vector3] = [starts[i]+Vector3(7,0,0),starts[i]+Vector3(7,0,6),starts[i]+Vector3(-3,0,6),starts[i]]
		citizen.configure("CIT-%03d" % (i+1),route,colors[i%colors.size()])
		add_child(citizen)
		citizen.add_to_group("interactables")
		citizen.set_meta("interaction_type","citizen")
		citizen.set_meta("prompt","گفت‌وگو با شهروند  •  E")

func _spawn_traffic() -> void:
	traffic = TRAFFIC_SCRIPT.new()
	traffic.name = "TrafficManager"
	add_child(traffic)
	var routes: Array[Array] = [
		[Vector3(-94,0.2,4),Vector3(94,0.2,4),Vector3(94,0.2,-4),Vector3(-94,0.2,-4)],
		[Vector3(4,0.2,-94),Vector3(4,0.2,94),Vector3(-4,0.2,94),Vector3(-4,0.2,-94)],
		[Vector3(-94,0.2,54),Vector3(94,0.2,54),Vector3(94,0.2,46),Vector3(-94,0.2,46)],
		[Vector3(54,0.2,-94),Vector3(54,0.2,94),Vector3(46,0.2,94),Vector3(46,0.2,-94)]
	]
	traffic.populate(self,routes)

func _build_systems() -> void:
	missions = MISSION_SCRIPT.new()
	missions.name = "MissionManager"
	add_child(missions)
	weather = WEATHER_SCRIPT.new()
	weather.name = "WeatherController"
	add_child(weather)
	weather.configure(sun,environment_node,rain)
	var terminal := Node3D.new()
	terminal.name = "DispatchTerminal"
	terminal.position = Vector3(20,0,27)
	terminal.add_to_group("interactables")
	terminal.set_meta("interaction_type","dispatch")
	terminal.set_meta("prompt","رایانهٔ اعزام مأموریت  •  E")
	var glow := OmniLight3D.new()
	glow.position.y = 2.4
	glow.omni_range = 4.5
	glow.light_color = Color(0.18,0.68,0.92)
	glow.light_energy = 0.7
	terminal.add_child(glow)
	add_child(terminal)

func _build_hud() -> void:
	hud = HUD_SCRIPT.new()
	hud.name = "GameHUD"
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.dispatch_requested.connect(_open_dispatch)
	hud.accept_mission_requested.connect(_accept_mission)
	hud.save_requested.connect(_save_game)
	hud.language_requested.connect(func(): LocaleManager.toggle_language())
	hud.weather_requested.connect(_cycle_weather)
	hud.citizen_record_requested.connect(_record_citizen_contact)
	hud.panel_opened.connect(func(): get_tree().paused = true)
	hud.panel_closed.connect(func(): get_tree().paused = false)

func _restore_save() -> void:
	var data := SaveManager.load_game()
	if data.is_empty():
		return
	player.global_position = SaveManager.saved_position(data, player.global_position)
	missions.next_index = clampi(GameState.mission_index, 0, missions.catalogue.size())
	if not GameState.current_mission.is_empty():
		if missions.is_valid_mission_data(GameState.current_mission):
			missions.active_mission = GameState.current_mission.duplicate(true)
			missions.active = true
			_create_marker()
		else:
			push_warning("Saved active mission is invalid and was cleared.")
			GameState.current_mission.clear()

func _current_position() -> Vector3:
	return patrol_car.global_position if driving else player.global_position

func _update_hud() -> void:
	var mission_text := ""
	var distance := -1.0
	if missions.active:
		var title_key := "title_en" if LocaleManager.language == "en" else "title_fa"
		mission_text = str(missions.active_mission.get(title_key,""))
		var objective_progress: Dictionary = missions.get_objective_progress(LocaleManager.language)
		if not objective_progress.is_empty():
			var progress_label := LocaleManager.translate("objective_progress") % [
				int(objective_progress.get("index", 0)),
				int(objective_progress.get("total", 0))
			]
			mission_text += "\n%s — %s" % [progress_label, str(objective_progress.get("title", ""))]
		distance = _current_position().distance_to(_mission_target())
	var speed: float = float(patrol_car.get_speed()) if driving else 0.0
	var time_value: float = weather.day_time
	var hour := int(time_value)
	var minute := int((time_value-float(hour))*60.0)
	hud.update_hud(speed,mission_text,_district(_current_position()),"%02d:%02d" % [hour,minute],distance,driving,_current_position())

func _update_prompt() -> void:
	if driving:
		hud.set_prompt("E خروج از خودرو   •   Q چراغ هشدار   •   H بوق")
		return
	var nearest := _nearest_interactable(3.6)
	if nearest:
		hud.set_prompt(str(nearest.get_meta("prompt",LocaleManager.translate("interact"))))
	elif missions.active and missions.is_near_objective(player.global_position,4.0):
		var objective_title: String = str(missions.get_active_objective_title(LocaleManager.language))
		hud.set_prompt("%s: %s" % [LocaleManager.translate("objective_step"), objective_title])
	else:
		hud.set_prompt("")

func _interact() -> void:
	if driving:
		_exit_vehicle()
		return
	var nearest := _nearest_interactable(3.6)
	if nearest:
		match str(nearest.get_meta("interaction_type","")):
			"dispatch":
				_open_dispatch()
			"vehicle":
				_enter_vehicle()
			"citizen":
				active_citizen = nearest
				nearest.call("begin_talk")
				hud.show_citizen_dialog()
		return
	if missions.active and missions.is_near_objective(player.global_position,4.0):
		var result: Dictionary = missions.advance_active_objective(player.global_position, LocaleManager.language)
		if result.is_empty():
			return
		if bool(result.get("completed", false)):
			hud.show_notification(LocaleManager.translate("mission_done"))
			_save_game()
		else:
			var next_title: String = str(missions.get_active_objective_title(LocaleManager.language))
			var message := "%s: %s" % [LocaleManager.translate("objective_step_done"), next_title]
			if not SaveManager.save_game(_current_position()):
				message += " — " + LocaleManager.translate("save_failed")
			hud.show_notification(message)
		return
	hud.show_notification("مورد تعاملی نزدیکی پیدا نشد")

func _nearest_interactable(max_distance: float) -> Node3D:
	var nearest: Node3D
	var best := max_distance
	for node in get_tree().get_nodes_in_group("interactables"):
		if not node is Node3D or not is_instance_valid(node):
			continue
		var distance := _current_position().distance_to(node.global_position)
		if distance < best:
			best = distance
			nearest = node
	return nearest

func _open_dispatch() -> void:
	hud.show_dispatch(missions.get_next_mission())

func _accept_mission() -> void:
	if missions.accept_next_mission():
		_create_marker()
		hud.close_panels()
		hud.show_notification(LocaleManager.translate("mission_received"))
	else:
		hud.show_dispatch({})
		hud.show_notification(LocaleManager.translate("no_mission"))

func _mission_target() -> Vector3:
	if not missions.active:
		return Vector3.ZERO
	var location: Array = missions.active_mission.get("location",[0,0,0])
	return Vector3(float(location[0]),0.0,float(location[2]))

func _create_marker() -> void:
	_clear_marker()
	objective_marker = Node3D.new()
	objective_marker.position = _mission_target()
	var pole := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.055
	cylinder.bottom_radius = 0.055
	cylinder.height = 2.8
	pole.mesh = cylinder
	pole.position.y = 1.4
	pole.material_override = _emission_material(Color(0.08,0.42,0.72))
	objective_marker.add_child(pole)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 0.96
	ring.mesh = torus
	ring.position.y = 2.9
	ring.material_override = pole.material_override
	objective_marker.add_child(ring)
	add_child(objective_marker)

func _clear_marker() -> void:
	if is_instance_valid(objective_marker):
		objective_marker.queue_free()
	objective_marker = null

func _enter_vehicle() -> void:
	driving = true
	player.set_control_enabled(false)
	patrol_car.set_driven(true)
	hud.show_notification("خودروی گشت آماده حرکت است")

func _exit_vehicle() -> void:
	driving = false
	patrol_car.set_driven(false)
	player.global_position = patrol_car.global_position + patrol_car.global_transform.basis.x * 2.4
	player.global_position.y = 0.2
	player.set_control_enabled(true)

func _register_patrol_report() -> void:
	var p := _current_position()
	GameState.add_report({
		"case_id":"PAT-%06d" % (GameState.reports.size()+1),
		"event_type":"patrol_observation",
		"location":[snappedf(p.x,0.1),snappedf(p.y,0.1),snappedf(p.z,0.1)],
		"description":"گزارش گشت در ناحیهٔ %s" % _district(p),
		"actions":["گشت شهری","ثبت موقعیت","ذخیره گزارش"],
		"result":"logged",
		"timestamp":Time.get_datetime_string_from_system()
	})
	hud.show_notification(LocaleManager.translate("report_saved"))

func _record_citizen_contact() -> void:
	if is_instance_valid(active_citizen):
		active_citizen.call("end_talk")
	GameState.register_citizen_contact()
	var p := _current_position()
	GameState.add_report({
		"case_id":"CIV-%06d" % (GameState.reports.size()+1),
		"event_type":"citizen_assistance",
		"location":[snappedf(p.x,0.1),0.0,snappedf(p.z,0.1)],
		"description":"گفت‌وگوی محترمانه و ثبت درخواست شهروند",
		"actions":["شنیدن درخواست","ارائه راهنمایی","ثبت نتیجه"],
		"result":"assisted",
		"timestamp":Time.get_datetime_string_from_system()
	})
	hud.show_notification("درخواست شهروند ثبت شد")

func _mission_completed(_mission: Dictionary, _report: Dictionary) -> void:
	_clear_marker()

func _report_added(_report: Dictionary) -> void:
	pass

func _save_game() -> void:
	var success := SaveManager.save_game(_current_position())
	hud.show_notification(LocaleManager.translate("saved") if success else LocaleManager.translate("save_failed"))

func _cycle_weather() -> void:
	weather.cycle_weather()
	hud.show_notification("آب‌وهوا تغییر کرد")

func _build_city_manager() -> void:
	city_manager = CITY_MANAGER_SCENE.instantiate()
	city_manager.name = "CityManager"
	city_manager.connect("district_changed", Callable(self, "_on_district_changed"))
	add_child(city_manager)

func _on_district_changed(_previous_id: String, _current_id: String, label: String) -> void:
	if is_instance_valid(hud):
		hud.show_notification(label)

func _district(p: Vector3) -> String:
	if not is_instance_valid(city_manager):
		return "ناحیه شمالی" if LocaleManager.language == "fa" else "North District"
	return str(city_manager.call("get_district_label_at", p, LocaleManager.language))

func _add_road_segment(world_position: Vector3, width: float, orientation: CityRoadSegment.Axis) -> void:
	var segment := CITY_ROAD_SEGMENT_SCENE.instantiate() as CityRoadSegment
	if segment == null:
		push_error("City road segment scene could not be instantiated.")
		return
	segment.name = "RoadSegment_%s_%s" % [str(orientation), str(int(absf(world_position.x + world_position.z)))]
	segment.position = world_position
	segment.configure(width, 220.0, orientation)
	add_child(segment)

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
		parent.add_child(body)
	return mesh

func _mat(color: Color, roughness: float = 0.86) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _emission_material(color: Color) -> StandardMaterial3D:
	var material := _mat(color,0.3)
	material.emission_enabled = true
	material.emission = color
	return material

func _sign(pos: Vector3, value: String, tint: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.font_size = 30
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint.lightened(0.55)
	label.position = pos
	add_child(label)

func _tree(pos: Vector3) -> void:
	_box(self,pos+Vector3(0,1,0),Vector3(0.38,2,0.38),_mat(Color(0.23,0.15,0.09)))
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.45
	sphere.height = 2.7
	crown.mesh = sphere
	crown.material_override = _mat(Color(0.14,0.3,0.17),0.94)
	crown.position = pos+Vector3(0,2.65,0)
	add_child(crown)

func _bench(pos: Vector3) -> void:
	var wood := _mat(Color(0.35,0.22,0.12),0.78)
	var metal := _mat(Color(0.11,0.15,0.17),0.58)
	_box(self,pos+Vector3(0,0.65,0),Vector3(2.1,0.14,0.52),wood)
	_box(self,pos+Vector3(0,1.05,-0.2),Vector3(2.1,0.78,0.12),wood)
	_box(self,pos+Vector3(-0.8,0.32,0),Vector3(0.14,0.7,0.48),metal)
	_box(self,pos+Vector3(0.8,0.32,0),Vector3(0.14,0.7,0.48),metal)

func _street_lamp(pos: Vector3) -> void:
	var metal := _mat(Color(0.13,0.16,0.18),0.46)
	_box(self,pos+Vector3(0,3.1,0),Vector3(0.16,6.2,0.16),metal)
	_box(self,pos+Vector3(0.55,6,0),Vector3(1.1,0.12,0.22),metal)
	var light := OmniLight3D.new()
	light.position = pos+Vector3(0.95,5.8,0)
	light.omni_range = 10
	light.light_energy = 0.0
	light.light_color = Color(0.95,0.81,0.62)
	add_child(light)

func _traffic_light(pos: Vector3) -> void:
	var signal_node := TRAFFIC_SIGNAL_SCENE.instantiate() as TrafficSignalController
	if signal_node == null:
		push_error("Traffic signal scene could not be instantiated.")
		return
	signal_node.name = "TrafficSignal_%03d" % get_child_count()
	signal_node.position = pos
	add_child(signal_node)
