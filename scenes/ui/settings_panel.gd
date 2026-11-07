extends Control
## Shared camp preferences and in-run pause menu.

signal closed
signal reset_requested

const UiTheme := preload("res://scenes/ui/ui_theme.gd")

var in_run := false
var _widgets: Dictionary = {}
var _tabs: TabContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.68)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 740
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Vardiya duraklatıldı" if in_run else "Ayarlar"
	title.theme_type_variation = "TitleLabel"
	box.add_child(title)
	var help := Label.new()
	help.text = "Fareyle nişan al · A/D veya ←/→ ile ilerle\nESC: duraklat / devam et · Altın otomatik kaydedilir."
	help.add_theme_font_size_override("font_size", 20)
	box.add_child(help)
	box.add_child(HSeparator.new())
	_tabs = TabContainer.new()
	_tabs.custom_minimum_size.y = 470
	box.add_child(_tabs)
	var controls := VBoxContainer.new()
	controls.name = "Fare"
	controls.add_theme_constant_override("separation", 10)
	_tabs.add_child(controls)
	_toggle(controls, "edge_scroll", "Fare kenara gelince kamerayı kaydır")
	_toggle(controls, "auto_follow", "Kesilen ağaçların ardından kamerayı ilerlet")
	_slider(controls, "scroll_speed", "Kamera kaydırma hızı", 0.25, 2.0, 0.05)
	_slider(controls, "cursor_smoothing", "Balta yumuşatma (0 = doğrudan takip)", 0.0, 1.0, 0.05)
	_toggle(controls, "auto_chop", "Otomatik vuruş (kapalıysa sol fareyi basılı tut)")
	_toggle(controls, "screen_shake", "Ekran sarsıntısı")
	var audio_tab := VBoxContainer.new()
	audio_tab.name = "Ses"
	audio_tab.add_theme_constant_override("separation", 12)
	_tabs.add_child(audio_tab)
	_toggle(audio_tab, "audio_muted", "Tüm sesleri kapat")
	_slider(audio_tab, "master_volume", "Genel ses seviyesi", 0.0, 1.0, 0.05)
	_slider(audio_tab, "sfx_volume", "Balta, ağaç ve arayüz sesleri", 0.0, 1.0, 0.05)
	_slider(audio_tab, "ambience_volume", "Orman ambiyansı", 0.0, 1.0, 0.05)
	var preview := Button.new()
	preview.text = "Sesi dene"
	preview.pressed.connect(func() -> void: Sound.play("hit"))
	audio_tab.add_child(preview)
	var audio_note := Label.new()
	audio_note.text = "Ses ayarları otomatik kaydedilir.\nPencereden ayrıldığında sesler de durur."
	audio_note.add_theme_font_size_override("font_size", 18)
	audio_tab.add_child(audio_note)
	_tabs.tab_changed.connect(func(_index: int) -> void: Sound.play("click"))
	box.add_child(HSeparator.new())
	var restore := Button.new()
	restore.text = "Ayarları varsayılana döndür"
	restore.pressed.connect(Settings.reset_controls)
	box.add_child(restore)
	if not in_run:
		var reset := Button.new()
		reset.text = "İlerlemeyi Sıfırla"
		reset.theme_type_variation = "DangerButton"
		reset.pressed.connect(func() -> void: reset_requested.emit())
		box.add_child(reset)
	var close := Button.new()
	close.text = "Devam et" if in_run else "Kapat"
	close.pressed.connect(func() -> void: closed.emit())
	box.add_child(close)
	Settings.changed.connect(_refresh)
	_refresh()


func _toggle(box: VBoxContainer, key: String, text: String) -> void:
	var button := CheckButton.new()
	button.text = text
	button.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	box.add_child(button)
	_widgets[key] = button


func _slider(box: VBoxContainer, key: String, text: String, low: float, high: float, step: float) -> void:
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var amount := Label.new()
	amount.custom_minimum_size.x = 60
	row.add_child(amount)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.custom_minimum_size.y = 24
	slider.value_changed.connect(func(v: float) -> void: Settings.set_value(key, v))
	box.add_child(slider)
	_widgets[key] = {"slider": slider, "amount": amount}


func _refresh() -> void:
	for key in _widgets:
		var widget: Variant = _widgets[key]
		if widget is CheckButton:
			widget.set_pressed_no_signal(bool(Settings.value(key)))
		else:
			widget.slider.set_value_no_signal(float(Settings.value(key)))
			widget.amount.text = "%d%%" % roundi(float(Settings.value(key)) * 100.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		closed.emit()
