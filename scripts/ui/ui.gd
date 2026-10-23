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
var brand_rule: Glass
var btn_sound: Tap
var ic_sound: Icon
var btn_debug: Tap
var ic_debug: Icon
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
var panes := {}
var tab_scroll: ScrollContainer
var seed_in: LineEdit
# current-track leaderboard: a summary button in the track card that opens a full dialog
var lb_card_btn: Tap
var lb_card_sum: Label
var lb_modal: Control
var lb_dialog_box: VBoxContainer
var lb_dialog_scroll: ScrollContainer
var lb_box: VBoxContainer          # the list of rank rows, inside the dialog
var lb_stats: Label                # runs / racers, inside the dialog
var lb_hero_rank: Label
var lb_hero_time: Label
var lb_hero_sub: Label
var lb_hero: Glass
var _lb_info = null
var act_row: HBoxContainer
var seed_row: HBoxContainer
var th_row: HBoxContainer
var fav_title: Label
var fav_cap: Label
var rand_cap: Label
var name_base := 34.0
var nav_menu: Control
var section_title: Label
var btn_rand: Tap
var panes_box: VBoxContainer
# track-card best time + medal (moved out of the bottom toolbar)
var card_best_lbl: Label
var card_best_dot: Dot
# bottom toolbar (player card + online status only)
var bottombar: Glass
var bar_box: Control
var btn_card: Tap
var pc_avatar: Icon
var pc_name: Label
var pc_status: Label
var pc_online: Label
# events (daily / weekly seed challenges)
var events_note: Label
var events_grid: GridContainer
var event_cards := {}
var _events_now := 0.0
var _events_t0 := 0
var acct_modal: Control
var seed_modal: Control
# debug track-preview compare screen (hidden dev tool; opened from the home top bar)
var debug_modal: Control
var debug_box: VBoxContainer
var debug_scroll: ScrollContainer
var debug_grid: GridContainer
var debug_seed_in: LineEdit
var debug_reroll: Tap
var debug_close: Tap
var debug_seeds: Array[String] = []
var debug_preview_views: Array[Dictionary] = []
var _debug_revision := 0
var _debug_task_running := false
const DEBUG_COUNT := 12
var seed_dialog_button: Tap
var seed_dialog_caption: Label
var seed_dialog_box: VBoxContainer
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
var fav_list: GridContainer
var fav_empty: Label
var recent_track_list: GridContainer
var recent_track_empty: Label
var track_action_modal: Control
var track_action_box: VBoxContainer
var track_action_preview: MapView
var track_action_title: Label
var track_action_sub: Label
var track_action_race: Tap
var track_action_watch: Tap
var track_action_remove: Tap
var _track_action_seed := ""
var _track_action_env := ""
var fav_track_cache := {}
var fav_track_cache_order: Array[String] = []
var fav_preview_views: Array[Dictionary] = []
var recent_preview_views: Array[Dictionary] = []
var fav_preview_revision := 0
var fav_preview_task_running := false
const FAV_TRACK_CACHE_LIMIT := 32
var sens_slider: HSlider
var sens_out: Label
# options content lives in options_body; it is reparented into options_modal when opened in-game
var options_body: VBoxContainer
var options_modal: Control
var options_scroll: ScrollContainer
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
var respawn_btn: Tap
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
var lap_info: HBoxContainer
var replay_lbl: Label
var replay_progress: ProgressBar
var replay_mode := false
var replay_exact := true
var lap_n: Label
var cp_n: Label
var cp_t: Label
var split_box: Glass
var split_lbl: Label
var split_tw: Tween
var hint: HBoxContainer
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
		if options_modal.visible:
			sens_slider.grab_focus()
		elif track_action_modal.visible:
			track_action_race.grab_focus()
		elif lb_modal.visible:
			(lb_modal.get_meta("close") as Control).grab_focus()
		elif debug_modal.visible:
			debug_reroll.grab_focus()
		elif seed_modal.visible:
			seed_in.grab_focus()
		else:
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
	var neighbor_path: NodePath
	if side == SIDE_LEFT:
		neighbor_path = owner.focus_neighbor_left
	elif side == SIDE_RIGHT:
		neighbor_path = owner.focus_neighbor_right
	elif side == SIDE_TOP:
		neighbor_path = owner.focus_neighbor_top
	else:
		neighbor_path = owner.focus_neighbor_bottom
	var next := owner.get_node_or_null(neighbor_path) as Control if not neighbor_path.is_empty() else null
	if next == null or not next.is_visible_in_tree() or next.focus_mode == Control.FOCUS_NONE:
		next = owner.find_valid_focus_neighbor(side)
	if next == null:
		next = owner.find_next_valid_focus() if direction.x > 0 or direction.y > 0 else owner.find_prev_valid_focus()
	var dialog := _active_dialog()
	if dialog != null and next != null and not dialog.is_ancestor_of(next):
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
	if game.state != "menu" and game.state != "paused" and game.state != "replay" and not finish_modal.visible and not color_popup.visible and not modal_open():
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
			elif game.state == "replay":
				game.toggle_pause()
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
		_close_dialog()
	elif color_popup.visible:
		color_popup.hide()
		custom_swatch.grab_focus()
	elif game.state == "paused":
		game.resume()
	elif game.state == "replay":
		game.toggle_pause()
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
	# accent speed-rule under the wordmark (Rocket League-style highlight)
	brand_rule = glass(accent, Color(0, 0, 0, 0), 2.0)
	brand_rule.custom_minimum_size = Vector2(0, 3)
	brand.add_child(brand_rule)
	tag = L("Procedural time trial", "body", 600, 10, Color(1, 1, 1, 0.7), false, 0.24, true)
	tag.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	tag.add_theme_constant_override("shadow_outline_size", 6)
	brand.add_child(tag)
	mtop.add_child(brand)
	var sb := icon_btn("sound")
	btn_sound = sb[0]
	ic_sound = sb[1]
	btn_sound.pressed.connect(func(): game.toggle_sound())
	mtop.add_child(btn_sound)
	var db := icon_btn("bug")
	btn_debug = db[0]
	ic_debug = db[1]
	btn_debug.tooltip_text = "Debug: compare track previews across seeds"
	btn_debug.pressed.connect(func(): show_debug(true))
	mtop.add_child(btn_debug)
	_build_nav()
	_build_bottombar()
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
	# section title header (replaces the old tab strip; the nav lives outside the panel now)
	section_title = L("PLAY", "display", 800, 20, FG, true, 0.06, true)
	sheet_box.add_child(section_title)
	sheet_box.add_child(trackhead)
	# section body
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
	_build_events_pane(panes_box)
	_build_garage_pane(panes_box)
	_build_tracks_pane(panes_box)
	_build_options_pane(panes_box)
	# play — the hero button: glossy accent slab with a play glyph, perfectly centred wordmark and a speed chevron
	btn_play = tap(accent, Color(0, 0, 0, 0), 18.0)
	btn_play.custom_minimum_size = Vector2(0, 76)
	btn_play.pad(16, 12, 16, 14)
	var prow := hbox(10)
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	# left play glyph (fixed-width so the wordmark stays dead-centre)
	var play_ic := Icon.new("play", 22)
	play_ic.filled = true
	play_ic.color = on_accent
	var play_wrap := center(play_ic)
	play_wrap.custom_minimum_size = Vector2(46, 0)
	play_wrap.size_flags_vertical = Control.SIZE_FILL
	var ptext := vbox(2)
	ptext.alignment = BoxContainer.ALIGNMENT_CENTER
	ptext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var race := L("RACE", "display", 800, 27, on_accent, true, 0.16, true)
	race.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	race.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	race.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.22))
	race.add_theme_constant_override("shadow_offset_y", 1)
	var enter := L("ENTER / A / CROSS", "mono", 700, 10, Color(on_accent, 0.55), false, 0.12)
	enter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ptext.add_child(race)
	ptext.add_child(enter)
	# right speed chevron, mirrored to the play glyph so the wordmark stays centred
	var chev := L("\u00bb", "display", 900, 26, Color(on_accent, 0.7), true)
	chev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var chev_wrap := center(chev)
	chev_wrap.custom_minimum_size = Vector2(46, 0)
	chev_wrap.size_flags_vertical = Control.SIZE_FILL
	prow.add_child(play_wrap)
	prow.add_child(ptext)
	prow.add_child(chev_wrap)
	btn_play.add_child(prow)
	btn_play.set_meta("race", race)
	btn_play.set_meta("enter", enter)
	btn_play.set_meta("chev", chev)
	btn_play.set_meta("play", play_ic)
	btn_play.pressed.connect(func(): game.start_race())
	_style_play()
	sheet_box.add_child(btn_play)


## Left section menu (collapses to a horizontal row on phones). Each item is an accent-pill Tap.
func _build_nav() -> void:
	nav_menu = Control.new()
	nav_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mtop.add_child(nav_menu)
	for t in [["drive", "Play"], ["events", "Events"], ["garage", "Garage"], ["tracks", "Tracks"], ["options", "Options"]]:
		var b := tap(Color(1, 1, 1, 0.025), Color(0, 0, 0, 0), 10.0)
		b.custom_minimum_size = Vector2(0, 44)
		b.focus_mode = Control.FOCUS_ALL
		var l := L(t[1], "body", 700, 13, DIM, false, 0.12, true)
		b.add_child(center(l))
		b.set_meta("v", t[0])
		b.set_meta("lbl", l)
		var v: String = t[0]
		b.pressed.connect(func(): game.set_tab(v))
		nav_menu.add_child(b)
		tabs.append(b)


