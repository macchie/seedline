class_name Ui
extends Control
## All 2D interface (port of the web build's HTML/CSS): menu sheet with Track / Garage / Saved / Options,
## race HUD with minimap, timer and touch controls, pause and finish cards, toast, loading screen.
## Layout units are CSS pixels; the window's content scale maps them to the screen like devicePixelRatio.

static var blur_ok := true

const INK := Color("#090b10")
const PANEL := Color(11 / 255.0, 14 / 255.0, 20 / 255.0, 0.84)
const PANEL2 := Color(1, 1, 1, 0.055)
const LINE := Color(1, 1, 1, 0.1)
const FG := Color("#f1f3f6")
const DIM := Color("#8e97a7")
const FAST := Color("#4fb2ff")
const SLOW := Color("#ff5a4f")
const MEDAL_COL := {"author": Color("#3ddc84"), "gold": Color("#f5c542"), "silver": Color("#c9cfd8"), "bronze": Color("#cf8752")}
const SWATCHES := ["#e8402c", "#ff8a1f", "#f2c230", "#2ec27e", "#1fb6c9", "#1f6ff1", "#7a4dff", "#f04fb3", "#eef1f5"]

var game                      # Main
var accent := Color("#ff9a3c")
var on_accent := Color("#140b02")
var touch := false
var safe := {"t": 0.0, "b": 0.0, "l": 16.0, "r": 16.0}

# menu
var menu: Control
var mtop: Control
var brand: VBoxContainer
var wm_a: Label
var wm_b: Label
var tag: Label
var btn_sound: Tap
var ic_sound: Icon
var sheet: Glass
var sheet_box: Control
var trackhead: VBoxContainer
var env_lbl: Label
var name_lbl: Label
var prev_map: MapView
var prev_box: Glass
var seed_lbl: Label
var btn_fav: Tap
var ic_fav: Icon
var tabs: Array = []
var panes := {}
var tab_scroll: ScrollContainer
var seed_in: LineEdit
var medals_box: VBoxContainer
var lb_box: VBoxContainer
var lb_stats: Label
var online_lbl: Label
var name_in: LineEdit
var net_status_lbl: Label
var f_rank: Label
var swatch_box: GridContainer
var swatches: Array = []
var finish_seg: Array = []
var fav_list: VBoxContainer
var fav_empty: Label
var sens_slider: HSlider
var sens_out: Label
var opt_segs := {}
var btn_play: Tap
var custom_swatch: Tap
var color_popup: PopupPanel
var color_picker: ColorPicker
var menu_on := true
var menu_tw: Tween
var pause_resume: Tap
var finish_retry: Tap
var _nav_stick := Vector2.ZERO
var _nav_direction := Vector2i.ZERO
var _nav_repeat_timer := 0.0

# hud
var hud: Control
var pads: Control
var wheel: Wheel
var steer_bar: Control
var steer_fill: ColorRect
var pad_brake: Tap
var pad_gas: Tap
var brake_l1: Label
var brake_l2: Label
var gas_l: Label
var tip_l: Label
var tip_r: Label
var divider: ColorRect
var top_l: HBoxContainer
var mini_box: Glass
var mini: MapView
var clock: VBoxContainer
var timer_box: Glass
var timer_lbl: Label
var lap_n: Label
var cp_n: Label
var cp_t: Label
var split_box: Glass
var split_lbl: Label
var split_tw: Tween
var hint: HBoxContainer
var boost_rect: ColorRect
var boost_tw: Tween
var count_lbl: Label
var count_tw: Tween

# modals and overlays
var pause_modal: Control
var pause_track: Label
var finish_modal: Control
var f_track: Label
var f_time: Label
var f_medal_dot: Control
var f_medal: Label
var f_delta: Label
var f_medals: VBoxContainer
var f_fav: Label
var toast_box: Glass
var toast_lbl: Label
var toast_tw: Tween
var stats_lbl: Label
var loading: ColorRect
var loading_tw: Tween
var vignette: ColorRect

var _hud_cache := {}
var _fonts_sz := {}


# ------------------------------------------------------------------ small builders

func L(text: String, fam: String, w: int, sz: float, col: Color, italic := false, ls := 0.0, upper := false) -> Label:
	var l := Label.new()
	l.text = text.to_upper() if upper else text
	l.add_theme_font_override("font", UiFonts.get_font(fam, w, italic, int(round(ls * sz))))
	l.add_theme_font_size_override("font_size", int(round(sz)))
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func restyle(l: Label, sz: float) -> void:
	l.add_theme_font_size_override("font_size", int(round(sz)))


func glass(fill: Color, border := Color(0, 0, 0, 0), r := 12.0, blur := 0.0) -> Glass:
	var g := Glass.new()
	g.style(fill, border, r, 1.0, blur)
	return g


func tap(fill: Color, border := Color(0, 0, 0, 0), r := 12.0, blur := 0.0) -> Tap:
	var t := Tap.new()
	t.style(fill, border, r, 1.0, blur)
	return t


func hbox(sep := 8) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func vbox(sep := 8) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	return b


func center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


func icon_btn(kind: String) -> Array:
	var b := tap(PANEL, LINE, 12.0, 2.5)
	b.custom_minimum_size = Vector2(42, 42)
	var ic := Icon.new(kind, 20)
	ic.color = FG
	b.add_child(center(ic))
	return [b, ic]


func eyebrow(text: String) -> Label:
	return L(text, "body", 600, 11, DIM, false, 0.16, true)


func dot(col: Color, d := 12.0) -> Control:
	var c := Dot.new()
	c.col = col
	c.custom_minimum_size = Vector2(d, d)
	return c


class Dot:
	extends Control
	var col := Color.WHITE
	var rect := false
	var rad := 4.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if rect:
			var sb := StyleBoxFlat.new()
			sb.bg_color = col
			sb.set_corner_radius_all(int(rad))
			draw_style_box(sb, Rect2(Vector2.ZERO, size))
		else:
			var r := minf(size.x, size.y) / 2.0
			draw_circle(size / 2.0, r, col)
			draw_arc(size / 2.0, r - 1.0, PI * 0.15, PI * 0.85, 12, Color(0, 0, 0, 0.25), 2.0, true)


func seg(options: Array, cb: Callable) -> Array:
	## options: [[value, label]]; returns [container, buttons]
	var box := glass(PANEL2, Color(0, 0, 0, 0), 12.0)
	box.pad(4, 4, 4, 4)
	var row := hbox(4)
	box.add_child(row)
	var btns: Array = []
	for o in options:
		var b := tap(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 9.0)
		b.custom_minimum_size = Vector2(0, 34)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := L(o[1], "body", 600, 12, DIM, false, 0.06, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(center(l))
		b.set_meta("v", o[0])
		b.set_meta("lbl", l)
		var v = o[0]
		b.pressed.connect(func(): cb.call(v))
		row.add_child(b)
		btns.append(b)
	return [box, btns]


func set_seg(btns: Array, value) -> void:
	for b in btns:
		var on: bool = b.get_meta("v") == value
		b.style(Color(1, 1, 1, 0.12) if on else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 9.0)
		(b.get_meta("lbl") as Label).add_theme_color_override("font_color", FG if on else DIM)


# ------------------------------------------------------------------ build

func _init(g) -> void:
	game = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = load("res://shaders/vignette.gdshader")
	vignette.material = vm
	add_child(vignette)
	var bb := BackBufferCopy.new()
	bb.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bb)
	_build_hud()
	_build_menu()
	_build_modals()
	_build_overlays()
	resized.connect(relayout)
	relayout()
	call_deferred("focus_default")


func focus_default() -> void:
	if color_popup and color_popup.visible:
		return
	if pause_modal and pause_modal.visible:
		pause_resume.grab_focus()
	elif finish_modal and finish_modal.visible:
		finish_retry.grab_focus()
	elif menu_on:
		btn_play.grab_focus()


