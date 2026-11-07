extends SceneTree
## Decode real assets, exercise gameplay hooks, validate mixing and saved preferences.
## Test files and player progression are isolated from the real save.

var fails := 0
var checks := 0


func _initialize() -> void:
	await process_frame
	var G := root.get_node("GameState")
	var S := root.get_node("Settings")
	var A := root.get_node("Sound")
	var story := root.get_node("Story")
	G.persist = false
	G.from_dict({})
	S.persist = false
	S.save_path = "user://test_audio.cfg"
	S.reset_controls()
	story.ui_enabled = false
	_eq("headless simulations start silent", A.enabled, false)
	for id in A.config.cues:
		for file in A.config.cues[id].files:
			_ok("no door creak is used: " + str(file), not str(file).begins_with("creak"))
			var stream: AudioStream = A.stream_for(A.SFX_ROOT + str(file))
			_ok("decodes " + str(file), stream != null and stream.get_length() > 0.0)
	_ok("ambient stream is a real loop", A._ambience.stream != null and A._ambience.stream.loop and A._ambience.stream.get_length() > 10.0)
	_eq("one limiter protects the combined mix", AudioServer.get_bus_effect_count(AudioServer.get_bus_index(A.MIX_BUS)), 1)
	_eq("missing sound file is harmless", A.stream_for("res://audio/missing.ogg"), null)
	A.enabled = true
	A._focused = true
	S.set_value("master_volume", 0.5)
	S.set_value("sfx_volume", 0.25)
	_near("master gain is correct", AudioServer.get_bus_volume_db(AudioServer.get_bus_index(A.MIX_BUS)), -6.0206)
	_near("effects gain is independent", AudioServer.get_bus_volume_db(AudioServer.get_bus_index(A.SFX_BUS)), -12.0412)
	S.set_value("audio_muted", true)
	_eq("mute reaches the actual mixer", AudioServer.is_bus_mute(AudioServer.get_bus_index(A.MIX_BUS)), true)
	_eq("muted effects start no voices", A.play("hit"), false)
	S.set_value("audio_muted", false)
	S.set_value("sfx_volume", 0.0)
	_eq("zero effect volume suppresses playback", A.play("hit"), false)
	S.set_value("sfx_volume", 0.8)
	S.set_value("master_volume", 0.65)
	S.persist = true
	S.save_settings()
	S.persist = false
	S.values = S.defaults.duplicate()
	S.load_settings()
	_near("audio preferences survive reload", float(S.value("master_volume")), 0.65)
	S.set_value("ambience_volume", INF)
	_near("invalid volume uses safe default", float(S.value("ambience_volume")), 0.4)
	var old_config := ConfigFile.new()
	old_config.set_value("controls", "edge_scroll", false)
	old_config.save(S.save_path)
	S.load_settings()
	_near("old preference files gain audio defaults", float(S.value("master_volume")), 0.75)
	_eq("old control preference is preserved", S.value("edge_scroll"), false)

	var played: Array[String] = []
	A.cue_played.connect(func(id: String) -> void: played.append(id))
	A.stop_effects()
	_eq("unknown cue is harmless", A.play("missing"), false)
	_eq("first landing has sound", A.play("land"), true)
	_eq("simultaneous landings are rate limited", A.play("land"), false)
	A.stop_effects()
	var accepted := 0
	for i in 100:
		A._next_allowed.clear()
		if A.play("land"):
			accepted += 1
	_eq("a cascade cannot grow the voice pool", accepted, int(A.config.world_voices))
	_eq("voice pool stays bounded", A._world_voices.size(), int(A.config.world_voices))
	A.stop_effects()
	A.set_ambience(true)
	_eq("ambient loop starts", A._ambience.playing, true)
	var fade: Tween = A._ambience_tween
	A.set_ambience(true)
	_eq("scene changes preserve the ambience fade", A._ambience_tween, fade)
	paused = true
	_eq("world effects cannot start while paused", A.play("hit"), false)
	_eq("ambient playback follows pause", A._ambience.can_process(), false)
	_eq("menu effects still work while paused", A.play("click"), true)
	paused = false
	A._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_eq("focus loss silences the whole mixer", AudioServer.is_bus_mute(AudioServer.get_bus_index(A.MIX_BUS)), true)
	_eq("background window cannot start effects", A.play("buy"), false)
	A._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_eq("focus return restores configured volume", AudioServer.is_bus_mute(AudioServer.get_bus_index(A.MIX_BUS)), false)
	A.stop_effects()
	played.clear()

	var f: Node2D = load("res://scenes/forest/forest.tscn").instantiate()
	f.manual_mode = true
	f.swing_enabled = false
	root.add_child(f)
	var tree: Node2D = f.add_tree("kavak", 1000.0)
	f.hit_tree(tree, 995.0, 700.0, 1.0, false)
	_ok("actual axe hit triggers wood sound", played.has("hit"))
	A.stop_effects()
	played.clear()
	f.hit_tree(tree, 995.0, 700.0, 1.0, true)
	_ok("critical hit has its own sound", played.has("crit"))
	A.stop_effects()
	played.clear()
	tree.hp = 1.0
	f.hit_tree(tree, 995.0, 700.0, 1.0, false)
	_ok("felling triggers a short wood tap", played.has("crack"))
	A.stop_effects()
	played.clear()
	f._on_landed(tree)
	_ok("ground contact triggers landing sound", played.has("land"))
	A.stop_effects()
	played.clear()
	f._complete()
	_ok("results trigger confirmation", played.has("result"))
	root.remove_child(f)
	f.free()
	A.stop_effects()
	played.clear()
	G.gold = 1000.0
	var camp: Control = load("res://scenes/camp/camp.tscn").instantiate()
	root.add_child(camp)
	camp._on_buy("axe_damage")
	_ok("successful purchase triggers coins", played.has("buy"))
	camp._settings_overlay.visible = true
	_eq("audio tab is present", camp._settings_overlay._tabs.get_tab_title(1), "Ses")
	_ok("volume controls exist in the live menu", camp._settings_overlay._widgets.has("master_volume") and camp._settings_overlay._widgets.has("ambience_volume"))
	root.remove_child(camp)
	camp.free()
	A.stop_effects()
	A.enabled = false
	A.set_ambience(false)
	_eq("disabled mixer can still stop ambience", A._ambience.playing, false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(S.save_path))
	# Give the Dummy audio driver's mix/cleanup cycle time to release stopped decoders.
	for i in 10:
		OS.delay_msec(25)
		await process_frame
	print("TEST_AUDIO ", "OK (%d checks)" % checks if fails == 0 else "FAIL %d of %d" % [fails, checks])
	quit(1 if fails > 0 else 0)


func _eq(label: String, actual: Variant, expected: Variant) -> void:
	checks += 1
	if actual != expected:
		fails += 1
		print("FAIL ", label, " got=", actual, " want=", expected)


func _ok(label: String, actual: bool) -> void:
	_eq(label, actual, true)


func _near(label: String, actual: float, expected: float) -> void:
	_eq(label, absf(actual - expected) < 0.01, true)
