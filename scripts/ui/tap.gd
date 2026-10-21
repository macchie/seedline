class_name Tap
extends Glass
## Pressable glass control (the web build's <button>s). Ignores taps that turned into a scroll drag.

signal pressed

const FOCUS_COLOR := Color("#ff9a3c")

var _down := false
var _from := Vector2.ZERO
var _moved := false
var _normal_border := Color(0, 0, 0, 0)
var _normal_border_w := 0.0


func _init() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_sync_focus_style)
	focus_exited.connect(_sync_focus_style)


func style(fill: Color, border: Color = Color(0, 0, 0, 0), r: float = 12.0, bw: float = 1.0, blur_lvl: float = 0.0) -> Glass:
	_normal_border = border
	_normal_border_w = bw if border.a > 0.0 else 0.0
	if has_focus():
		return super.style(fill, FOCUS_COLOR, r, maxf(bw, 2.0), blur_lvl)
	return super.style(fill, border, r, bw, blur_lvl)


func _sync_focus_style() -> void:
	if has_focus():
		border_col = FOCUS_COLOR
		border_w = 2.0
	else:
		border_col = _normal_border
		border_w = _normal_border_w
	_sync()


func set_border_state(border: Color, width: float) -> void:
	_normal_border = border
	_normal_border_w = width
	_sync_focus_style()


func activate() -> void:
	pressed.emit()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			grab_focus()
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
