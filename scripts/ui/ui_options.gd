class_name UiOptions
extends RefCounted
## The Options surface — the Visuals / Controls / Other pane (also reparented into its own in-game
## modal), every slider and segmented control, and the full key / gamepad rebinding flow. Split out
## of the Ui monolith; it owns its widgets and the rebind state, and reaches back into Ui for the
## layout helpers, palette, panes dict and the shared hint/account/nav bits. Ui keeps thin delegators
## for the few entry points the game and input pipeline call (sync_opts, capture_binding, …).

var ui: Ui
var body: VBoxContainer
var modal: Control
var scroll: ScrollContainer
var tab_seg: Array = []
var visuals_box: VBoxContainer
var controls_box: VBoxContainer
var other_box: VBoxContainer
var segs := {}
var sens_slider: HSlider
var sens_out: Label
var zoom_slider: HSlider
var zoom_out: Label
var uiscale_slider: HSlider
var uiscale_out: Label
var fov_slider: HSlider
var fov_out: Label
var music_slider: HSlider
var music_out: Label
var sfx_slider: HSlider
var sfx_out: Label
var bind_dev := "kb"
var bind_dev_btns: Array = []
var bind_rows: VBoxContainer
var bind_btns := {}
var bind_note: Label
var acct_status: Label
var acct_btn: Tap
var acct_lbl: Label
var net_status_lbl: Label
var _rebind := {}
var _rebind_t := 0


func _init(u: Ui) -> void:
	ui = u