func _focus_direction(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	if not has_focusable_ui():
		focus_default()
	var owner := _focus_owner()
	if owner == null:
		return
	if color_popup.visible and (owner == color_picker or color_picker.is_ancestor_of(owner)):
		var c := color_picker.color
		color_picker.color = Color.from_hsv(
			fposmod(c.h + direction.x * 0.025, 1.0),
			c.s,
			clampf(c.v - direction.y * 0.04, 0.0, 1.0),
			c.a
		)
		return
	if owner is HSlider and direction.x != 0:
		var slider := owner as HSlider
		slider.value = clampf(slider.value + direction.x * slider.step, slider.min_value, slider.max_value)
		return
	var side: int
	if direction.x < 0:
		side = SIDE_LEFT
	elif direction.x > 0:
		side = SIDE_RIGHT
	elif direction.y < 0:
		side = SIDE_TOP
	else:
		side = SIDE_BOTTOM
	var next := owner.find_valid_focus_neighbor(side)
	if next == null:
		next = owner.find_next_valid_focus() if direction.x > 0 or direction.y > 0 else owner.find_prev_valid_focus()
	if next and next != owner:
		next.grab_focus()
		if tab_scroll.is_ancestor_of(next):
			tab_scroll.ensure_control_visible(next)


func has_focusable_ui() -> bool:
	return _focus_owner() != null


func _focus_owner() -> Control:
	if color_popup.visible:
		var popup_focus := color_popup.gui_get_focus_owner()
		if popup_focus:
			return popup_focus
	return get_viewport().gui_get_focus_owner()


func _set_stick_direction(direction: Vector2i) -> void:
	if direction == _nav_direction:
		return
	_nav_direction = direction
	_nav_repeat_timer = 0.35
	if direction != Vector2i.ZERO:
		_focus_direction(direction)


func handle_joypad_event(ev: InputEvent) -> bool:
	if game.state != "menu" and game.state != "paused" and not finish_modal.visible and not color_popup.visible:
		return false
	if ev is InputEventJoypadMotion:
		if ev.axis == JOY_AXIS_LEFT_X:
			_nav_stick.x = ev.axis_value
		elif ev.axis == JOY_AXIS_LEFT_Y:
			_nav_stick.y = ev.axis_value
		else:
			return false
		var direction := Vector2i.ZERO
		if absf(_nav_stick.x) > 0.65 or absf(_nav_stick.y) > 0.65:
			if absf(_nav_stick.x) > absf(_nav_stick.y):
				direction.x = 1 if _nav_stick.x > 0.0 else -1
			else:
				direction.y = 1 if _nav_stick.y > 0.0 else -1
		_set_stick_direction(direction)
		return true
	if not ev is InputEventJoypadButton or not ev.pressed:
		return false
	match ev.button_index:
		JOY_BUTTON_DPAD_LEFT:
			_focus_direction(Vector2i.LEFT)
		JOY_BUTTON_DPAD_RIGHT:
			_focus_direction(Vector2i.RIGHT)
		JOY_BUTTON_DPAD_UP:
			_focus_direction(Vector2i.UP)
		JOY_BUTTON_DPAD_DOWN:
			_focus_direction(Vector2i.DOWN)
		JOY_BUTTON_A:
			_activate_focus()
		JOY_BUTTON_B:
			_cancel_ui()
		JOY_BUTTON_START:
			if game.state == "menu":
				game.start_race()
			elif game.state == "paused":
				game.resume()
		_:
			return false
	return true


func _activate_focus() -> void:
	var owner := _focus_owner()
	if owner is Tap:
		(owner as Tap).activate()
	elif owner is BaseButton:
		(owner as BaseButton).pressed.emit()
	elif owner is LineEdit:
		DisplayServer.virtual_keyboard_show((owner as LineEdit).text)


func _cancel_ui() -> void:
	if color_popup.visible:
		color_popup.hide()
		custom_swatch.grab_focus()
	elif game.state == "paused":
		game.resume()
	elif finish_modal.visible:
		game.to_menu()


func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu)
	# brand + sound
	mtop = Control.new()
	mtop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(mtop)
	brand = VBoxContainer.new()
	brand.add_theme_constant_override("separation", 2)
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wm := hbox(0)
	wm_a = L("SEED", "display", 800, 34, FG, true, 0.01)
	wm_b = L("LINE", "display", 800, 34, accent, true, 0.01)
	for l in [wm_a, wm_b]:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		l.add_theme_constant_override("shadow_offset_y", 2)
		l.add_theme_constant_override("shadow_outline_size", 10)
	wm.add_child(wm_a)
	wm.add_child(wm_b)
	brand.add_child(wm)
	tag = L("Procedural time trial", "body", 600, 10, Color(1, 1, 1, 0.7), false, 0.24, true)
	tag.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	tag.add_theme_constant_override("shadow_outline_size", 6)
	brand.add_child(tag)
	online_lbl = L("", "body", 600, 10, Color(1, 1, 1, 0.7), false, 0.18, true)
	online_lbl.visible = false
	brand.add_child(online_lbl)
	mtop.add_child(brand)
	var sb := icon_btn("sound")
	btn_sound = sb[0]
	ic_sound = sb[1]
	btn_sound.pressed.connect(func(): game.toggle_sound())
	mtop.add_child(btn_sound)
	# sheet
	sheet = glass(Color(11 / 255.0, 14 / 255.0, 20 / 255.0, 0.78), LINE, 20.0, 3.5)
	sheet.fill_bot = Color(9 / 255.0, 11 / 255.0, 16 / 255.0, 0.96)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.clip_contents = true
	menu.add_child(sheet)
	sheet_box = Control.new()
	sheet_box.mouse_filter = Control.MOUSE_FILTER_PASS
	sheet.add_child(sheet_box)
	# track head
	trackhead = vbox(8)
	var throw := hbox(12)
	var thtext := vbox(6)
	thtext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thtext.alignment = BoxContainer.ALIGNMENT_CENTER
	env_lbl = eyebrow("Canyon")
	name_lbl = L("Track", "display", 800, 34, FG, true, 0.005, true)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_constant_override("line_spacing", -8)
	thtext.add_child(env_lbl)
	thtext.add_child(name_lbl)
	throw.add_child(thtext)
	prev_box = glass(Color(0, 0, 0, 0.25), LINE, 12.0)
	prev_map = MapView.new()
	prev_map.preview = true
	prev_box.add_child(prev_map)
	throw.add_child(prev_box)
	trackhead.add_child(throw)
	var seedrow := hbox(8)
	var chip := tap(PANEL2, Color(1, 1, 1, 0.22), 12.0)
	chip.dash = 6.0
	chip.custom_minimum_size = Vector2(0, 42)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.pad(12, 0, 12, 0)
	var chiprow := hbox(8)
	seed_lbl = L("—", "mono", 700, 15, FG, false, 0.06)
	seed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chiprow.add_child(seed_lbl)
	var copy := L("Copy", "body", 600, 10, DIM, false, 0.14, true)
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chiprow.add_child(copy)
	chip.add_child(chiprow)
	chip.pressed.connect(func(): game.copy_seed())
	seedrow.add_child(chip)
	var fb := icon_btn("star")
	btn_fav = fb[0]
	ic_fav = fb[1]
	btn_fav.pressed.connect(func(): game.toggle_fav())
	seedrow.add_child(btn_fav)
	var nb := icon_btn("dice")
	nb[0].pressed.connect(func(): game.new_random_track())
	seedrow.add_child(nb[0])
	trackhead.add_child(seedrow)
	sheet_box.add_child(trackhead)
	# tabs
	var tbox := glass(PANEL2, Color(0, 0, 0, 0), 12.0)
	tbox.pad(4, 4, 4, 4)
	var trow := hbox(4)
	tbox.add_child(trow)
	for t in [["track", "Track"], ["garage", "Garage"], ["saved", "Saved"], ["options", "Options"]]:
		var b := tap(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 9.0)
		b.custom_minimum_size = Vector2(0, 34)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := L(t[1], "body", 600, 12, DIM, false, 0.06, true)
		b.add_child(center(l))
		b.set_meta("v", t[0])
		b.set_meta("lbl", l)
		var v: String = t[0]
		b.pressed.connect(func(): game.set_tab(v))
		trow.add_child(b)
		tabs.append(b)
	sheet_box.add_child(tbox)
	# tab body
	tab_scroll = ScrollContainer.new()
	tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tab_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	var thin := StyleBoxFlat.new()
	thin.bg_color = Color(1, 1, 1, 0.18)
	thin.set_corner_radius_all(3)
	thin.content_margin_left = 3
	thin.content_margin_right = 3
	tab_scroll.get_v_scroll_bar().add_theme_stylebox_override("grabber", thin)
	tab_scroll.get_v_scroll_bar().add_theme_stylebox_override("grabber_highlight", thin)
	tab_scroll.get_v_scroll_bar().add_theme_stylebox_override("grabber_pressed", thin)
	tab_scroll.get_v_scroll_bar().add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	sheet_box.add_child(tab_scroll)
	var panes_box := vbox(0)
	panes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_scroll.add_child(panes_box)
	_build_track_pane(panes_box)
	_build_garage_pane(panes_box)
	_build_saved_pane(panes_box)
	_build_options_pane(panes_box)
	# play
	btn_play = tap(accent, Color(0, 0, 0, 0), 14.0)
	btn_play.custom_minimum_size = Vector2(0, 52)
	var prow := hbox(12)
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	var race := L("Race", "display", 800, 24, on_accent, true, 0.08, true)
	race.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var enter := L("ENTER / A / CROSS", "mono", 700, 10, Color(on_accent, 0.55), false, 0.05)
	enter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prow.add_child(race)
	prow.add_child(enter)
	btn_play.add_child(prow)
	btn_play.set_meta("race", race)
	btn_play.set_meta("enter", enter)
	btn_play.pressed.connect(func(): game.start_race())
	sheet_box.add_child(btn_play)


