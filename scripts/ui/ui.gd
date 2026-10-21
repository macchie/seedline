class_name Ui
extends Control
## All 2D interface (port of the web build's HTML/CSS): menu with Drive / Garage / Options,
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
const BOOST_SWATCHES := ["#38e8ff", "#3fb4ff", "#ff9a3c", "#d25bff", "#2ec27e", "#ff4f78", "#f2c230", "#eef1f5"]

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
var seed_copy_lbl: Label
var btn_fav: Tap
var ic_fav: Icon
var tabs: Array = []
var tab_list: Control
var panes := {}
var tab_scroll: ScrollContainer
var seed_in: LineEdit
var lb_box: VBoxContainer
var lb_group: VBoxContainer
var lb_panel: Glass
var lb_panel_box: VBoxContainer
var lb_panel_title: Label
var lb_split := false
var act_row: HBoxContainer
var seed_row: HBoxContainer
var th_row: HBoxContainer
var fav_title: Label
var fav_cap: Label
var rand_cap: Label
var name_base := 34.0
var tabs_box: Glass
var btn_rand: Tap
var panes_box: VBoxContainer
var lb_eyebrow: Label
var lb_stats: Label
var online_lbl: Label
var btn_acct: Tap
var ic_acct: Icon
var acct_modal: Control
var acct_scroll: ScrollContainer
var acct_box: VBoxContainer
var acct_mode := "signin"
var acct_busy := false
var _acct_settled := false
var acct_seg: Array = []
var acct_seg_box: Control
var acct_form: VBoxContainer
var acct_info: VBoxContainer
var acct_head: Label
var acct_sub: Label
var acct_email: LineEdit
var acct_pw: LineEdit
var acct_name: LineEdit
var acct_rename: LineEdit
var acct_save_name: Tap
var acct_err: Label
var acct_submit: Tap
var acct_submit_lbl: Label
var acct_signout: Tap
var acct_who: Label
var acct_mail_lbl: Label
var acct_opt_status: Label
var acct_opt_btn: Tap
var acct_opt_lbl: Label
var net_status_lbl: Label
var f_rank: Label
var swatch_box: GridContainer
var swatches: Array = []
var boost_swatch_box: GridContainer
var boost_swatches: Array = []
var finish_seg: Array = []
var fav_list: VBoxContainer
var fav_empty: Label
var fav_track_cache := {}
var fav_track_cache_order: Array[String] = []
var fav_preview_views: Array[Dictionary] = []
var fav_preview_revision := 0
var fav_preview_task_running := false
const FAV_TRACK_CACHE_LIMIT := 32
var sens_slider: HSlider
var sens_out: Label
var opt_segs := {}
var pad_boost: Tap
var bind_dev := "kb"
var bind_dev_btns: Array = []
var bind_rows: VBoxContainer
var bind_btns := {}
var bind_note: Label
var _rebind := {}
var _rebind_t := 0
var boost_l: Label
var meter: BoostMeter
var btn_play: Tap
var custom_swatch: Tap
var color_popup: PopupPanel
var color_picker: ColorPicker
var picker_target := "paint"
var menu_on := true
var menu_tw: Tween
var pause_resume: Tap
var finish_retry: Tap
var _nav_stick := Vector2.ZERO
var _nav_direction := Vector2i.ZERO
var _nav_repeat_timer := 0.0
const NAV_FIRST_DELAY := 0.5
const NAV_REPEAT_DELAY := 0.24

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
var f_best: VBoxContainer
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


