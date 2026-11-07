extends Node
## Scene-independent mixer. Cosmetic randomness never touches the gameplay RNG.
## Headless tests/simulations stay silent unless they explicitly enable this node.

signal cue_played(id: String)

const MIX_BUS := "BaltaciMix"
const SFX_BUS := "BaltaciEffects"
const AMBIENCE_BUS := "BaltaciAmbience"
const SFX_ROOT := "res://audio/sfx/"

var enabled := true
var config: Dictionary = {}
var _world_voices: Array[AudioStreamPlayer] = []
var _ui_voices: Array[AudioStreamPlayer] = []
var _ambience: AudioStreamPlayer
var _ambience_wanted := false
var _ambience_tween: Tween
var _cache: Dictionary = {}
var _next_allowed: Dictionary = {}
var _last_variant: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _focused := true
var _quitting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	enabled = DisplayServer.get_name() != "headless" and not OS.get_cmdline_user_args().has("--no-audio")
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio.json"))
	_rng.randomize()
	_ensure_bus(MIX_BUS, "Master")
	_ensure_bus(SFX_BUS, MIX_BUS)
	_ensure_bus(AMBIENCE_BUS, MIX_BUS)
	var mix_index := AudioServer.get_bus_index(MIX_BUS)
	if AudioServer.get_bus_effect_count(mix_index) == 0:
		var limiter := AudioEffectHardLimiter.new()
		limiter.ceiling_db = float(config.get("limiter_ceiling_db", -2.0))
		AudioServer.add_bus_effect(mix_index, limiter)
	for i in int(config.get("world_voices", 8)):
		_world_voices.append(_make_player(SFX_BUS, Node.PROCESS_MODE_PAUSABLE))
	for i in int(config.get("ui_voices", 3)):
		_ui_voices.append(_make_player(SFX_BUS, Node.PROCESS_MODE_ALWAYS))
	_ambience = _make_player(AMBIENCE_BUS, Node.PROCESS_MODE_PAUSABLE)
	var ambient_stream := stream_for(str(config.ambience.file))
	if ambient_stream != null:
		# This private stream belongs to the mixer, not a shared imported resource.
		ambient_stream = ambient_stream.duplicate()
		ambient_stream.set("loop", true)
		_ambience.stream = ambient_stream
	for cue in config.cues.values():
		for file in cue.files:
			stream_for(SFX_ROOT + str(file))
	Settings.changed.connect(_apply_levels)
	get_tree().node_added.connect(_on_node_added)
	_apply_levels()


func _ensure_bus(bus_name: String, send: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, send)


func _make_player(bus_name: String, mode: Node.ProcessMode) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	player.process_mode = mode
	add_child(player)
	return player


func stream_for(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path, "AudioStream"):
		stream = load(path) as AudioStream
	elif FileAccess.file_exists(path):
		# Also works on a fresh source checkout before the editor imports audio.
		if path.ends_with(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(path)
		elif path.ends_with(".mp3"):
			stream = AudioStreamMP3.load_from_file(path)
	_cache[path] = stream
	return stream


func play(id: String) -> bool:
	if not enabled or not _focused or bool(Settings.value("audio_muted")):
		return false
	if float(Settings.value("master_volume")) <= 0.0 or float(Settings.value("sfx_volume")) <= 0.0:
		return false
	var cue: Dictionary = config.get("cues", {}).get(id, {})
	if cue.is_empty():
		return false
	var ui := bool(cue.get("ui", false))
	if get_tree().paused and not ui:
		return false
	var group := str(cue.get("group", id))
	var now := Time.get_ticks_msec()
	if now < int(_next_allowed.get(group, 0)):
		return false
	var voices: Array[AudioStreamPlayer] = _ui_voices if ui else _world_voices
	var voice: AudioStreamPlayer = null
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		return false   # bound simultaneous voices; chains never allocate extra players
	var files: Array = cue.get("files", [])
	if files.is_empty():
		return false
	var variant := _rng.randi_range(0, files.size() - 1)
	if files.size() > 1 and variant == int(_last_variant.get(id, -1)):
		variant = (variant + 1) % files.size()
	var stream := stream_for(SFX_ROOT + str(files[variant]))
	if stream == null:
		return false
	_last_variant[id] = variant
	_next_allowed[group] = now + roundi(float(cue.get("interval", 0.0)) * 1000.0)
	voice.stream = stream
	voice.volume_db = float(cue.get("volume_db", -12.0))
	voice.pitch_scale = _rng.randf_range(float(cue.get("pitch_min", 1.0)), float(cue.get("pitch_max", 1.0)))
	voice.play()
	cue_played.emit(id)
	return true


func set_ambience(on: bool) -> void:
	_ambience_wanted = on
	if on and _ambience.playing:
		return   # scene changes preserve the current loop and its entrance fade
	if _ambience_tween != null:
		_ambience_tween.kill()
	if not on:
		_ambience.stop()
		return
	if not enabled or _ambience.stream == null:
		return
	if not _ambience.playing:
		_ambience.volume_db = -60.0
		_ambience.play()
		_ambience_tween = create_tween()
		_ambience_tween.tween_property(_ambience, "volume_db", float(config.ambience.volume_db), float(config.ambience.fade_seconds))


func _apply_levels() -> void:
	var master := float(Settings.value("master_volume"))
	var muted := bool(Settings.value("audio_muted")) or not _focused
	_set_bus_level(MIX_BUS, master, muted)
	_set_bus_level(SFX_BUS, float(Settings.value("sfx_volume")), false)
	_set_bus_level(AMBIENCE_BUS, float(Settings.value("ambience_volume")), false)
	if _ambience_wanted and enabled and not _ambience.playing:
		set_ambience(true)


func _set_bus_level(bus_name: String, volume: float, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, muted or volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))


func stop_effects() -> void:
	for player in _world_voices + _ui_voices:
		player.stop()
	_next_allowed.clear()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(_button_pressed.bind(node))


func _button_pressed(button: BaseButton) -> void:
	if button.is_visible_in_tree() and not button.disabled:
		play("click")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		_quit_cleanly()
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
	else:
		return
	if is_node_ready():
		_apply_levels()


func _quit_cleanly() -> void:
	if _quitting:
		return
	_quitting = true
	await drain()
	get_tree().quit()


func drain() -> void:
	var had_playback := _ambience.playing
	for voice in _world_voices + _ui_voices:
		had_playback = had_playback or voice.playing
	enabled = false
	stop_effects()
	set_ambience(false)
	# Godot releases audio decoders asynchronously; allow the mix to drain before exit.
	if had_playback:
		await get_tree().create_timer(0.15, true, false, true).timeout