func build_pane(parent: Control) -> void:
	var p := ui._pane(parent, "options")
	body = ui.vbox(12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(body)
	# top tab strip: Visuals / Controls / Other
	var ts := ui.seg([["visuals", "Visuals"], ["controls", "Controls"], ["other", "Other"]], func(v): _set_tab(v))
	tab_seg = ts[1]
	body.add_child(ts[0])
	# one scrollable column per tab (only the active one is visible)
	visuals_box = ui.vbox(12)
	controls_box = ui.vbox(12)
	other_box = ui.vbox(12)
	for b in [visuals_box, controls_box, other_box]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(b)
	# each setting lives in its own titled card so the page reads cleanly
	var group := func(host: Control, title: String) -> VBoxContainer:
		var card := ui.glass(Ui.PANEL2, Ui.LINE, 12.0)
		card.pad(16, 14, 16, 14)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col := ui.vbox(10)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(col)
		col.add_child(ui.eyebrow(title))
		host.add_child(card)
		return col

	# ---------- Visuals ----------
	for spec in [["gfx", "Graphics", [["high", "Toon shading"], ["low", "Battery saver"]]],
			["quality", "Detail", [["low", "Low"], ["med", "Medium"], ["high", "High"]]],
			["msaa", "Anti-aliasing", [["off", "Off"], ["fxaa", "FXAA"], ["2x", "2×"], ["4x", "4×"]]],
			["stats", "Frame rate readout", [["", "Hidden"], ["1", "Shown"]]]]:
		var col := group.call(visuals_box, spec[1]) as VBoxContainer
		var k: String = spec[0]
		var s := ui.seg(spec[2], func(v): ui.game.set_opt(k, v))
		segs[k] = s[1]
		col.add_child(s[0])
	# camera zoom (dolly in/out), interface scale and field of view — each a 0..100 slider, 50 = default
	var zc := _slider_card(group.call(visuals_box, "Camera zoom"), "Zoom", "Wider", "Closer", func(v): ui.game.set_zoom(int(v)))
	zoom_slider = zc[0]
	zoom_out = zc[1]
	var uc := _slider_card(group.call(visuals_box, "Interface scale"), "Scale", "Smaller", "Larger", func(v): ui.game.set_ui_scale(int(v)))
	uiscale_slider = uc[0]
	uiscale_out = uc[1]
	var fc := _slider_card(group.call(visuals_box, "Field of view"), "FOV", "Narrow", "Wide", func(v): ui.game.set_fov(int(v)))
	fov_slider = fc[0]
	fov_out = fc[1]

	# ---------- Controls ----------
	# touch steering sensitivity
	var tcol := group.call(controls_box, "Touch steering") as VBoxContainer
	var srow := ui.hbox(0)
	var sa := ui.L("Sensitivity", "body", 500, 12, Ui.DIM)
	sa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	srow.add_child(sa)
	sens_out = ui.L("Quick", "body", 600, 11, Ui.FG, false, 0.16, true)
	sens_out.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	srow.add_child(sens_out)
	tcol.add_child(srow)
	sens_slider = HSlider.new()
	sens_slider.min_value = 0
	sens_slider.max_value = 100
	sens_slider.step = 1
	sens_slider.custom_minimum_size = Vector2(0, 30)
	sens_slider.focus_mode = Control.FOCUS_ALL
	_style_slider(sens_slider)
	sens_slider.value_changed.connect(func(v): ui.game.set_sens(int(v)))
	tcol.add_child(sens_slider)
	var rl := ui.hbox(0)
	var gl := ui.L("Gentle", "body", 600, 10, Ui.DIM, false, 0.12, true)
	gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.add_child(gl)
	rl.add_child(ui.L("Quick", "body", 600, 10, Ui.DIM, false, 0.12, true))
	tcol.add_child(rl)
	# steering hand
	var hcol := group.call(controls_box, "Steering hand") as VBoxContainer
	var hs := ui.seg([["left", "Left thumb"], ["right", "Right thumb"]], func(v): ui.game.set_opt("side", v))
	segs["side"] = hs[1]
	hcol.add_child(hs[0])
	# vibration (touch buzz + gamepad rumble)
	var vcol := group.call(controls_box, "Vibration") as VBoxContainer
	var vs := ui.seg([["on", "On"], ["off", "Off"]], func(v): ui.game.set_opt("haptics", v))
	segs["haptics"] = vs[1]
	vcol.add_child(vs[0])
	# key / gamepad bindings
	var bcol := group.call(controls_box, "Key bindings") as VBoxContainer
	var ds := ui.seg([["kb", "Keyboard"], ["pad", "Gamepad"]], func(v): _set_bind_device(v))
	bind_dev_btns = ds[1]
	bcol.add_child(ds[0])
	bind_rows = ui.vbox(4)
	for a in Bindings.visible_actions(ui.game.DRIFT_ENABLED):
		var id: String = a[0]
		var row := ui.hbox(6)
		var nm := ui.L(a[1], "body", 500, 13, Ui.FG)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.custom_minimum_size = Vector2(60, 0)
		row.add_child(nm)
		var btns: Array = []
		for slot in 2:
			var b := ui.tap(Ui.PANEL2, Ui.LINE, 8.0)
			b.custom_minimum_size = Vector2(112, 34)
			var bl := ui.L("—", "mono", 700, 11, Ui.FG)
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.add_child(ui.center(bl))
			b.set_meta("lbl", bl)
			var sl := slot
			b.pressed.connect(func(): _begin_rebind(id, sl))
			row.add_child(b)
			btns.append(b)
		bind_btns[id] = btns
		bind_rows.add_child(row)
	bcol.add_child(bind_rows)
	var reset := ui.tap(Ui.PANEL, Ui.LINE, 10.0)
	reset.custom_minimum_size = Vector2(0, 36)
	var rl2 := ui.L("Reset to defaults", "body", 600, 12, Ui.FG, false, 0.06, true)
	rl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset.add_child(ui.center(rl2))
	reset.pressed.connect(func():
		_cancel_rebind()
		Bindings.reset_device(bind_dev)
		refresh_binds())
	bcol.add_child(reset)
	bind_note = ui.L("", "body", 400, 12, Ui.DIM)
	bind_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bind_note.custom_minimum_size = Vector2(120, 0)
	bcol.add_child(bind_note)
	_set_bind_device("kb")

	# ---------- Other ----------
	# audio levels (the global on/off still lives on the top-bar sound button)
	var mc := _slider_card(group.call(other_box, "Music volume"), "Music", "Off", "Loud", func(v): ui.game.set_music_vol(int(v)))
	music_slider = mc[0]
	music_out = mc[1]
	var sc := _slider_card(group.call(other_box, "Effects volume"), "SFX", "Off", "Loud", func(v): ui.game.set_sfx_vol(int(v)))
	sfx_slider = sc[0]
	sfx_out = sc[1]
	var acol := group.call(other_box, "Account") as VBoxContainer
	acct_status = ui.L("", "body", 400, 12, Ui.DIM)
	acct_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	acct_status.custom_minimum_size = Vector2(120, 0)
	acol.add_child(acct_status)
	var ob := ui._cbtn("Sign in / Create account", false)
	acct_btn = ob[0]
	acct_lbl = ob[1]
	ob[0].pressed.connect(func(): ui.show_account(true))
	acol.add_child(ob[0])
	net_status_lbl = ui.L("", "body", 400, 12, Ui.DIM)
	net_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	net_status_lbl.custom_minimum_size = Vector2(120, 0)
	acol.add_child(net_status_lbl)

	_set_tab("visuals")


func _slider_card(col: VBoxContainer, label: String, left: String, right: String, cb: Callable) -> Array:
	var row := ui.hbox(0)
	var a := ui.L(label, "body", 500, 12, Ui.DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(a)
	var out := ui.L("Default", "body", 600, 11, Ui.FG, false, 0.16, true)
	out.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(out)
	col.add_child(row)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 1
	s.custom_minimum_size = Vector2(0, 30)
	s.focus_mode = Control.FOCUS_ALL
	_style_slider(s)
	s.value_changed.connect(cb)
	col.add_child(s)
	var caps := ui.hbox(0)
	var lc := ui.L(left, "body", 600, 10, Ui.DIM, false, 0.12, true)
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caps.add_child(lc)
	caps.add_child(ui.L(right, "body", 600, 10, Ui.DIM, false, 0.12, true))
	col.add_child(caps)
	return [s, out]


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.18)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate()
	fill.bg_color = ui.accent
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var img := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	for y in 36:
		for x in 36:
			var d := Vector2(x + 0.5 - 18, y + 0.5 - 18).length()
			img.set_pixel(x, y, Color(ui.accent, clampf(16.5 - d, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	tex.set_size_override(Vector2i(18, 18))
	s.add_theme_icon_override("grabber", tex)
	s.add_theme_icon_override("grabber_highlight", tex)


## Re-tint every slider to the current accent (called from Ui.set_accent).
func restyle() -> void:
	for s in [sens_slider, zoom_slider, uiscale_slider, fov_slider, music_slider, sfx_slider]:
		if s:
			_style_slider(s)


func _set_tab(v: String) -> void:
	visuals_box.visible = v == "visuals"
	controls_box.visible = v == "controls"
	other_box.visible = v == "other"
	ui.set_seg(tab_seg, v)


func build_modal() -> void:
	modal = ColorRect.new()
	(modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.82)
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.visible = false
	ui.add_child(modal)
	var card := ui.glass(Ui.PANEL, Ui.LINE, 20.0, 3.0)
	card.pad(22, 16, 22, 16)
	card.clip_contents = true
	modal.add_child(card)
	var box := ui.vbox(12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(box)
	var head := ui.hbox(8)
	var htext := ui.vbox(2)
	htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(ui.eyebrow("Settings"))
	htext.add_child(ui.L("Options", "display", 800, 24, Ui.FG, true, 0.0, true))
	head.add_child(htext)
	var cb := ui.icon_btn("x")
	cb[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb[0].pressed.connect(func(): show(false))
	head.add_child(cb[0])
	modal.set_meta("close", cb[0])
	box.add_child(head)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)


func show(on: bool) -> void:
	if modal == null or on == modal.visible:
		return
	if on:
		if body.get_parent() != scroll:
			body.get_parent().remove_child(body)
			scroll.add_child(body)
		ui.sync_opts()
		refresh_binds()
		ui.sync_account()
		modal.visible = true
		ui._set_stick_direction(Vector2i.ZERO)
		_set_tab("visuals")
		ui.relayout()
		ui._rise(modal.get_child(0))
		if tab_seg.size() > 0:
			(tab_seg[0] as Control).grab_focus()
	else:
		modal.visible = false
		ui._set_stick_direction(Vector2i.ZERO)
		var focus := ui._focus_owner()
		if focus and modal.is_ancestor_of(focus):
			focus.release_focus()
		if body.get_parent() == scroll:
			scroll.remove_child(body)
			ui.panes["options"].add_child(body)
		if ui._active_section == "options":
			ui._active_section = ""
			ui._sync_tab_styles()
		if ui.pause_modal.visible:
			ui.pause_resume.grab_focus()
		elif ui.menu_on:
			ui.focus_default()


func layout(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if modal == null or not modal.visible:
		return
	var card: Glass = modal.get_child(0)
	var cw := minf(620.0, W - sl - sr - 16.0)
	var avail := H - st - sb - 16.0
	body.custom_minimum_size.x = cw - 44.0
	# size the keybind buttons for the modal width (overrides the menu-panel sizing)
	var cwin := cw - 44.0 - 12.0
	var blabel := 46.0 if cwin < 300.0 else (52.0 if cwin < 360.0 else 60.0)
	var bbtn := clampf((cwin - blabel - 18.0) / 2.0, 72.0, 120.0)
	for row in bind_rows.get_children():
		row.add_theme_constant_override("separation", 6)
		row.get_child(0).custom_minimum_size.x = blabel
		for slot in 2:
			(row.get_child(slot + 1) as Control).custom_minimum_size.x = bbtn
	var content := body.get_combined_minimum_size().y
	scroll.custom_minimum_size = Vector2(0, minf(content, maxf(160.0, avail - 72.0)))
	card.size = Vector2(cw, 0)
	card.size = Vector2(cw, minf(card.get_combined_minimum_size().y, avail))
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - card.size.y) / 2.0))
	card._sync()


func set_tab_visuals() -> void:
	_set_tab("visuals")


## Mirror the saved options into the sliders + segmented controls (the widget half of Ui.sync_opts).
func sync() -> void:
	var o: Dictionary = ui.game.opts
	for k in segs:
		ui.set_seg(segs[k], str(o.get(k, "")))
	var v := int(o.sensV)
	sens_slider.set_value_no_signal(v)
	sens_out.text = ("Gentle" if v < 34 else ("Normal" if v < 67 else "Quick")).to_upper()
	var zv := int(o.get("zoom", 50))
	zoom_slider.set_value_no_signal(zv)
	zoom_out.text = "DEFAULT" if zv == 50 else ("%+d%%" % int(round((zv - 50) / 50.0 * 15.0)))
	var uv := int(o.get("uiscale", 50))
	uiscale_slider.set_value_no_signal(uv)
	uiscale_out.text = "%d%%" % int(round((1.0 + (uv - 50) / 50.0 * 0.25) * 100.0))
	var fv := int(o.get("fov", 50))
	fov_slider.set_value_no_signal(fv)
	fov_out.text = "%d°" % int(round(46.0 + (fv - 50) / 50.0 * 10.0))
	var mvol := int(o.get("musicvol", 55))
	music_slider.set_value_no_signal(mvol)
	music_out.text = "%d%%" % mvol
	var svol := int(o.get("sfxvol", 100))
	sfx_slider.set_value_no_signal(svol)
	sfx_out.text = "%d%%" % svol


# ---------------------------------------------------------------- account widgets (driven by Ui)
func set_net_status(text: String) -> void:
	if net_status_lbl:
		net_status_lbl.text = text


func sync_account(registered: bool, email: String) -> void:
	if acct_status:
		acct_status.text = ("Signed in as %s" % email) if registered else "Playing as a guest. Sign in to sync your car and runs."
		acct_lbl.text = ("Manage account" if registered else "Sign in / Create account").to_upper()


# ---------------------------------------------------------------- key / gamepad rebinding
func _set_bind_device(d: String) -> void:
	bind_dev = d
	_cancel_rebind()
	ui.set_seg(bind_dev_btns, d)
	refresh_binds()


func refresh_binds() -> void:
	for id in bind_btns:
		for slot in 2:
			var b: Tap = bind_btns[id][slot]
			var val = Bindings.get_slot(bind_dev, id, slot)
			var txt: String = Bindings.key_label(val) if bind_dev == "kb" else Bindings.pad_label(val)
			var listening: bool = _rebind.get("action", "") == id and _rebind.get("slot", -1) == slot
			(b.get_meta("lbl") as Label).text = "Press…" if listening else txt
			(b.get_meta("lbl") as Label).add_theme_color_override("font_color", ui.accent if listening else Ui.FG)
	if bind_dev == "kb":
		bind_note.text = "Tap a slot, then press a key. Tap it again to clear. Esc cancels."
	else:
		bind_note.text = "Tap a slot, then press a button or move a stick or trigger. Menus always use D-pad / stick, A / Cross to select, B / Circle to go back."
	ui.refresh_hint()


func _begin_rebind(action: String, slot: int) -> void:
	if _rebind.get("action", "") == action and _rebind.get("slot", -1) == slot:
		_apply_binding(0 if bind_dev == "kb" else "")
		return
	_rebind = {"action": action, "slot": slot, "dev": bind_dev}
	_rebind_t = Time.get_ticks_msec()
	refresh_binds()
	var stamp := _rebind_t
	ui.get_tree().create_timer(6.0).timeout.connect(func():
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