## Labeled button: icon, title and a one-line caption that explains what it does. Returns [tap, icon, title, caption].
func _action_btn(kind: String, title: String, caption: String, tip: String) -> Array:
	var b := tap(PANEL, LINE, 12.0, 2.5)
	b.custom_minimum_size = Vector2(0, 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = tip
	b.pad(10, 4, 8, 4)
	var row := hbox(8)
	var ic := Icon.new(kind, 20)
	ic.color = FG
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var col := vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := L(title, "body", 700, 12, FG, false, 0.04, true)
	t.clip_text = true
	t.custom_minimum_size = Vector2(1, 0)
	var c := L(caption, "body", 400, 10, DIM)
	c.clip_text = true
	c.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	c.custom_minimum_size = Vector2(1, 0)
	col.add_child(t)
	col.add_child(c)
	row.add_child(col)
	b.add_child(row)
	return [b, ic, t, c]


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
	Input.joy_connection_changed.connect(func(_d, _c): refresh_binds())
	relayout()
	call_deferred("focus_default")


func focus_default() -> void:
	if color_popup and color_popup.visible:
		return
	if modal_open():
		acct_email.grab_focus()
	elif pause_modal and pause_modal.visible:
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
	if modal_open() and next != null and not acct_modal.is_ancestor_of(next):
		return
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
	_nav_repeat_timer = NAV_FIRST_DELAY
	if direction != Vector2i.ZERO:
		_focus_direction(direction)


func handle_joypad_event(ev: InputEvent) -> bool:
	if game.state != "menu" and game.state != "paused" and not finish_modal.visible and not color_popup.visible and not modal_open():
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
			if modal_open():
				return true
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
	if modal_open():
		show_account(false)
	elif color_popup.visible:
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
	var ab := icon_btn("user")
	btn_acct = ab[0]
	ic_acct = ab[1]
	btn_acct.tooltip_text = "Account"
	btn_acct.pressed.connect(func(): show_account(true))
	mtop.add_child(btn_acct)
	# desktop-only side panel for the track leaderboard
	lb_panel = glass(Color(11 / 255.0, 14 / 255.0, 20 / 255.0, 0.78), LINE, 18.0, 3.5)
	lb_panel.fill_bot = Color(9 / 255.0, 11 / 255.0, 16 / 255.0, 0.96)
	lb_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	lb_panel.clip_contents = true
	lb_panel.pad(18, 16, 18, 16)
	lb_panel.visible = false
	lb_panel_box = vbox(10)
	lb_panel_title = L("Track leaderboard", "display", 800, 22, FG, true, 0.04, true)
	lb_panel_box.add_child(lb_panel_title)
	lb_panel_box.add_child(L("Fastest online times on this exact seed.", "body", 400, 12, DIM))
	lb_panel.add_child(lb_panel_box)
	mtop.add_child(lb_panel)
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
	th_row = throw
	var thtext := vbox(6)
	thtext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thtext.alignment = BoxContainer.ALIGNMENT_CENTER
	env_lbl = eyebrow("Canyon")
	env_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	env_lbl.custom_minimum_size = Vector2(1, 0)
	name_lbl = L("Track", "display", 800, 34, FG, true, 0.005, true)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(1, 0)
	name_lbl.max_lines_visible = 3
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	thtext.add_child(env_lbl)
	thtext.add_child(name_lbl)
	throw.add_child(thtext)
	prev_box = glass(Color(0, 0, 0, 0.25), LINE, 12.0)
	prev_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	prev_map = MapView.new()
	prev_map.preview = true
	prev_box.add_child(prev_map)
	throw.add_child(prev_box)
	trackhead.add_child(throw)
	var seedrow := hbox(8)
	seed_row = seedrow
	var chip := tap(PANEL2, Color(1, 1, 1, 0.22), 12.0)
	chip.dash = 6.0
	chip.custom_minimum_size = Vector2(0, 42)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.pad(12, 0, 12, 0)
	chip.tooltip_text = "Copy this track's seed. Share it so others can race the exact same track."
	var chiprow := hbox(8)
	var sl0 := L("Seed", "body", 600, 10, DIM, false, 0.14, true)
	sl0.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chiprow.add_child(sl0)
	seed_lbl = L("—", "mono", 700, 15, FG, false, 0.06)
	seed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seed_lbl.clip_text = true
	seed_lbl.custom_minimum_size = Vector2(1, 0)
	chiprow.add_child(seed_lbl)
	seed_copy_lbl = L("Tap to copy", "body", 600, 10, DIM, false, 0.14, true)
	seed_copy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chiprow.add_child(seed_copy_lbl)
	chip.add_child(chiprow)
	chip.pressed.connect(func(): game.copy_seed())
	seedrow.add_child(chip)
	trackhead.add_child(seedrow)
	act_row = hbox(8)
	var fb := _action_btn("star", "Save track", "Add to Tracks", "Save this track so you can find it later in the Tracks menu.")
	btn_fav = fb[0]
	ic_fav = fb[1]
	fav_title = fb[2]
	fav_cap = fb[3]
	btn_fav.pressed.connect(func(): game.toggle_fav())
	act_row.add_child(btn_fav)
	var nb := _action_btn("dice", "Random track", "Roll a new seed", "Generate a brand new random track.")
	rand_cap = nb[3]
	btn_rand = nb[0]
	nb[0].pressed.connect(func(): game.new_random_track())
	act_row.add_child(nb[0])
	trackhead.add_child(act_row)
	sheet_box.add_child(trackhead)
	# tabs
	var tbox := glass(PANEL2, Color(0, 0, 0, 0), 12.0)
	tabs_box = tbox
	tbox.pad(4, 4, 4, 4)
	var trow := hbox(4)
	tbox.add_child(trow)
	tab_list = Control.new()
	tab_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_list.custom_minimum_size = Vector2(0, 42)
	tbox.add_child(tab_list)
	for t in [["drive", "Drive"], ["garage", "Garage"], ["tracks", "Tracks"], ["options", "Options"]]:
		var b := tap(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 9.0)
		b.custom_minimum_size = Vector2(0, 42)
		b.focus_mode = Control.FOCUS_ALL
		var l := L(t[1], "body", 700, 12, DIM, false, 0.12, true)
		b.add_child(center(l))
		b.set_meta("v", t[0])
		b.set_meta("lbl", l)
		var v: String = t[0]
		b.pressed.connect(func(): game.set_tab(v))
		tab_list.add_child(b)
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
	panes_box = vbox(0)
	panes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_scroll.add_child(panes_box)
	_build_track_pane(panes_box)
	_build_garage_pane(panes_box)
	_build_tracks_pane(panes_box)
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
	var p := _pane(parent, "drive")
	p.add_child(eyebrow("Track code"))
	var form := hbox(8)
	seed_in = LineEdit.new()
	seed_in.placeholder_text = "Paste a seed, e.g. A7K2M9Q4B6N8P3RX"
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
	# Keep online rankings available on wide desktop layouts without crowding the Drive panel.
	var lb_head := hbox(8)
	lb_eyebrow = eyebrow("Leaderboard")
	lb_eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb_head.add_child(lb_eyebrow)
	lb_stats = L("", "body", 600, 10, DIM, false, 0.12, true)
	lb_head.add_child(lb_stats)
	lb_box = vbox(2)
	lb_group = vbox(6)
	lb_group.add_child(lb_head)
	lb_group.add_child(lb_box)
	p.add_child(lb_group)
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
	cu.pressed.connect(func():
		picker_target = "paint"
		_open_picker())
	swatch_box.add_child(cu)
	custom_swatch = cu
	swatches.append(cu)
	p.add_child(eyebrow("Booster color"))
	boost_swatch_box = GridContainer.new()
	boost_swatch_box.columns = 4
	boost_swatch_box.add_theme_constant_override("h_separation", 8)
	boost_swatch_box.add_theme_constant_override("v_separation", 8)
	boost_swatch_box.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(boost_swatch_box)
	for c in BOOST_SWATCHES:
		var b := tap(U.css(c), Color(0, 0, 0, 0), 12.0)
		b.inset_col = Color(0, 0, 0, 0.2)
		b.inset_h = 6.0
		b.border_w = 2.0
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("c", c)
		var cc: String = c
		b.pressed.connect(func(): game.set_boost_color(cc))
		boost_swatch_box.add_child(b)
		boost_swatches.append(b)
	var boost_custom := tap(Color.WHITE, Color(0, 0, 0, 0), 12.0)
	boost_custom._mat.set_shader_parameter("conic", 1.0)
	boost_custom.set_meta("c", "custom")
	boost_custom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boost_custom.border_w = 2.0
	boost_custom.pressed.connect(func():
		picker_target = "booster"
		_open_picker())
	boost_swatch_box.add_child(boost_custom)
	boost_swatches.append(boost_custom)
	color_popup = PopupPanel.new()
	color_picker = ColorPicker.new()
	color_picker.focus_mode = Control.FOCUS_ALL
	color_picker.edit_alpha = false
	color_picker.presets_visible = false
	color_picker.sampler_visible = false
	color_picker.color_modes_visible = false
	color_picker.color_changed.connect(func(c):
		if picker_target == "booster":
			game.set_boost_color("#" + c.to_html(false))
		else:
			game.set_car_color("#" + c.to_html(false)))
	color_popup.add_child(color_picker)
	add_child(color_popup)
	p.add_child(eyebrow("Finish"))
	var s := seg([["gloss", "Gloss"], ["metal", "Metallic"], ["matte", "Matte"]], func(v): game.set_finish(v))
	finish_seg = s[1]
	p.add_child(s[0])


func _build_tracks_pane(parent: Control) -> void:
	var p := _pane(parent, "tracks")
	p.add_child(eyebrow("Saved tracks"))
	fav_list = vbox(6)
	p.add_child(fav_list)
	fav_empty = L("No saved tracks yet. Save a track from Drive to keep it here.", "body", 400, 13, DIM)
	fav_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fav_empty.custom_minimum_size = Vector2(0, 36)
	p.add_child(fav_empty)


func _open_picker() -> void:
	color_picker.color = U.css(game.car_cfg.boost_color if picker_target == "booster" else game.car_cfg.color)
	var sz := Vector2i(
		mini(300, maxi(200, int(size.x) - 24)),
		mini(360, maxi(220, int(size.y) - 24))
	)
	color_popup.popup_centered(sz)
	call_deferred("_focus_color_picker")


func _focus_color_picker() -> void:
	if color_popup.visible:
		color_picker.grab_focus()


func _build_options_pane(parent: Control) -> void:
	var p := _pane(parent, "options")
	p.add_child(eyebrow("Visuals"))
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
	o2.add_child(eyebrow("Controls"))
	var ds := seg([["kb", "Keyboard"], ["pad", "Gamepad"]], func(v): _set_bind_device(v))
	bind_dev_btns = ds[1]
	o2.add_child(ds[0])
	bind_rows = vbox(4)
	for a in Bindings.visible_actions(game.DRIFT_ENABLED):
		var id: String = a[0]
		var row := hbox(6)
		var nm := L(a[1], "body", 500, 13, FG)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.custom_minimum_size = Vector2(60, 0)
		row.add_child(nm)
		var btns: Array = []
		for slot in 2:
			var b := tap(PANEL2, LINE, 8.0)
			b.custom_minimum_size = Vector2(112, 34)
			var bl := L("—", "mono", 700, 11, FG)
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.add_child(center(bl))
			b.set_meta("lbl", bl)
			var sl := slot
			b.pressed.connect(func(): _begin_rebind(id, sl))
			row.add_child(b)
			btns.append(b)
		bind_btns[id] = btns
		bind_rows.add_child(row)
	o2.add_child(bind_rows)
	var reset := tap(PANEL2, LINE, 10.0)
	reset.custom_minimum_size = Vector2(0, 36)
	var rl2 := L("Reset to defaults", "body", 600, 12, FG, false, 0.06, true)
	rl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset.add_child(center(rl2))
	reset.pressed.connect(func():
		_cancel_rebind()
		Bindings.reset_device(bind_dev)
		refresh_binds())
	o2.add_child(reset)
	bind_note = L("", "body", 400, 12, DIM)
	bind_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bind_note.custom_minimum_size = Vector2(120, 0)
	o2.add_child(bind_note)
	p.add_child(o2)
	_set_bind_device("kb")
	var oa := vbox(6)
	oa.add_child(eyebrow("Account"))
	acct_opt_status = L("", "body", 400, 12, DIM)
	acct_opt_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	acct_opt_status.custom_minimum_size = Vector2(120, 0)
	oa.add_child(acct_opt_status)
	var ob := _cbtn("Sign in / Create account", false)
	acct_opt_btn = ob[0]
	acct_opt_lbl = ob[1]
	ob[0].pressed.connect(func(): show_account(true))
	oa.add_child(ob[0])
	p.add_child(oa)
	net_status_lbl = L("", "body", 400, 12, DIM)
	net_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	net_status_lbl.custom_minimum_size = Vector2(120, 0)
	p.add_child(net_status_lbl)


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
	pad_boost = tap(Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.42), Color("#ff9a3c"), 22.0, 2.0)
	pad_boost.border_w = 1.5
	pad_boost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boost_l = L("BOOST", "display", 800, 14, Color("#ff9a3c"), true, 0.08)
	pad_boost.add_child(center(boost_l))
	pads.add_child(pad_boost)
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
	refresh_hint()
	hud.add_child(hint)
	meter = BoostMeter.new()
	hud.add_child(meter)
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
	f_best = vbox(2)
	fbox.add_child(f_best)
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
	_build_account_modal()


