extends SceneTree
## Input, pause and preference regression checks; no player save is written.

var fails := 0
var checks := 0


func _initialize() -> void:
	await process_frame
	var G := root.get_node("GameState")
	var S := root.get_node("Settings")
	var story := root.get_node("Story")
	G.persist = false
	G.from_dict({})
	story.ui_enabled = false
	S.persist = false
	S.save_path = "user://test_controls.cfg"
	S.reset_controls()
	S.set_value("scroll_speed", 99.0)
	_eq("scroll speed is bounded", S.value("scroll_speed"), 2.0)
	S.set_value("scroll_speed", NAN)
	_eq("NaN setting falls back", S.value("scroll_speed"), 1.0)
	S.set_value("edge_scroll", "false")
	_eq("wrong boolean type falls back", S.value("edge_scroll"), true)
	S.set_value("unknown", 1)
	_eq("unknown setting ignored", S.values.has("unknown"), false)
	S.set_value("cursor_smoothing", 0.0)
	S.set_value("scroll_speed", 0.5)
	S.persist = true
	S.save_settings()
	S.values = {}
	S.load_settings()
	_eq("preferences survive reload", [S.value("cursor_smoothing"), S.value("scroll_speed")], [0.0, 0.5])
	S.persist = false
	G.reset()
	_eq("progress reset preserves controls", S.value("scroll_speed"), 0.5)

	var f: Node2D = load("res://scenes/forest/forest.tscn").instantiate()
	f.manual_mode = true
	f.swing_enabled = false
	root.add_child(f)
	f._axe.position = Vector2(100, 100)
	f._axe.target = Vector2(900, 600)
	f.virtual_cursor_active = true
	f.virtual_cursor = f._axe.target
	f._axe.tick(0.001, 0.1)
	_eq("zero smoothing follows pointer directly during hitstop", f._axe.position, Vector2(900, 600))
	S.set_value("cursor_smoothing", 1.0)
	f._axe.position = Vector2(100, 100)
	f._axe.target = Vector2(900, 600)
	f._axe.swing(0.5)
	f._axe.flush_impact()
	_eq("impact visually matches its target", f._axe.position, Vector2(900, 600))
	var t: Node2D = f.add_tree("kavak", 1000.0)
	f._shake_off = Vector2(24, 5)
	_eq("aim includes visible screen shake offset", f.strike_at(Vector2(1024, 705)), t)
	f._shake_off = Vector2.ZERO
	f.advance(0.001, 0.5)
	_near("shift clock uses real time during hitstop", f.time_left, 19.5)
	_near("duration uses real time", f.elapsed, 0.5)
	f.story_enabled = true
	f.ensure_forest(20000.0)
	_eq("preloading deep trees awards no exploration", G.max_depth, 0)
	t.set_meta("column", 36)
	f.hit_tree(t, 995.0, 700.0, 1.0, false)
	_eq("reaching a tree records its actual depth", G.max_depth, 37)
	f.story_enabled = false

	f.manual_mode = false
	f.set_process(false)
	f.virtual_cursor_active = true
	f.virtual_cursor = Vector2(800, 700)
	_escape()
	_eq("ESC opens the pause menu through input dispatch", paused, true)
	_eq("pause stops the scene tree", paused, true)
	_eq("pause menu remains available", f._pause_menu.visible, true)
	_eq("pause menu covers the viewport", f._pause_menu.size, root.get_visible_rect().size)
	var before: float = f.time_left
	f.advance(1.0)
	_near("paused shift loses no time", f.time_left, before)
	_escape()
	_eq("ESC resumes through input dispatch", paused, false)
	_eq("resume unpauses", paused, false)
	_eq("resume drops stale pending contact", f._axe.has_pending_impact(), false)
	f._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_eq("focus loss pauses automatically", paused, true)
	f.set_paused(false)
	S.set_value("auto_chop", false)
	f.swing_enabled = true
	f._swing_cd = 0.0
	f.advance(0.1)
	_eq("manual chopping waits for a held mouse button", f._axe.has_pending_impact(), false)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	f.advance(0.1)
	_eq("held mouse starts a manual chop", f._axe.has_pending_impact(), true)
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	f._axe.stop()
	f.swing_enabled = false
	S.set_value("auto_chop", true)
	S.set_value("auto_follow", false)
	S.set_value("edge_scroll", false)
	f.virtual_cursor = Vector2(1590, 700)
	f._update_camera(0.1)
	_near("edge scrolling can be disabled", f.cam_x, 0.0)
	S.set_value("edge_scroll", true)
	f.virtual_cursor = Vector2(1590, 50)
	f._update_camera(0.1)
	_near("HUD edge does not move the camera", f.cam_x, 0.0)
	f.virtual_cursor = Vector2(1600, 700)
	f._update_camera(0.1)
	_near("pointer outside viewport does not scroll", f.cam_x, 0.0)
	f.virtual_cursor = Vector2(1585, 700)
	f._update_camera(0.1)
	_near("camera speed preference scales edge movement", f.cam_x, 49.5)
	f.cam_x = 0.0
	f.virtual_cursor = Vector2(995, 700)
	t.hp = 1.0
	f._axe.target = f.virtual_cursor
	f._axe.swing(0.4)
	f.end_run()
	_eq("interactive run end completes the pending hit", t.state, t.State.FALLING)
	f.manual_mode = true
	root.remove_child(f)
	f.free()
	story.queue.clear()
	G.set_flag("kemal_challenge", true)
	f = load("res://scenes/forest/forest.tscn").instantiate()
	f.manual_mode = true
	f.swing_enabled = false
	root.add_child(f)
	f.story_enabled = true
	for i in 15:
		var chained: Node2D = f.add_tree("kavak", 1000.0 + i * 1000.0)
		f._begin_fall(chained, 1, 101)
	_eq("airborne chain grants no quest success", story.queue.has("kemal_defeat"), false)
	for i in 14:
		f._on_landed(f.trees[i])
	_eq("fourteen landed links do not complete fifteen-link quest", story.queue.has("kemal_defeat"), false)
	f._on_landed(f.trees[14])
	_eq("fifteen landed links complete the quest", story.queue.has("kemal_defeat"), true)
	root.remove_child(f)
	f.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(S.save_path))
	print("TEST_CONTROLS ", "OK (%d checks)" % checks if fails == 0 else "FAIL %d" % fails)
	quit(1 if fails > 0 else 0)


func _eq(label: String, actual: Variant, expected: Variant) -> void:
	checks += 1
	if actual != expected:
		fails += 1
		print("FAIL ", label, " got=", actual, " want=", expected)


func _near(label: String, actual: float, expected: float) -> void:
	_eq(label, absf(actual - expected) < 0.01, true)


func _escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