func _pane(parent: Control, key: String) -> VBoxContainer:
	var p := vbox(12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	panes[key] = p
	return p


func _build_track_pane(parent: Control) -> void:
	var p := _pane(parent, "track")
	var form := hbox(8)
	seed_in = LineEdit.new()
	seed_in.placeholder_text = "Paste a seed, e.g. K7Q2XM"
	seed_in.max_length = 24
	seed_in.custom_minimum_size = Vector2(0, 42)
	seed_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_in.context_menu_enabled = true
	seed_in.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	var sbx := StyleBoxFlat.new()
	sbx.bg_color = PANEL2
	sbx.border_color = LINE
	sbx.set_border_width_all(1)
	sbx.set_corner_radius_all(12)
	sbx.content_margin_left = 12
	sbx.content_margin_right = 12
	seed_in.add_theme_stylebox_override("normal", sbx)
	var sbf := sbx.duplicate()
	sbf.border_color = accent
	sbf.set_border_width_all(2)
	seed_in.add_theme_stylebox_override("focus", sbf)
	seed_in.add_theme_font_override("font", UiFonts.get_font("mono", 500))
	seed_in.add_theme_font_size_override("font_size", 14)
	seed_in.add_theme_color_override("font_color", FG)
	seed_in.add_theme_color_override("font_placeholder_color", DIM)
	seed_in.add_theme_color_override("caret_color", FG)
	seed_in.text_changed.connect(func(t):
		var up: String = t.to_upper()
		if up != t:
			var c := seed_in.caret_column
			seed_in.text = up
			seed_in.caret_column = c)
	seed_in.text_submitted.connect(func(t): game.submit_seed(seed_in.text))
	form.add_child(seed_in)
	var load_b := tap(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 12.0)
	load_b.custom_minimum_size = Vector2(0, 42)
	load_b.pad(16, 0, 16, 0)
	load_b.add_child(center(L("Load", "body", 600, 13, FG, false, 0.06, true)))
	load_b.pressed.connect(func(): game.submit_seed(seed_in.text))
	form.add_child(load_b)
	p.add_child(form)
	medals_box = vbox(2)
	p.add_child(medals_box)
	var lb_head := hbox(8)
	var lbe := eyebrow("Leaderboard")
	lbe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb_head.add_child(lbe)
	lb_stats = L("", "body", 600, 10, DIM, false, 0.12, true)
	lb_head.add_child(lb_stats)
	p.add_child(lb_head)
	lb_box = vbox(2)
	p.add_child(lb_box)
	render_leaderboard(null)


func _build_garage_pane(parent: Control) -> void:
	var p := _pane(parent, "garage")
	p.add_child(eyebrow("Paint"))
	swatch_box = GridContainer.new()
	swatch_box.columns = 5
	swatch_box.add_theme_constant_override("h_separation", 8)
	swatch_box.add_theme_constant_override("v_separation", 8)
	swatch_box.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(swatch_box)
	for c in SWATCHES:
		var b := tap(U.css(c), Color(0, 0, 0, 0), 12.0)
		b.inset_col = Color(0, 0, 0, 0.2)
		b.inset_h = 6.0
		b.border_w = 2.0
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("c", c)
		var cc: String = c
		b.pressed.connect(func(): game.set_car_color(cc))
		swatch_box.add_child(b)
		swatches.append(b)
	var cu := tap(Color.WHITE, Color(0, 0, 0, 0), 12.0)
	cu._mat.set_shader_parameter("conic", 1.0)
	cu.set_meta("c", "custom")
	cu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cu.border_w = 2.0
	cu.pressed.connect(_open_picker)
	swatch_box.add_child(cu)
	custom_swatch = cu
	swatches.append(cu)
	color_popup = PopupPanel.new()
	color_picker = ColorPicker.new()
	color_picker.focus_mode = Control.FOCUS_ALL
	color_picker.edit_alpha = false
	color_picker.presets_visible = false
	color_picker.sampler_visible = false
	color_picker.color_modes_visible = false
	color_picker.color_changed.connect(func(c): game.set_car_color("#" + c.to_html(false)))
	color_popup.add_child(color_picker)
	add_child(color_popup)
	p.add_child(eyebrow("Finish"))
	var s := seg([["gloss", "Gloss"], ["metal", "Metallic"], ["matte", "Matte"]], func(v): game.set_finish(v))
	finish_seg = s[1]
	p.add_child(s[0])


func _open_picker() -> void:
	color_picker.color = U.css(game.car_cfg.color)
	var sz := Vector2i(300, 360)
	color_popup.popup_centered(sz)
	call_deferred("_focus_color_picker")


func _focus_color_picker() -> void:
	if color_popup.visible:
		color_picker.grab_focus()


func _build_saved_pane(parent: Control) -> void:
	var p := _pane(parent, "saved")
	fav_list = vbox(6)
	p.add_child(fav_list)
	fav_empty = L("No saved tracks yet. Tap the star next to a seed to keep it here with your best time.", "body", 400, 14, DIM)
	fav_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fav_empty.custom_minimum_size = Vector2(0, 0)
	p.add_child(fav_empty)


func _build_options_pane(parent: Control) -> void:
	var p := _pane(parent, "options")
	var o1 := vbox(6)
	var head := hbox(0)
	head.add_child(eyebrow("Touch steering · "))
	sens_out = L("Quick", "body", 600, 11, FG, false, 0.16, true)
	head.add_child(sens_out)
	o1.add_child(head)
	sens_slider = HSlider.new()
	sens_slider.min_value = 0
	sens_slider.max_value = 100
	sens_slider.step = 1
	sens_slider.custom_minimum_size = Vector2(0, 30)
	sens_slider.focus_mode = Control.FOCUS_ALL
	_style_slider(sens_slider)
	sens_slider.value_changed.connect(func(v): game.set_sens(int(v)))
	o1.add_child(sens_slider)
	var rl := hbox(0)
	var gl := L("Gentle", "body", 600, 10, DIM, false, 0.12, true)
	gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.add_child(gl)
	rl.add_child(L("Quick", "body", 600, 10, DIM, false, 0.12, true))
	o1.add_child(rl)
	p.add_child(o1)
	for spec in [["side", "Steering hand", [["left", "Left thumb"], ["right", "Right thumb"]]], ["gfx", "Graphics", [["high", "Toon shading"], ["low", "Battery saver"]]],
			["stats", "Frame rate readout", [["", "Hidden"], ["1", "Shown"]]]]:
		var o := vbox(6)
		o.add_child(eyebrow(spec[1]))
		var k: String = spec[0]
		var s := seg(spec[2], func(v): game.set_opt(k, v))
		opt_segs[k] = s[1]
		o.add_child(s[0])
		p.add_child(o)
	var o2 := vbox(6)
	o2.add_child(eyebrow("How to drive"))
	var keys := GridContainer.new()
	keys.columns = 2
	keys.add_theme_constant_override("h_separation", 12)
	keys.add_theme_constant_override("v_separation", 6)
	keys.mouse_filter = Control.MOUSE_FILTER_PASS
	for kv in [["↑ / W", "Accelerate · tap right before GO for a perfect start"],
			["← → / A D", "Steer"], ["↓ / S", "Brake"], ["Backspace", "Respawn at last checkpoint"], ["R · Esc", "Restart · pause"],
			["Touch", "Steer with the left half · GAS and BRAKE on the right"],
			["Pad", "D-pad / left stick navigate · Cross / A select · Circle / B back · R2 / RT gas · L2 / LT brake · left stick steer · Triangle / Y respawn · Options / Start pause"]]:
		var kb := glass(PANEL2, LINE, 6.0)
		kb.pad(6, 3, 6, 3)
		kb.add_child(L(kv[0], "mono", 700, 11, FG))
		kb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		kb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		keys.add_child(kb)
		var d := L(kv[1], "body", 400, 13, DIM)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.custom_minimum_size = Vector2(120, 0)
		keys.add_child(d)
	o2.add_child(keys)
	p.add_child(o2)
	var o3 := vbox(6)
	o3.add_child(eyebrow("Online racer name"))
	name_in = LineEdit.new()
	name_in.max_length = 20
	name_in.custom_minimum_size = Vector2(0, 42)
	name_in.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	var nsb: StyleBoxFlat = seed_in.get_theme_stylebox("normal").duplicate()
	name_in.add_theme_stylebox_override("normal", nsb)
	name_in.add_theme_stylebox_override("focus", seed_in.get_theme_stylebox("focus").duplicate())
	name_in.add_theme_font_override("font", UiFonts.get_font("body", 600))
	name_in.add_theme_font_size_override("font_size", 14)
	name_in.add_theme_color_override("font_color", FG)
	name_in.add_theme_color_override("caret_color", FG)
	name_in.text_submitted.connect(func(t): game.set_racer_name(t))
	name_in.focus_exited.connect(func(): game.set_racer_name(name_in.text))
	o3.add_child(name_in)
	net_status_lbl = L("", "body", 400, 12, DIM)
	o3.add_child(net_status_lbl)
	p.add_child(o3)


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.18)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate()
	fill.bg_color = accent
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var img := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	for y in 36:
		for x in 36:
			var d := Vector2(x + 0.5 - 18, y + 0.5 - 18).length()
			img.set_pixel(x, y, Color(accent, clampf(16.5 - d, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	tex.set_size_override(Vector2i(18, 18))
	s.add_theme_icon_override("grabber", tex)
	s.add_theme_icon_override("grabber_highlight", tex)


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	add_child(hud)
	# touch zones (behind the top bar)
	pads = Control.new()
	pads.set_anchors_preset(Control.PRESET_FULL_RECT)
	pads.mouse_filter = Control.MOUSE_FILTER_STOP
	pads.gui_input.connect(_pads_input)
	pads.visible = false
	hud.add_child(pads)
	divider = ColorRect.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dm := ShaderMaterial.new()
	var dsh := Shader.new()
	dsh.code = "shader_type canvas_item; void fragment(){ COLOR = vec4(1.0,1.0,1.0, 0.07 * smoothstep(0.0, 0.4, UV.y)); }"
	dm.shader = dsh
	divider.material = dm
	pads.add_child(divider)
	wheel = Wheel.new()
	wheel.modulate.a = 0.72
	pads.add_child(wheel)
	steer_bar = ColorRect.new()
	steer_bar.color = Color(1, 1, 1, 0.14)
	steer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	steer_bar.clip_contents = true
	pads.add_child(steer_bar)
	steer_fill = ColorRect.new()
	steer_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	steer_bar.add_child(steer_fill)
	pad_brake = tap(Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.42), Color(1, 120 / 255.0, 110 / 255.0, 0.45), 22.0, 2.0)
	pad_brake.border_w = 1.5
	pad_brake.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bl := vbox(4)
	bl.alignment = BoxContainer.ALIGNMENT_CENTER
	brake_l1 = L("BRAKE", "display", 800, 15, Color("#ffb3ad"), true, 0.08)
	brake_l2 = L("HOLD", "body", 700, 9, Color("#ffb3ad", 0.7), false, 0.16)
	brake_l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brake_l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.add_child(brake_l1)
	bl.add_child(brake_l2)
	pad_brake.add_child(center(bl))
	pads.add_child(pad_brake)
	pad_gas = tap(Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.42), accent, 22.0, 2.0)
	pad_gas.border_w = 1.5
	pad_gas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gas_l = L("GAS", "display", 800, 15, accent, true, 0.08)
	pad_gas.add_child(center(gas_l))
	pads.add_child(pad_gas)
	tip_l = L("Slide left ↔ right\nanywhere on this half", "body", 600, 11, Color(1, 1, 1, 0.8), false, 0.12, true)
	tip_r = L("Gas · brake\nslide between them", "body", 600, 11, Color(1, 1, 1, 0.8), false, 0.12, true)
	for t in [tip_l, tip_r]:
		t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		t.add_theme_constant_override("shadow_outline_size", 6)
		pads.add_child(t)
	# top bar
	top_l = hbox(8)
	var pb := icon_btn("pause")
	pb[0].pressed.connect(func(): game.toggle_pause())
	top_l.add_child(pb[0])
	var rb := icon_btn("respawn")
	rb[0].pressed.connect(func(): game.respawn())
	top_l.add_child(rb[0])
	hud.add_child(top_l)
	mini_box = glass(PANEL, LINE, 14.0, 2.5)
	mini = MapView.new()
	mini_box.add_child(mini)
	hud.add_child(mini_box)
	# clock
	clock = VBoxContainer.new()
	clock.add_theme_constant_override("separation", 6)
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_box = glass(PANEL, LINE, 12.0, 2.5)
	timer_box.pad(14, 9, 14, 8)
	timer_lbl = L("0:00.000", "mono", 700, 30, FG, false, -0.02)
	timer_box.add_child(timer_lbl)
	clock.add_child(center(timer_box))
	var lap := hbox(10)
	lap.alignment = BoxContainer.ALIGNMENT_CENTER
	var li := Color(1, 1, 1, 0.85)
	var lap_a := hbox(0)
	lap_a.add_child(_shadowed(L("Lap ", "body", 600, 11, li, false, 0.16, true)))
	lap_n = _shadowed(L("1", "body", 600, 11, FG, false, 0.16))
	lap_a.add_child(lap_n)
	lap_a.add_child(_shadowed(L("/" + str(U.LAPS), "body", 600, 11, li, false, 0.16)))
	lap.add_child(lap_a)
	var cp_a := hbox(0)
	cp_a.add_child(_shadowed(L("CP ", "body", 600, 11, li, false, 0.16, true)))
	cp_n = _shadowed(L("0", "body", 600, 11, FG, false, 0.16))
	cp_a.add_child(cp_n)
	cp_a.add_child(_shadowed(L("/", "body", 600, 11, li, false, 0.16)))
	cp_t = _shadowed(L("4", "body", 600, 11, li, false, 0.16))
	cp_a.add_child(cp_t)
	lap.add_child(cp_a)
	clock.add_child(lap)
	split_box = glass(PANEL, Color(0, 0, 0, 0), 9.0, 2.5)
	split_box.pad(10, 6, 10, 6)
	split_lbl = L("", "mono", 700, 17, FG)
	split_box.add_child(split_lbl)
	split_box.modulate.a = 0.0
	clock.add_child(center(split_box))
	hud.add_child(clock)
	# keyboard hints
	hint = hbox(14)
	for h in [["⌫", "Respawn"], ["R", "Restart"], ["Esc", "Pause"]]:
		var row := hbox(4)
		var k := glass(PANEL, LINE, 5.0)
		k.pad(5, 2, 5, 2)
		k.add_child(L(h[0], "mono", 700, 11, FG))
		row.add_child(k)
		var t := L(h[1], "body", 500, 12, Color(1, 1, 1, 0.6))
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(t)
		hint.add_child(row)
	hud.add_child(hint)
	boost_rect = ColorRect.new()
	boost_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	boost_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bm := ShaderMaterial.new()
	bm.shader = load("res://shaders/boost_fx.gdshader")
	boost_rect.material = bm
	boost_rect.modulate.a = 0.0
	hud.add_child(boost_rect)
	count_lbl = L("", "display", 800, 150, FG, true)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	count_lbl.add_theme_constant_override("shadow_offset_y", 6)
	count_lbl.add_theme_constant_override("shadow_outline_size", 24)
	count_lbl.modulate.a = 0.0
	hud.add_child(count_lbl)


func _shadowed(l: Label) -> Label:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_outline_size", 5)
	return l


func _card(parent: Control) -> Array:
	var modal := ColorRect.new()
	modal.color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.55)
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.visible = false
	parent.add_child(modal)
	var card := glass(PANEL, LINE, 20.0, 3.0)
	card.pad(22, 22, 22, 22)
	modal.add_child(card)
	var box := vbox(14)
	card.add_child(box)
	return [modal, card, box]


