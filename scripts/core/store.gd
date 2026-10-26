class_name Store
## localStorage stand-in: the same keys as the web build ('seedline.'+key), kept as JSON in user://.
##
## Writes are coalesced and pushed off the main thread. `set_value` only updates the in-memory
## dictionary (authoritative, so reads stay correct and synchronous) and marks the store dirty; a
## tiny flusher node attached to the scene tree serialises and writes the file at most once per
## frame, on a worker thread. This keeps bursts of saves — the network run-queue flush, or stashing
## a finished run's ghost + inputs — from stalling the frame on repeated full-blob disk writes.

const PATH := "user://seedline.json"
static var _data := {}
static var _loaded := false
static var _dirty := false
static var _flusher: _Flusher = null


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var v = JSON.parse_string(f.get_as_text())
			if v is Dictionary:
				_data = v


static func get_value(k: String, d = null):
	_load()
	if not _data.has(k) or _data[k] == null:
		return d
	var v = _data[k]
	if v is Dictionary or v is Array:
		return v.duplicate(true)
	return v


static func set_value(k: String, v) -> void:
	_load()
	_data[k] = v.duplicate(true) if (v is Dictionary or v is Array) else v
	_dirty = true
	if _flusher != null:
		_flusher.set_process(true)
		return
	# attach the flusher the first time we have a tree; fall back to a direct write when headless
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		_flusher = _Flusher.new()
		(loop as SceneTree).root.add_child.call_deferred(_flusher)
	else:
		_write_now()


static func _write_now() -> void:
	_dirty = false
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_data))


## Persist any pending changes immediately (called on quit so the last frame of writes is not lost).
static func flush() -> void:
	if _flusher != null:
		_flusher.flush_now()
	elif _dirty:
		_write_now()


# Drives the coalesced, off-main-thread write. Lives on the scene tree root; processes only while
# there is work to do (a pending change or an in-flight write to reclaim).
class _Flusher:
	extends Node

	var _task := -1

	func _ready() -> void:
		process_priority = 1000  # run late so a frame's saves are all captured by one write

	func _process(_dt: float) -> void:
		if _task != -1:
			if not WorkerThreadPool.is_task_completed(_task):
				return
			WorkerThreadPool.wait_for_task_completion(_task)
			_task = -1
		if Store._dirty:
			Store._dirty = false
			var payload := JSON.stringify(Store._data)  # snapshot on the main thread (data is only mutated here)
			_task = WorkerThreadPool.add_task(_write.bind(payload))
		else:
			set_process(false)  # idle: stop ticking until the next save

	func _write(payload: String) -> void:
		var f := FileAccess.open(Store.PATH, FileAccess.WRITE)
		if f:
			f.store_string(payload)

	func flush_now() -> void:
		if _task != -1:
			WorkerThreadPool.wait_for_task_completion(_task)
			_task = -1
		if Store._dirty:
			Store._dirty = false
			var f := FileAccess.open(Store.PATH, FileAccess.WRITE)
			if f:
				f.store_string(JSON.stringify(Store._data))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_CRASH:
			flush_now()
