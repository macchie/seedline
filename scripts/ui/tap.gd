class_name Tap
extends Glass
## Pressable glass control (the web build's <button>s). Ignores taps that turned into a scroll drag.

signal pressed

var _down := false
var _from := Vector2.ZERO
var _moved := false


func _init() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_down = true
			_moved = false
			_from = ev.global_position
		elif _down:
			_down = false
			if not _moved and Rect2(Vector2.ZERO, size).has_point(ev.position):
				pressed.emit()
				accept_event()
	elif ev is InputEventMouseMotion and _down:
		if ev.global_position.distance_to(_from) > 8.0:
			_moved = true
