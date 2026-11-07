extends SceneTree
## Chapter checkpoints, finite maps, unlocks, replay and real camp map selection.

var fails := 0
var checks := 0


func _initialize() -> void:
	await process_frame
	var G := root.get_node("GameState")
	var C := root.get_node("Chapters")
	var story := root.get_node("Story")
	G.persist = false
	G.save_path = "user://test_chapters.json"
	G.from_dict({})
	story.ui_enabled = false
	_eq("five distinct chapters", C.definitions.size(), 5)
	_eq("new campaign starts in grove", G.selected_chapter, "grove")
	_eq("second chapter starts locked", G.select_chapter("pines"), false)
	for chapter in C.definitions:
		for i in int(chapter.tree_count):
			var type: String = C.pick_tree(str(chapter.id), i)
			_ok("chapter tree is valid", root.get_node("Balance").trees.has(type))
			_eq("chapter species stay stable between shifts", C.pick_tree(str(chapter.id), i), type)
	G.from_dict({"gold": 321, "levels": {"axe_damage": 4}, "max_depth": 100})
	_eq("legacy gold preserved", G.gold, 321.0)
	_eq("legacy upgrades preserved", G.level_of("axe_damage"), 4)
	_eq("legacy depth does not invent completed chapters", G.chapter_progress, {})
	G.from_dict({"chapter_progress": {"grove": [0, 0, 11, 12, -1, 0.5, "2", null, true, NAN], "bad": [0]}, "selected_chapter": "pines"})
	_eq("invalid and duplicate saved slots are removed", G.chapter_progress, {"grove": [0, 11]})
	_eq("locked saved selection falls back", G.selected_chapter, "grove")
	G.from_dict({})
	G.persist = true   # only this test's save path
	var f := _forest()
	f.begin_chapter("grove")
	f.fall_mult = 0.0
	_eq("finite chapter contains exactly twelve trees", f.trees.size(), 12)
	f.ensure_forest(1000000)
	_eq("generation cannot extend beyond the chapter", f.generated_columns(), 12)
	var positions: Array = []
	for tree in f.trees:
		positions.append(tree.position.x)
	for slot in [0, 2, 5]:
		var tree: Node2D = f.trees[slot]
		f.hit_tree(tree, tree.position.x - 5.0, 700.0, 999.0, false)
	_eq("airborne trees are not checkpointed", G.chapter_progress, {})
	_step(f, 0.8)
	_eq("landed local progress is live on the HUD", f._hud._chapter_map.live_count, 3)
	f.end_run()
	_step(f, 0.2)
	_eq("partial result saves exact slots", G.chapter_progress.get("grove"), [0, 2, 5])
	_eq("three kavak pay six gold", G.gold, 6.0)
	_eq("partial chapter stays locked ahead", C.is_unlocked("pines", G.chapter_progress), false)
	_eq("partial result reports saved checkpoint", G.last_run.get("chapter_cleared"), 3)
	var snapshot: Dictionary = G.to_dict()
	snapshot.chapter_progress.grove.append(9)
	_eq("chapter snapshot is independent", G.chapter_progress.grove.size(), 3)
	_free(f)
	G.from_dict({})
	G.load_game()
	_eq("payout and checkpoint reload together", [G.gold, G.chapter_progress.grove], [6.0, [0, 2, 5]])
	f = _forest()
	f.begin_chapter("grove")
	f.fall_mult = 0.0
	_eq("next shift has only nine standing trees", f.standing_count(), 9)
	for i in f.trees.size():
		_eq("checkpoint does not move tree slots", f.trees[i].position.x, positions[i])
	for slot in [0, 2, 5]:
		_eq("previously paid tree is a stump", f.trees[slot].state, f.trees[slot].State.GONE)
	_eq("restored stumps cannot be chopped again", f.strike_at(Vector2(positions[0] - f.cam_x, 700)), null)
	f.cam_x = 100000.0
	f._cull_behind()
	_eq("camera cannot delete unfinished chapter trees", f.standing_count(), 9)
	f.manual_mode = false
	f.virtual_cursor_active = true
	f.virtual_cursor = Vector2(-100, -100)
	f._update_camera(0.1)
	_ok("camera is clamped to the finite map", f.cam_x <= f._chapter_cam_limit)
	_eq("scrolling awards no chapter progress", G.chapter_progress.grove.size(), 3)
	f.manual_mode = true
	for tree in f.trees:
		if tree.is_standing():
			f.hit_tree(tree, tree.position.x - 5.0, 700.0, 999.0, false)
	_step(f, 1.2)
	_eq("clearing the chapter ends the shift automatically", f.phase, f.Phase.DONE)
	_eq("completion counts all saved and new trees", G.last_run.get("chapter_cleared"), 12)
	_eq("first completion is recorded", G.last_run.get("chapter_newly_completed"), true)
	_eq("next chapter is unlocked", C.is_unlocked("pines", G.chapter_progress), true)
	_eq("future chapter remains locked", C.is_unlocked("ridge", G.chapter_progress), false)
	_eq("all twelve paid trees total twenty-four gold", G.gold, 24.0)
	_eq("next chapter can be selected", G.select_chapter("pines"), true)
	_free(f)
	G.select_chapter("grove")
	f = _forest()
	f.begin_chapter("grove")
	_eq("completed chapter starts as an explicit replay", f.chapter_replay, true)
	_eq("replay starts with a fresh local objective", f.chapter_cleared.size(), 0)
	_eq("replay restores all its trees", f.standing_count(), 12)
	f.end_run()
	_step(f, 0.1)
	_eq("unfinished replay keeps permanent completion", C.is_complete("grove", G.chapter_progress), true)
	_eq("unfinished replay reports its own progress", G.last_run.get("chapter_cleared"), 0)
	_eq("replay cannot repeat first-completion reward", G.last_run.get("chapter_newly_completed"), false)
	_eq("replay does not relock later chapters", C.is_unlocked("pines", G.chapter_progress), true)
	_free(f)
	G.from_dict({})
	f = _forest()
	f.begin_chapter("grove")
	f.fall_mult = 0.0
	f.hit_tree(f.trees[0], f.trees[0].position.x - 5, 700, 999, false)
	_step(f, 0.8)
	f._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_eq("window close saves landed progress", G.chapter_progress.get("grove"), [0])
	_eq("window close pays the same landed tree", G.gold, 2.0)
	f._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_eq("repeated close cannot pay twice", G.gold, 2.0)
	_free(f)

	var all_done := {}
	for chapter in C.definitions:
		all_done[chapter.id] = range(int(chapter.tree_count))
	G.from_dict({"chapter_progress": all_done, "selected_chapter": "oak_path"})
	_eq("last chapter has no invalid next destination", C.next_id("oak_path"), "")
	var camp: Control = load("res://scenes/camp/camp.tscn").instantiate()
	root.add_child(camp)
	_eq("camp map exposes five chapter choices", camp._chapter_map._buttons.size(), 5)
	for i in C.definitions.size():
		camp._chapter_map._buttons[i].pressed.emit()
		_eq("map click selects the matching chapter", G.selected_chapter, str(C.definitions[i].id))
	G.from_dict({})
	camp._refresh()
	_eq("locked chapter button is disabled", camp._chapter_map._buttons[1].disabled, true)
	camp._chapter_map._buttons[1].pressed.emit()
	_eq("locked map click cannot bypass progression", G.selected_chapter, "grove")
	root.remove_child(camp)
	camp.free()
	# Exercise the actual results button and scene transition into the unlocked chapter.
	G.persist = false
	G.from_dict({})
	f = _forest()
	current_scene = f
	f.begin_chapter("grove")
	f.fall_mult = 0.0
	for tree in f.trees:
		f.hit_tree(tree, tree.position.x - 5, 700, 999, false)
	_step(f, 1.2)
	f._go_next_chapter()
	_eq("next chapter cannot open before results reveal", G.selected_chapter, "grove")
	var deadline := Time.get_ticks_msec() + 6000
	while not f._hud.results_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	_ok("results eventually enable navigation", f._hud.results_ready)
	var next_button: Button = null
	for node in f._hud._results_root.find_children("*", "Button", true, false):
		if node.text == "Sonraki Bölüm →":
			next_button = node
	_ok("completion creates a real next-chapter button", next_button != null and not next_button.disabled)
	if next_button != null:
		next_button.pressed.emit()
		await create_timer(0.9).timeout
		_eq("results button opens the next forest scene", current_scene.chapter_id, "pines")
		_eq("scene transition preserves completed checkpoint", C.is_complete("grove", G.chapter_progress), true)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(G.save_path + suffix))
	await process_frame
	print("TEST_CHAPTERS ", "OK (%d checks)" % checks if fails == 0 else "FAIL %d of %d" % [fails, checks])
	quit(1 if fails > 0 else 0)


func _forest() -> Node2D:
	var forest: Node2D = load("res://scenes/forest/forest.tscn").instantiate()
	forest.manual_mode = true
	forest.swing_enabled = false
	root.add_child(forest)
	return forest


func _step(forest: Node2D, seconds: float) -> void:
	for i in ceili(seconds * 30.0):
		forest.advance(1.0 / 30.0)


func _free(forest: Node2D) -> void:
	root.remove_child(forest)
	forest.free()


func _eq(label: String, actual: Variant, expected: Variant) -> void:
	checks += 1
	if actual != expected:
		fails += 1
		print("FAIL ", label, " got=", actual, " want=", expected)


func _ok(label: String, actual: bool) -> void:
	_eq(label, actual, true)