func _field(placeholder: String, secret := false) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.secret = secret
	f.custom_minimum_size = Vector2(0, 44)
	f.add_theme_stylebox_override("normal", (seed_in.get_theme_stylebox("normal") as StyleBox).duplicate())
	f.add_theme_stylebox_override("focus", (seed_in.get_theme_stylebox("focus") as StyleBox).duplicate())
	f.add_theme_font_override("font", UiFonts.get_font("body", 600))
	f.add_theme_font_size_override("font_size", 14)
	f.add_theme_color_override("font_color", FG)
	f.add_theme_color_override("caret_color", FG)
	f.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.3))
	return f


func _build_account_modal() -> void:
	acct_modal = ColorRect.new()
	(acct_modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.7)
	acct_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	acct_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	acct_modal.visible = false
	add_child(acct_modal)
	var card := glass(PANEL, LINE, 20.0, 3.0)
	card.pad(22, 22, 22, 22)
	acct_modal.add_child(card)
	acct_scroll = ScrollContainer.new()
	acct_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	acct_scroll.follow_focus = true
	card.add_child(acct_scroll)
	acct_box = vbox(12)
	acct_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acct_scroll.add_child(acct_box)
	acct_head = L("Account", "display", 800, 30, FG, true, 0.0, true)
	acct_box.add_child(acct_head)
	acct_sub = L("", "body", 400, 12, DIM)
	acct_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	acct_sub.custom_minimum_size = Vector2(120, 0)
	acct_box.add_child(acct_sub)
	# signed out
	acct_form = vbox(10)
	var sg := seg([["signin", "Sign in"], ["register", "Create account"]], func(v): _set_acct_mode(v))
	acct_seg_box = sg[0]
	acct_seg = sg[1]
	acct_form.add_child(acct_seg_box)
	acct_email = _field("Email")
	acct_email.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	acct_email.max_length = 120
	acct_pw = _field("Password (8+ characters)", true)
	acct_pw.max_length = 128
	acct_name = _field("Racer name (optional)")
	acct_name.max_length = 20
	acct_email.text_submitted.connect(func(_t): acct_pw.grab_focus())
	acct_pw.text_submitted.connect(func(_t): _acct_enter())
	acct_name.text_submitted.connect(func(_t): _acct_submit())
	acct_form.add_child(acct_email)
	acct_form.add_child(acct_pw)
	acct_form.add_child(acct_name)
	acct_err = L("", "body", 600, 12, Color("#ff6b5e"))
	acct_err.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	acct_err.custom_minimum_size = Vector2(120, 0)
	acct_err.visible = false
	acct_form.add_child(acct_err)
	var sbm := _cbtn("Sign in", true)
	acct_submit = sbm[0]
	acct_submit_lbl = sbm[1]
	acct_submit.pressed.connect(func(): _acct_submit())
	acct_form.add_child(acct_submit)
	acct_box.add_child(acct_form)
	# signed in
	acct_info = vbox(10)
	var who := glass(PANEL2, Color(0, 0, 0, 0), 12.0)
	who.pad(14, 10, 14, 10)
	var wcol := vbox(2)
	acct_who = L("", "display", 800, 22, FG, true, 0.02, true)
	acct_who.clip_text = true
	acct_who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	acct_who.custom_minimum_size = Vector2(1, 0)
	acct_mail_lbl = L("", "body", 500, 12, DIM)
	acct_mail_lbl.clip_text = true
	acct_mail_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	acct_mail_lbl.custom_minimum_size = Vector2(1, 0)
	wcol.add_child(acct_who)
	wcol.add_child(acct_mail_lbl)
	who.add_child(wcol)
	acct_info.add_child(who)
	acct_info.add_child(eyebrow("Racer name"))
	acct_rename = _field("Racer name")
	acct_rename.max_length = 20
	acct_rename.text_submitted.connect(func(_t): _acct_save_name())
	acct_info.add_child(acct_rename)
	var sn := _cbtn("Save name", false)
	acct_save_name = sn[0]
	acct_save_name.pressed.connect(func(): _acct_save_name())
	acct_info.add_child(sn[0])
	var so := _cbtn("Sign out", false)
	acct_signout = so[0]
	acct_signout.pressed.connect(func(): _acct_sign_out())
	acct_info.add_child(so[0])
	acct_box.add_child(acct_info)
	var cl := _cbtn("Close", false, "Esc")
	cl[0].pressed.connect(func(): show_account(false))
	acct_box.add_child(cl[0])
	acct_modal.set_meta("close", cl[0])
	_set_acct_mode("signin")


