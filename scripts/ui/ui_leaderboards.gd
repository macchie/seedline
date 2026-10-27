class_name UiLeaderboards
extends RefCounted
## The global standings dialog — skill by Performance Points, exploration by unique tracks. Split out
## of the Ui monolith: it owns its own widgets and reaches back into the shared Ui for the layout
## helpers (L/glass/seg…), palette and game access. The modal stays a direct child of Ui so the
## existing top-of-stack z-ordering and focus routing keep working unchanged.

var ui: Ui
var modal: Control
var box: VBoxContainer
var scroll: ScrollContainer
var list: VBoxContainer
var hero_rank: Label
var hero_val: Label
var hero_sub: Label
var seg: Array = []
var board := "global"
var data = null


func _init(u: Ui) -> void:
	ui = u


func build() -> void:
	modal = ColorRect.new()
	(modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.72)
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.visible = false
	ui.add_child(modal)
	var card := ui.glass(Ui.PANEL, Ui.LINE, 20.0, 3.0)
	card.pad(22, 18, 22, 18)
	card.clip_contents = true
	modal.add_child(card)
	box = ui.vbox(12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(box)
	var head := ui.hbox(8)
	var htext := ui.vbox(2)
	htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(ui.eyebrow("Global standings"))
	htext.add_child(ui.L("Leaderboards", "display", 800, 26, Ui.FG, true, 0.0, true))
	head.add_child(htext)
	var cb := ui.icon_btn("x")
	cb[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb[0].pressed.connect(func(): hide())
	head.add_child(cb[0])
	modal.set_meta("close", cb[0])
	box.add_child(head)
	var sg := ui.seg([["global", "Global PP"], ["explorers", "Explorers"]], func(v): _set_board(v))
	seg = sg[1]
	box.add_child(sg[0])
	var hero := ui.glass(Color(ui.accent, 0.12), Color(ui.accent, 0.4), 14.0)
	hero.pad(16, 12, 16, 12)
	var hrow := ui.hbox(12)
	var hcol := ui.vbox(2)
	hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hcol.alignment = BoxContainer.ALIGNMENT_CENTER
	hcol.add_child(ui.eyebrow("Your rank"))
	hero_sub = ui.L("Not ranked yet", "body", 500, 12, Ui.DIM)
	hero_sub.clip_text = true
	hero_sub.custom_minimum_size = Vector2(1, 0)
	hcol.add_child(hero_sub)
	hrow.add_child(hcol)
	hero_val = ui.L("", "mono", 700, 18, Ui.FG)
	hero_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(hero_val)
	hero_rank = ui.L("—", "display", 800, 40, ui.accent, true, 0.0)
	hero_rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(hero_rank)
	hero.add_child(hrow)
	box.add_child(hero)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	list = ui.vbox(2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	ui.set_seg(seg, board)


func show() -> void:
	if modal == null:
		return
	board = "global"
	ui.set_seg(seg, board)
	_render()
	modal.visible = true
	ui._set_stick_direction(Vector2i.ZERO)
	ui.game.net.fetch_leaderboards()
	ui.relayout()
	ui._rise(modal.get_child(0))
	(modal.get_meta("close") as Control).grab_focus()


func hide() -> void:
	if modal == null or not modal.visible:
		return
	modal.visible = false
	ui._set_stick_direction(Vector2i.ZERO)
	var focus := ui._focus_owner()
	if focus and modal.is_ancestor_of(focus):
		focus.release_focus()
	ui._active_section = ""
	ui._sync_tab_styles()
	if ui.menu_on:
		ui._focus_nav("leaderboards")


func render_data(d) -> void:
	data = d
	if modal and modal.visible:
		_render()


func _set_board(b: String) -> void:
	board = b
	ui.set_seg(seg, b)
	_render()


func _fmt_value(b: String, v: float) -> String:
	if b == "explorers":
		var n := int(round(v))
		return "%d track%s" % [n, "" if n == 1 else "s"]
	return ui._fmt_pp(v) + " PP"


func _render() -> void:
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()
		list.remove_child(c)
	var d = data
	if not (d is Dictionary) or d.get("error", false):
		hero_rank.text = "—"
		hero_rank.add_theme_color_override("font_color", Ui.DIM)
		hero_val.text = ""
		hero_sub.text = "Connect to see global standings"
		var m := ui.L("Sign in and race to join the global leaderboards.", "body", 400, 12, Ui.DIM)
		m.custom_minimum_size = Vector2(0, 30)
		list.add_child(m)
		return
	var b = d.get(board, {})
	if not (b is Dictionary):
		b = {}
	var me = b.get("me")
	if me is Dictionary and int(me.get("rank", 0)) > 0:
		hero_rank.text = "#%d" % int(me.rank)
		hero_rank.add_theme_color_override("font_color", ui.accent)
		hero_val.text = _fmt_value(board, float(me.get("value", 0.0)))
		# the global board carries the player's RL-style medal; surface it beside the rank
		if board == "global" and me.get("medal") is Dictionary:
			hero_sub.text = ui._medal_name(me.medal)
			hero_sub.add_theme_color_override("font_color", ui._medal_col(me.medal))
		else:
			hero_sub.text = "Your rank"
			hero_sub.add_theme_color_override("font_color", Ui.DIM)
	else:
		hero_rank.text = "—"
		hero_rank.add_theme_color_override("font_color", Ui.DIM)
		hero_val.text = ""
		hero_sub.text = "Race to get ranked"
	var top = b.get("top", [])
	if not (top is Array) or top.is_empty():
		var m2 := ui.L("No one has ranked yet — be the first.", "body", 400, 12, Ui.DIM)
		m2.custom_minimum_size = Vector2(0, 30)
		list.add_child(m2)
		return
	var my_rank := int(me.get("rank", -1)) if me is Dictionary else -1
	for t in top:
		if not (t is Dictionary):
			continue
		var rk := int(t.get("rank", 0))
		list.add_child(_row(rk, str(t.get("name", "racer")), float(t.get("value", 0.0)), rk == my_rank))


func _row(rank: int, name: String, value: float, me: bool) -> Control:
	var row := ui.glass(Color(ui.accent, 0.12) if me else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8.0)
	row.custom_minimum_size = Vector2(0, 34)
	row.pad(8, 0, 10, 0)
	var h := ui.hbox(10)
	var rk := ui.L("#%d" % rank, "mono", 700, 13, ui.accent if me else Ui.DIM)
	rk.custom_minimum_size = Vector2(44, 0)
	rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(rk)
	var nm := ui.L(name, "body", 600, 13, Ui.FG, false, 0.04, true)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(nm)
	var vl := ui.L(_fmt_value(board, value), "mono", 700, 13, ui.accent if me else Ui.FG)
	vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(vl)
	row.add_child(h)
	return row


func layout(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
	if modal == null or not modal.visible:
		return
	var card: Glass = modal.get_child(0)
	var cw := minf(820.0, W - sl - sr - 16.0)
	var ch := minf(880.0, H - st - sb - 16.0)
	box.custom_minimum_size.x = cw - 44.0
	card.size = Vector2(cw, ch)
	card.position = Vector2((W - cw) / 2.0, maxf(st + 8.0, (H - ch) / 2.0))
	card._sync()