## Persistent bottom toolbar: player card (avatar + name + status) plus now-racing / best / online.
func _build_bottombar() -> void:
	bottombar = glass(Color(11 / 255.0, 14 / 255.0, 20 / 255.0, 0.82), LINE, 16.0, 3.5)
	bottombar.fill_bot = Color(9 / 255.0, 11 / 255.0, 16 / 255.0, 0.96)
	bottombar.mouse_filter = Control.MOUSE_FILTER_STOP
	bottombar.clip_contents = true
	mtop.add_child(bottombar)
	bar_box = Control.new()
	bar_box.mouse_filter = Control.MOUSE_FILTER_PASS
	bottombar.add_child(bar_box)
	# player card — opens the account screen
	btn_card = tap(Color(1, 1, 1, 0.04), LINE, 12.0)
	btn_card.custom_minimum_size = Vector2(0, 48)
	btn_card.pad(8, 6, 14, 6)
	btn_card.tooltip_text = "Account"
	var crow := hbox(10)
	var avatar_box := glass(Color(accent, 0.18), Color(accent, 0.5), 10.0)
	avatar_box.custom_minimum_size = Vector2(38, 38)
	avatar_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pc_avatar = Icon.new("user", 20)
	pc_avatar.color = FG
	avatar_box.add_child(center(pc_avatar))
	crow.add_child(avatar_box)
	var ccol := vbox(1)
	ccol.alignment = BoxContainer.ALIGNMENT_CENTER
	ccol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc_name = L("Racer", "display", 800, 14, FG, true, 0.02, true)
	pc_name.clip_text = true
	pc_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pc_name.custom_minimum_size = Vector2(1, 0)
	pc_status = L("● OFFLINE", "body", 600, 10, DIM, false, 0.14, true)
	ccol.add_child(pc_name)
	ccol.add_child(pc_status)
	crow.add_child(ccol)
	btn_card.add_child(crow)
	btn_card.pressed.connect(func(): show_account(true))
	bar_box.add_child(btn_card)
	# online presence count (right side)
	pc_online = L("● OFFLINE", "body", 600, 10, DIM, false, 0.14, true)
	pc_online.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_box.add_child(pc_online)


func _pane(parent: Control, key: String) -> VBoxContainer:
	var p := vbox(12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	panes[key] = p
	return p


func _build_track_pane(parent: Control) -> void:
	var p := _pane(parent, "drive")
	# track-card summary: personal best on the left, a leaderboard button on the right
	var stat_row := hbox(8)
	var best_chip := glass(PANEL2, LINE, 12.0)
	best_chip.custom_minimum_size = Vector2(0, 50)
	best_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	best_chip.pad(12, 0, 12, 0)
	var best_in := hbox(8)
	card_best_dot = dot(MEDAL_COL["gold"], 9)
	card_best_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_best_dot.visible = false
	best_in.add_child(card_best_dot)
	var best_col := vbox(1)
	best_col.alignment = BoxContainer.ALIGNMENT_CENTER
	best_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	best_col.add_child(L("YOUR BEST", "body", 600, 9, DIM, false, 0.14, true))
	card_best_lbl = L("NOT RACED YET", "mono", 700, 14, DIM, false, 0.02)
	card_best_lbl.clip_text = true
	card_best_lbl.custom_minimum_size = Vector2(1, 0)
	best_col.add_child(card_best_lbl)
	best_in.add_child(best_col)
	best_chip.add_child(best_in)
	stat_row.add_child(best_chip)
	lb_card_btn = tap(PANEL2, LINE, 12.0)
	lb_card_btn.custom_minimum_size = Vector2(0, 50)
	lb_card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb_card_btn.pad(12, 0, 10, 0)
	lb_card_btn.tooltip_text = "Open the full online leaderboard for this track."
	var lbrow := hbox(8)
	var lbicon := Icon.new("trophy", 18)
	lbicon.color = accent
	lbicon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbrow.add_child(lbicon)
	var lbcol := vbox(1)
	lbcol.alignment = BoxContainer.ALIGNMENT_CENTER
	lbcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbcol.add_child(L("LEADERBOARD", "body", 700, 11, FG, false, 0.06, true))
	lb_card_sum = L("—", "body", 500, 10, DIM, false, 0.04, true)
	lb_card_sum.clip_text = true
	lb_card_sum.custom_minimum_size = Vector2(1, 0)
	lbcol.add_child(lb_card_sum)
	lbrow.add_child(lbcol)
	var lbchev := L("›", "display", 800, 20, DIM, true)
	lbchev.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbrow.add_child(lbchev)
	lb_card_btn.add_child(lbrow)
	lb_card_btn.pressed.connect(func(): show_leaderboard(true))
	stat_row.add_child(lb_card_btn)
	p.add_child(stat_row)
	p.add_child(eyebrow("Track code"))
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
	seed_in.text_submitted.connect(func(_text): _submit_seed())
	var seed_action := _cbtn("Race a track code", false, "ENTER")
	seed_dialog_button = seed_action[0]
	seed_dialog_button.pressed.connect(func(): show_seed_dialog(true))
	p.add_child(seed_dialog_button)
	var seed_note := L("Paste a 16-character code to race the same course as a friend.", "body", 400, 11, DIM)
	seed_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	seed_note.custom_minimum_size = Vector2(120, 0)
	p.add_child(seed_note)
	render_leaderboard(null)


func _build_events_pane(parent: Control) -> void:
	var p := _pane(parent, "events")
	events_note = L("Connect to compete in the daily and weekly seed challenges.", "body", 400, 12, DIM)
	events_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	events_note.custom_minimum_size = Vector2(1, 0)
	p.add_child(events_note)
	events_grid = GridContainer.new()
	events_grid.columns = 2
	events_grid.add_theme_constant_override("h_separation", 10)
	events_grid.add_theme_constant_override("v_separation", 10)
	events_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(events_grid)
	_build_event_card(events_grid, "daily", "Daily Seed", "A fresh seed every day. Set the fastest time before midnight UTC.")
	_build_event_card(events_grid, "weekly", "Weekly Seed", "One seed all week. Grind for the top of the board.")


## One challenge card (daily or weekly): title + countdown, the featured seed, your rank, top times, Race.
func _build_event_card(parent: Control, kind: String, title: String, blurb: String) -> void:
	var card := glass(PANEL2, LINE, 14.0)
	card.pad(14, 12, 14, 14)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	var col := vbox(9)
	card.add_child(col)
	var head := hbox(8)
	var title_lbl := L(title, "display", 800, 16, FG, true, 0.04, true)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var cd := L("—", "mono", 700, 11, accent, false, 0.04)
	cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title_lbl)
	head.add_child(cd)
	col.add_child(head)
	var blurb_lbl := L(blurb, "body", 400, 11, DIM)
	blurb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb_lbl.custom_minimum_size = Vector2(1, 0)
	col.add_child(blurb_lbl)
	# featured seed (tap to copy)
	var chip := tap(PANEL2, Color(1, 1, 1, 0.2), 10.0)
	chip.dash = 6.0
	chip.custom_minimum_size = Vector2(0, 38)
	chip.pad(12, 0, 12, 0)
	var chiprow := hbox(8)
	var sl0 := L("Seed", "body", 600, 10, DIM, false, 0.14, true)
	sl0.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chiprow.add_child(sl0)
	var seed_lbl := L("—", "mono", 700, 14, FG, false, 0.05)
	seed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seed_lbl.clip_text = true
	chiprow.add_child(seed_lbl)
	var copy_lbl := L("Copy", "body", 600, 9, DIM, false, 0.14, true)
	copy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chiprow.add_child(copy_lbl)
	chip.add_child(chiprow)
	col.add_child(chip)
	var rank_lbl := L("NOT RACED YET", "body", 700, 11, DIM, false, 0.08, true)
	col.add_child(rank_lbl)
	var top_box := vbox(4)
	col.add_child(top_box)
	var race := tap(accent, Color(0, 0, 0, 0), 12.0)
	race.custom_minimum_size = Vector2(0, 44)
	var rl := L("RACE THIS SEED", "display", 800, 13, on_accent, true, 0.08, true)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	race.add_child(center(rl))
	race.set_meta("lbl", rl)
	col.add_child(race)
	parent.add_child(card)
	var entry := {"card": card, "cd": cd, "seed_lbl": seed_lbl, "rank_lbl": rank_lbl, "top_box": top_box, "race": race, "seed": "", "ends_at": 0.0}
	event_cards[kind] = entry
	chip.pressed.connect(func():
		if entry.seed != "":
			DisplayServer.clipboard_set(entry.seed)
			toast("Seed copied"))
	race.pressed.connect(func():
		if entry.seed != "":
			game.load_event_seed(entry.seed))


