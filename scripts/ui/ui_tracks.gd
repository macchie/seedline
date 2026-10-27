class_name UiTracks
extends RefCounted
## The Tracks dialog — saved + recently-played track grids and the per-track action sheet (race /
## watch / remove). Split out of the Ui monolith; it owns its own widgets and reaches back into the
## shared Ui for layout helpers, palette, the preview cache (shared with the event cards) and the
## best-time/replay lookups. Modals stay direct children of Ui so z-order and focus routing are
## unchanged.

var ui: Ui
var tracks_body: VBoxContainer
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
var track_action_cancel: Tap
var _track_action_seed := ""
var _track_action_env := ""
var fav_preview_views: Array[Dictionary] = []
var recent_preview_views: Array[Dictionary] = []
var fav_preview_revision := 0
var fav_preview_task_running := false


func _init(u: Ui) -> void:
	ui = u


func build_pane(parent: Control) -> void:
	var p := ui._pane(parent, "tracks")
	tracks_body = ui.vbox(10)
	tracks_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(tracks_body)
	tracks_body.add_child(ui.eyebrow("Saved tracks"))
	fav_list = _grid()
	tracks_body.add_child(fav_list)
	fav_empty = ui.L("No saved tracks yet. Save a track from Drive to keep it here.", "body", 400, 13, Ui.DIM)
	fav_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fav_empty.custom_minimum_size = Vector2(0, 36)
	tracks_body.add_child(fav_empty)
	tracks_body.add_child(ui.eyebrow("Last played"))
	recent_track_list = _grid()
	tracks_body.add_child(recent_track_list)
	recent_track_empty = ui.L("Tracks you race or watch will appear here.", "body", 400, 13, Ui.DIM)
	recent_track_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recent_track_empty.custom_minimum_size = Vector2(0, 36)
	tracks_body.add_child(recent_track_empty)


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.mouse_filter = Control.MOUSE_FILTER_PASS
	return g


## One track tile (minimap + name + seed) for the saved / recent grids; tapping opens the action dialog.
func _tile(seed_s: String, env_s: String, title: String, show_remove: bool) -> Dictionary:
	if not Envs.KEYS.has(env_s):
		var parsed = ui.game.parse_seed(seed_s)
		if parsed != null:
			env_s = str(parsed.env)
	var ed: Dictionary = Envs.DATA.get(env_s, {})
	var acc := U.css(ed.accent) if not ed.is_empty() else ui.accent
	var cur: bool = ui.game.track != null and seed_s == ui.game.track.seed and env_s == ui.game.track.env_key
	# wash the card in a hint of the environment's accent so each world reads at a glance
	var tint := Color(acc.r, acc.g, acc.b, 0.14 if cur else 0.08)
	var cell := ui.tap(tint, ui.accent if cur else Color(acc.r, acc.g, acc.b, 0.22), 12.0)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.pad(8, 8, 8, 8)
	cell.tooltip_text = "Open " + title
	var col := ui.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pbox := ui.glass(Color(0, 0, 0, 0.26), Ui.LINE, 9.0)
	pbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbox.pad(3, 3, 3, 3)
	var preview := MapView.new()
	preview.preview = true
	preview.custom_minimum_size = Vector2(116, 116)
	pbox.add_child(preview)
	col.add_child(pbox)
	var name_lbl := ui.L(title, "display", 800, 13, Ui.FG, true, 0.0, true)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.custom_minimum_size = Vector2(1, 0)
	col.add_child(name_lbl)
	# environment line: a colour dot + the world's name, with its weather tagged on the right
	if not ed.is_empty():
		var env_row := ui.hbox(5)
		var ed_dot := ui.dot(acc, 7)
		ed_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		env_row.add_child(ed_dot)
		var env_lbl := ui.L(str(ed.name), "body", 600, 10, acc, false, 0.02, true)
		env_lbl.clip_text = true
		env_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		env_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		env_row.add_child(env_lbl)
		var weather_s := str(ed.get("weather", "none"))
		if weather_s != "none" and weather_s != "":
			var w_lbl := ui.L(weather_s.capitalize(), "body", 500, 9, Ui.DIM, false, 0.04, true)
			w_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			env_row.add_child(w_lbl)
		col.add_child(env_row)
	var meta := ui.vbox(2)
	# seed is always shown so every tile stays shareable, best time sits on its own line below
	var seed_lbl := ui.L(seed_s, "mono", 500, 10, Ui.DIM)
	seed_lbl.clip_text = true
	seed_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	seed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(seed_lbl)
	var bt = ui._best_time(seed_s)
	var has_replay := ui._has_replay(seed_s)
	if bt != null or has_replay:
		var line := ui.hbox(5)
		if bt != null:
			var best_lbl := ui.L("BEST " + U.fmt(bt), "mono", 500, 10, ui.accent)
			best_lbl.clip_text = true
			best_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(best_lbl)
		if has_replay:
			var r := Icon.new("respawn", 13)
			r.color = ui.accent
			r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			r.tooltip_text = "Replay available"
			line.add_child(r)
		meta.add_child(line)
	col.add_child(meta)
	cell.add_child(col)
	var env_final := env_s
	cell.pressed.connect(func(): show_action(seed_s, env_final, title, show_remove))
	return {"cell": cell, "view": {"map": preview, "seed": seed_s, "env": env_final, "accent": acc}}


