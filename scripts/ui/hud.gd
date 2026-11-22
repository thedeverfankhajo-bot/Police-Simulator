extends CanvasLayer

signal dispatch_requested
signal accept_mission_requested
signal save_requested
signal language_requested
signal weather_requested
signal citizen_record_requested
signal panel_opened
signal panel_closed

var hud_speed: Label
var hud_clock: Label
var hud_mission: Label
var hud_trust: Label
var hud_distance: Label
var hud_position: Label
var hud_prompt: Label
var dispatch_panel: PanelContainer
var overlay: PanelContainer
var dispatch_title: Label
var dispatch_description: Label
var overlay_title: Label
var overlay_body: RichTextLabel
var dialogue: PanelContainer
var _overlay_content: VBoxContainer
var _volume_slider: HSlider
var _dialog_copy: Label
var _root: Control
var paused: bool = false
var _dialog_copy: Label

func _ready() -> void:
	_build()
	LocaleManager.language_changed.connect(_refresh_language)
	GameState.stats_changed.connect(_refresh_stats)
	_refresh_stats()

func _build() -> void:
	var root := Control.new()
	_root = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	var top := _make_panel(root, Vector2(0.02, 0.025), Vector2(0.98, 0.13))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	top.add_child(row)
	var brand := _label("POLICE  /  CITY SERVICES", 15, Color(0.42, 0.76, 0.94))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	var district := _label("NORTH DISTRICT", 14)
	row.add_child(district)
	hud_clock = _label("10:00", 15)
	row.add_child(hud_clock)
	hud_trust = _label("", 14, Color(0.44, 0.83, 0.66))
	row.add_child(hud_trust)
	hud_speed = _label("0 km/h", 18, Color(0.96, 0.78, 0.36))
	row.add_child(hud_speed)

	var left := _make_panel(root, Vector2(0.02, 0.16), Vector2(0.275, 0.57))
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 9)
	left.add_child(left_col)
	left_col.add_child(_label("GPS  /  CITY MAP", 12, Color(0.44, 0.78, 0.95)))
	var map := _make_panel(left_col, Vector2.ZERO, Vector2.ONE)
	map.custom_minimum_size = Vector2(0, 124)
	var map_text := _label("┌───────┬────────┐\n│ RES.  │ SHOP   │\n├── MAIN ROAD ───┤\n│ PARK  │ IND.   │\n└───────┴────────┘", 14, Color(0.65, 0.83, 0.85))
	map.add_child(map_text)
	hud_position = _label("GPS: X 000 / Z 000", 12, Color(0.68,0.82,0.87))
	left_col.add_child(hud_position)
	hud_distance = _label("فاصله تا هدف: —", 12, Color(0.75, 0.82, 0.87))
	left_col.add_child(hud_distance)
	hud_mission = _label(LocaleManager.tr("mission_none"), 15, Color(0.95, 0.79, 0.43))
	hud_mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_col.add_child(hud_mission)
	left_col.add_child(_label("WASD حرکت  •  Shift دویدن", 11, Color(0.58, 0.68, 0.76)))

	var right := _make_panel(root, Vector2(0.79, 0.16), Vector2(0.98, 0.72))
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 7)
	right.add_child(actions)
	actions.add_child(_label("CITY OPERATIONS", 12, Color(0.42, 0.76, 0.94)))
	_action(actions, "dispatch", func(): dispatch_requested.emit())
	_action(actions, "map", func(): _show_overlay("map"))
	_action(actions, "reports", func(): _show_overlay("reports"))
	_action(actions, "profile", func(): _show_overlay("profile"))
	_action(actions, "settings", func(): _show_overlay("settings"))
	_action(actions, "weather", func(): weather_requested.emit())
	_action(actions, "save", func(): save_requested.emit())
	_action(actions, "language", func(): language_requested.emit())

	hud_prompt = _label("", 16, Color(0.95, 0.83, 0.48))
	hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_prompt.anchor_left = 0.3
	hud_prompt.anchor_right = 0.7
	hud_prompt.anchor_top = 0.83
	hud_prompt.anchor_bottom = 0.9
	root.add_child(hud_prompt)

	var footer := _make_panel(root, Vector2(0.02, 0.92), Vector2(0.98, 0.98))
	footer.add_child(_label("WASD حرکت/رانندگی   •   E تعامل   •   M نقشه   •   J گزارش   •   Esc توقف", 11, Color(0.59, 0.69, 0.77)))

	dispatch_panel = _make_panel(root, Vector2(0.32, 0.28), Vector2(0.68, 0.7))
	dispatch_panel.visible = false
	var dispatch_col := VBoxContainer.new()
	dispatch_col.add_theme_constant_override("separation", 12)
	dispatch_panel.add_child(dispatch_col)
	dispatch_col.add_child(_label("DISPATCH  /  مرکز اعزام", 13, Color(0.44, 0.78, 0.95)))
	dispatch_title = _label("مأموریت آماده", 21, Color(0.96, 0.8, 0.46))
	dispatch_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dispatch_col.add_child(dispatch_title)
	dispatch_description = _label("", 15)
	dispatch_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dispatch_col.add_child(dispatch_description)
	_action(dispatch_col, "accept", func(): accept_mission_requested.emit())
	_action(dispatch_col, "close", func(): close_panels())

	overlay = _make_panel(root, Vector2(0.26, 0.19), Vector2(0.74, 0.8))
	overlay.visible = false
	var overlay_col := VBoxContainer.new()
	overlay_col.add_theme_constant_override("separation", 12)
	overlay.add_child(overlay_col)
	overlay_title = _label("", 22, Color(0.94, 0.79, 0.46))
	overlay_col.add_child(overlay_title)
	overlay_body = RichTextLabel.new()
	overlay_body.bbcode_enabled = true
	overlay_body.fit_content = true
	overlay_body.scroll_active = true
	overlay_body.custom_minimum_size = Vector2(0, 250)
	overlay_body.add_theme_color_override("default_color", Color(0.82, 0.88, 0.92))
	overlay_col.add_child(overlay_body)
	_overlay_content = overlay_col
	var volume_label := _label("صدای موتور و هشدار", 13, Color(0.62,0.76,0.83))
	overlay_col.add_child(volume_label)
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.value = AudioManager.master_volume
	_volume_slider.value_changed.connect(func(value: float): AudioManager.master_volume = value)
	overlay_col.add_child(_volume_slider)
	_action(overlay_col, "back", func(): close_panels())

	dialogue = _make_panel(root, Vector2(0.3, 0.32), Vector2(0.7, 0.68))
	dialogue.visible = false
	var dialog_col := VBoxContainer.new()
	dialogue.add_child(dialog_col)
	dialog_col.add_child(_label("CITIZEN SERVICES  /  گفت‌وگو", 14, Color(0.43, 0.77, 0.93)))
	var dialog_copy := _label(LocaleManager.tr("citizen_text"), 17)
	_dialog_copy = dialog_copy
	dialog_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_col.add_child(dialog_copy)
	_action(dialog_col, "record", func(): citizen_record_requested.emit(); close_panels())
	_action(dialog_col, "close", func(): close_panels())

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _make_panel(parent: Control, from: Vector2, to: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = from.x
	panel.anchor_top = from.y
	panel.anchor_right = to.x
	panel.anchor_bottom = to.y
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.065, 0.92), Color(0.12, 0.23, 0.31, 0.88)))
	panel.add_theme_constant_override("margin_left", 13)
	panel.add_theme_constant_override("margin_right", 13)
	panel.add_theme_constant_override("margin_top", 9)
	panel.add_theme_constant_override("margin_bottom", 9)
	parent.add_child(panel)
	return panel