func render_events(data: Dictionary) -> void:
	if data.get("error", false):
		if events_note:
			events_note.text = "Challenges are unavailable right now."
			events_note.visible = true
		return
	if events_note:
		events_note.visible = false
	_events_now = float(data.get("now", 0))
	_events_t0 = Time.get_ticks_msec()
	for kind in ["daily", "weekly"]:
		if not event_cards.has(kind):
			continue
		var c: Dictionary = event_cards[kind]
		var ev = data.get(kind, {})
		if not (ev is Dictionary):
			ev = {}
		c.seed = str(ev.get("seed", ""))
		c.ends_at = float(ev.get("ends_at", 0))
		c.seed_lbl.text = c.seed if c.seed != "" else "—"
		var me = ev.get("me")
		var me_rank := int(me.get("rank", 0)) if me is Dictionary else 0
		if me_rank > 0:
			c.rank_lbl.text = "YOUR RANK #%d · %s" % [me_rank, U.fmt(float(me.get("time_ms", 0)) / 1000.0)]
			c.rank_lbl.add_theme_color_override("font_color", accent)
		else:
			c.rank_lbl.text = "NOT RACED YET"
			c.rank_lbl.add_theme_color_override("font_color", DIM)
		(c.race.get_meta("lbl") as Label).add_theme_color_override("font_color", on_accent)
		c.race.style(accent, Color(0, 0, 0, 0), 12.0)
		for ch in c.top_box.get_children():
			ch.queue_free()
		var top = ev.get("top", [])
		if not (top is Array) or top.is_empty():
			c.top_box.add_child(L("No times yet — be the first.", "body", 400, 11, DIM))
		else:
			var shown := 0
			for t in top:
				shown += 1
				if shown > 5:
					break
				var rk := int(t.get("rank", shown))
				c.top_box.add_child(_event_row(rk, str(t.get("name", "racer")), float(t.get("time_ms", 0)) / 1000.0, rk == me_rank))
	relayout()


func _event_row(rank: int, name: String, time_s: float, mine: bool) -> Control:
	var row := hbox(8)
	var col := accent if mine else DIM
	var r := L("#%d" % rank, "mono", 700, 12, col)
	r.custom_minimum_size = Vector2(32, 0)
	r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(r)
	var nm := L(name, "body", 600, 12, FG if not mine else accent)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(nm)
	var tm := L(U.fmt(time_s), "mono", 700, 12, accent if mine else FG)
	tm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(tm)
	return row


func _fmt_countdown(secs: float) -> String:
	if secs <= 0.0:
		return "ENDED"
	var s := int(secs)
	var d := s / 86400
	var h := (s % 86400) / 3600
	var m := (s % 3600) / 60
	if d > 0:
		return "ENDS IN %dd %dh" % [d, h]
	if h > 0:
		return "ENDS IN %dh %dm" % [h, m]
	if m > 0:
		return "ENDS IN %dm" % m
	return "ENDS IN %ds" % (s % 60)


func _build_garage_pane(parent: Control) -> void:
	var p := _pane(parent, "garage")
	var preview_note := glass(PANEL2, LINE, 12.0)
	preview_note.pad(12, 9, 12, 9)
	var preview_row := hbox(8)
	var preview_dot := dot(accent, 8)
	preview_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview_row.add_child(preview_dot)
	var preview_text := vbox(2)
	preview_text.add_child(L("Live car preview", "body", 700, 12, FG, false, 0.08, true))
	var preview_caption := L("Paint and booster colors update instantly.", "body", 400, 11, DIM)
	preview_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_caption.custom_minimum_size = Vector2(1, 0)
	preview_text.add_child(preview_caption)
	preview_row.add_child(preview_text)
	preview_note.add_child(preview_row)
	p.add_child(preview_note)
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
	fav_list = _track_grid()
	p.add_child(fav_list)
	fav_empty = L("No saved tracks yet. Save a track from Drive to keep it here.", "body", 400, 13, DIM)
	fav_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fav_empty.custom_minimum_size = Vector2(0, 36)
	p.add_child(fav_empty)
	p.add_child(eyebrow("Last played"))
	recent_track_list = _track_grid()
	p.add_child(recent_track_list)
	recent_track_empty = L("Tracks you race or watch will appear here.", "body", 400, 13, DIM)
	recent_track_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recent_track_empty.custom_minimum_size = Vector2(0, 36)
	p.add_child(recent_track_empty)


func _track_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.mouse_filter = Control.MOUSE_FILTER_PASS
	return g


## One track tile (minimap + name + seed) for the saved / recent grids; tapping opens the action dialog.
func _track_tile(seed_s: String, env_s: String, title: String, show_remove: bool) -> Dictionary:
	if not Envs.DATA.has(env_s):
		var parsed = game.parse_seed(seed_s)
		if parsed != null:
			env_s = str(parsed.env)
	var acc := U.css(Envs.DATA[env_s].accent) if Envs.DATA.has(env_s) else accent
	var cur: bool = game.track != null and seed_s == game.track.seed and env_s == game.track.env_key
	var cell := tap(PANEL2, accent if cur else LINE, 12.0)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.pad(8, 8, 8, 8)
	cell.tooltip_text = "Open " + title
	var col := vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pbox := glass(Color(0, 0, 0, 0.26), LINE, 9.0)
	pbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbox.pad(3, 3, 3, 3)
	var preview := MapView.new()
	preview.preview = true
	preview.custom_minimum_size = Vector2(116, 116)
	pbox.add_child(preview)
	col.add_child(pbox)
	var name_lbl := L(title, "display", 800, 13, FG, true, 0.0, true)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.custom_minimum_size = Vector2(1, 0)
	col.add_child(name_lbl)
	var meta := hbox(5)
	var bt = _best_time(seed_s)
	if bt != null:
		var seed_lbl := L("BEST " + U.fmt(bt), "mono", 500, 10, accent)
		seed_lbl.clip_text = true
		seed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meta.add_child(seed_lbl)
	else:
		var seed_lbl := L(seed_s, "mono", 500, 10, DIM)
		seed_lbl.clip_text = true
		seed_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		seed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meta.add_child(seed_lbl)
	if _has_replay(seed_s):
		var r := Icon.new("respawn", 13)
		r.color = accent
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.tooltip_text = "Replay available"
		meta.add_child(r)
	col.add_child(meta)
	cell.add_child(col)
	var env_final := env_s
	cell.pressed.connect(func(): show_track_action(seed_s, env_final, title, show_remove))
	return {"cell": cell, "view": {"map": preview, "seed": seed_s, "env": env_final, "accent": acc}}


func _best_time(seed_s: String):
	var b = Store.get_value("best5." + seed_s, null)
	return b.t if (b is Dictionary and b.has("t")) else null


func _has_replay(seed_s: String) -> bool:
	var b = Store.get_value("best5." + seed_s, null)
	if not (b is Dictionary):
		return false
	var inputs = b.get("inputs", [])
	var ghost = b.get("ghost", [])
	return (inputs is Array and not inputs.is_empty()) or (ghost is Array and ghost.size() >= 6)