func build_action_modal() -> void:
	track_action_modal = ColorRect.new()
	(track_action_modal as ColorRect).color = Color(5 / 255.0, 6 / 255.0, 10 / 255.0, 0.72)
	track_action_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_action_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	track_action_modal.visible = false
	ui.add_child(track_action_modal)
	var card := ui.glass(Ui.PANEL, Ui.LINE, 20.0, 3.0)
	card.pad(22, 20, 22, 20)
	card.clip_contents = true
	track_action_modal.add_child(card)
	track_action_box = ui.vbox(12)
	track_action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(track_action_box)
	var head := ui.hbox(8)
	var htext := ui.vbox(2)
	htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(ui.eyebrow("Track"))
	track_action_title = ui.L("Track", "display", 800, 24, Ui.FG, true, 0.0, true)
	track_action_title.clip_text = true
	track_action_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	track_action_title.custom_minimum_size = Vector2(1, 0)
	htext.add_child(track_action_title)
	head.add_child(htext)
	var cb := ui.icon_btn("x")
	cb[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb[0].pressed.connect(func(): hide_action())
	head.add_child(cb[0])
	track_action_modal.set_meta("close", cb[0])
	track_action_box.add_child(head)
	var prow := ui.hbox(12)
	var pbox := ui.glass(Color(0, 0, 0, 0.26), Ui.LINE, 10.0)
	pbox.custom_minimum_size = Vector2(120, 120)
	pbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pbox.pad(4, 4, 4, 4)
	track_action_preview = MapView.new()
	track_action_preview.preview = true
	track_action_preview.custom_minimum_size = Vector2(112, 112)
	pbox.add_child(track_action_preview)
	prow.add_child(pbox)
	var pcol := ui.vbox(6)
	pcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pcol.alignment = BoxContainer.ALIGNMENT_CENTER
	track_action_sub = ui.L("", "body", 500, 12, Ui.DIM)
	track_action_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	track_action_sub.custom_minimum_size = Vector2(1, 0)
	pcol.add_child(track_action_sub)
	prow.add_child(pcol)
	track_action_box.add_child(prow)
	var race := ui._cbtn("Race this track", true, "A")
	track_action_race = race[0]
	race[0].pressed.connect(func(): _action_do("race"))
	track_action_box.add_child(race[0])
	var watch := ui._cbtn("Watch replay", false)
	track_action_watch = watch[0]
	watch[0].pressed.connect(func(): _action_do("watch"))
	track_action_box.add_child(watch[0])
	var remove := ui._cbtn("Remove from saved", false)
	track_action_remove = remove[0]
	remove[0].pressed.connect(func(): _action_do("remove"))
	track_action_box.add_child(remove[0])
	var close := ui._cbtn("Cancel", false, "Esc")
	track_action_cancel = close[0]
	close[0].pressed.connect(func(): hide_action())
	track_action_box.add_child(close[0])


func show_action(seed_s: String, env_s: String, title: String, is_fav: bool) -> void:
	if track_action_modal == null:
		return
	if not Envs.KEYS.has(env_s):
		var parsed = ui.game.parse_seed(seed_s)
		if parsed != null:
			env_s = str(parsed.env)
	_track_action_seed = seed_s
	_track_action_env = env_s
	track_action_title.text = title.to_upper()
	var acc := U.css(Envs.DATA[env_s].accent) if Envs.DATA.has(env_s) else ui.accent
	var env_name := str(Envs.DATA[env_s].name) if Envs.DATA.has(env_s) else env_s
	var bt = ui._best_time(seed_s)
	var sub := env_name
	if Envs.DATA.has(env_s):
		var weather_s := str(Envs.DATA[env_s].get("weather", "none"))
		if weather_s != "none" and weather_s != "":
			sub += "  ·  " + weather_s.capitalize()
	sub += "  ·  " + seed_s
	if bt != null:
		sub += "\nYour best " + U.fmt(bt)
	track_action_sub.text = sub
	track_action_watch.visible = ui._has_replay(seed_s)
	track_action_remove.visible = is_fav
	_wire_action_focus()
	track_action_preview.t = null
	track_action_preview.set_track(ui._cached_fav_track(seed_s, env_s), acc)
	# draw above the tracks section it was opened from (built earlier, so a lower sibling)
	ui.move_child(track_action_modal, ui.get_child_count() - 1)
	track_action_modal.visible = true
	ui._set_stick_direction(Vector2i.ZERO)
	ui.relayout()
	ui._rise(track_action_modal.get_child(0))
	track_action_race.grab_focus()


## A vertical focus ring over just the visible sheet buttons. The track tiles behind the sheet stay
## focusable, so without explicit neighbours the gamepad's geometric search can grab a tile (outside
## this dialog) and the nav then refuses to move — leaving focus stuck. This keeps it self-contained.
func _wire_action_focus() -> void:
	var chain: Array[Control] = [track_action_race]
	if track_action_watch.visible:
		chain.append(track_action_watch)
	if track_action_remove.visible:
		chain.append(track_action_remove)
	chain.append(track_action_cancel)
	for i in chain.size():
		var c := chain[i]
		var up := chain[(i - 1 + chain.size()) % chain.size()]
		var down := chain[(i + 1) % chain.size()]
		c.focus_neighbor_top = c.get_path_to(up)
		c.focus_neighbor_bottom = c.get_path_to(down)
		c.focus_neighbor_left = c.get_path_to(c)
		c.focus_neighbor_right = c.get_path_to(c)
		c.focus_next = c.get_path_to(down)
		c.focus_previous = c.get_path_to(up)


func hide_action() -> void:
	if track_action_modal == null or not track_action_modal.visible:
		return
	track_action_modal.visible = false
	ui._set_stick_direction(Vector2i.ZERO)
	var focus := ui._focus_owner()
	if focus and track_action_modal.is_ancestor_of(focus):
		focus.release_focus()
	if ui.menu_on and ui.game.menu_tab == "tracks":
		ui.call_deferred("_focus_tracks_entry")


func _action_do(kind: String) -> void:
	var s := _track_action_seed
	var e := _track_action_env
	hide_action()
	if kind == "race":
		# close the tracks dialog so the race (and the Play screen behind it) isn't covered
		ui.hide_section()
		ui.game.race_track(s, e)
	elif kind == "watch":
		ui.hide_section()
		ui.game.replay_track(s, e)
	elif kind == "remove":
		ui.game.remove_fav(s)


func layout_action(W: float, H: float, sl: float, sr: float, st: float, sb: float) -> void:
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


func render_favs() -> void:
	# the saved-track tiles only live inside the Tracks dialog; while it's closed, skip the rebuild
	# (show_section rebuilds from current state on open) so boot and every refresh_menu don't pay for it
	if ui._section_key != "tracks":
		return
	fav_preview_revision += 1
	for c in fav_list.get_children():
		c.queue_free()
		fav_list.remove_child(c)
	var favs: Array = ui.game.favs
	fav_preview_views.clear()
	fav_empty.visible = favs.is_empty()
	for f in favs:
		var tile := _tile(str(f.seed), str(f.get("env", "")), str(f.name), true)
		fav_list.add_child(tile.cell)
		fav_preview_views.append(tile.view)
	if ui._section_key == "tracks" and ui.section_modal != null and ui.section_modal.visible:
		call_deferred("_populate_previews")


func render_recent() -> void:
	if not recent_track_list or ui._section_key != "tracks":
		return
	fav_preview_revision += 1
	recent_preview_views.clear()
	for child in recent_track_list.get_children():
		recent_track_list.remove_child(child)
		child.queue_free()
	var tracks: Array = ui.game.recent_tracks
	recent_track_empty.visible = tracks.is_empty()
	for entry in tracks:
		if not entry is Dictionary:
			continue
		var seed_s := str(entry.get("seed", ""))
		if seed_s == "":
			continue
		var tile := _tile(seed_s, str(entry.get("env", "")), str(entry.get("name", seed_s)), false)
		recent_track_list.add_child(tile.cell)
		recent_preview_views.append(tile.view)
	if ui._section_key == "tracks" and ui.section_modal != null and ui.section_modal.visible:
		call_deferred("_populate_previews")


## Fill in the track-tile minimaps. Cached (and already-loaded current) tracks render instantly;
## the rest are generated on worker threads in parallel — WorkerThreadPool caps itself at the host's
## core count, so the previews build quickly without pinning every CPU — then applied on the main
## thread. Generation is pure (TrackGen keeps no shared state), so it is safe off the main thread.
func _populate_previews() -> void:
	if fav_preview_task_running or ui._section_key != "tracks" or ui.section_modal == null or not ui.section_modal.visible:
		return
	fav_preview_task_running = true
	var revision := fav_preview_revision
	var previews: Array = fav_preview_views + recent_preview_views
	# cheap pass: paint every cache hit now, and gather the unique seeds that still need generating
	var pending: Array = []            # [{entry, key}]
	var jobs := {}                     # key -> {seed, env}; deduped so shared seeds generate once
	for entry in previews:
		var preview := entry.map as MapView
		if not is_instance_valid(preview) or preview.t != null:
			continue
		var key: String = str(entry.env) + "|" + str(entry.seed)
		var cached := ui._cache_lookup(key, str(entry.seed), str(entry.env))
		if cached != null:
			preview.set_track(cached, entry.accent)
			continue
		pending.append({"entry": entry, "key": key})
		if not jobs.has(key):
			jobs[key] = {"seed": str(entry.seed), "env": str(entry.env)}
	if jobs.is_empty():
		fav_preview_task_running = false
		return
	# generate the misses in parallel off the main thread
	var keys: Array = jobs.keys()
	var results := {}
	var mutex := Mutex.new()
	var task_id := WorkerThreadPool.add_group_task(func(i: int):
		var k: String = keys[i]
		var job: Dictionary = jobs[k]
		var td := TrackGen.generate(job.seed, job.env)
		mutex.lock()
		results[k] = td
		mutex.unlock(), keys.size(), -1, false, "seedline track previews")
	while not WorkerThreadPool.is_group_task_completed(task_id):
		await ui.get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	# apply on the main thread (unless the list changed underneath us while generating)
	if revision == fav_preview_revision:
		for k in results:
			ui._cache_put(str(k), results[k])
		for item in pending:
			var preview := item.entry.map as MapView
			if is_instance_valid(preview) and preview.t == null and results.has(item.key):
				preview.set_track(results[item.key], item.entry.accent)
	fav_preview_task_running = false
	if ui._section_key == "tracks" and ui.section_modal.visible and revision != fav_preview_revision:
		call_deferred("_populate_previews")