func _set_acct_mode(m: String) -> void:
	acct_mode = m
	set_seg(acct_seg, m)
	var reg := m == "register"
	acct_name.visible = reg
	acct_submit_lbl.text = ("Create account" if reg else "Sign in").to_upper()
	acct_pw.placeholder_text = "Password (8+ characters)" if reg else "Password"
	acct_err.visible = false
	if acct_modal.visible:
		relayout()


func _acct_enter() -> void:
	if acct_mode == "register":
		acct_name.grab_focus()
	else:
		_acct_submit()


func _acct_error(t: String) -> void:
	acct_err.text = t
	acct_err.visible = t != ""
	if acct_modal.visible:
		relayout()


func _acct_submit() -> void:
	if acct_busy:
		return
	var mail := acct_email.text.strip_edges()
	var pw := acct_pw.text
	if not game.net.enabled:
		_acct_error("Online features are disabled in this build.")
		return
	if mail.length() < 5 or mail.find("@") < 1 or mail.rfind(".") < mail.find("@") + 2:
		_acct_error("Enter a valid email address.")
		return
	if acct_mode == "register" and pw.length() < Net.PASSWORD_MIN:
		_acct_error("Use at least %d characters for the password." % Net.PASSWORD_MIN)
		return
	if pw == "":
		_acct_error("Enter your password.")
		return
	acct_busy = true
	acct_submit_lbl.text = "PLEASE WAIT…"
	_acct_error("")
	var r: Dictionary
	if acct_mode == "register":
		r = await game.net.register(mail, pw, acct_name.text)
	else:
		r = await game.net.login(mail, pw)
	acct_busy = false
	_set_acct_mode(acct_mode)
	if r.ok:
		acct_pw.text = ""
		show_account(false)
		toast("Signed in" if acct_mode == "signin" else "Account created")
	else:
		_acct_error(_acct_message(r))


func _acct_message(r: Dictionary) -> String:
	match int(r.code):
		0:
			return "Can't reach the server. Check your connection and try again."
		400:
			var m := str(r.message)
			return m if m != "" else "Check your email and password."
		401, 404:
			return "Wrong email or password."
		409:
			return "That email is already registered. Use Sign in instead."
		429:
			return "Too many attempts. Wait a moment and try again."
	return "Something went wrong (%d). Try again." % int(r.code)


func _acct_save_name() -> void:
	var n := acct_rename.text.strip_edges()
	if n.length() < 2:
		toast("Name needs at least 2 characters")
		return
	if n != game.net.display_name:
		game.set_racer_name(n)
		toast("Racer name saved")
	sync_account()


func _acct_sign_out() -> void:
	if acct_busy:
		return
	acct_busy = true
	await game.net.logout()
	acct_busy = false
	show_account(false)
	toast("Signed out")


func modal_open() -> bool:
	return acct_modal != null and acct_modal.visible


func show_account(on: bool) -> void:
	if on == acct_modal.visible:
		return
	acct_modal.visible = on
	_set_stick_direction(Vector2i.ZERO)
	if on:
		sync_account()
		_acct_error("")
		relayout()
		_rise(acct_modal.get_child(0))
		if game.net.is_registered():
			(acct_modal.get_meta("close") as Control).grab_focus()
		else:
			acct_email.grab_focus()
	else:
		var focus := _focus_owner()
		if focus and acct_modal.is_ancestor_of(focus):
			focus.release_focus()
		if menu_on:
			btn_acct.grab_focus()