func _build_track_action_modal() -> void:
	track_action_modal = ColorRect.new()
	(track_action_modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.72)
	track_action_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_action_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	track_action_modal.visible = false
	add_child(track_action_modal)
	var card := glass(PANEL, LINE, 20.0, 3.0)
	card.pad(22, 20, 22, 20)
	card.clip_contents = true
	track_action_modal.add_child(card)
	track_action_box = vbox(12)
	track_action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(track_action_box)
	var head := hbox(8)
	var htext := vbox(2)
	htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(eyebrow("Track"))
	track_action_title = L("Track", "display", 800, 24, FG, true, 0.0, true)
	track_action_title.clip_text = true
	track_action_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	track_action_title.custom_minimum_size = Vector2(1, 0)
	htext.add_child(track_action_title)
	head.add_child(htext)
	var cb := icon_btn("x")
	cb[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb[0].pressed.connect(func(): hide_track_action())
	head.add_child(cb[0])
	track_action_modal.set_meta("close", cb[0])
	track_action_box.add_child(head)
	var prow := hbox(12)
	var pbox := glass(Color(0, 0, 0, 0.26), LINE, 10.0)
	pbox.custom_minimum_size = Vector2(120, 120)
	pbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pbox.pad(4, 4, 4, 4)
	track_action_preview = MapView.new()
	track_action_preview.preview = true
	track_action_preview.custom_minimum_size = Vector2(112, 112)
	pbox.add_child(track_action_preview)
	prow.add_child(pbox)
	var pcol := vbox(6)
	pcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pcol.alignment = BoxContainer.ALIGNMENT_CENTER
	track_action_sub = L("", "body", 500, 12, DIM)
	track_action_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	track_action_sub.custom_minimum_size = Vector2(1, 0)
	pcol.add_child(track_action_sub)
	prow.add_child(pcol)
	track_action_box.add_child(prow)
	var race := _cbtn("Race this track", true, "A")
	track_action_race = race[0]
	race[0].pressed.connect(func(): _track_action_do("race"))
	track_action_box.add_child(race[0])
	var watch := _cbtn("Watch replay", false)
	track_action_watch = watch[0]
	watch[0].pressed.connect(func(): _track_action_do("watch"))
	track_action_box.add_child(watch[0])
	var remove := _cbtn("Remove from saved", false)
	track_action_remove = remove[0]
	remove[0].pressed.connect(func(): _track_action_do("remove"))
	track_action_box.add_child(remove[0])
	var close := _cbtn("Cancel", false, "Esc")
	close[0].pressed.connect(func(): hide_track_action())
	track_action_box.add_child(close[0])


func show_track_action(seed_s: String, env_s: String, title: String, is_fav: bool) -> void:
	if track_action_modal == null:
		return
	if not Envs.DATA.has(env_s):
		var parsed = game.parse_seed(seed_s)
		if parsed != null:
			env_s = str(parsed.env)
	_track_action_seed = seed_s
	_track_action_env = env_s
	track_action_title.text = title.to_upper()
	var acc := U.css(Envs.DATA[env_s].accent) if Envs.DATA.has(env_s) else accent
	var env_name := str(Envs.DATA[env_s].name) if Envs.DATA.has(env_s) else env_s
	var bt = _best_time(seed_s)
	var sub := env_name + "  \u00b7  " + seed_s
	if bt != null:
		sub += "\nYour best " + U.fmt(bt)
	track_action_sub.text = sub
	track_action_watch.visible = _has_replay(seed_s)
	track_action_remove.visible = is_fav
	track_action_preview.t = null
	track_action_preview.set_track(_cached_fav_track(seed_s, env_s), acc)
	track_action_modal.visible = true
	_set_stick_direction(Vector2i.ZERO)
	relayout()
	_rise(track_action_modal.get_child(0))
	track_action_race.grab_focus()


func hide_track_action() -> void:
	if track_action_modal == null or not track_action_modal.visible:
		return
	track_action_modal.visible = false
	_set_stick_direction(Vector2i.ZERO)
	var focus := _focus_owner()
	if focus and track_action_modal.is_ancestor_of(focus):
		focus.release_focus()
	if menu_on and game.menu_tab == "tracks":
		call_deferred("_focus_tracks_entry")


func _track_action_do(kind: String) -> void:
	var s := _track_action_seed
	var e := _track_action_env
	hide_track_action()
	if kind == "race":
		game.race_track(s, e)
	elif kind == "watch":
		game.replay_track(s, e)
	elif kind == "remove":
		game.remove_fav(s)


func _layout_track_action(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if track_action_modal == null:
		return
	var card: Glass = track_action_modal.get_child(0)
	var cw := minf(420.0, W - sl - sr - 16.0)
	track_action_box.custom_minimum_size.x = cw - 44.0
	track_action_sub.custom_minimum_size.x = maxf(80.0, cw - 44.0 - 132.0)
	card.size = Vector2(cw, 0)
	card.size = Vector2(cw, minf(card.get_combined_minimum_size().y, H - st - sb - 16.0))
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - card.size.y) / 2.0))
	card._sync()


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
	options_body = vbox(12)
	options_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(options_body)
	options_body.add_child(eyebrow("Visuals"))
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
	options_body.add_child(o1)
	for spec in [["side", "Steering hand", [["left", "Left thumb"], ["right", "Right thumb"]]], ["gfx", "Graphics", [["high", "Toon shading"], ["low", "Battery saver"]]],
			["stats", "Frame rate readout", [["", "Hidden"], ["1", "Shown"]]]]:
		var o := vbox(6)
		o.add_child(eyebrow(spec[1]))
		var k: String = spec[0]
		var s := seg(spec[2], func(v): game.set_opt(k, v))
		opt_segs[k] = s[1]
		o.add_child(s[0])
		options_body.add_child(o)
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
	options_body.add_child(o2)
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
	options_body.add_child(oa)
	net_status_lbl = L("", "body", 400, 12, DIM)
	net_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	net_status_lbl.custom_minimum_size = Vector2(120, 0)
	options_body.add_child(net_status_lbl)


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
	respawn_btn = rb[0]
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
	lap_info = hbox(10)
	lap_info.alignment = BoxContainer.ALIGNMENT_CENTER
	var li := Color(1, 1, 1, 0.85)
	var lap_a := hbox(0)
	lap_a.add_child(_shadowed(L("Lap ", "body", 600, 11, li, false, 0.16, true)))
	lap_n = _shadowed(L("1", "body", 600, 11, FG, false, 0.16))
	lap_a.add_child(lap_n)
	lap_a.add_child(_shadowed(L("/" + str(U.LAPS), "body", 600, 11, li, false, 0.16)))
	lap_info.add_child(lap_a)
	var cp_a := hbox(0)
	cp_a.add_child(_shadowed(L("CP ", "body", 600, 11, li, false, 0.16, true)))
	cp_n = _shadowed(L("0", "body", 600, 11, FG, false, 0.16))
	cp_a.add_child(cp_n)
	cp_a.add_child(_shadowed(L("/", "body", 600, 11, li, false, 0.16)))
	cp_t = _shadowed(L("4", "body", 600, 11, li, false, 0.16))
	cp_a.add_child(cp_t)
	lap_info.add_child(cp_a)
	clock.add_child(lap_info)
	replay_lbl = L("", "mono", 700, 10, FG, false, 0.08, true)
	replay_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	replay_lbl.visible = false
	clock.add_child(replay_lbl)
	replay_progress = ProgressBar.new()
	replay_progress.custom_minimum_size = Vector2(160, 8)
	replay_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	replay_progress.show_percentage = false
	replay_progress.visible = false
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color(1, 1, 1, 0.18)
	progress_bg.set_corner_radius_all(4)
	replay_progress.add_theme_stylebox_override("background", progress_bg)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = accent
	progress_fill.set_corner_radius_all(4)
	replay_progress.add_theme_stylebox_override("fill", progress_fill)
	clock.add_child(replay_progress)
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
	var ropt := _cbtn("Options", false)
	ropt[0].pressed.connect(func(): show_options(true))
	row.add_child(r2[0])
	row.add_child(ropt[0])
	pg.add_child(row)
	var r3 := _cbtn("Menu", false)
	r3[0].pressed.connect(func(): game.to_menu())
	pg.add_child(r3[0])
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
	_build_debug_modal()
	_build_leaderboard_modal()
	_build_track_action_modal()
	_build_options_modal()


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
	_build_seed_modal()


func _build_seed_modal() -> void:
	seed_modal = ColorRect.new()
	seed_modal.color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.72)
	seed_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	seed_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	seed_modal.visible = false
	add_child(seed_modal)
	var card := glass(PANEL, LINE, 20.0, 3.0)
	card.pad(22, 20, 22, 20)
	seed_modal.add_child(card)
	seed_dialog_box = vbox(12)
	card.add_child(seed_dialog_box)
	seed_dialog_box.add_child(eyebrow("Find a course"))
	seed_dialog_box.add_child(L("Race a track code", "display", 800, 28, FG, true, 0.0, true))
	seed_dialog_caption = L("Enter a seed to load the exact same generated track.", "body", 400, 12, DIM)
	seed_dialog_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	seed_dialog_caption.custom_minimum_size = Vector2(120, 0)
	seed_dialog_box.add_child(seed_dialog_caption)
	seed_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_dialog_box.add_child(seed_in)
	var actions := hbox(8)
	var load := _cbtn("Load track", true)
	load[0].pressed.connect(_submit_seed)
	var cancel := _cbtn("Cancel", false)
	cancel[0].pressed.connect(func(): show_seed_dialog(false))
	actions.add_child(load[0])
	actions.add_child(cancel[0])
	seed_dialog_box.add_child(actions)


func _submit_seed() -> void:
	if game.parse_seed(seed_in.text) == null:
		game.submit_seed(seed_in.text)
		seed_in.grab_focus()
		return
	show_seed_dialog(false)
	game.submit_seed(seed_in.text)


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
	return _active_dialog() != null


func _active_dialog() -> Control:
	if options_modal != null and options_modal.visible:
		return options_modal
	if track_action_modal != null and track_action_modal.visible:
		return track_action_modal
	if lb_modal != null and lb_modal.visible:
		return lb_modal
	if debug_modal != null and debug_modal.visible:
		return debug_modal
	if acct_modal != null and acct_modal.visible:
		return acct_modal
	if seed_modal != null and seed_modal.visible:
		return seed_modal
	return null


func _close_dialog() -> void:
	if options_modal != null and options_modal.visible:
		show_options(false)
	elif track_action_modal != null and track_action_modal.visible:
		hide_track_action()
	elif lb_modal != null and lb_modal.visible:
		show_leaderboard(false)
	elif debug_modal != null and debug_modal.visible:
		show_debug(false)
	elif acct_modal != null and acct_modal.visible:
		show_account(false)
	elif seed_modal != null and seed_modal.visible:
		show_seed_dialog(false)


func show_seed_dialog(on: bool) -> void:
	if on == seed_modal.visible:
		return
	seed_modal.visible = on
	_set_stick_direction(Vector2i.ZERO)
	if on:
		relayout()
		_rise(seed_modal.get_child(0))
		seed_in.grab_focus()
	else:
		var focus := _focus_owner()
		if focus and seed_modal.is_ancestor_of(focus):
			focus.release_focus()
		if menu_on:
			seed_dialog_button.grab_focus()


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
			btn_card.grab_focus()


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
	if pc_avatar:
		pc_avatar.color = accent if reg else FG
		pc_avatar.queue_redraw()
	sync_player_card()
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


