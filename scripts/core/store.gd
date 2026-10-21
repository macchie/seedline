class_name Store
## localStorage stand-in: the same keys as the web build ('seedline.'+key), kept as JSON in user://.

const PATH := "user://seedline.json"
static var _data := {}
static var _loaded := false


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
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_data))