func sync_account() -> void:
	var net: Net = game.net
	var reg := net.is_registered()
	acct_form.visible = not reg
	acct_info.visible = reg
	acct_head.text = ("Your account" if reg else "Account").to_upper()
	acct_sub.text = ("Your car and settings sync to every device you sign in on." if reg else
		"Sign in to keep your car and runs across devices. Creating an account keeps everything you've done so far.")
	acct_who.text = net.display_name
	acct_mail_lbl.text = net.email
	ic_acct.color = accent if reg else FG
	ic_acct.queue_redraw()
	if acct_opt_status:
		acct_opt_status.text = ("Signed in as %s" % net.email) if reg else "Playing as a guest. Sign in to sync your car and runs."
		acct_opt_lbl.text = ("Manage account" if reg else "Sign in / Create account").to_upper()
	if acct_rename and not acct_rename.has_focus():
		acct_rename.text = net.display_name
	if acct_modal.visible:
		relayout()


func _layout_account(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if acct_modal == null:
		return
	var card: Glass = acct_modal.get_child(0)
	var cw := minf(440.0, W - sl - sr - 16.0)
	var avail := H - st - sb - 16.0
	# wrapped labels only report their real height once they have the final width
	for l in [acct_sub, acct_err]:
		l.custom_minimum_size.x = cw - 44.0
	acct_box.custom_minimum_size.x = cw - 44.0
	var content := acct_box.get_combined_minimum_size().y
	acct_scroll.custom_minimum_size = Vector2(0, minf(content, maxf(120.0, avail - 44.0)))
	card.size = Vector2(cw, 0)
	card.size = Vector2(cw, card.get_combined_minimum_size().y)
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - card.size.y) / 2.0))
	card._sync()
	if not _acct_settled:
		_acct_settled = true
		get_tree().process_frame.connect(func():
			_acct_settled = false
			if acct_modal.visible:
				_layout_account(W, H, sl, sr, st, sb), CONNECT_ONE_SHOT)


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
	var desktop_menu := W >= 860.0
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
	tag.visible = W >= 400.0
	var top_pad := st + (24.0 if desktop else 14.0)
	var bsz := brand.get_combined_minimum_size()
	brand.size = bsz
	if right_brand:
		# justify-content:flex-end, gap 14: brand then sound button at the right
		btn_sound.position = Vector2(W - sr - 42.0, top_pad + (bsz.y - 42.0) / 2.0)
		brand.position = Vector2(btn_sound.position.x - 14.0 - 50.0 - bsz.x, top_pad)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		(wm_a.get_parent() as HBoxContainer).alignment = BoxContainer.ALIGNMENT_END
	else:
		brand.position = Vector2(sl, top_pad)
		btn_sound.position = Vector2(W - sr - 42.0, top_pad + (bsz.y - 42.0) / 2.0)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		(wm_a.get_parent() as HBoxContainer).alignment = BoxContainer.ALIGNMENT_BEGIN
	btn_sound.size = Vector2(42, 42)
	btn_acct.size = Vector2(42, 42)
	btn_acct.position = btn_sound.position - Vector2(50.0, 0.0)
	# sheet
	var name_size := clampf(7.4 * vw, 26.0, 40.0)
	var pm := clampf(21.0 * vw, 72.0, 96.0)
	if landscape_short:
		name_size = 24.0
		pm = 60.0
	trackhead.visible = game.menu_tab == "drive"
	btn_play.visible = game.menu_tab == "drive"
	# on phones the track head scrolls with the tab content so the body keeps a usable height
	var head_scroll := not desktop
	var head_iw := (W - sl - sr) if not landscape_short else (minf(360.0, 0.46 * W) - 32.0)
	name_base = name_size
	prev_box.custom_minimum_size = Vector2(pm, pm)
	prev_map.custom_minimum_size = Vector2(pm, pm)
	for c in [fav_cap, rand_cap]:
		c.visible = not landscape_short and W >= 400.0
	for ab in [btn_fav, btn_rand]:
		ab.custom_minimum_size.y = 36.0 if landscape_short else (40.0 if W < 400.0 else 46.0)
	seed_row.get_child(0).custom_minimum_size.y = 36.0 if landscape_short else 42.0
	var compact_seed := landscape_short or W < 400.0
	seed_copy_lbl.text = "COPY" if compact_seed else "TAP TO COPY"
	restyle(seed_lbl, 12.0 if compact_seed else 15.0)
	restyle(seed_copy_lbl, 9.0 if compact_seed else 10.0)
	_place_head(head_scroll)
	if head_scroll:
		trackhead.custom_minimum_size = Vector2(0, _trackhead_height(head_iw - 6.0))
	else:
		trackhead.custom_minimum_size = Vector2.ZERO
	if desktop:
		sheet.pad(18, 18, 18, 18)
		sheet.radius = Vector4(18, 18, 18, 18)
		sheet.border_col = LINE
		var w := 570.0
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
		var maxh := minf(H * (0.44 if garage else 0.6), 420.0 if garage else 720.0)
		var content := _sheet_content_height(W - sl - sr)
		var h := minf(maxh, content + 24.0 + sb)
		sheet.position = Vector2(0, H - h)
		sheet.size = Vector2(W, h)
	var content_w := sheet.size.x - float(sheet.get_theme_constant("margin_left")) - float(sheet.get_theme_constant("margin_right"))
	if desktop_menu:
		content_w -= 128.0
	else:
		content_w -= 12.0
	var bind_label_w := 46.0 if W < 360.0 else (52.0 if W < 400.0 else 60.0)
	var bind_gap := 4 if W < 360.0 else 6
	var bind_button_w := clampf((content_w - bind_label_w - float(bind_gap * 3)) / 2.0, 72.0, 112.0)
	for row in bind_rows.get_children():
		row.add_theme_constant_override("separation", bind_gap)
		row.get_child(0).custom_minimum_size.x = bind_label_w
		for slot in 2:
			(row.get_child(slot + 1) as Control).custom_minimum_size.x = bind_button_w
	if desktop_menu:
		tabs_box.style(Color(1, 1, 1, 0.035), Color(1, 1, 1, 0.06), 14.0)
	else:
		tabs_box.style(Color(1, 1, 1, 0.055), Color(0, 0, 0, 0), 12.0)
	_layout_sheet_inner()
	sheet._sync()
	if not menu_on:
		_apply_menu_hidden()
	_layout_lb_panel(W, H, st, sr, desktop and W >= 1100.0, desktop and W >= 1100.0 and game.menu_tab == "drive")
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
	pad_boost.visible = touch
	if not touch:
		var ms := clampf(0.14 * minf(W, H), 84.0, 120.0)
		meter.size = Vector2(ms, ms)
		meter.position = Vector2(W - sr - ms - 16.0, H - sb - ms - 16.0)
	restyle(count_lbl, clampf(30.0 * vw, 110.0, 190.0))
	count_lbl.size = Vector2(W, H)
	count_lbl.position = Vector2.ZERO
	count_lbl.pivot_offset = Vector2(W, H) / 2.0
	(boost_rect.material as ShaderMaterial).set_shader_parameter("rect_size", Vector2(W, H))
	_layout_pads(W, H, sl, sr, sb)
	# modals
	_layout_account(W, H, sl, sr, st, sb)
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
	if size.x >= 860.0:
		var nav_w := 112.0
		var gap := 16.0
		var content_x := nav_w + gap
		var content_w := maxf(1.0, iw - content_x)
		tabs_box.pad(8, 8, 8, 8)
		tabs_box.position = Vector2.ZERO
		tabs_box.size = Vector2(nav_w, minf(tabs.size() * 48.0 + 16.0, ih))
		tab_list.size = tabs_box.size - Vector2(16, 16)
		for i in tabs.size():
			var b: Tap = tabs[i]
			b.position = Vector2(0, i * 48.0)
			b.size = Vector2(tab_list.size.x, 42.0)
		var main_y := 0.0
		if trackhead.visible:
			var hh := _trackhead_height(content_w - 6.0)
			trackhead.position = Vector2(content_x, main_y)
			trackhead.size = Vector2(content_w, hh)
			main_y += hh + 10.0
		var play_h := btn_play.get_combined_minimum_size().y if btn_play.visible else 0.0
		var body_h := maxf(0.0, ih - main_y - play_h - (10.0 if play_h > 0.0 else 0.0))
		tab_scroll.position = Vector2(content_x, main_y)
		tab_scroll.size = Vector2(content_w, body_h)
		btn_play.position = Vector2(content_x, main_y + body_h + 10.0)
		btn_play.size = Vector2(content_w, play_h)
		for c in [tabs_box, trackhead, tab_scroll, btn_play]:
			c.visible = c == tabs_box or (c == trackhead and trackhead.visible) or (c == tab_scroll) or (c == btn_play and btn_play.visible)
		return
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
	tabs_box.pad(4, 4, 4, 4)
	tab_list.size = tabs_box.size - Vector2(8, 8)
	var nav_gap := 2.0 if size.x < 320.0 else (4.0 if size.x < 360.0 else 8.0)
	var nav_font := 10.0 if size.x < 320.0 else (11.0 if size.x < 400.0 else 12.0)
	var item_w := maxf(0.0, (tab_list.size.x - nav_gap * (tabs.size() - 1)) / tabs.size())
	for i in tabs.size():
		var b: Tap = tabs[i]
		b.position = Vector2(i * (item_w + nav_gap), 0)
		b.size = Vector2(item_w, tab_list.size.y)
		restyle(b.get_meta("lbl"), nav_font)