func _layout_seed_dialog(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if seed_modal == null:
		return
	var card: Glass = seed_modal.get_child(0)
	var cw := minf(460.0, W - sl - sr - 16.0)
	var avail := H - st - sb - 16.0
	seed_dialog_caption.custom_minimum_size.x = cw - 44.0
	seed_dialog_box.custom_minimum_size.x = cw - 44.0
	card.size = Vector2(cw, 0)
	card.size = Vector2(cw, minf(card.get_combined_minimum_size().y, avail))
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - card.size.y) / 2.0))
	card._sync()


func _build_debug_modal() -> void:
	debug_modal = ColorRect.new()
	(debug_modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.82)
	debug_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	debug_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_modal.visible = false
	add_child(debug_modal)
	var card := glass(PANEL, LINE, 20.0, 3.0)
	card.pad(22, 20, 22, 20)
	card.clip_contents = true
	debug_modal.add_child(card)
	debug_box = vbox(12)
	debug_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(debug_box)
	var head := hbox(8)
	var htext := vbox(2)
	htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(eyebrow("Debug"))
	htext.add_child(L("Track previews", "display", 800, 24, FG, true, 0.0, true))
	head.add_child(htext)
	var cb := icon_btn("x")
	debug_close = cb[0]
	debug_close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	debug_close.pressed.connect(func(): show_debug(false))
	head.add_child(debug_close)
	debug_box.add_child(head)
	var cap := L("Compare the generated minimap for different seeds. Tap a tile to load that track.", "body", 400, 12, DIM)
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.custom_minimum_size = Vector2(1, 0)
	debug_box.add_child(cap)
	var tools := hbox(8)
	debug_seed_in = LineEdit.new()
	debug_seed_in.placeholder_text = "Add a seed, e.g. A7K2M9Q4B6N8P3RX"
	debug_seed_in.max_length = 24
	debug_seed_in.custom_minimum_size = Vector2(0, 42)
	debug_seed_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_seed_in.context_menu_enabled = true
	debug_seed_in.add_theme_stylebox_override("normal", (seed_in.get_theme_stylebox("normal") as StyleBox).duplicate())
	debug_seed_in.add_theme_stylebox_override("focus", (seed_in.get_theme_stylebox("focus") as StyleBox).duplicate())
	debug_seed_in.add_theme_font_override("font", UiFonts.get_font("mono", 500))
	debug_seed_in.add_theme_font_size_override("font_size", 14)
	debug_seed_in.add_theme_color_override("font_color", FG)
	debug_seed_in.add_theme_color_override("font_placeholder_color", DIM)
	debug_seed_in.add_theme_color_override("caret_color", FG)
	debug_seed_in.text_changed.connect(func(t):
		var up: String = t.to_upper()
		if up != t:
			var c := debug_seed_in.caret_column
			debug_seed_in.text = up
			debug_seed_in.caret_column = c)
	debug_seed_in.text_submitted.connect(func(_t): _debug_add_seed())
	tools.add_child(debug_seed_in)
	var add := _cbtn("Add", false, "ENTER")
	add[0].size_flags_horizontal = Control.SIZE_SHRINK_END
	add[0].custom_minimum_size = Vector2(92, 42)
	add[0].pressed.connect(func(): _debug_add_seed())
	tools.add_child(add[0])
	var rr := _cbtn("Reroll", true)
	debug_reroll = rr[0]
	debug_reroll.size_flags_horizontal = Control.SIZE_SHRINK_END
	debug_reroll.custom_minimum_size = Vector2(108, 42)
	debug_reroll.pressed.connect(func(): _debug_reroll())
	tools.add_child(debug_reroll)
	debug_box.add_child(tools)
	debug_scroll = ScrollContainer.new()
	debug_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	debug_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	debug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	debug_box.add_child(debug_scroll)
	debug_grid = GridContainer.new()
	debug_grid.columns = 3
	debug_grid.add_theme_constant_override("h_separation", 10)
	debug_grid.add_theme_constant_override("v_separation", 10)
	debug_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_scroll.add_child(debug_grid)


func _debug_cell(seed_s: String) -> Control:
	var parsed = game.parse_seed(seed_s)
	var env_s := str(parsed.env) if parsed != null else "CANYON"
	if not Envs.DATA.has(env_s):
		env_s = "CANYON"
	var acc := U.css(Envs.DATA[env_s].accent)
	var cell := tap(PANEL2, LINE, 12.0)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.pad(8, 8, 8, 8)
	cell.tooltip_text = "Load " + seed_s
	var col := vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pbox := glass(Color(0, 0, 0, 0.26), LINE, 9.0)
	pbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbox.pad(3, 3, 3, 3)
	var preview := MapView.new()
	preview.preview = true
	preview.custom_minimum_size = Vector2(120, 120)
	pbox.add_child(preview)
	col.add_child(pbox)
	var name_lbl := L(str(Envs.DATA[env_s].name), "display", 800, 13, FG, true, 0.0, true)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.custom_minimum_size = Vector2(1, 0)
	col.add_child(name_lbl)
	var seed_lbl := L(seed_s, "mono", 500, 10, DIM)
	seed_lbl.clip_text = true
	seed_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	seed_lbl.custom_minimum_size = Vector2(1, 0)
	col.add_child(seed_lbl)
	cell.add_child(col)
	cell.pressed.connect(func():
		show_debug(false)
		game.load_fav(seed_s, env_s))
	debug_preview_views.append({"map": preview, "seed": seed_s, "env": env_s, "accent": acc, "name": name_lbl})
	return cell


func _debug_fill_random() -> void:
	while debug_seeds.size() < DEBUG_COUNT:
		var code := U.rand_seed_code()
		if not debug_seeds.has(code):
			debug_seeds.append(code)


func _debug_reset_seeds() -> void:
	debug_seeds.clear()
	if game.track != null and str(game.track.seed) != "":
		debug_seeds.append(str(game.track.seed))
	_debug_fill_random()


func _debug_reroll() -> void:
	debug_seeds.clear()
	_debug_fill_random()
	_rebuild_debug_grid()


func _debug_add_seed() -> void:
	var parsed = game.parse_seed(debug_seed_in.text)
	if parsed == null:
		toast("Enter a seed first")
		return
	var sc := str(parsed.seed)
	debug_seed_in.text = ""
	if debug_seeds.has(sc):
		toast("Already shown")
		debug_seed_in.grab_focus()
		return
	debug_seeds.push_front(sc)
	_rebuild_debug_grid()
	debug_seed_in.grab_focus()


func _rebuild_debug_grid() -> void:
	if debug_grid == null:
		return
	_debug_revision += 1
	debug_preview_views.clear()
	for child in debug_grid.get_children():
		debug_grid.remove_child(child)
		child.queue_free()
	for seed_s in debug_seeds:
		debug_grid.add_child(_debug_cell(seed_s))
	if debug_modal.visible:
		call_deferred("_populate_debug")
	relayout()


func _populate_debug() -> void:
	if _debug_task_running or debug_modal == null or not debug_modal.visible:
		return
	_debug_task_running = true
	var revision := _debug_revision
	for entry in debug_preview_views:
		if revision != _debug_revision or not debug_modal.visible:
			break
		var preview := entry.map as MapView
		if not is_instance_valid(preview) or preview.t != null:
			continue
		var track := _cached_fav_track(str(entry.seed), str(entry.env))
		preview.set_track(track, entry.accent)
		var nm := entry.get("name") as Label
		if is_instance_valid(nm) and track != null and str(track.name) != "":
			nm.text = str(track.name).to_upper()
		await get_tree().process_frame
	_debug_task_running = false


func show_debug(on: bool) -> void:
	if debug_modal == null or on == debug_modal.visible:
		return
	debug_modal.visible = on
	_set_stick_direction(Vector2i.ZERO)
	if on:
		if debug_seeds.is_empty():
			_debug_reset_seeds()
		_rebuild_debug_grid()
		_rise(debug_modal.get_child(0))
		debug_reroll.grab_focus()
	else:
		var focus := _focus_owner()
		if focus and debug_modal.is_ancestor_of(focus):
			focus.release_focus()
		if menu_on:
			btn_debug.grab_focus()


func _layout_debug(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if debug_modal == null:
		return
	var card: Glass = debug_modal.get_child(0)
	var cw := minf(980.0, W - sl - sr - 16.0)
	var ch := minf(760.0, H - st - sb - 16.0)
	card.size = Vector2(cw, ch)
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - ch) / 2.0))
	card._sync()
	var grid_w := cw - 44.0 - 12.0
	var cols := clampi(int(grid_w / 150.0), 1, 6)
	debug_grid.columns = cols
	var cellw := (grid_w - 10.0 * (cols - 1)) / float(cols)
	var pw := maxf(60.0, cellw - 16.0 - 6.0)
	for entry in debug_preview_views:
		var mv := entry.map as MapView
		if is_instance_valid(mv):
			mv.custom_minimum_size = Vector2(pw, pw)