func _cbtn(text: String, primary: bool, small := "") -> Array:
	var b := tap(accent if primary else Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 12.0)
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := hbox(6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := L(text, "body", 600, 13, on_accent if primary else FG, false, 0.06, true)
	row.add_child(l)
	if small != "":
		row.add_child(L(small, "mono", 600, 13, Color(on_accent if primary else FG, 0.55)))
	b.add_child(row)
	b.set_meta("primary", primary)
	return [b, l]


func _build_modals() -> void:
	var pc := _card(self)
	pause_modal = pc[0]
	var pbox: VBoxContainer = pc[2]
	pause_track = eyebrow("Paused")
	pbox.add_child(pause_track)
	pbox.add_child(L("Paused", "display", 800, 34, FG, true, 0.0, true))
	var pg := vbox(8)
	var r1 := _cbtn("Resume", true)
	pause_resume = r1[0]
	r1[0].pressed.connect(func(): game.resume())
	pg.add_child(r1[0])
	var row := hbox(8)
	var r2 := _cbtn("Restart", false)
	r2[0].pressed.connect(func(): game.restart(true))
	var r3 := _cbtn("Menu", false)
	r3[0].pressed.connect(func(): game.to_menu())
	row.add_child(r2[0])
	row.add_child(r3[0])
	pg.add_child(row)
	pbox.add_child(pg)
	var fc := _card(self)
	finish_modal = fc[0]
	var fbox: VBoxContainer = fc[2]
	f_track = eyebrow("Finish")
	fbox.add_child(f_track)
	f_time = L("0:00.000", "mono", 700, 52, FG, false, -0.03)
	fbox.add_child(f_time)
	var rr := hbox(10)
	var badge := glass(PANEL2, Color(0, 0, 0, 0), 15.0)
	badge.custom_minimum_size = Vector2(0, 30)
	badge.pad(12, 0, 12, 0)
	var brow := hbox(8)
	f_medal_dot = dot(Color.WHITE)
	f_medal_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brow.add_child(f_medal_dot)
	f_medal = L("No medal", "body", 600, 12, FG, false, 0.12, true)
	f_medal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brow.add_child(f_medal)
	badge.add_child(brow)
	rr.add_child(badge)
	f_delta = L("", "mono", 700, 15, FG)
	f_delta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rr.add_child(f_delta)
	fbox.add_child(rr)
	f_rank = L("", "body", 600, 12, accent, false, 0.12, true)
	f_rank.visible = false
	fbox.add_child(f_rank)
	f_medals = vbox(2)
	fbox.add_child(f_medals)
	var fg := vbox(8)
	var b1 := _cbtn("Retry", true, "R")
	finish_retry = b1[0]
	b1[0].pressed.connect(func(): game.restart(true))
	fg.add_child(b1[0])
	var row2 := hbox(8)
	var b2 := _cbtn("Save track", false)
	f_fav = b2[1]
	b2[0].pressed.connect(func(): game.toggle_fav())
	var b3 := _cbtn("Next track", false)
	b3[0].pressed.connect(func(): game.next_track())
	row2.add_child(b2[0])
	row2.add_child(b3[0])
	fg.add_child(row2)
	var b4 := _cbtn("Menu", false)
	b4[0].pressed.connect(func(): game.to_menu())
	fg.add_child(b4[0])
	fbox.add_child(fg)


func _build_overlays() -> void:
	toast_box = glass(PANEL, LINE, 10.0, 2.5)
	toast_box.pad(14, 8, 14, 8)
	toast_lbl = L("", "body", 600, 13, FG)
	toast_box.add_child(toast_lbl)
	toast_box.modulate.a = 0.0
	add_child(toast_box)
	stats_lbl = L("", "mono", 600, 11, Color.WHITE)
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0, 0, 0, 0.45)
	sbg.set_corner_radius_all(6)
	sbg.content_margin_left = 7
	sbg.content_margin_right = 7
	sbg.content_margin_top = 3
	sbg.content_margin_bottom = 3
	stats_lbl.add_theme_stylebox_override("normal", sbg)
	stats_lbl.visible = false
	add_child(stats_lbl)
	loading = ColorRect.new()
	loading.color = INK
	loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading.mouse_filter = Control.MOUSE_FILTER_STOP
	var ll := L("Laying asphalt…", "display", 800, 28, DIM, true, 0.1, true)
	ll.set_anchors_preset(Control.PRESET_FULL_RECT)
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading.add_child(ll)
	add_child(loading)