## The track head's height with the name wrapped at the width it will get (labels measure lazily)
func _place_head(in_scroll: bool) -> void:
	var target: Control = panes_box if in_scroll else sheet_box
	if trackhead.get_parent() == target:
		return
	trackhead.get_parent().remove_child(trackhead)
	target.add_child(trackhead)
	target.move_child(trackhead, 0)


func _trackhead_height(iw: float) -> float:
	var pm := prev_box.custom_minimum_size.x
	var text_w := maxf(40.0, iw - pm - 12.0)
	env_lbl.size = Vector2(text_w, env_lbl.size.y)
	_fit_name(text_w)
	name_lbl.size = Vector2(text_w, name_lbl.size.y)
	var env_h := env_lbl.get_minimum_size().y
	var name_h := name_lbl.get_minimum_size().y
	var top := maxf(env_h + 6.0 + name_h, pm)
	th_row.custom_minimum_size.y = top
	return top + 8.0 + seed_row.get_combined_minimum_size().y + 8.0 + act_row.get_combined_minimum_size().y


## Shrink the track name until its longest word fits and it takes at most two lines.
func _fit_name(text_w: float) -> void:
	var font := name_lbl.get_theme_font("font")
	var txt := name_lbl.text.to_upper()
	var avail := text_w * 0.95
	var sz := int(round(name_base))
	while sz > 16:
		var ok := true
		for w in txt.split(" ", false):
			if font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > avail:
				ok = false
				break
		if ok:
			var h := font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, avail, sz).y
			ok = h <= font.get_height(sz) * 2.05
		if ok:
			break
		sz -= 1
	restyle(name_lbl, sz)
	name_lbl.add_theme_constant_override("line_spacing", -int(sz * 0.2))


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
			if trackhead.get_parent() == panes_box and trackhead.visible:
				h += trackhead.custom_minimum_size.y + 12.0
		elif c == trackhead:
			h += _trackhead_height(inner_w)
		else:
			h += c.get_combined_minimum_size().y
	return h + 10.0 * maxf(0.0, n - 1)


## On wide desktop windows the leaderboard leaves the Track tab and lives in its own panel on the right.
func right_panel_width() -> float:
	return lb_panel.size.x + 16.0 if lb_panel.visible else 0.0