func _build_options_modal() -> void:
	options_modal = ColorRect.new()
	(options_modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.82)
	options_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	options_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	options_modal.visible = false
	add_child(options_modal)
	var card := glass(PANEL, LINE, 20.0, 3.0)
	card.pad(22, 16, 22, 16)
	card.clip_contents = true
	options_modal.add_child(card)
	var box := vbox(12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(box)
	var head := hbox(8)
	var htext := vbox(2)
	htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(eyebrow("Settings"))
	htext.add_child(L("Options", "display", 800, 24, FG, true, 0.0, true))
	head.add_child(htext)
	var cb := icon_btn("x")
	cb[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb[0].pressed.connect(func(): show_options(false))
	head.add_child(cb[0])
	options_modal.set_meta("close", cb[0])
	box.add_child(head)
	options_scroll = ScrollContainer.new()
	options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	options_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	options_scroll.follow_focus = true
	options_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(options_scroll)


func show_options(on: bool) -> void:
	if options_modal == null or on == options_modal.visible:
		return
	if on:
		if options_body.get_parent() != options_scroll:
			options_body.get_parent().remove_child(options_body)
			options_scroll.add_child(options_body)
		sync_opts()
		refresh_binds()
		sync_account()
		options_modal.visible = true
		_set_stick_direction(Vector2i.ZERO)
		relayout()
		_rise(options_modal.get_child(0))
		sens_slider.grab_focus()
	else:
		options_modal.visible = false
		_set_stick_direction(Vector2i.ZERO)
		var focus := _focus_owner()
		if focus and options_modal.is_ancestor_of(focus):
			focus.release_focus()
		if options_body.get_parent() == options_scroll:
			options_scroll.remove_child(options_body)
			panes["options"].add_child(options_body)
		if pause_modal.visible:
			pause_resume.grab_focus()
		elif menu_on:
			focus_default()


func _layout_options(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if options_modal == null or not options_modal.visible:
		return
	var card: Glass = options_modal.get_child(0)
	var cw := minf(460.0, W - sl - sr - 16.0)
	var avail := H - st - sb - 16.0
	options_body.custom_minimum_size.x = cw - 44.0
	# size the keybind buttons for the modal width (overrides the menu-panel sizing)
	var cwin := cw - 44.0 - 12.0
	var blabel := 46.0 if cwin < 300.0 else (52.0 if cwin < 360.0 else 60.0)
	var bbtn := clampf((cwin - blabel - 18.0) / 2.0, 72.0, 120.0)
	for row in bind_rows.get_children():
		row.add_theme_constant_override("separation", 6)
		row.get_child(0).custom_minimum_size.x = blabel
		for slot in 2:
			(row.get_child(slot + 1) as Control).custom_minimum_size.x = bbtn
	var content := options_body.get_combined_minimum_size().y
	options_scroll.custom_minimum_size = Vector2(0, minf(content, maxf(160.0, avail - 72.0)))
	card.size = Vector2(cw, 0)
	card.size = Vector2(cw, minf(card.get_combined_minimum_size().y, avail))
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - card.size.y) / 2.0))
	card._sync()

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
	var rail := W >= 720.0                 # left menu + right panel + bottom bar
	var desktop := W >= 860.0
	var garage: bool = game.menu_tab == "garage"
	var bar_h := 64.0 if rail else 54.0
	# brand (top-left; the account button moved into the bottom player card)
	var wm_size := 44.0 if desktop else (30.0 if rail else 28.0)
	restyle(wm_a, wm_size)
	restyle(wm_b, wm_size)
	brand.alignment = BoxContainer.ALIGNMENT_BEGIN
	tag.visible = W >= 360.0
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	(wm_a.get_parent() as HBoxContainer).alignment = BoxContainer.ALIGNMENT_BEGIN
	var top_pad := st + (22.0 if rail else 12.0)
	var bsz := brand.get_combined_minimum_size()
	brand.size = bsz
	brand.position = Vector2(sl, top_pad)
	btn_sound.size = Vector2(42, 42)
	btn_sound.position = Vector2(W - sr - 42.0, top_pad + (bsz.y - 42.0) / 2.0)
	btn_debug.size = Vector2(42, 42)
	btn_debug.position = Vector2(W - sr - 42.0 - 42.0 - 8.0, btn_sound.position.y)
	# bottom toolbar
	var bar_y := H - sb - bar_h - 10.0
	bottombar.position = Vector2(sl, bar_y)
	bottombar.size = Vector2(W - sl - sr, bar_h)
	bottombar.radius = Vector4(16, 16, 16, 16)
	bottombar.pad(0, 0, 0, 0)
	_layout_bottombar(bottombar.size.x, bottombar.size.y)
	# hero Race button (compact on short landscape screens so it never crowds the action row)
	trackhead.visible = game.menu_tab == "drive"
	btn_play.visible = game.menu_tab == "drive"
	var race_l := btn_play.get_meta("race") as Label
	(btn_play.get_meta("enter") as Label).visible = not landscape_short
	(btn_play.get_meta("chev") as Label).visible = not landscape_short
	if landscape_short:
		btn_play.custom_minimum_size.y = 52.0
		btn_play.inset = 8.0
		btn_play.pad(12, 8, 12, 9)
		restyle(race_l, 21.0)
	else:
		btn_play.custom_minimum_size.y = 76.0
		btn_play.inset = 12.0
		btn_play.pad(16, 12, 16, 14)
		restyle(race_l, 27.0)
	# track head sizing
	var name_size := 24.0 if landscape_short else clampf(7.4 * vw, 26.0, 40.0)
	var pm := 60.0 if landscape_short else clampf(21.0 * vw, 72.0, 96.0)
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
	section_title.visible = not landscape_short
	restyle(section_title, 18.0 if not desktop else 20.0)
	# section nav + panel
	var nav_top := top_pad + bsz.y + 14.0
	var head_scroll := (not rail) or landscape_short
	if rail:
		var nav_w := 150.0 if desktop else 124.0
		sheet.pad(18, 16, 18, 16)
		sheet.radius = Vector4(18, 18, 18, 18)
		var panel_x := sl + nav_w + 16.0
		var panel_w := minf(clampf(0.42 * W, 400.0, 540.0), W - sr - panel_x)
		sheet.position = Vector2(panel_x, nav_top)
		sheet.size = Vector2(panel_w, maxf(160.0, bar_y - 12.0 - nav_top))
		_layout_nav(true, Vector2(sl, nav_top), nav_w, bar_y - 24.0 - nav_top)
	else:
		var nav_h := 44.0
		sheet.pad(16, 14, 16, 14)
		sheet.radius = Vector4(18, 18, 18, 18)
		var panel_w := W - sl - sr
		var inner_w := panel_w - 32.0
		var panel_bottom := bar_y - 10.0
		var cap := minf(H * (0.52 if garage else 0.62), panel_bottom - nav_top - nav_h - 12.0)
		var content := _sheet_content_height(inner_w)
		var panel_h := clampf(content + 28.0, 140.0, maxf(140.0, cap))
		var panel_top := panel_bottom - panel_h
		sheet.position = Vector2(sl, panel_top)
		sheet.size = Vector2(panel_w, panel_h)
		_layout_nav(false, Vector2(sl, panel_top - nav_h - 10.0), panel_w, nav_h)
	# track head height within the panel
	var head_iw := sheet.size.x - float(sheet.get_theme_constant("margin_left")) - float(sheet.get_theme_constant("margin_right"))
	_place_head(head_scroll)
	if head_scroll:
		trackhead.custom_minimum_size = Vector2(0, _trackhead_height(head_iw - 6.0))
	else:
		trackhead.custom_minimum_size = Vector2.ZERO
	# keybind button widths from the panel inner width
	var content_w := head_iw - 12.0
	# responsive grids inside the panel (events, saved tracks, recents)
	if events_grid:
		events_grid.columns = 2 if content_w >= 430.0 else 1
	var tile_cols := clampi(int(content_w / 150.0), 1, 4)
	if fav_list:
		fav_list.columns = tile_cols
	if recent_track_list:
		recent_track_list.columns = tile_cols
	var bind_label_w := 46.0 if W < 360.0 else (52.0 if W < 400.0 else 60.0)
	var bind_gap := 4 if W < 360.0 else 6
	var bind_button_w := clampf((content_w - bind_label_w - float(bind_gap * 3)) / 2.0, 72.0, 112.0)
	for row in bind_rows.get_children():
		row.add_theme_constant_override("separation", bind_gap)
		row.get_child(0).custom_minimum_size.x = bind_label_w
		for slot in 2:
			(row.get_child(slot + 1) as Control).custom_minimum_size.x = bind_button_w
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
	hint.visible = not touch and not replay_mode
	pad_boost.visible = touch and not replay_mode
	if not touch and not replay_mode:
		var ms := clampf(0.14 * minf(W, H), 84.0, 120.0)
		meter.size = Vector2(ms, ms)
		meter.position = Vector2(W - sr - ms - 16.0, H - sb - ms - 16.0)
	restyle(count_lbl, clampf(30.0 * vw, 110.0, 190.0))
	count_lbl.size = Vector2(W, H)
	count_lbl.position = Vector2.ZERO
	count_lbl.pivot_offset = Vector2(W, H) / 2.0
	_layout_pads(W, H, sl, sr, sb)
	# modals
	_layout_account(W, H, sl, sr, st, sb)
	_layout_seed_dialog(W, H, sl, sr, st, sb)
	_layout_debug(W, H, sl, sr, st, sb)
	_layout_leaderboard(W, H, sl, sr, st, sb)
	_layout_track_action(W, H, sl, sr, st, sb)
	_layout_options(W, H, sl, sr, st, sb)
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
	_place_stats()