func _label(value: String, size: int = 14, tint: Color = Color(0.83, 0.88, 0.92)) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label

func _action(parent: Control, key: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = LocaleManager.tr(key)
	button.set_meta("translation_key", key)
	button.add_to_group("localized_buttons")
	button.custom_minimum_size = Vector2(0, 32)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", Color(0.83, 0.9, 0.94))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.06, 0.105, 0.14, 0.95), Color(0.16, 0.32, 0.4)))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.1, 0.2, 0.26, 0.98), Color(0.26, 0.56, 0.66)))
	button.pressed.connect(callback)
	parent.add_child(button)

func update_hud(speed: float, mission_name: String, district: String, clock_text: String, distance: float, driving: bool, world_position: Vector3) -> void:
	hud_speed.text = "%.0f km/h" % speed if driving else LocaleManager.tr("on_foot")
	hud_mission.text = mission_name if mission_name != "" else LocaleManager.tr("mission_none")
	hud_clock.text = clock_text
	hud_position.text = "GPS: X %.0f  /  Z %.0f" % [world_position.x, world_position.z]
	hud_distance.text = "%s: %.0f m" % [LocaleManager.tr("distance"), distance] if distance >= 0.0 else "%s: —" % LocaleManager.tr("distance")

func set_prompt(value: String) -> void:
	hud_prompt.text = value

func show_dispatch(mission: Dictionary) -> void:
	if mission.is_empty():
		dispatch_title.text = LocaleManager.tr("no_mission")
		dispatch_description.text = LocaleManager.tr("mission_none")
	else:
		var title_key := "title_en" if LocaleManager.language == "en" else "title_fa"
		var description_key := "description_en" if LocaleManager.language == "en" else "description_fa"
		dispatch_title.text = str(mission.get(title_key, mission.get("id", "")))
		dispatch_description.text = "%s\n\n%s: %s\nپاداش: %d XP" % [str(mission.get(description_key, "")), LocaleManager.tr("case"), str(mission.get("id", "")), int(mission.get("reward", 0))]
	dispatch_panel.visible = true
	overlay.visible = false
	_set_mouse(true)

func show_citizen_dialog() -> void:
	dialogue.visible = true
	_set_mouse(true)
	panel_opened.emit()

func show_notification(message: String) -> void:
	hud_prompt.text = message

func _show_overlay(kind: String) -> void:
	var title := kind
	var body := ""
	match kind:
		"map":
			title = LocaleManager.tr("map")
			body = "[color=#7fc6dc]NORTH DISTRICT[/color]\n\n┌──────────────┬──────────────┐\n│ RESIDENTIAL  │ COMMERCIAL   │\n├────── MAIN BOULEVARD ──────┤\n│ PUBLIC PARK  │ INDUSTRIAL   │\n├──────────────┼──────────────┤\n│        POLICE STATION       │\n└────────────────────────────┘\n\nنقشهٔ شماتیک محله‌ها و بلوار اصلی"
		"reports":
			title = LocaleManager.tr("reports")
			if GameState.reports.is_empty():
				body = LocaleManager.tr("no_reports")
			else:
				for report in GameState.reports:
					body += "[b]%s[/b]  •  %s\n%s\nنتیجه: %s\n\n" % [str(report.get("case_id", "")), str(report.get("event_type", "")), str(report.get("description", "")), str(report.get("result", ""))]
		"profile":
			title = LocaleManager.tr("profile")
			body = "%s: %d\n%s: %d\n%s: %d%%\n%s: %d\nامتیاز: %d" % [LocaleManager.tr("level"), GameState.level, LocaleManager.tr("xp"), GameState.experience, LocaleManager.tr("trust"), GameState.public_trust, LocaleManager.tr("missions"), GameState.missions_completed, GameState.score]
		"settings":
			title = LocaleManager.tr("settings_title")
			body = "Graphics: Balanced\nAudio: Procedural patrol engine tone\nControls: WASD / Mouse / E\nAccessibility: فارسی / English"
	overlay_title.text = title
	overlay_body.text = body
	_volume_slider.visible = kind == "settings"
	overlay.visible = true
	dispatch_panel.visible = false
	_set_mouse(true)
	panel_opened.emit()

func close_panels() -> void:
	var was_open := is_panel_open()
	dispatch_panel.visible = false
	overlay.visible = false
	dialogue.visible = false
	_set_mouse(false)
	if was_open:
		panel_closed.emit()

func is_panel_open() -> bool:
	return dispatch_panel.visible or overlay.visible or dialogue.visible

func _set_mouse(open: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED

func _refresh_stats() -> void:
	if is_instance_valid(hud_trust):
		hud_trust.text = "%s: %d%%" % [LocaleManager.tr("trust"), GameState.public_trust]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and is_panel_open():
		close_panels()
		get_viewport().set_input_as_handled()

func _refresh_language(_code: String) -> void:
	_refresh_stats()
	if is_instance_valid(_root):
		_root.layout_direction = Control.LAYOUT_DIRECTION_RTL if LocaleManager.language == "fa" else Control.LAYOUT_DIRECTION_LTR
	for item in get_tree().get_nodes_in_group("localized_buttons"):
		if is_instance_valid(item) and item is Button:
			item.text = LocaleManager.tr(str(item.get_meta("translation_key", "")))
	if is_instance_valid(_dialog_copy):
		_dialog_copy.text = LocaleManager.tr("citizen_text")