func _layout_lb_panel(W: float, H: float, st: float, sr: float, wide: bool, show: bool) -> void:
	var split: bool = wide
	if split != lb_split:
		lb_split = split
		lb_group.get_parent().remove_child(lb_group)
		if split:
			lb_panel_box.add_child(lb_group)
		else:
			var tp: VBoxContainer = panes["drive"]
			tp.add_child(lb_group)
	lb_eyebrow.visible = not split
	lb_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL if split else Control.SIZE_SHRINK_BEGIN
	lb_panel.visible = show
	if not show:
		return
	var w := clampf(W * 0.26, 300.0, 380.0)
	var top := maxf(st + 92.0, btn_sound.position.y + btn_sound.size.y + 12.0)
	lb_panel.position = Vector2(W - sr - w, top)
	lb_panel_title.text = "Track leaderboard".to_upper()
	var avail := H - top - 24.0
	lb_panel.size = Vector2(w, w)
	var need := lb_panel_box.get_combined_minimum_size().y + 32.0
	lb_panel.size = Vector2(w, clampf(need, 160.0, avail))
	lb_panel._sync()


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
	var boh := clampf(11.0 * vw, 56.0, 72.0)
	pad_boost.size = Vector2(gw, boh)
	pad_boost.position = Vector2(pad_gas.position.x, pad_gas.position.y - 10.0 - boh)
	pad_boost.pivot_offset = pad_boost.size / 2.0
	pad_boost._sync()
	var msz := clampf(20.0 * vw, 70.0, 92.0)
	if touch:
		meter.size = Vector2(msz, msz)
		meter.position = Vector2(pad_brake.position.x + (bw - msz) / 2.0, pad_brake.position.y - 8.0 - msz)
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
		tip_r.position = Vector2(sl, H - sb - 18.0 - gh - 24.0 - boh - tip_r.size.y)
	else:
		tip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip_l.size.x = W / 2.0 - sl
		tip_l.position = Vector2(sl, H - sb - 20.0 - wsz - 18.0 - tip_l.size.y)
		tip_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tip_r.position = Vector2(W - sr - tip_r.size.x, H - sb - 18.0 - gh - 24.0 - boh - tip_r.size.y)


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
	for m in [pause_modal, finish_modal, acct_modal]:
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
	fav_title.text = ("Saved" if fav else "Save track").to_upper()
	fav_cap.text = "Tap to remove" if fav else "Add to Saved tab"
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


func render_personal_best(box: VBoxContainer, pb) -> void:
	for c in box.get_children():
		c.queue_free()
		box.remove_child(c)
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
	fav_preview_revision += 1
	for c in fav_list.get_children():
		c.queue_free()
		fav_list.remove_child(c)
	var favs: Array = game.favs
	fav_preview_views.clear()
	fav_empty.visible = favs.is_empty()
	for f in favs:
		var cur: bool = game.track != null and f.seed == game.track.seed
		var row := tap(PANEL2, accent if cur else Color(0, 0, 0, 0), 12.0)
		row.custom_minimum_size = Vector2(0, 76)
		row.pad(8, 7, 8, 7)
		var env_key := str(f.get("env", ""))
		if not Envs.DATA.has(env_key):
			var parsed = game.parse_seed(str(f.get("seed", "")))
			if parsed != null:
				env_key = str(parsed.env)
		var map_accent := U.css(Envs.DATA[env_key].accent) if Envs.DATA.has(env_key) else accent
		var h := hbox(10)
		var preview_box := glass(Color(0, 0, 0, 0.26), LINE, 9.0)
		preview_box.custom_minimum_size = Vector2(62, 62)
		preview_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		preview_box.pad(2, 2, 2, 2)
		var preview := MapView.new()
		preview.preview = true
		preview.custom_minimum_size = Vector2(58, 58)
		preview_box.add_child(preview)
		h.add_child(preview_box)
		var nm := vbox(3)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.alignment = BoxContainer.ALIGNMENT_CENTER
		var nb := L(str(f.name), "display", 800, 17, FG, true, 0.0, true)
		nb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nb.clip_text = true
		nb.custom_minimum_size = Vector2(1, 0)
		nm.add_child(nb)
		var seed_label := L(str(f.seed), "mono", 500, 11, DIM)
		seed_label.clip_text = true
		seed_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		seed_label.custom_minimum_size = Vector2(1, 0)
		nm.add_child(seed_label)
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
		var env_s := env_key
		x.pressed.connect(func(): game.remove_fav(seed_s))
		h.add_child(x)
		row.add_child(h)
		row.pressed.connect(func(): game.load_fav(seed_s, env_s))
		fav_list.add_child(row)
		fav_preview_views.append({
			"map": preview,
			"seed": seed_s,
			"env": env_s,
			"accent": map_accent,
		})
	if game.menu_tab == "tracks":
		call_deferred("_populate_fav_previews")


func _populate_fav_previews() -> void:
	if fav_preview_task_running or game.menu_tab != "tracks":
		return
	fav_preview_task_running = true
	var revision := fav_preview_revision
	for entry in fav_preview_views:
		if revision != fav_preview_revision or game.menu_tab != "tracks":
			break
		var preview := entry.map as MapView
		if not is_instance_valid(preview) or preview.t != null:
			continue
		var track := _cached_fav_track(str(entry.seed), str(entry.env))
		preview.set_track(track, entry.accent)
		await get_tree().process_frame
	fav_preview_task_running = false
	if game.menu_tab == "tracks" and revision != fav_preview_revision:
		call_deferred("_populate_fav_previews")


func _cached_fav_track(seed: String, env_key: String) -> TrackData:
	var key := env_key + "|" + seed
	if fav_track_cache.has(key):
		fav_track_cache_order.erase(key)
		fav_track_cache_order.append(key)
		return fav_track_cache[key]
	var track: TrackData
	if game.track != null and game.track.seed == seed and game.track.env_key == env_key:
		track = game.track
	else:
		track = TrackGen.generate(seed, env_key)
	fav_track_cache[key] = track
	fav_track_cache_order.append(key)
	if fav_track_cache_order.size() > FAV_TRACK_CACHE_LIMIT:
		var expired: String = fav_track_cache_order.pop_front()
		fav_track_cache.erase(expired)
	return track


func set_tab(t: String) -> void:
	for b in tabs:
		var on: bool = b.get_meta("v") == t
		b.style(Color(1, 1, 1, 0.1) if on else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 9.0)
		(b.get_meta("lbl") as Label).add_theme_color_override("font_color", FG if on else DIM)
	for k in panes:
		panes[k].visible = k == t
	tab_scroll.scroll_vertical = 0
	if btn_play:
		btn_play.visible = t == "drive"
	relayout()
	if t == "tracks":
		call_deferred("_populate_fav_previews")


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
	var boost_color: String = game.car_cfg.boost_color
	var custom_boost := not BOOST_SWATCHES.has(boost_color)
	for b in boost_swatches:
		var key: String = b.get_meta("c")
		var on := (key == boost_color) or (key == "custom" and custom_boost)
		b.set_border_state(FG if on else Color(1, 1, 1, 0.12), 2.0 if on else 1.0)