## Stack the section panel's blocks by hand (flex column: title, track head, scrolling body, Race pinned at the bottom)
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
	var gap := 12.0
	var body_h := maxf(0.0, ih - fixed - gap * (blocks.size() - 1))
	for c in blocks:
		var h: float = body_h if c == tab_scroll else heights[c]
		c.position = Vector2(0, y)
		c.size = Vector2(iw, h)
		y += h + gap


## Section menu: vertical rail (desktop/landscape) or a horizontal chip row (phones).
func _layout_nav(vertical: bool, pos: Vector2, w: float, h: float) -> void:
	nav_menu.position = pos
	var n := tabs.size()
	if vertical:
		var gap := 8.0
		# shrink the rail items when the screen is too short to stack them at full height
		var bh := 46.0 if h <= 0.0 else clampf((h - gap * (n - 1)) / n, 32.0, 46.0)
		nav_menu.size = Vector2(w, n * bh + (n - 1) * gap)
		for i in n:
			var b: Tap = tabs[i]
			b.position = Vector2(0, i * (bh + gap))
			b.size = Vector2(w, bh)
			restyle(b.get_meta("lbl"), 13.0)
	else:
		nav_menu.size = Vector2(w, h)
		var gap := 8.0 if w >= 360.0 else 5.0
		var iw := maxf(0.0, (w - gap * (n - 1)) / n)
		for i in n:
			var b: Tap = tabs[i]
			b.position = Vector2(i * (iw + gap), 0)
			b.size = Vector2(iw, h)
			restyle(b.get_meta("lbl"), 11.0 if w < 400.0 else 12.0)


## Bottom toolbar contents: player card on the left, online count on the right, now-racing + best between.
func _layout_bottombar(w: float, h: float) -> void:
	var pad := 10.0
	var cy := h / 2.0
	var card_w := clampf(w * 0.5, 160.0, 300.0)
	btn_card.size = Vector2(card_w, h - 12.0)
	btn_card.position = Vector2(pad, 6.0)
	pc_online.size = pc_online.get_combined_minimum_size()
	pc_online.position = Vector2(w - pad - pc_online.size.x, cy - pc_online.size.y / 2.0)


## The track head's height with the name wrapped at the width it will get (labels measure lazily)
func _place_head(in_scroll: bool) -> void:
	var target: Control = panes_box if in_scroll else sheet_box
	if trackhead.get_parent() == target:
		return
	trackhead.get_parent().remove_child(trackhead)
	target.add_child(trackhead)
	# keep the section title first in the panel; the head sits at the top of the scroll pane otherwise
	target.move_child(trackhead, 1 if target == sheet_box else 0)


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


## Kept for the in-game camera offset; the leaderboard no longer has a persistent side panel.
func right_panel_width() -> float:
	return 0.0


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
	if brand_rule:
		brand_rule.fill_top = accent
		brand_rule.fill_bot = accent
		brand_rule.glow_col = Color(accent, 0.6)
		brand_rule._sync()
	_style_play()
	if tabs.size() > 0:
		_sync_tab_styles()
	_style_slider(sens_slider)
	var f: StyleBoxFlat = seed_in.get_theme_stylebox("focus")
	f.border_color = accent
	for m in [pause_modal, finish_modal, acct_modal, seed_modal]:
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


## The hero Race button: glossy accent slab, bright top, deep bottom and a neon glow halo.
func _style_play() -> void:
	if not btn_play:
		return
	# glossy accent slab: bright top, deep bottom, a darker inner lip for depth and a soft neon halo
	btn_play.fill_top = accent.lightened(0.26)
	btn_play.fill_bot = accent.darkened(0.28)
	btn_play.radius = Vector4(18, 18, 18, 18)
	btn_play.glow_col = Color(accent, 0.5)
	btn_play.glow = 22.0
	btn_play.inset = 12.0
	btn_play.inset_col = Color(accent.darkened(0.5), 0.55)
	btn_play.inset_h = 16.0
	btn_play.sheen = 0.32
	btn_play._tinted = false  # re-baseline so a focused button re-tints from the new accent gradient
	btn_play.set_border_state(Color(1, 1, 1, 0.34), 1.5)
	(btn_play.get_meta("race") as Label).add_theme_color_override("font_color", on_accent)
	(btn_play.get_meta("enter") as Label).add_theme_color_override("font_color", Color(on_accent, 0.55))
	(btn_play.get_meta("chev") as Label).add_theme_color_override("font_color", Color(on_accent, 0.7))
	(btn_play.get_meta("play") as Icon).color = on_accent
	(btn_play.get_meta("play") as Icon).queue_redraw()


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
	sync_player_card()
	render_favs()
	render_recent_tracks()
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
	_lb_info = info
	_update_lb_summary(info)
	if lb_box == null:
		return
	for c in lb_box.get_children():
		c.queue_free()
		lb_box.remove_child(c)
	if lb_stats:
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
		if lb_stats:
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
	if lb_modal and lb_modal.visible:
		relayout()


## Compact leaderboard state shown on the track-card button and the dialog hero (your rank, big).
func _update_lb_summary(info) -> void:
	var sum_txt := "Tap to view online times"
	var rank_txt := "—"
	var time_txt := ""
	var sub_txt := "Not raced yet"
	if info == null:
		sum_txt = "Offline for this track"
	elif info is Dictionary and info.get("loading", false):
		sum_txt = "Loading…"
	elif info is Dictionary and info.get("error", false):
		sum_txt = "Leaderboard offline"
	elif info is Dictionary:
		var st: Dictionary = info.get("stats", {})
		var runs := int(st.get("runs", 0))
		var players := int(st.get("players", 0))
		var mine = info.get("me")
		if mine is Dictionary and int(mine.get("rank", 0)) > 0:
			var rk := int(mine.rank)
			rank_txt = "#%d" % rk
			time_txt = U.fmt(float(mine.get("time_ms", 0)) / 1000.0)
			sub_txt = "of %d racers" % maxi(players, rk)
			sum_txt = "You're #%d · %d racers" % [rk, players]
		elif runs > 0:
			sub_txt = "%d racers · not raced yet" % players
			sum_txt = "%d runs · %d racers" % [runs, players]
		else:
			sub_txt = "Be the first to race"
			sum_txt = "No times yet"
	if lb_card_sum:
		lb_card_sum.text = sum_txt.to_upper()
	if lb_hero_rank:
		lb_hero_rank.text = rank_txt
		lb_hero_rank.add_theme_color_override("font_color", accent if rank_txt != "—" else DIM)
		lb_hero_time.text = time_txt
		lb_hero_sub.text = sub_txt


func show_leaderboard(on: bool) -> void:
	if lb_modal == null or on == lb_modal.visible:
		return
	lb_modal.visible = on
	_set_stick_direction(Vector2i.ZERO)
	if on:
		render_leaderboard(_lb_info)
		relayout()
		_rise(lb_modal.get_child(0))
		(lb_modal.get_meta("close") as Control).grab_focus()
	else:
		var focus := _focus_owner()
		if focus and lb_modal.is_ancestor_of(focus):
			focus.release_focus()
		if menu_on:
			lb_card_btn.grab_focus()


func _build_leaderboard_modal() -> void:
	lb_modal = ColorRect.new()
	(lb_modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.72)
	lb_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	lb_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	lb_modal.visible = false
	add_child(lb_modal)
	var card := glass(PANEL, LINE, 20.0, 3.0)
	card.pad(22, 20, 22, 20)
	card.clip_contents = true
	lb_modal.add_child(card)
	lb_dialog_box = vbox(12)
	lb_dialog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb_dialog_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(lb_dialog_box)
	var head := hbox(8)
	var htext := vbox(2)
	htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(eyebrow("Online ranking"))
	htext.add_child(L("Track leaderboard", "display", 800, 24, FG, true, 0.0, true))
	head.add_child(htext)
	var cb := icon_btn("x")
	cb[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb[0].pressed.connect(func(): show_leaderboard(false))
	head.add_child(cb[0])
	lb_modal.set_meta("close", cb[0])
	lb_dialog_box.add_child(head)
	# hero: your position, shown big
	lb_hero = glass(Color(accent, 0.12), Color(accent, 0.4), 14.0)
	lb_hero.pad(16, 12, 16, 12)
	var hrow := hbox(12)
	var hcol := vbox(2)
	hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hcol.alignment = BoxContainer.ALIGNMENT_CENTER
	hcol.add_child(eyebrow("Your position"))
	lb_hero_sub = L("Not raced yet", "body", 500, 12, DIM)
	lb_hero_sub.clip_text = true
	lb_hero_sub.custom_minimum_size = Vector2(1, 0)
	hcol.add_child(lb_hero_sub)
	hrow.add_child(hcol)
	lb_hero_time = L("", "mono", 700, 18, FG)
	lb_hero_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(lb_hero_time)
	lb_hero_rank = L("\u2014", "display", 800, 44, accent, true, 0.0)
	lb_hero_rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(lb_hero_rank)
	lb_hero.add_child(hrow)
	lb_dialog_box.add_child(lb_hero)
	lb_stats = L("", "body", 600, 10, DIM, false, 0.12, true)
	lb_dialog_box.add_child(lb_stats)
	lb_dialog_scroll = ScrollContainer.new()
	lb_dialog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lb_dialog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	lb_dialog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb_dialog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lb_dialog_box.add_child(lb_dialog_scroll)
	lb_box = vbox(2)
	lb_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb_dialog_scroll.add_child(lb_box)


func _layout_leaderboard(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if lb_modal == null:
		return
	var card: Glass = lb_modal.get_child(0)
	var cw := minf(480.0, W - sl - sr - 16.0)
	lb_dialog_box.custom_minimum_size.x = cw - 44.0
	lb_stats.custom_minimum_size.x = cw - 44.0
	var list_h := lb_box.get_combined_minimum_size().y
	var base := lb_dialog_box.get_combined_minimum_size().y
	var ch := clampf(base + list_h + 36.0, 240.0, minf(640.0, H - st - sb - 16.0))
	card.size = Vector2(cw, ch)
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - ch) / 2.0))
	card._sync()


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
	pc_online.text = ("● %d ONLINE" % n) if on else "● OFFLINE"
	pc_online.add_theme_color_override("font_color", Color("#3ddc84") if on else DIM)
	sync_player_card()