# ------------------------------------------------------------------ layout (the CSS media queries)

func relayout() -> void:
	var W := size.x
	var H := size.y
	if W < 2.0 or H < 2.0:
		return
	var st: float = safe.t
	var sb: float = safe.b
	var sl: float = maxf(16.0, safe.l)
	var sr: float = maxf(16.0, safe.r)
	var vw := W / 100.0
	var landscape_short := W > H and H <= 560.0
	var desktop := W >= 860.0
	var garage: bool = game.menu_tab == "garage"
	# brand
	var wm_size := 34.0
	if landscape_short:
		wm_size = 28.0
	if desktop:
		wm_size = 44.0
	restyle(wm_a, wm_size)
	restyle(wm_b, wm_size)
	var right_brand := landscape_short
	brand.alignment = BoxContainer.ALIGNMENT_BEGIN
	var top_pad := st + (24.0 if desktop else 14.0)
	var bsz := brand.get_combined_minimum_size()
	brand.size = bsz
	if right_brand:
		# justify-content:flex-end, gap 14: brand then sound button at the right
		btn_sound.position = Vector2(W - sr - 42.0, top_pad + (bsz.y - 42.0) / 2.0)
		brand.position = Vector2(btn_sound.position.x - 14.0 - bsz.x, top_pad)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		(wm_a.get_parent() as HBoxContainer).alignment = BoxContainer.ALIGNMENT_END
	else:
		brand.position = Vector2(sl, top_pad)
		btn_sound.position = Vector2(W - sr - 42.0, top_pad + (bsz.y - 42.0) / 2.0)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		(wm_a.get_parent() as HBoxContainer).alignment = BoxContainer.ALIGNMENT_BEGIN
	btn_sound.size = Vector2(42, 42)
	# sheet
	var name_size := clampf(7.4 * vw, 26.0, 40.0)
	var pm := clampf(21.0 * vw, 72.0, 96.0)
	var rail := landscape_short or desktop
	trackhead.visible = not garage or rail
	if desktop:
		sheet.pad(18, 18, 18, 18)
		sheet.radius = Vector4(18, 18, 18, 18)
		sheet.border_col = LINE
		var w := 390.0
		var top := st + 92.0
		sheet.position = Vector2(sl, top)
		sheet.size = Vector2(w, H - top - 24.0)
		name_size = clampf(7.4 * vw, 26.0, 40.0)
	elif landscape_short:
		sheet.pad(sl, 12, sr, 12)
		sheet.radius = Vector4(16, 16, 16, 16)
		var w2 := minf(360.0, 0.46 * W)
		sheet.position = Vector2(sl, st + 8.0)
		sheet.size = Vector2(w2, H - st - 16.0)
		sheet.pad(16, 12, 16, 12)
	else:
		sheet.radius = Vector4(20, 20, 0, 0)
		sheet.pad(sl, 12, sr, sb + 12.0)
		var maxh := minf(H * (0.44 if garage else 0.6), 420.0 if garage else 560.0)
		var content := _sheet_content_height(W - sl - sr)
		var h := minf(maxh, content + 24.0 + sb)
		sheet.position = Vector2(0, H - h)
		sheet.size = Vector2(W, h)
	restyle(name_lbl, name_size)
	prev_box.custom_minimum_size = Vector2(pm, pm)
	prev_map.custom_minimum_size = Vector2(pm, pm)
	_layout_sheet_inner()
	sheet._sync()
	if not menu_on:
		_apply_menu_hidden()
	# hud
	top_l.position = Vector2(sl, st + 12.0)
	mini_box.size = Vector2(112, 112)
	mini_box.position = Vector2(W - sr - 112.0, st + 12.0)
	mini.custom_minimum_size = Vector2(112, 112)
	restyle(timer_lbl, clampf(6.4 * vw, 24.0, 34.0))
	clock.size = clock.get_combined_minimum_size()
	clock.position = Vector2((W - clock.size.x) / 2.0, st + 12.0)
	hint.size = hint.get_combined_minimum_size()
	hint.position = Vector2(sl, H - sb - 16.0 - hint.size.y)
	hint.visible = not touch
	restyle(count_lbl, clampf(30.0 * vw, 110.0, 190.0))
	count_lbl.size = Vector2(W, H)
	count_lbl.position = Vector2.ZERO
	count_lbl.pivot_offset = Vector2(W, H) / 2.0
	(boost_rect.material as ShaderMaterial).set_shader_parameter("rect_size", Vector2(W, H))
	_layout_pads(W, H, sl, sr, sb)
	# modals
	for m in [pause_modal, finish_modal]:
		var card: Glass = m.get_child(0)
		var cw := minf(420.0, W - sl - sr)
		card.size = Vector2(cw, 0)
		card.size = Vector2(cw, card.get_combined_minimum_size().y)
		card.position = Vector2((W - cw) / 2.0, (H - card.size.y) / 2.0)
		card._sync()
	restyle(f_time, clampf(12.0 * vw, 40.0, 56.0))
	# overlays
	toast_box.size = toast_box.get_combined_minimum_size()
	toast_box.position = Vector2((W - toast_box.size.x) / 2.0, st + 70.0)
	stats_lbl.size = stats_lbl.get_combined_minimum_size()
	stats_lbl.position = Vector2(W - sr - stats_lbl.size.x, H - sb - 6.0 - stats_lbl.size.y)


