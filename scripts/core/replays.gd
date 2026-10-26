class_name Replays
## Heavy run replays (ghost path + input recording + start state) kept out of the main JSON store,
## one compact binary file per seed. The store keeps only lightweight metadata (best time, splits),
## so UI best-time reads stay tiny and the shared blob no longer grows with every raced track.
##
## Files are named by a hash of the seed (seeds are arbitrary text; the hash is filesystem-safe and
## fixed length) and pruned to a cap, oldest-written first, so replays can't accumulate forever.

const DIR := "user://replays"
const MAX_FILES := 200


static func _path(seed: String) -> String:
	return "%s/%s.bin" % [DIR, seed.sha256_text()]


static func has(seed: String) -> bool:
	return FileAccess.file_exists(_path(seed))


static func save(seed: String, replay: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(_path(seed), FileAccess.WRITE)
	if f == null:
		return
	f.store_var(replay)
	f.close()
	_prune()


static func load(seed: String) -> Dictionary:
	var p := _path(seed)
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var v = f.get_var()
	return v if v is Dictionary else {}


static func remove(seed: String) -> void:
	var p := _path(seed)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(p)


# Keep the cap by deleting the oldest-written replay files. A pruned replay only loses its "watch"
# data — the best time lives on in the main store — so this is safe to run on every save.
static func _prune() -> void:
	var files := DirAccess.get_files_at(DIR)
	if files.size() <= MAX_FILES:
		return
	var items: Array = []
	for n in files:
		items.append({"n": n, "t": FileAccess.get_modified_time(DIR + "/" + n)})
	items.sort_custom(func(a, b): return a.t < b.t)
	for i in (items.size() - MAX_FILES):
		DirAccess.remove_absolute(DIR + "/" + str(items[i].n))
