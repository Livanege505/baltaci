extends Node
## Read-only chapter catalog and pure validation/unlock rules.

var definitions: Array = []


func _ready() -> void:
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapters.json")).get("chapters", [])


func get_chapter(id: String) -> Dictionary:
	for chapter in definitions:
		if chapter.id == id:
			return chapter
	return {}


func index_of(id: String) -> int:
	for i in definitions.size():
		if definitions[i].id == id:
			return i
	return -1


func first_id() -> String:
	return str(definitions[0].id) if not definitions.is_empty() else ""


func next_id(id: String) -> String:
	var index := index_of(id)
	return str(definitions[index + 1].id) if index >= 0 and index + 1 < definitions.size() else ""


func sanitize_slots(id: String, raw: Variant) -> Array:
	var chapter := get_chapter(id)
	var slots: Array = []
	if chapter.is_empty() or typeof(raw) != TYPE_ARRAY:
		return slots
	for value in raw:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			continue
		if float(value) != floorf(float(value)) or float(value) < 0.0 or float(value) >= int(chapter.tree_count):
			continue
		var slot := int(value)
		if not slots.has(slot):
			slots.append(slot)
	slots.sort()
	return slots


func sanitize_progress(raw: Variant) -> Dictionary:
	var progress := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return progress
	for chapter in definitions:
		var slots := sanitize_slots(str(chapter.id), raw.get(chapter.id, []))
		if not slots.is_empty():
			progress[chapter.id] = slots
	return progress


func cleared_count(id: String, progress: Dictionary) -> int:
	return sanitize_slots(id, progress.get(id, [])).size()


func is_complete(id: String, progress: Dictionary) -> bool:
	var chapter := get_chapter(id)
	return not chapter.is_empty() and cleared_count(id, progress) >= int(chapter.tree_count)


func is_unlocked(id: String, progress: Dictionary) -> bool:
	var index := index_of(id)
	if index < 0:
		return false
	for i in index:
		if not is_complete(str(definitions[i].id), progress):
			return false
	return true


func pick_tree(id: String, slot: int) -> String:
	var chapter := get_chapter(id)
	if chapter.is_empty():
		return str(Balance.tree_order[0])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(chapter.seed) + slot * 7919
	var roll := rng.randf()
	var sum := 0.0
	for tree_id in chapter.mix:
		sum += float(chapter.mix[tree_id])
		if roll < sum:
			return str(tree_id)
	return str(chapter.mix.keys()[-1])