## Stack the sheet's blocks by hand (flex column: head, tabs, scrolling body, play button pinned to the bottom)
func _layout_sheet_inner() -> void:
	var ml := float(sheet.get_theme_constant("margin_left"))
	var mr := float(sheet.get_theme_constant("margin_right"))
	var mt := float(sheet.get_theme_constant("margin_top"))
	var mb := float(sheet.get_theme_constant("margin_bottom"))
	var iw := sheet.size.x - ml - mr
	var ih := sheet.size.y - mt - mb
	sheet_box.position = Vector2(ml, mt)
	sheet_box.size = Vector2(iw, ih)
	var y := 0.0
	var fixed := 0.0
	var blocks: Array = []
	for c in sheet_box.get_children():
		if c.visible:
			blocks.append(c)
	var heights := {}
	for c in blocks:
		if c == tab_scroll:
			continue
		var h0: float
		if c == trackhead:
			h0 = _trackhead_height(iw)
		else:
			h0 = c.get_combined_minimum_size().y
		heights[c] = h0
		fixed += h0
	var body_h := maxf(0.0, ih - fixed - 10.0 * (blocks.size() - 1))
	for c in blocks:
		var h: float = body_h if c == tab_scroll else heights[c]
		c.position = Vector2(0, y)
		c.size = Vector2(iw, h)
		y += h + 10.0


## The track head's height with the name wrapped at the width it will get (labels measure lazily)
func _trackhead_height(iw: float) -> float:
	var pm := prev_box.custom_minimum_size.x
	var text_w := maxf(40.0, iw - pm - 12.0)
	name_lbl.size = Vector2(text_w, name_lbl.size.y)
	var name_h := name_lbl.get_minimum_size().y
	var top := maxf(env_lbl.get_minimum_size().y + 6.0 + name_h, pm)
	return top + 8.0 + 42.0


func _sheet_content_height(inner_w: float) -> float:
	var h := 0.0
	var n := 0
	for c in sheet_box.get_children():
		if not c.visible:
			continue
		n += 1
		if c == tab_scroll:
			var p: Control = panes[game.menu_tab]
			p.size.x = inner_w
			h += p.get_combined_minimum_size().y
		elif c == trackhead:
			h += _trackhead_height(inner_w)
		else:
			h += c.get_combined_minimum_size().y
	return h + 10.0 * maxf(0.0, n - 1)


func _layout_pads(W: float, H: float, sl: float, sr: float, sb: float) -> void:
	var vw := W / 100.0
	var wsz := clampf(36.0 * vw, 128.0, 168.0)
	var mirror: bool = game.opts.side == "right"
	var wx := (0.75 if mirror else 0.25) * W - wsz / 2.0
	wheel.size = Vector2(wsz, wsz)
	wheel.position = Vector2(wx, H - sb - 26.0 - wsz)
	wheel.pivot_offset = Vector2(wsz, wsz) / 2.0
	steer_bar.size = Vector2(wsz * 1.1, 4)
	steer_bar.position = Vector2(wx + wsz / 2.0 - wsz * 0.55, wheel.position.y + wsz + 12.0)
	var bw := clampf(18.0 * vw, 66.0, 98.0)
	var bh := clampf(25.0 * vw, 88.0, 108.0)
	var gw := clampf(22.0 * vw, 76.0, 110.0)
	var gh := clampf(36.0 * vw, 128.0, 160.0)
	pad_brake.size = Vector2(bw, bh)
	pad_gas.size = Vector2(gw, gh)
	var by := H - sb - 18.0
	if mirror:
		pad_gas.position = Vector2(sl, by - gh)
		pad_brake.position = Vector2(sl + gw + 8.0, by - bh)
	else:
		pad_gas.position = Vector2(W - sr - gw, by - gh)
		pad_brake.position = Vector2(W - sr - gw - 8.0 - bw, by - bh)
	pad_brake.pivot_offset = pad_brake.size / 2.0
	pad_gas.pivot_offset = pad_gas.size / 2.0
	pad_brake._sync()
	pad_gas._sync()
	divider.position = Vector2(W / 2.0, H * 0.22)
	divider.size = Vector2(1, H * 0.78)
	var maxw := 0.44 * W
	for t in [tip_l, tip_r]:
		t.custom_minimum_size = Vector2(0, 0)
		t.size = t.get_combined_minimum_size()
	if mirror:
		tip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip_l.size.x = W - sr - W / 2.0
		tip_l.position = Vector2(W / 2.0, H - sb - 20.0 - wsz - 18.0 - tip_l.size.y)
		tip_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tip_r.position = Vector2(sl, H - sb - 18.0 - gh - 14.0 - tip_r.size.y)
	else:
		tip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip_l.size.x = W / 2.0 - sl
		tip_l.position = Vector2(sl, H - sb - 20.0 - wsz - 18.0 - tip_l.size.y)
		tip_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tip_r.position = Vector2(W - sr - tip_r.size.x, H - sb - 18.0 - gh - 14.0 - tip_r.size.y)


## Rect of the menu sheet in UI units (for the camera's view offset)
func sheet_rect() -> Rect2:
	return Rect2(sheet.position, sheet.size)


# ------------------------------------------------------------------ state sync

func set_accent(a: Color, on: Color) -> void:
	accent = a
	on_accent = on
	wm_b.add_theme_color_override("font_color", accent)
	btn_play.style(accent, Color(0, 0, 0, 0), 14.0)
	(btn_play.get_meta("race") as Label).add_theme_color_override("font_color", on_accent)
	(btn_play.get_meta("enter") as Label).add_theme_color_override("font_color", Color(on_accent, 0.55))
	_style_slider(sens_slider)
	var f: StyleBoxFlat = seed_in.get_theme_stylebox("focus")
	f.border_color = accent
	for m in [pause_modal, finish_modal]:
		for b in _all_taps(m):
			if b.has_meta("primary") and b.get_meta("primary"):
				b.style(accent, Color(0, 0, 0, 0), 12.0)
				for l in _labels(b):
					l.add_theme_color_override("font_color", on_accent if l.text != "R" else Color(on_accent, 0.55))
	wheel.accent = accent
	wheel.queue_redraw()
	steer_fill.color = accent
	sync_pedals(false, false)
	sync_icons()


