extends Control
## Shared route map: checkpoint progress during a shift, unlocked chapter selection at camp.

signal chapter_selected(id: String)

const Juice := preload("res://scenes/ui/juice.gd")
const GOLD := Color("ffd579")
const CREAM := Color("f8ecd2")
const GREEN := Color("98cc77")
const MUTED := Color("a29480")

var interactive := false
var selected_id := ""
var progress: Dictionary = {}
var live_count := -1
var replay := false
var _buttons: Array[Button] = []
var _box: StyleBox
var _face: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = Juice.panel_box(Color(0.35, 0.28, 0.24), 18, 4)
	if _box == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("30251c", 0.95)
		flat.border_color = Color("936c41")
		flat.set_border_width_all(2)
		flat.set_corner_radius_all(16)
		_box = flat
	_face = Art.tex("ui/pipsy_happy")
	if interactive:
		for chapter in Chapters.definitions:
			var button := Button.new()
			button.flat = true
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			var hover := StyleBoxFlat.new()
			hover.bg_color = Color(1.0, 0.85, 0.5, 0.1)
			hover.set_corner_radius_all(12)
			button.add_theme_stylebox_override("hover", hover)
			button.add_theme_stylebox_override("pressed", hover)
			button.pressed.connect(func() -> void: chapter_selected.emit(str(chapter.id)))
			add_child(button)
			_buttons.append(button)
	resized.connect(_layout)
	_layout()
	queue_redraw()


func set_state(id: String, saved: Dictionary, cleared: int = -1, is_replay: bool = false) -> void:
	if selected_id == id and progress == saved and live_count == cleared and replay == is_replay:
		return
	selected_id = id
	progress = saved.duplicate(true)
	live_count = cleared
	replay = is_replay
	_layout()
	queue_redraw()


func _layout() -> void:
	if _buttons.is_empty():
		return
	var width := (size.x - 64.0) / float(Chapters.definitions.size())
	for i in _buttons.size():
		var chapter: Dictionary = Chapters.definitions[i]
		var button := _buttons[i]
		button.position = Vector2(32.0 + width * i, 38.0)
		button.size = Vector2(width, size.y - 70.0)
		button.disabled = not Chapters.is_unlocked(str(chapter.id), progress)
		button.tooltip_text = "%s · %d/%d ağaç%s" % [chapter.name, Chapters.cleared_count(str(chapter.id), progress), int(chapter.tree_count), " · Önce önceki bölümü tamamla" if button.disabled else ""]


func _draw() -> void:
	if _box == null or Chapters.definitions.is_empty():
		return
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	var chapter := Chapters.get_chapter(selected_id)
	if chapter.is_empty():
		chapter = Chapters.definitions[0]
	var index := Chapters.index_of(str(chapter.id))
	var done := live_count if live_count >= 0 else Chapters.cleared_count(str(chapter.id), progress)
	var total := int(chapter.tree_count)
	var ratio := clampf(float(done) / float(total), 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var title := "Bölüm %d/%d · %s · %d/%d ağaç%s" % [index + 1, Chapters.definitions.size(), chapter.name, done, total, " · Tekrar" if replay else ""]
	draw_string(font, Vector2(20, 28), title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 40.0, 21, CREAM)
	var left := 32.0
	var step := (size.x - left * 2.0) / float(Chapters.definitions.size())
	var route_y := size.y * 0.48
	for i in Chapters.definitions.size():
		var def: Dictionary = Chapters.definitions[i]
		var x := left + step * i
		var unlocked := Chapters.is_unlocked(str(def.id), progress)
		var complete := Chapters.is_complete(str(def.id), progress)
		var color := GREEN if complete else (GOLD if i == index else MUTED)
		draw_line(Vector2(x, route_y), Vector2(x + step, route_y), Color("554737"), 8.0, true)
		var fill := 1.0 if complete else 0.0
		if i == index and live_count >= 0:
			fill = ratio
		if fill > 0.0:
			draw_line(Vector2(x, route_y), Vector2(x + step * fill, route_y), color, 5.0, true)
		var end := Vector2(x + step * 0.5, route_y)
		draw_circle(end, 13.0, Color("30251c"))
		draw_arc(end, 13.0, 0.0, TAU, 28, color if unlocked else MUTED, 2.0, true)
		draw_string(font, end + Vector2(-12, 6), "✓" if complete else str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 24.0, 17, color)
		draw_string(font, Vector2(x, route_y + 36.0), str(def.short_name), HORIZONTAL_ALIGNMENT_CENTER, step, 18, CREAM if unlocked else MUTED)
	var marker := Vector2(left + step * (float(index) + ratio), route_y - 27.0)
	if _face != null:
		draw_texture_rect(_face, Rect2(marker - Vector2(22, 26), Vector2(44, 44)), false)
	else:
		draw_circle(marker, 8.0, GOLD)
	draw_colored_polygon(PackedVector2Array([marker + Vector2(-5, 17), marker + Vector2(5, 17), marker + Vector2(0, 24)]), GOLD)
	var bar := Rect2(24, size.y - 21, size.x - 48.0, 5.0)
	draw_rect(bar, Color("554737"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), GOLD)