## Refresh the bottom toolbar: racer identity, online status, the current track and its best time.
func sync_player_card() -> void:
	if pc_name == null:
		return
	var net: Net = game.net
	var on := net.is_online()
	pc_name.text = net.display_name.to_upper()
	pc_status.text = "● ONLINE" if on else "● OFFLINE"
	pc_status.add_theme_color_override("font_color", Color("#3ddc84") if on else DIM)
	if pc_avatar:
		pc_avatar.color = accent if net.is_registered() else FG
		pc_avatar.queue_redraw()
	_sync_card_best()


## Personal best + medal shown inside the track card (replaces the old bottom-bar chip).
func _sync_card_best() -> void:
	if card_best_lbl == null:
		return
	var best = game.best
	var bt = best.t if (best is Dictionary and best.has("t")) else null
	card_best_lbl.text = ("BEST  " + U.fmt(bt)) if bt != null else "NOT RACED YET"
	card_best_lbl.add_theme_color_override("font_color", accent if bt != null else DIM)
	var med = null
	if bt != null and game.track != null and game.track.medals is Dictionary:
		med = CarSim.medal_for(bt, game.track.medals)
	if card_best_dot:
		card_best_dot.visible = med != null
		if med != null:
			card_best_dot.col = MEDAL_COL[med]
			card_best_dot.queue_redraw()


func set_net_status(text: String) -> void:
	if net_status_lbl:
		net_status_lbl.text = text


func set_replay_mode(on: bool, best_time: float = 0.0, exact: bool = true) -> void:
	replay_mode = on
	replay_exact = exact
	replay_lbl.visible = on
	lap_info.visible = true
	replay_progress.visible = on
	replay_progress.max_value = maxf(best_time, 0.001)
	replay_progress.value = 0.0
	replay_lbl.text = ("BEST RUN REPLAY · " if exact else "LEGACY ROUTE PREVIEW · ") + U.fmt(best_time) if on else ""
	pads.visible = hud.visible and touch and not on
	hint.visible = hud.visible and not touch and not on
	meter.visible = hud.visible and not on
	respawn_btn.visible = not on
	if on:
		_hud_cache.erase("t")
		hud_sync(true)
	relayout()


func set_replay_complete() -> void:
	if replay_mode:
		replay_lbl.text = ("BEST RUN COMPLETE · " if replay_exact else "ROUTE PREVIEW COMPLETE · ") + U.fmt(game.best.t)
		replay_progress.value = replay_progress.max_value


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
		var tile := _track_tile(str(f.seed), str(f.get("env", "")), str(f.name), true)
		fav_list.add_child(tile.cell)
		fav_preview_views.append(tile.view)
	if game.menu_tab == "tracks":
		call_deferred("_populate_fav_previews")


func render_recent_tracks() -> void:
	if not recent_track_list:
		return
	fav_preview_revision += 1
	recent_preview_views.clear()
	for child in recent_track_list.get_children():
		recent_track_list.remove_child(child)
		child.queue_free()
	var tracks: Array = game.recent_tracks
	recent_track_empty.visible = tracks.is_empty()
	for entry in tracks:
		if not entry is Dictionary:
			continue
		var seed_s := str(entry.get("seed", ""))
		if seed_s == "":
			continue
		var tile := _track_tile(seed_s, str(entry.get("env", "")), str(entry.get("name", seed_s)), false)
		recent_track_list.add_child(tile.cell)
		recent_preview_views.append(tile.view)
	if game.menu_tab == "tracks":
		call_deferred("_populate_fav_previews")


func _populate_fav_previews() -> void:
	if fav_preview_task_running or game.menu_tab != "tracks":
		return
	fav_preview_task_running = true
	var revision := fav_preview_revision
	var previews: Array = fav_preview_views + recent_preview_views
	for entry in previews:
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


func _sync_tab_styles() -> void:
	for b in tabs:
		var on: bool = b.get_meta("v") == game.menu_tab
		# active tab reads as a glowing accent pill; inactive stays a quiet slot
		b.inset = 4.0 if on else 0.0
		b.glow = 11.0 if on else 0.0
		b.glow_col = Color(accent, 0.4)
		b.style(Color(accent, 0.2) if on else Color(11 / 255.0, 14 / 255.0, 20 / 255.0, 0.66), Color(accent, 0.65) if on else Color(1, 1, 1, 0.08), 10.0)
		(b.get_meta("lbl") as Label).add_theme_color_override("font_color", FG if on else DIM)


func set_tab(t: String) -> void:
	_sync_tab_styles()
	if section_title:
		section_title.text = {"drive": "PLAY", "events": "EVENTS", "garage": "GARAGE", "tracks": "TRACKS", "options": "OPTIONS"}.get(t, t.to_upper())
	if t == "events" and events_note:
		events_note.visible = not game.net.is_online()
		events_note.text = ("Connect to compete in the daily and weekly seed challenges." if not game.net.is_online()
			else "Loading today's challenges…")
		game.fetch_events()
	for k in panes:
		panes[k].visible = k == t
	tab_scroll.scroll_vertical = 0
	if btn_play:
		btn_play.visible = t == "drive"
	relayout()
	if t == "tracks":
		call_deferred("_populate_fav_previews")
		if menu_on:
			call_deferred("_focus_tracks_entry")


func _focus_tracks_entry() -> void:
	if not menu_on or game.menu_tab != "tracks":
		return
	var target: Control = null
	if fav_list.get_child_count() > 0:
		target = fav_list.get_child(0)
	elif recent_track_list.get_child_count() > 0:
		target = recent_track_list.get_child(0)
	else:
		target = tabs.filter(func(tab): return tab.get_meta("v") == "tracks")[0]
	if target and target.is_visible_in_tree():
		target.grab_focus()
		if tab_scroll.is_ancestor_of(target):
			tab_scroll.ensure_control_visible(target)


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
		_close_dialog()


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
	# live countdowns on the event cards
	if menu_on and not event_cards.is_empty() and panes.has("events") and panes["events"].visible:
		var server_now := _events_now + float(Time.get_ticks_msec() - _events_t0) / 1000.0
		for kind in event_cards:
			var c: Dictionary = event_cards[kind]
			if c.ends_at > 0.0:
				c.cd.text = _fmt_countdown(c.ends_at - server_now)


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
	pads.visible = on and touch and not replay_mode
	hint.visible = on and not touch and not replay_mode
	meter.visible = on and not replay_mode
	respawn_btn.visible = not replay_mode


func set_touch(on: bool) -> void:
	touch = on
	pads.visible = hud.visible and touch and not replay_mode
	hint.visible = hud.visible and not touch and not replay_mode
	if is_node_ready():
		refresh_hint()
		relayout()


func hud_sync(force: bool) -> void:
	var g = game
	if not replay_mode:
		meter.set_state(g.car.boost_amt, CarSim.BOOST_CAP, g.car.boost_held)
	var t: float = 0.0
	if g.state == "countdown":
		t = 0.0
	elif g.state == "finished":
		t = g.finish_t
	elif g.state == "replay":
		t = g.replay_t
	else:
		t = g.race_steps * U.STEP
	var s := U.fmt(t)
	if replay_mode:
		var best_time := float(g.best.get("t", 0.0)) if g.best is Dictionary else 0.0
		replay_lbl.text = ("BEST RUN REPLAY · " if replay_exact else "LEGACY ROUTE PREVIEW · ") + U.fmt(best_time)
		replay_progress.max_value = maxf(best_time, 0.001)
		replay_progress.value = minf(t, best_time)
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
	_place_stats()


## Bottom-right FPS readout, lifted above the menu's bottom sheet on phones so it never sits under Race.
func _place_stats() -> void:
	stats_lbl.size = stats_lbl.get_combined_minimum_size()
	var sr := maxf(16.0, safe.r)
	var y: float = size.y - safe.b - 6.0 - stats_lbl.size.y
	if menu_on and bottombar:
		y = bottombar.position.y - 6.0 - stats_lbl.size.y
	stats_lbl.position = Vector2(size.x - sr - stats_lbl.size.x, y)


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