func _all_taps(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is Tap:
			out.append(c)
		out.append_array(_all_taps(c))
	return out


func _labels(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is Label:
			out.append(c)
		out.append_array(_labels(c))
	return out


func sync_icons() -> void:
	var snd: bool = game.opts.sound
	ic_sound.color = accent if snd else FG
	ic_sound.filled = snd
	ic_sound.wave_alpha = 1.0 if snd else 0.15
	ic_sound.queue_redraw()
	var fav: bool = game.is_fav()
	ic_fav.color = accent if fav else FG
	ic_fav.filled = fav
	ic_fav.queue_redraw()
	f_fav.text = ("Saved ★" if fav else "Save track").to_upper()


func refresh_menu() -> void:
	var e: Dictionary = game.env
	var t: TrackData = game.track
	var tod := ""
	if Envs.NIGHT_ENABLED or e.get("tod", "") == "Dusk":
		tod = " · " + str(e.tod)
	env_lbl.text = (str(e.name) + tod + " · " + ("%.2f" % (t.length / 1000.0)) + " km · " + str(U.LAPS) + " laps · " + str(t.cps.size()) + " CP").to_upper()
	name_lbl.text = t.name.to_upper()
	seed_lbl.text = t.seed
	var b = Store.get_value("best5." + t.seed, null)
	render_medals(medals_box, b.t if b != null else null)
	render_leaderboard({"loading": true} if game.net_eligible() else null)
	game.fetch_leaderboard()
	sync_icons()
	render_favs()
	prev_map.set_track(t, accent)
	mini.set_track(t, accent)
	relayout()


func _medal_row(parent: Control, col: Color, name: String, time: String, pb := false) -> void:
	var row := glass(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0.0)
	row.custom_minimum_size = Vector2(0, 30)
	row.pad(4, 0, 4, 0)
	var h := hbox(10)
	var d := dot(col)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(d)
	var n := L(name, "body", 600, 12, FG if pb else DIM, false, 0.1, true)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(n)
	var tl := L(time, "mono", 700 if pb else 500, 14, accent if pb else FG)
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(tl)
	row.add_child(h)
	parent.add_child(row)
	if not pb:
		var sep := ColorRect.new()
		sep.color = Color(1, 1, 1, 0.05)
		sep.custom_minimum_size = Vector2(0, 1)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(sep)


func render_medals(box: VBoxContainer, pb) -> void:
	for c in box.get_children():
		c.queue_free()
		box.remove_child(c)
	var m: Dictionary = game.track.medals
	for md in CarSim.MEDALS:
		_medal_row(box, MEDAL_COL[md[0]], md[1], U.fmt(m[md[0]]))
	_medal_row(box, accent, "Personal best", U.fmt(pb) if pb != null else "—", true)


## info: null = nothing to show, {"loading": true}, {"error": true} or the server's track info.
func render_leaderboard(info) -> void:
	if lb_box == null:
		return
	for c in lb_box.get_children():
		c.queue_free()
		lb_box.remove_child(c)
	lb_stats.text = ""
	var msg := ""
	if info == null:
		msg = "Online ranking is off for this track"
	elif info.get("loading", false):
		msg = "Loading…"
	elif info.get("error", false):
		msg = "Leaderboard offline"
	else:
		var st: Dictionary = info.get("stats", {})
		var runs := int(st.get("runs", 0))
		lb_stats.text = ("%d RUNS · %d RACERS" % [runs, int(st.get("players", 0))])
		var top = info.get("top", [])
		if not (top is Array):
			top = []
		if top.is_empty():
			msg = "No times yet. Be the first."
		var mine = info.get("me")
		var shown_me := false
		for r in top:
			var is_me: bool = mine is Dictionary and int(r.rank) == int(mine.get("rank", -1)) and str(r.name) == str(mine.get("name", ""))
			shown_me = shown_me or is_me
			_rank_row(int(r.rank), str(r.name), float(r.time_ms) / 1000.0, is_me)
		if mine is Dictionary and not shown_me and int(mine.get("rank", 0)) > 0:
			_rank_row(int(mine.rank), str(mine.get("name", "")), float(mine.time_ms) / 1000.0, true)
	if msg != "":
		var l := L(msg, "body", 400, 12, DIM)
		l.custom_minimum_size = Vector2(0, 30)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lb_box.add_child(l)
	if game.track != null:
		relayout()


func _rank_row(rank: int, name: String, t: float, me: bool) -> void:
	var row := glass(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0.0)
	row.custom_minimum_size = Vector2(0, 28)
	row.pad(4, 0, 4, 0)
	var h := hbox(10)
	var rk := L("%d" % rank, "mono", 700, 12, accent if me else DIM)
	rk.custom_minimum_size = Vector2(26, 0)
	rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(rk)
	var n := L(name, "body", 600, 12, FG if me else DIM, false, 0.06, true)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.clip_text = true
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(n)
	var tl := L(U.fmt(t), "mono", 700 if me else 500, 13, accent if me else FG)
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(tl)
	row.add_child(h)
	lb_box.add_child(row)


func set_online_count(n: int, on: bool) -> void:
	online_lbl.visible = on
	online_lbl.text = "● %d ONLINE" % n


func set_net_status(text: String) -> void:
	if net_status_lbl:
		net_status_lbl.text = text


func set_finish_rank(info) -> void:
	var me = info.get("me") if info is Dictionary else null
	if me is Dictionary and int(me.get("rank", 0)) > 0:
		var runs := int(info.get("stats", {}).get("players", 0))
		f_rank.text = ("World rank #%d of %d" % [int(me.rank), runs]).to_upper()
		f_rank.visible = true
	else:
		f_rank.visible = false


func render_favs() -> void:
	for c in fav_list.get_children():
		c.queue_free()
		fav_list.remove_child(c)
	var favs: Array = game.favs
	fav_empty.visible = favs.is_empty()
	for f in favs:
		var cur: bool = game.track != null and f.seed == game.track.seed
		var row := tap(PANEL2, accent if cur else Color(0, 0, 0, 0), 12.0)
		row.custom_minimum_size = Vector2(0, 52)
		row.pad(12, 6, 6, 6)
		var h := hbox(10)
		var ed := Dot.new()
		ed.rect = true
		ed.col = U.css(Envs.DATA[f.env].accent) if Envs.DATA.has(f.env) else DIM
		ed.custom_minimum_size = Vector2(10, 28)
		ed.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ed)
		var nm := vbox(3)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.alignment = BoxContainer.ALIGNMENT_CENTER
		var nb := L(str(f.name), "display", 800, 17, FG, true, 0.0, true)
		nb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nb.clip_text = true
		nm.add_child(nb)
		nm.add_child(L(str(f.seed), "mono", 500, 11, DIM))
		h.add_child(nm)
		var b = Store.get_value("best5." + str(f.seed), null)
		var bt = b.t if b != null else null
		var med = CarSim.medal_for(bt, f.medals) if (f.has("medals") and f.get("v", 0) == 5 and f.medals is Dictionary) else null
		var tm := hbox(6)
		if med != null:
			var d := dot(MEDAL_COL[med])
			d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			tm.add_child(d)
		var tl := L(U.fmt(bt) if bt != null else "—", "mono", 500, 13, FG)
		tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tm.add_child(tl)
		h.add_child(tm)
		var x := tap(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 9.0)
		x.custom_minimum_size = Vector2(34, 34)
		x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var xi := Icon.new("x", 14)
		xi.color = DIM
		x.add_child(center(xi))
		var seed_s: String = f.seed
		var env_s: String = f.env
		x.pressed.connect(func(): game.remove_fav(seed_s))
		h.add_child(x)
		row.add_child(h)
		row.pressed.connect(func(): game.load_fav(seed_s, env_s))
		fav_list.add_child(row)


func set_tab(t: String) -> void:
	for b in tabs:
		var on: bool = b.get_meta("v") == t
		b.style(Color(1, 1, 1, 0.1) if on else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 9.0)
		(b.get_meta("lbl") as Label).add_theme_color_override("font_color", FG if on else DIM)
	for k in panes:
		panes[k].visible = k == t
	tab_scroll.scroll_vertical = 0
	relayout()


func sync_opts() -> void:
	var o: Dictionary = game.opts
	for k in opt_segs:
		set_seg(opt_segs[k], str(o.get(k, "")))
	var v := int(o.sensV)
	sens_slider.set_value_no_signal(v)
	sens_out.text = ("Gentle" if v < 34 else ("Normal" if v < 67 else "Quick")).to_upper()
	stats_lbl.visible = str(o.stats) != ""
	sync_icons()
	relayout()


func sync_car() -> void:
	var c: String = game.car_cfg.color
	var custom := not SWATCHES.has(c)
	for b in swatches:
		var key: String = b.get_meta("c")
		var on := (key == c) or (key == "custom" and custom)
		b.set_border_state(FG if on else Color(1, 1, 1, 0.12), 2.0 if on else 1.0)
	set_seg(finish_seg, game.car_cfg.finish)


func _process(_dt: float) -> void:
	if _nav_direction != Vector2i.ZERO and (menu_on or pause_modal.visible or finish_modal.visible or color_popup.visible):
		_nav_repeat_timer -= _dt
		if _nav_repeat_timer <= 0.0:
			_focus_direction(_nav_direction)
			_nav_repeat_timer = 0.12
	# keep swatches square (aspect-ratio: 1)
	if swatch_box and swatch_box.is_visible_in_tree():
		for b in swatches:
			if absf(b.custom_minimum_size.y - b.size.x) > 0.5:
				b.custom_minimum_size.y = b.size.x


# ------------------------------------------------------------------ menu / hud visibility

func set_menu(on: bool) -> void:
	menu_on = on
	if menu_tw:
		menu_tw.kill()
	menu_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	mtop.visible = on
	if on:
		relayout()
		focus_default()
		var target := sheet.position
		_apply_menu_hidden()
		menu_tw.tween_property(sheet, "position", target, 0.45)
		menu_tw.tween_property(sheet, "modulate:a", 1.0, 0.3)
		menu_tw.tween_property(mtop, "modulate:a", 1.0, 0.3)
	else:
		_set_stick_direction(Vector2i.ZERO)
		var focus := _focus_owner()
		if focus and (sheet.is_ancestor_of(focus) or mtop.is_ancestor_of(focus)):
			focus.release_focus()
		var rect := sheet_rect()
		menu_tw.tween_property(sheet, "position:y", rect.position.y + rect.size.y * 1.05, 0.45)
		menu_tw.tween_property(sheet, "modulate:a", 0.0, 0.3)
		menu_tw.tween_property(mtop, "modulate:a", 0.0, 0.3)


func _apply_menu_hidden() -> void:
	if menu_on:
		sheet.position.y += sheet.size.y * 1.05
		sheet.modulate.a = 0.0
	else:
		sheet.position.y += sheet.size.y * 1.05
		sheet.modulate.a = 0.0


func show_hud(on: bool) -> void:
	hud.visible = on
	pads.visible = on and touch


func set_touch(on: bool) -> void:
	touch = on
	pads.visible = hud.visible and touch
	hint.visible = not touch


func hud_sync(force: bool) -> void:
	var g = game
	var t: float = 0.0
	if g.state == "countdown":
		t = 0.0
	elif g.state == "finished":
		t = g.finish_t
	else:
		t = g.race_steps * U.STEP
	var s := U.fmt(t)
	if force or _hud_cache.get("t") != s:
		timer_lbl.text = s
		_hud_cache["t"] = s
	var ln := mini(g.lap, U.LAPS)
	if force or _hud_cache.get("l") != ln:
		lap_n.text = str(ln)
		_hud_cache["l"] = ln
	if force or _hud_cache.get("c") != g.next_cp:
		cp_n.text = str(g.next_cp)
		cp_t.text = str(g.track.cps.size())
		_hud_cache["c"] = g.next_cp
	var cs := clock.get_combined_minimum_size()
	if force or cs != clock.size:
		clock.size = cs
		clock.position.x = (size.x - clock.size.x) / 2.0


func show_split(d, t: float) -> void:
	if d == null:
		split_lbl.text = U.fmt(t)
		split_lbl.add_theme_color_override("font_color", FG)
	else:
		split_lbl.text = U.fmt_delta(d)
		split_lbl.add_theme_color_override("font_color", FAST if d <= 0.0 else SLOW)
	clock.size = clock.get_combined_minimum_size()
	clock.position.x = (size.x - clock.size.x) / 2.0
	if split_tw:
		split_tw.kill()
	split_box.modulate.a = 0.0
	split_tw = create_tween()
	split_tw.tween_property(split_box, "modulate:a", 1.0, 0.2)
	split_tw.tween_interval(2.4)
	split_tw.tween_property(split_box, "modulate:a", 0.0, 0.2)


func clear_split() -> void:
	if split_tw:
		split_tw.kill()
	split_box.modulate.a = 0.0


func count_flash(txt: String, go: bool) -> void:
	count_lbl.text = txt
	count_lbl.add_theme_color_override("font_color", accent if go else FG)
	if count_tw:
		count_tw.kill()
	count_lbl.scale = Vector2(1.7, 1.7)
	count_lbl.modulate.a = 0.0
	count_tw = create_tween().set_parallel(true)
	count_tw.tween_property(count_lbl, "scale", Vector2(0.9, 0.9), 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var a := create_tween()
	a.tween_property(count_lbl, "modulate:a", 1.0, 0.175)
	a.tween_property(count_lbl, "modulate:a", 0.0, 0.525)


func boost_fx(c: Color) -> void:
	(boost_rect.material as ShaderMaterial).set_shader_parameter("glow", c)
	if boost_tw:
		boost_tw.kill()
	boost_tw = create_tween()
	boost_tw.tween_property(boost_rect, "modulate:a", 0.55, 0.04)
	boost_tw.tween_interval(0.1)
	boost_tw.tween_property(boost_rect, "modulate:a", 0.0, 0.45)


func toast(s: String) -> void:
	toast_lbl.text = s
	toast_box.size = toast_box.get_combined_minimum_size()
	var y: float = safe.t + 70.0
	toast_box.position = Vector2((size.x - toast_box.size.x) / 2.0, y - 8.0)
	if toast_tw:
		toast_tw.kill()
	toast_tw = create_tween()
	toast_tw.set_parallel(true)
	toast_tw.tween_property(toast_box, "modulate:a", 1.0, 0.25)
	toast_tw.tween_property(toast_box, "position:y", y, 0.25)
	toast_tw.chain().tween_interval(1.35)
	toast_tw.chain().tween_property(toast_box, "modulate:a", 0.0, 0.25)


func show_pause(on: bool, track_txt: String = "") -> void:
	pause_modal.visible = on
	if on:
		_set_stick_direction(Vector2i.ZERO)
		pause_track.text = track_txt.to_upper()
		_rise(pause_modal.get_child(0))
		pause_resume.grab_focus()
	elif finish_modal.visible:
		finish_retry.grab_focus()
	else:
		var focus := _focus_owner()
		if focus and pause_modal.is_ancestor_of(focus):
			focus.release_focus()


func _rise(card: Control) -> void:
	relayout()
	var y := card.position.y
	card.position.y = y + 24.0
	card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "position:y", y, 0.45)
	tw.tween_property(card, "modulate:a", 1.0, 0.45)


func hide_finish() -> void:
	finish_modal.visible = false
	_set_stick_direction(Vector2i.ZERO)
	var focus := _focus_owner()
	if focus and finish_modal.is_ancestor_of(focus):
		focus.release_focus()


func show_finish(track_txt: String, t: float, medal, delta_txt: String, delta_col: Color, pb) -> void:
	f_track.text = track_txt.to_upper()
	f_time.text = U.fmt(t)
	if medal != null:
		var md: Array = []
		for m in CarSim.MEDALS:
			if m[0] == medal:
				md = m
		f_medal_dot.visible = true
		(f_medal_dot as Dot).col = MEDAL_COL[medal]
		f_medal_dot.queue_redraw()
		f_medal.text = (md[1] + " medal").to_upper()
	else:
		f_medal_dot.visible = false
		f_medal.text = "NO MEDAL"
	f_delta.text = delta_txt
	f_delta.add_theme_color_override("font_color", delta_col)
	render_medals(f_medals, pb)
	sync_icons()
	finish_modal.visible = true
	_rise(finish_modal.get_child(0))
	finish_retry.grab_focus()


func set_loading(on: bool) -> void:
	if loading_tw:
		loading_tw.kill()
	if on:
		loading.visible = true
		loading.modulate.a = 1.0
	else:
		loading_tw = create_tween()
		loading_tw.tween_property(loading, "modulate:a", 0.0, 0.4)
		loading_tw.tween_callback(func(): loading.visible = false)


func set_stats(s: String) -> void:
	stats_lbl.text = s
	stats_lbl.size = stats_lbl.get_combined_minimum_size()
	stats_lbl.position = Vector2(size.x - maxf(16.0, safe.r) - stats_lbl.size.x, size.y - safe.b - 6.0 - stats_lbl.size.y)


# ------------------------------------------------------------------ touch controls

func sync_pedals(gas: bool, brake: bool) -> void:
	var dark := Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.42)
	pad_gas.fill_top = accent if gas else dark
	pad_gas.fill_bot = pad_gas.fill_top
	pad_gas.border_col = accent
	pad_gas.scale = Vector2(0.95, 0.95) if gas else Vector2.ONE
	gas_l.add_theme_color_override("font_color", on_accent if gas else accent)
	pad_gas._sync()
	pad_brake.fill_top = Color(1, 90 / 255.0, 79 / 255.0, 0.55) if brake else dark
	pad_brake.fill_bot = pad_brake.fill_top
	pad_brake.scale = Vector2(0.95, 0.95) if brake else Vector2.ONE
	brake_l1.add_theme_color_override("font_color", Color.WHITE if brake else Color("#ffb3ad"))
	brake_l2.add_theme_color_override("font_color", Color(Color.WHITE if brake else Color("#ffb3ad"), 0.7))
	pad_brake._sync()


