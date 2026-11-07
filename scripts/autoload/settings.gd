extends Node
## Preferences are independent of progression; resetting a game preserves controls.

signal changed

var save_path := "user://settings.cfg"
var persist := true
var defaults: Dictionary = {}
var values: Dictionary = {}


func _ready() -> void:
	defaults = JSON.parse_string(FileAccess.get_file_as_string("res://data/controls.json"))
	values = defaults.duplicate()
	for arg in OS.get_cmdline_user_args():
		if arg == "--no-save" or arg.begins_with("--autoshot") or arg.begins_with("--autoplay"):
			persist = false
	load_settings()


func value(key: String):
	return values.get(key, defaults.get(key))


func set_value(key: String, new_value: Variant) -> void:
	if not defaults.has(key):
		return
	var clean: Variant = _validated(key, new_value)
	if values.get(key) == clean:
		return
	values[key] = clean
	save_settings()
	changed.emit()


func _validated(key: String, candidate: Variant) -> Variant:
	if typeof(defaults[key]) == TYPE_BOOL:
		return candidate if typeof(candidate) == TYPE_BOOL else defaults[key]
	if typeof(candidate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(candidate)):
		return defaults[key]
	if key == "scroll_speed":
		return clampf(float(candidate), 0.25, 2.0)
	return clampf(float(candidate), 0.0, 1.0)


func load_settings() -> void:
	var config := ConfigFile.new()
	values = defaults.duplicate()
	if config.load(save_path) == OK:
		for key in defaults:
			values[key] = _validated(key, config.get_value("controls", key, defaults[key]))
	changed.emit()


func save_settings() -> void:
	if not persist:
		return
	var config := ConfigFile.new()
	for key in values:
		config.set_value("controls", key, values[key])
	var err := config.save(save_path)
	if err != OK:
		push_warning("Ayarlar kaydedilemedi: %s" % error_string(err))


func reset_controls() -> void:
	values = defaults.duplicate()
	save_settings()
	changed.emit()
