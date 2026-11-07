extends SceneTree

var fails := 0
var checks := 0


func _initialize() -> void:
	await process_frame
	var G := root.get_node("GameState")
	G.persist = false
	G.from_dict({})
	var story := root.get_node("Story")
	story.ui_enabled = false
	for id in ["kemal_defeat", "depth100"]:
		var has_map := false
		for line in story.get_beat(id).lines:
			if line.get("show", "") == "story/map_piece":
				has_map = true
		_eq("map card is wired in " + id, has_map, true)
	var box: CanvasLayer = load("res://scenes/story/dialogue_box.tscn").instantiate()
	root.add_child(box)
	box._show_card("story/map_piece")
	_eq("map has a rendered card", box._card != null and box._card.texture != null, true)
	box._show_card("missing/card")
	_eq("missing art clears card without crashing", box._card, null)
	box._show_card("story/map_piece")
	box._cleanup()
	_eq("closing clears card", box._card, null)
	root.remove_child(box)
	box.free()
	var hud: GDScript = load("res://scenes/forest/forest_hud.gd")
	_eq("first run reaction is encouraging", hud.reaction_kind(2, 0, 0, false), "happy")
	_eq("personal improvement gets happy reaction", hud.reaction_kind(120, 100, 200, true), "happy")
	_eq("poor run compares with personal average", hud.reaction_kind(50, 100, 200, true), "cry")
	_eq("ordinary run is neutral", hud.reaction_kind(100, 100, 200, true), "")
	hud.record_total(100)
	hud.record_total(200)
	_eq("run average is an EMA", float(G.get_flag(hud.FLAG_AVG)), 135.0)
	_eq("best total stays separate", float(G.get_flag(hud.FLAG_BEST)), 200.0)
	await process_frame
	print("TEST_STORY_UI ", "OK (%d checks)" % checks if fails == 0 else "FAIL %d" % fails)
	quit(1 if fails > 0 else 0)


func _eq(label: String, actual: Variant, expected: Variant) -> void:
	checks += 1
	if actual != expected:
		fails += 1
		print("FAIL ", label, " got=", actual, " want=", expected)