func _input(ev: InputEvent) -> void:
	if modal_open() and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		show_account(false)


func _process(_dt: float) -> void:
	if _nav_direction != Vector2i.ZERO and (menu_on or pause_modal.visible or finish_modal.visible or color_popup.visible or modal_open()):
		_nav_repeat_timer -= _dt
		if _nav_repeat_timer <= 0.0:
			_focus_direction(_nav_direction)
			_nav_repeat_timer = NAV_REPEAT_DELAY
	# keep swatches square (aspect-ratio: 1)
	if swatch_box and swatch_box.is_visible_in_tree():
		for b in swatches + boost_swatches:
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
	if is_node_ready():
		refresh_hint()
		relayout()


func hud_sync(force: bool) -> void:
	var g = game
	meter.set_state(g.car.boost_amt, CarSim.BOOST_CAP, g.car.boost_held)
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


func _set_bind_device(d: String) -> void:
	bind_dev = d
	_cancel_rebind()
	set_seg(bind_dev_btns, d)
	refresh_binds()


func refresh_binds() -> void:
	for id in bind_btns:
		for slot in 2:
			var b: Tap = bind_btns[id][slot]
			var v = Bindings.get_slot(bind_dev, id, slot)
			var txt: String = Bindings.key_label(v) if bind_dev == "kb" else Bindings.pad_label(v)
			var listening: bool = _rebind.get("action", "") == id and _rebind.get("slot", -1) == slot
			(b.get_meta("lbl") as Label).text = "Press…" if listening else txt
			(b.get_meta("lbl") as Label).add_theme_color_override("font_color", accent if listening else FG)
	if bind_dev == "kb":
		bind_note.text = "Tap a slot, then press a key. Tap it again to clear. Esc cancels."
	else:
		bind_note.text = "Tap a slot, then press a button or move a stick or trigger. Menus always use D-pad / stick, A / Cross to select, B / Circle to go back."
	refresh_hint()


func _begin_rebind(action: String, slot: int) -> void:
	if _rebind.get("action", "") == action and _rebind.get("slot", -1) == slot:
		_apply_binding(0 if bind_dev == "kb" else "")
		return
	_rebind = {"action": action, "slot": slot, "dev": bind_dev}
	_rebind_t = Time.get_ticks_msec()
	refresh_binds()
	var stamp := _rebind_t
	get_tree().create_timer(6.0).timeout.connect(func():
		if _rebind_t == stamp and not _rebind.is_empty():
			_cancel_rebind())


func rebind_active() -> bool:
	return not _rebind.is_empty()


func _cancel_rebind() -> void:
	if _rebind.is_empty():
		return
	_rebind = {}
	refresh_binds()


func _apply_binding(value) -> void:
	Bindings.set_slot(_rebind.dev, _rebind.action, _rebind.slot, value)
	_rebind = {}
	refresh_binds()


## Called first for every input event while a slot is listening; returns true if the event was consumed.
func capture_binding(ev: InputEvent) -> bool:
	if Time.get_ticks_msec() - _rebind_t < 200:
		return ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion
	if _rebind.dev == "kb":
		if ev is InputEventKey:
			if ev.pressed and not ev.echo:
				if ev.keycode == KEY_ESCAPE:
					_cancel_rebind()
				else:
					var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
					_apply_binding(code)
			return true
		return false
	if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
		var b := Bindings.pad_from_event(ev)
		if b.begins_with("a:") and b.split(":")[1] in ["4", "5"] and b.ends_with("-"):
			return true
		if b != "":
			_apply_binding(b)
		return true
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_cancel_rebind()
		return true
	return false


func refresh_hint() -> void:
	for c in hint.get_children():
		hint.remove_child(c)
		c.queue_free()
	var items := [["boost", "Boost"], ["respawn", "Respawn"], ["restart", "Restart"], ["pause", "Pause"]]
	var pad_mode: bool = not Input.get_connected_joypads().is_empty() and not game.touch_ui
	for h in items:
		var label: String
		if pad_mode:
			label = Bindings.pad_label(Bindings.get_slot("pad", h[0], 0))
			if label == "—":
				label = Bindings.pad_label(Bindings.get_slot("pad", h[0], 1))
		else:
			label = Bindings.key_label(Bindings.get_slot("kb", h[0], 0))
		if label == "—":
			continue
		var row := hbox(4)
		var k := glass(PANEL, LINE, 5.0)
		k.pad(5, 2, 5, 2)
		k.add_child(L(label, "mono", 700, 11, FG))
		row.add_child(k)
		var t := L(h[1], "body", 500, 12, Color(1, 1, 1, 0.6))
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(t)
		hint.add_child(row)
	if is_node_ready() and hint.is_inside_tree():
		hint.size = hint.get_combined_minimum_size()


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
	render_personal_best(f_best, pb)
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

func sync_pedals(gas: bool, brake: bool, boost := false) -> void:
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
	var bo := Color("#ff9a3c")
	pad_boost.fill_top = Color(bo, 0.7) if boost else dark
	pad_boost.fill_bot = pad_boost.fill_top
	pad_boost.border_col = bo
	pad_boost.scale = Vector2(0.95, 0.95) if boost else Vector2.ONE
	boost_l.add_theme_color_override("font_color", Color.BLACK if boost else bo)
	pad_boost._sync()


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
			game.touch_down(ev.index, ev.position.x, _pedal_at(ev.position))
		else:
			game.touch_up(ev.index)
		pads.accept_event()
	elif ev is InputEventScreenDrag:
		game.touch_move(ev.index, ev.position.x, _pedal_at(ev.position))
		pads.accept_event()


func _pedal_at(p: Vector2) -> String:
	var br := Rect2(pad_boost.position, pad_boost.size).grow(8.0)
	if br.has_point(p):
		return "boost"
	var gc := pad_gas.position.x + pad_gas.size.x / 2.0
	var bc := pad_brake.position.x + pad_brake.size.x / 2.0
	return "gas" if absf(p.x - gc) <= absf(p.x - bc) else "brake"
