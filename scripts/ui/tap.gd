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
var _tinted := false
var _base_top := Color(0, 0, 0, 0)
var _base_bot := Color(0, 0, 0, 0)
var _pulse: Tween


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
	_tinted = false
	super.style(fill, border, r, bw, blur_lvl)
	_sync_focus_style()
	return self


## Focus is shown with a thick pulsing accent border and a tinted fill, so the selected control is obvious from a couch.
func _sync_focus_style() -> void:
	if _pulse:
		_pulse.kill()
		_pulse = null
	if has_focus():
		var tint := Color(FOCUS_COLOR, 0.22)
		if not _tinted:
			_base_top = fill_top
			_base_bot = fill_bot
			_tinted = true
		fill_top = _base_top.blend(tint)
		fill_bot = _base_bot.blend(tint)
		border_col = FOCUS_COLOR
		border_w = 3.0
		if is_inside_tree():
			_pulse = create_tween().set_loops()
			_pulse.tween_method(_set_pulse, 1.0, 0.45, 0.55).set_trans(Tween.TRANS_SINE)
			_pulse.tween_method(_set_pulse, 0.45, 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	else:
		if _tinted:
			fill_top = _base_top
			fill_bot = _base_bot
			_tinted = false
		border_col = _normal_border
		border_w = _normal_border_w
	_sync()


func _set_pulse(a: float) -> void:
	border_col = Color(FOCUS_COLOR, a)
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