func set_wheel(disp: float, on: bool) -> void:
	if wheel.on != on:
		wheel.on = on
		var tw := create_tween()
		tw.tween_property(wheel, "modulate:a", 1.0 if on else 0.72, 0.0 if on else 0.2)
	wheel.rot = disp * 1.95
	wheel.queue_redraw()
	var w := steer_bar.size.x
	steer_fill.size = Vector2(absf(disp * 0.5) * w, 4)
	steer_fill.position = Vector2((0.5 + disp * 0.5) * w if disp < 0.0 else 0.5 * w, 0)


func hide_tip(which: String) -> void:
	var l := tip_l if which == "L" else tip_r
	if l.modulate.a > 0.5:
		create_tween().tween_property(l, "modulate:a", 0.0, 0.4)
		var seen: Dictionary = Store.get_value("tips", {})
		seen[which] = 1
		Store.set_value("tips", seen)


func init_tips() -> void:
	var seen: Dictionary = Store.get_value("tips", {})
	if seen.get("L", 0):
		tip_l.modulate.a = 0.0
	if seen.get("R", 0):
		tip_r.modulate.a = 0.0


func _pads_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			game.touch_down(ev.index, ev.position.x, _pedal_at(ev.position.x))
		else:
			game.touch_up(ev.index)
		pads.accept_event()
	elif ev is InputEventScreenDrag:
		game.touch_move(ev.index, ev.position.x, _pedal_at(ev.position.x))
		pads.accept_event()


func _pedal_at(x: float) -> String:
	var gc := pad_gas.position.x + pad_gas.size.x / 2.0
	var bc := pad_brake.position.x + pad_brake.size.x / 2.0
	return "gas" if absf(x - gc) <= absf(x - bc) else "brake"
