extends Node3D
## Seedline — game loop, race rules, camera, input, persistence (port of the web build's main script).

const TURBO_COL := [0xffffff, 0x3fb4ff, 0xffa32a, 0xd25bff]
const DRIFT_ENABLED := false
const KEYMAP := {KEY_UP: "gas", KEY_W: "gas", KEY_DOWN: "brake", KEY_S: "brake", KEY_SPACE: "drift", KEY_SHIFT: "drift", KEY_K: "drift",
	KEY_LEFT: "left", KEY_A: "left", KEY_RIGHT: "right", KEY_D: "right"}

# --- persistent options (same keys and defaults as localStorage in the web build)
var opts := {"gfx": "high", "sound": true, "side": "left", "sensV": 75, "stats": ""}
var car_cfg := {"color": "#e8402c", "finish": "gloss"}
var favs: Array = []
var is_touch := false
var touch_ui := false

# --- scene
var env_node: WorldEnvironment
var environment: Environment
var sun: DirectionalLight3D
var cam: Camera3D
var ink: MeshInstance3D
var ink_mat: ShaderMaterial
var grade: ColorRect
var grade_mat: ShaderMaterial
var ui: Ui
var world: World = null
var car_v: CarModel
var ghost_v: CarModel
var fx: Fx
var sfx: Sfx

# --- race state
var track: TrackData = null
var env: Dictionary = Envs.DATA["CANYON"]
var car := CarSim.new()
var state := "menu"
var race_steps := 0
var lap := 1
var next_cp := 0
var splits: Array = []
var ghost_rec: Array = []
var snapshot = null
var cd_t := 0.0
var cd_last := 0
var best = null
var finish_t := 0.0
var shake := 0.0
var menu_s := 0.0
var menu_tab := "track"
var last_step_input := {"gas": false, "brake": false, "drift": false, "steer": 0.0, "analog": false}
var cd := {"gas": false, "blown": false, "boost": false}
var paused_from := "race"
var keys := {}
var ts := {"steer_id": -1, "val": 0.0, "disp": 0.0, "pedal": {}, "gas": false, "brake": false}
var pad_prev := {"y": false, "st": false}

var acc := 0.0
var sim_t := 0.0
var cam_pos := Vector3.ZERO
var cam_look := Vector3.ZERO
var cam_init := false
var cam_fov := 46.0
var w_off := 0.0
var was_wet := false
var rip_t := 0.0
var ghost_idx := 0
var mini_ghost = null
var wheel_spin := 0.0
var finish_timer: SceneTreeTimer = null

# --- performance (adaptive resolution)
var perf := {"scale": 0.9, "max": 0.9, "min": 0.6, "frames": 0, "fps": 60.0, "last": 0}
var dpr := 1.0
var base_pr := 1.0


# ================================================================== boot

func _ready() -> void:
	is_touch = DisplayServer.is_touchscreen_available() and (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"))
	touch_ui = is_touch
	perf.scale = 0.75 if is_touch else 0.9
	perf.max = perf.scale
	var o = Store.get_value("opts", {})
	for k in o:
		opts[k] = o[k]
	if opts.get("sensV") == null or not opts.get("v4", false):
		opts.sensV = 75
		opts.v4 = 1
		opts.erase("cam")
		opts.erase("auto")
		opts.erase("sens")
		Store.set_value("opts", opts)
	var c = Store.get_value("car", {})
	for k in c:
		car_cfg[k] = c[k]
	favs = Store.get_value("favs", [])
	_build_scene()
	get_window().size_changed.connect(_on_resize)
	_on_resize()
	ui.set_touch(touch_ui)
	ui.init_tips()
	ui.sync_opts()
	ui.sync_car()
	ui.set_tab(menu_tab)
	apply_gfx()
	var first = Store.get_value("last", null)
	if first != null:
		load_track(str(first), Store.get_value("lastEnv", null))
	else:
		load_track(U.rand_seed_code())
	ui.set_loading(false)


func _build_scene() -> void:
	# lighting and fog are done in the shaders (display space, like the web build); the environment only clears
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = false
	environment.glow_enabled = false
	env_node = WorldEnvironment.new()
	env_node.environment = environment
	add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 520.0
	sun.directional_shadow_split_1 = 0.35
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.shadow_blur = 1.0
	sun.light_specular = 0.0
	sun.light_color = Color.WHITE
	sun.light_energy = 1.0
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 46.0
	cam.near = 1.0
	cam.far = 1400.0
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(cam)
	cam.current = true
	# ink outlines + cloud shadows: a full-screen quad drawn first among the transparent passes
	ink_mat = ShaderMaterial.new()
	ink_mat.shader = load("res://shaders/ink_clouds.gdshader")
	ink_mat.render_priority = -128
	ink_mat.set_shader_parameter("noise_tex", Tex.noise())
	ink = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	ink.mesh = q
	ink.material_override = ink_mat
	ink.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ink.custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))
	ink.position = Vector3(0, 0, -2)
	cam.add_child(ink)
	car_v = CarModel.new(false)
	add_child(car_v)
	ghost_v = CarModel.new(true)
	ghost_v.visible = false
	add_child(ghost_v)
	car_v.apply_cfg(car_cfg.color, car_cfg.finish)
	fx = Fx.new()
	add_child(fx)
	sfx = Sfx.new()
	add_child(sfx)
	var gl := CanvasLayer.new()
	gl.layer = 0
	add_child(gl)
	grade = ColorRect.new()
	grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade_mat = ShaderMaterial.new()
	grade_mat.shader = load("res://shaders/grade.gdshader")
	grade.material = grade_mat
	gl.add_child(grade)
	var ul := CanvasLayer.new()
	ul.layer = 1
	add_child(ul)
	ui = Ui.new(self)
	ul.add_child(ui)


func _on_resize() -> void:
	var win := get_window()
	dpr = _device_pixel_ratio()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_size = Vector2i(maxi(1, int(win.size.x / dpr)), maxi(1, int(win.size.y / dpr)))
	var sa := DisplayServer.get_display_safe_area()
	var ws := Vector2(win.size)
	var sr := DisplayServer.screen_get_usable_rect()
	if sa.size.x > 0 and OS.has_feature("mobile"):
		ui.safe = {"t": sa.position.y / dpr, "b": maxf(0.0, ws.y - sa.end.y) / dpr, "l": sa.position.x / dpr, "r": maxf(0.0, ws.x - sa.end.x) / dpr}
	_apply_resolution()
	ui.relayout()


func _device_pixel_ratio() -> float:
	var s := DisplayServer.screen_get_scale()
	if OS.has_feature("android"):
		s = DisplayServer.screen_get_dpi() / 160.0
	elif OS.has_feature("windows") or OS.has_feature("linuxbsd"):
		s = maxf(s, roundf(DisplayServer.screen_get_dpi() / 96.0 * 4.0) / 4.0)
	return clampf(s, 1.0, 4.0)


func _apply_resolution() -> void:
	var hi: bool = opts.gfx == "high"
	base_pr = minf(dpr, (1.75 if is_touch else 2.0) if hi else 1.0)
	var f: float = base_pr * perf.scale if hi else base_pr * perf.scale / perf.max
	var vp := get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = clampf(f / dpr, 0.25, 1.0)


func apply_gfx() -> void:
	var hi: bool = opts.gfx == "high"
	sun.shadow_enabled = hi
	ink.visible = hi
	grade_mat.set_shader_parameter("full", hi)
	_apply_resolution()


# ================================================================== tracks

func parse_seed(s: String):
	s = s.strip_edges().to_upper()
	var re := RegEx.new()
	re.compile("\\s+")
	s = re.sub(s, "-", true)
	if s == "":
		return null
	var m := RegEx.new()
	m.compile("^(" + "|".join(Envs.KEYS) + ")-(.+)$")
	var r := m.search(s)
	if r:
		return {"seed": s, "env": r.get_string(1)}
	return {"seed": s, "env": Envs.KEYS[SeedRng.hash_str(s) % Envs.KEYS.size()]}


func load_track(seed_str: String, env_key = null) -> void:
	var p = parse_seed(seed_str)
	if p == null:
		return
	if env_key != null and Envs.DATA.has(env_key):
		p.env = env_key
	env = Envs.variant(p.env, Envs.is_night_seed(p.seed))
	track = TrackGen.generate(p.seed, p.env)
	build_world()
	ui.set_accent(U.css(env.accent), U.css(env.onAccent))
	Store.set_value("last", p.seed)
	Store.set_value("lastEnv", p.env)
	for f in favs:
		if f.seed == p.seed:
			f.name = track.name
			f.medals = track.medals
			f.env = track.env_key
			f.v = 5
			Store.set_value("favs", favs)
	place_car_at(0, 4)
	cam_init = false
	menu_s = 0.0
	fx.clear_skids()
	ui.refresh_menu()


func build_world() -> void:
	if world:
		world.queue_free()
		remove_child(world)
	world = World.new()
	add_child(world)
	var e := env
	world.build(track, e, is_touch)
	environment.background_color = U.hexc(e.fog)
	var dark: bool = e.get("dark", false)
	RenderingServer.global_shader_parameter_set("g_fog_col", Mats.v3(U.hexc(e.fog)))
	RenderingServer.global_shader_parameter_set("g_hemi_sky", Mats.v3(U.hexc(e.hemiS)))
	RenderingServer.global_shader_parameter_set("g_hemi_ground", Mats.v3(U.hexc(e.hemiG)))
	RenderingServer.global_shader_parameter_set("g_hemi_i", float(e.hemiI) * 0.9)
	RenderingServer.global_shader_parameter_set("g_rim", 0.16 if dark else 0.2)
	RenderingServer.global_shader_parameter_set("g_rim_col", Mats.v3(U.hexc(0x8fa8ff if dark else 0xfff4e0)))
	# toon bands light flat ground at full strength, so the sun is dimmed to compensate
	RenderingServer.global_shader_parameter_set("g_sun", Mats.v3(U.hexc(e.sun) * (float(e.sunI) * 0.72)))
	var sd: Array = e.sunDir
	var dir := Vector3(sd[0], sd[1], sd[2]).normalized()
	sun.transform = Transform3D(Basis.looking_at(-dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD), Vector3.ZERO)
	# painted sky used as the environment map of the car and road (setSky)
	var top := U.hexc(0x0a1030 if dark else e.fog).lerp(U.hexc(0x1a2350 if dark else 0x6aa8e8), 0.4 if dark else 0.45)
	var gnd := U.hexc(e.gLow) * (0.25 if dark else 0.7)
	RenderingServer.global_shader_parameter_set("g_sky_top", Mats.v3(top))
	RenderingServer.global_shader_parameter_set("g_sky_hor", Mats.v3(U.hexc(e.fog)))
	RenderingServer.global_shader_parameter_set("g_sky_gnd", Mats.v3(gnd))
	grade_mat.set_shader_parameter("bloom_th", 0.78 if dark else 0.95)
	grade_mat.set_shader_parameter("bloom", 0.42 if dark else 0.24)
	var g: Dictionary = e.get("grade", {})
	var tint: Array = g.get("tint", [1, 1, 1])
	grade_mat.set_shader_parameter("tint", Vector3(tint[0], tint[1], tint[2]))
	grade_mat.set_shader_parameter("sat", g.get("sat", 1.1))
	grade_mat.set_shader_parameter("vig", g.get("vig", 0.34))
	ink_mat.set_shader_parameter("cloud", g.get("cloud", 0.3))
	ui.mini.car_col = U.css(car_cfg.color)
	ui.prev_map.car_col = U.css(car_cfg.color)


func place_car_at(i: int, back: int = 0) -> void:
	car.place(track, i, back)
	fx.last_wheel = [null, null]


# ================================================================== input

func _unhandled_input(ev: InputEvent) -> void:
	if (ev is InputEventJoypadButton or ev is InputEventJoypadMotion) and ui.handle_joypad_event(ev):
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventKey:
		var k = KEYMAP.get(ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
		if k != null:
			keys[k] = ev.pressed
			if state != "menu":
				get_viewport().set_input_as_handled()
		if not ev.pressed or ev.echo:
			return
		var code: int = ev.keycode
		if state == "menu":
			if code == KEY_ENTER or code == KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				start_race()
			return
		if code == KEY_BACKSPACE or code == KEY_DELETE:
			respawn()
		elif code == KEY_R or ((code == KEY_ENTER or code == KEY_KP_ENTER) and state != "paused"):
			if state != "paused":
				restart(true)
		elif code == KEY_ESCAPE or code == KEY_P:
			toggle_pause()


func _input(ev: InputEvent) -> void:
	# a real touch switches the race HUD to touch controls (like the web build's first pointerdown)
	if ev is InputEventScreenTouch and ev.pressed and not touch_ui:
		touch_ui = true
		ui.set_touch(true)
		if state != "menu" and state != "paused":
			ui.show_hud(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		keys.clear()
		release_all_touch()
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if state == "race" or state == "countdown":
			toggle_pause()


func sens_frac() -> float:
	return U.lerpf2(0.5, 0.2, U.clampf2(float(opts.sensV), 0.0, 100.0) / 100.0)


func steer_side(x: float) -> bool:
	return (x < ui.size.x * 0.5) != (opts.side == "right")


func steer_from_x(x: float) -> void:
	var half := ui.size.x / 2.0
	var c := half * 1.5 if opts.side == "right" else half * 0.5
	var r := half * sens_frac()
	ts.val = U.clampf2((x - c) / r, -1.0, 1.0)


func touch_down(id: int, x: float, pedal: String) -> void:
	if state == "menu":
		return
	if steer_side(x) and ts.steer_id < 0:
		ts.steer_id = id
		steer_from_x(x)
		ui.hide_tip("L")
	elif not steer_side(x):
		ts.pedal[id] = pedal
		sync_pedals()


func touch_move(id: int, x: float, pedal: String) -> void:
	if id == ts.steer_id:
		steer_from_x(x)
	elif ts.pedal.has(id):
		if ts.pedal[id] != pedal:
			ts.pedal[id] = pedal
			sync_pedals()


func touch_up(id: int) -> void:
	if id == ts.steer_id:
		ts.steer_id = -1
		ts.val = 0.0
	if ts.pedal.has(id):
		ts.pedal.erase(id)
		sync_pedals()


func sync_pedals() -> void:
	var g := false
	var b := false
	for p in ts.pedal.values():
		if p == "gas":
			g = true
		else:
			b = true
	if b and not ts.brake:
		haptic(12)
	elif g and not ts.gas:
		haptic(6)
	ts.gas = g
	ts.brake = b
	ui.sync_pedals(g, b)
	if g or b:
		ui.hide_tip("R")


func release_all_touch() -> void:
	ts.steer_id = -1
	ts.val = 0.0
	ts.pedal.clear()
	sync_pedals()


func haptic(ms: int) -> void:
	if is_touch:
		Input.vibrate_handheld(ms)


func read_input() -> Dictionary:
	var analog := false
	var gas: bool = keys.get("gas", false) or ts.gas
	var brake: bool = keys.get("brake", false) or ts.brake
	var drift: bool = keys.get("drift", false) or ts.brake
	var steer := (1.0 if keys.get("right", false) else 0.0) - (1.0 if keys.get("left", false) else 0.0)
	if ts.steer_id >= 0:
		var a := maxf(0.0, absf(ts.val) - 0.04) / 0.96
		steer = U.jsign(ts.val) * a
		analog = true
	var pads := Input.get_connected_joypads()
	var steer_strength := 0.15
	var pad_y := false
	var pad_st := false
	for pad in pads:
		var device := int(pad)
		var ax := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		if absf(ax) > steer_strength:
			steer = U.clampf2(ax, -1.0, 1.0)
			analog = true
			steer_strength = absf(ax)
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.3 or Input.is_joy_button_pressed(device, JOY_BUTTON_A):
			gas = true
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > 0.3 or Input.is_joy_button_pressed(device, JOY_BUTTON_B):
			brake = true
		if Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_SHOULDER) or Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER) or Input.is_joy_button_pressed(device, JOY_BUTTON_X):
			drift = true
		pad_y = pad_y or Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
		pad_st = pad_st or Input.is_joy_button_pressed(device, JOY_BUTTON_START)
	if pad_y and not pad_prev.y:
		respawn()
	if pad_st and not pad_prev.st:
		toggle_pause()
	pad_prev = {"y": pad_y, "st": pad_st}
	return {"gas": gas, "brake": brake, "drift": drift and DRIFT_ENABLED, "steer": steer, "analog": analog}


func joypad_gas_pressed() -> bool:
	for pad in Input.get_connected_joypads():
		var device := int(pad)
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.3 or Input.is_joy_button_pressed(device, JOY_BUTTON_A):
			return true
	return false


# ================================================================== race

static func crossed(prev: int, cur: int, target: int, N: int) -> bool:
	var d := cur - prev
	if d > N / 2:
		d -= N
	if d < -N / 2:
		d += N
	if d <= 0 or d > 30:
		return false
	var t := target - prev
	if t <= 0:
		t += N
	return t <= d


func collide(c: CarSim) -> void:
	var cs := World.OCS
	var cx := int(floor(c.x / cs))
	var cz := int(floor(c.z / cs))
	var t := track
	var bi := c.idx
	# guard rails on bridges and ramps
	if t.py[bi] > 0.3:
		var lim := U.HW - 1.15
		var lat := (c.x - t.px[bi]) * t.nx[bi] + (c.z - t.pz[bi]) * t.nz[bi]
		if absf(lat) > lim:
			var sg := U.jsign(lat)
			var push := lat - sg * lim
			c.x -= t.nx[bi] * push
			c.z -= t.nz[bi] * push
			var vn := (c.vx * t.nx[bi] + c.vz * t.nz[bi]) * sg
			if vn > 0.0:
				c.vx -= t.nx[bi] * sg * vn * 1.35
				c.vz -= t.nz[bi] * sg * vn * 1.35
				c.impact = maxf(c.impact, vn * 0.7)
				c.w *= 0.6
	if c.y < 1.5:
		for i in range(-1, 2):
			for j in range(-1, 2):
				var a = world.obs.get(U.grid_key(cx + i, cz + j))
				if a == null:
					continue
				for o in a:
					var dx: float = c.x - o.x
					var dz: float = c.z - o.y
					var d := U.hypot(dx, dz)
					var m: float = o.z + 1.25
					if d < m and d > 1e-4:
						var nx := dx / d
						var nz := dz / d
						c.x = o.x + nx * m
						c.z = o.y + nz * m
						var vn := c.vx * nx + c.vz * nz
						if vn < 0.0:
							c.vx -= 1.3 * vn * nx
							c.vz -= 1.3 * vn * nz
							c.vx *= 0.88
							c.vz *= 0.88
							c.w *= 0.5
							c.impact = maxf(c.impact, -vn)
							c.drift = false
	var b: Dictionary = world.bounds
	if c.x < b.x0 + 30.0 or c.x > b.x1 - 30.0 or c.z < b.z0 + 30.0 or c.z > b.z1 - 30.0:
		c.x = U.clampf2(c.x, b.x0 + 30.0, b.x1 - 30.0)
		c.z = U.clampf2(c.z, b.z0 + 30.0, b.z1 - 30.0)
		c.vx *= -0.4
		c.vz *= -0.4


func physics_step() -> void:
	var racing := state == "race"
	var inp: Dictionary = read_input() if racing else {"gas": false, "brake": state == "finished", "drift": false, "steer": 0.0, "analog": false}
	last_step_input = inp
	car.px = car.x
	car.pz = car.z
	car.ph = car.h
	car.step(U.STEP, inp, float(env.get("grip", 1.0)))
	collide(car)
	var prev := car.update_progress(track)
	car.in_water = env.get("shore", false) and not car.on_road and world.terrain_h(car.x, car.z, absf(car.lat)) < -0.4
	if not racing:
		return
	if race_steps % 6 == 0:
		ghost_rec.append(U.jround(car.x * 100.0) / 100.0)
		ghost_rec.append(U.jround(car.z * 100.0) / 100.0)
		ghost_rec.append(U.jround(car.h * 1000.0) / 1000.0)
	race_steps += 1
	if absf(car.lat) < U.HW + 6.0:
		var K := track.cps.size()
		var target: int = track.cps[next_cp] if next_cp < K else 0
		if crossed(prev, car.idx, target, track.n):
			var t := race_steps * U.STEP
			splits.append(t)
			snapshot = {"x": car.x, "z": car.z, "h": car.h, "vx": car.vx, "vz": car.vz, "idx": car.idx}
			var si := splits.size() - 1
			var ref = null
			if best != null and best.has("splits") and si < best.splits.size():
				ref = best.splits[si]
			ui.show_split(t - ref if ref != null else null, t)
			if next_cp < K:
				world.gates[next_cp].flash = 1.0
				next_cp += 1
				sfx.chime(true)
			else:
				lap += 1
				next_cp = 0
				if lap > U.LAPS:
					finish_race(t)
					return
				sfx.chime(false)
				ui.toast("Lap " + str(lap) + " / " + str(U.LAPS))


func restart(quick: bool) -> void:
	if track == null:
		return
	ui.hide_finish()
	ui.show_pause(false)
	place_car_at(0, 4)
	race_steps = 0
	lap = 1
	next_cp = 0
	splits = []
	ghost_rec = []
	snapshot = null
	finish_t = 0.0
	best = Store.get_value("best5." + track.seed, null)
	ghost_v.visible = false
	fx.clear_skids()
	for g in world.gates:
		g.flash = 0.0
	state = "countdown"
	cd_t = 1.5 if quick else 2.25
	cd_last = -1
	cd.gas = keys.get("gas", false) or ts.gas
	cd.blown = false
	cd.boost = false
	ui.clear_split()
	ui.hud_sync(true)


func start_race() -> void:
	sfx.init(opts.sound)
	set_menu(false)
	ui.show_hud(true)
	release_all_touch()
	DisplayServer.screen_set_keep_on(true)
	restart(false)


func respawn() -> void:
	if state != "race":
		return
	if snapshot != null:
		car.x = snapshot.x
		car.z = snapshot.z
		car.h = snapshot.h
		car.vx = snapshot.vx
		car.vz = snapshot.vz
		car.w = 0.0
		car.steer = 0.0
		car.drift = false
		car.level = 0
		car.hop_t = 0.0
		car.idx = snapshot.idx
		car.boost_t = 0.0
		car.px = car.x
		car.pz = car.z
		car.ph = car.h
		fx.last_wheel = [null, null]
		car.update_progress(track)
	else:
		restart(true)


func toggle_pause() -> void:
	if state == "race" or state == "countdown":
		release_all_touch()
		paused_from = state
		state = "paused"
		ui.show_pause(true, track.name + " · " + track.seed)
	elif state == "paused":
		resume()


func resume() -> void:
	ui.show_pause(false)
	state = paused_from


func to_menu() -> void:
	state = "menu"
	release_all_touch()
	DisplayServer.screen_set_keep_on(false)
	ui.show_pause(false)
	ui.hide_finish()
	ui.show_hud(false)
	set_menu(true)
	place_car_at(0, 4)
	ghost_v.visible = false
	fx.clear_skids()
	sfx.engine(0, 0, false, false)
	sfx.skid(0)
	ui.refresh_menu()


func finish_race(t: float) -> void:
	state = "finished"
	finish_t = t
	sfx.beep(990, 0.12, "triangle", 0.25)
	get_tree().create_timer(0.12).timeout.connect(func(): sfx.beep(1480, 0.3, "triangle", 0.22))
	var prev_best = best.t if best != null else null
	var is_pb: bool = prev_best == null or t < prev_best
	if is_pb:
		best = {"t": t, "splits": splits.duplicate(), "ghost": ghost_rec.duplicate()}
		Store.set_value("best5." + track.seed, best)
		for f in favs:
			if f.seed == track.seed:
				f.best = t
				Store.set_value("favs", favs)
	var seed_now := track.seed
	get_tree().create_timer(1.3).timeout.connect(func():
		if state != "finished" or track.seed != seed_now:
			return
		var m = CarSim.medal_for(t, track.medals)
		var dtxt := ""
		var dcol := Ui.FG
		if prev_best == null:
			dtxt = "First finish"
		else:
			dtxt = ("New best " if is_pb else "") + U.fmt_delta(t - prev_best)
			dcol = Ui.FAST if t < prev_best else Ui.SLOW
		ui.show_finish(track.name + " · " + track.seed, t, m, dtxt, dcol, minf(t, prev_best if prev_best != null else t)))


# ================================================================== menu actions (bound from the UI)

func set_menu(on: bool) -> void:
	ui.set_menu(on)


func set_tab(t: String) -> void:
	menu_tab = t
	ui.set_tab(t)
	cam_init = true


func is_fav() -> bool:
	if track == null:
		return false
	for f in favs:
		if f.seed == track.seed:
			return true
	return false


func toggle_fav() -> void:
	var idx := -1
	for i in favs.size():
		if favs[i].seed == track.seed:
			idx = i
	if idx >= 0:
		favs.remove_at(idx)
		ui.toast("Removed from saved")
	else:
		var b = Store.get_value("best5." + track.seed, null)
		favs.push_front({"seed": track.seed, "name": track.name, "env": track.env_key, "best": b.t if b != null else null, "medals": track.medals, "v": 5})
		ui.toast("Saved " + track.name)
	Store.set_value("favs", favs)
	ui.sync_icons()
	ui.render_favs()
	ui.relayout()


func remove_fav(seed: String) -> void:
	favs = favs.filter(func(x): return x.seed != seed)
	Store.set_value("favs", favs)
	ui.render_favs()
	ui.sync_icons()
	ui.relayout()


func load_fav(seed: String, env_key: String) -> void:
	with_loading(func(): load_track(seed, env_key))
	set_tab("track")


func with_loading(fn: Callable) -> void:
	ui.set_loading(true)
	await get_tree().create_timer(0.03).timeout
	await RenderingServer.frame_post_draw
	fn.call()
	await get_tree().process_frame
	ui.set_loading(false)


func new_random_track() -> void:
	with_loading(func():
		load_track(U.rand_seed_code())
		ui.toast("Destination: " + str(env.name)))


func next_track() -> void:
	ui.hide_finish()
	with_loading(func():
		load_track(U.rand_seed_code())
		restart(false)
		ui.toast("Destination: " + str(env.name)))


func submit_seed(v: String) -> void:
	if parse_seed(v) == null:
		ui.toast("Enter a seed first")
		return
	ui.seed_in.release_focus()
	ui.seed_in.text = ""
	with_loading(func():
		load_track(v)
		ui.toast("Loaded " + track.name))


func copy_seed() -> void:
	DisplayServer.clipboard_set(track.seed)
	ui.toast("Seed copied")


func toggle_sound() -> void:
	opts.sound = not opts.sound
	Store.set_value("opts", opts)
	ui.sync_opts()
	sfx.init(opts.sound)
	sfx.set_on(opts.sound)


func set_opt(k: String, v) -> void:
	opts[k] = v
	Store.set_value("opts", opts)
	ui.sync_opts()
	if k == "gfx":
		apply_gfx()


func set_sens(v: int) -> void:
	opts.sensV = v
	Store.set_value("opts", opts)
	ui.sync_opts()


func set_car_color(c: String) -> void:
	car_cfg.color = c
	save_car()


func set_finish(f: String) -> void:
	car_cfg.finish = f
	save_car()


func save_car() -> void:
	Store.set_value("car", car_cfg)
	car_v.apply_cfg(car_cfg.color, car_cfg.finish)
	ui.mini.car_col = U.css(car_cfg.color)
	ui.prev_map.car_col = U.css(car_cfg.color)
	ui.sync_car()


# ================================================================== frame

func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, 0.1)
	sim_t += dt
	RenderingServer.global_shader_parameter_set("g_time", sim_t)
	if track == null or world == null:
		return
	if state == "countdown":
		# start boost: first press of the gas inside the last third of a second before GO
		var g: bool = keys.get("gas", false) or ts.gas or joypad_gas_pressed()
		if g and not cd.gas:
			if cd_t <= 0.34:
				cd.boost = not cd.blown
			else:
				cd.blown = true
		cd.gas = g
		cd_t -= dt
		var n := int(ceil(cd_t / 0.75))
		if n != cd_last and cd_t > 0.0:
			cd_last = n
			ui.count_flash(str(n), false)
			sfx.beep(520, 0.14)
		if cd_t <= 0.0:
			state = "race"
			ui.count_flash("GO", true)
			sfx.beep(1040, 0.35, "square", 0.2)
			acc = 0.0
			if cd.boost:
				car.boost_t = 1.1
				car.turbo = 2
				ui.toast("Perfect start!")
	if state == "race" or state == "finished":
		acc += dt
		var n2 := 0
		while acc >= U.STEP and n2 < 20:
			physics_step()
			acc -= U.STEP
			n2 += 1
			if state != "race" and state != "finished":
				break
	else:
		car.px = car.x
		car.pz = car.z
		car.ph = car.h
		acc = 0.0
	var al := acc / U.STEP if (state == "race" or state == "finished") else 1.0
	var x := U.lerpf2(car.px, car.x, al)
	var z := U.lerpf2(car.pz, car.z, al)
	var h := car.ph + U.ang_diff(car.ph, car.h) * al
	var speed := U.hypot(car.vx, car.vz)
	_update_car_visuals(dt, x, z, h, speed)
	_update_ghost()
	_update_effects(dt, x, z, h, speed)
	# gates and living scenery
	var acc_col := U.css(env.accent)
	for k in world.gates.size():
		var g: Dictionary = world.gates[k]
		g.flash = maxf(0.0, g.flash - dt * 1.2)
		var is_next := state != "menu" and k == next_cp
		var op: float = 0.18 + ((0.32 + 0.18 * sin(sim_t * 6.0)) if is_next else 0.0) + g.flash * 0.6
		g.mat.set_shader_parameter("opacity", op)
		g.mat.set_shader_parameter("color", Mats.v3(U.hexc(0x5cf2a6) if g.flash > 0.0 else acc_col))
	world.cam_look = cam_look
	world.tick(dt, sim_t)
	_update_camera(dt, x, z, h, speed)
	world.update_weather(cam_look.x, cam_look.z)
	# audio
	var lin := last_step_input
	var active := state != "menu" and state != "paused"
	var gas_now: bool = lin.gas or (state == "countdown" and (keys.get("gas", false) or ts.gas))
	sfx.engine(speed, 1.0 if gas_now else 0.0, car.boost_t > 0.0, active)
	var slip := absf(car.vl)
	sfx.skid((U.clampf2((slip - 2.0) / 16.0, 0.05, 0.22) + (0.06 if car.drift else 0.0)) if (active and _skidding and car.on_road) else 0.0)
	var wind := 0.0
	if active:
		wind = U.clampf2(speed / 90.0, 0.0, 1.0) * 0.07 + (0.05 if env.weather == "rain" else 0.0) + (0.045 if (env.get("shore", false) and not env.get("lava", false)) else 0.0)
	sfx.wind(wind)
	if touch_ui and state != "menu":
		var tv: float = ts.val if ts.steer_id >= 0 else 0.0
		ts.disp += (tv - ts.disp) * (1.0 - exp(-dt * (30.0 if ts.steer_id >= 0 else 12.0)))
		if absf(ts.disp) < 0.002:
			ts.disp = 0.0
		ui.set_wheel(ts.disp, ts.steer_id >= 0)
	if state != "menu":
		ui.hud_sync(false)
		ui.mini.car_pos = Vector2(car.x, car.z)
		ui.mini.ghost_pos = mini_ghost
		ui.mini.queue_redraw()
	elif menu_tab != "garage":
		var i := int(floor(menu_s)) % track.n
		ui.prev_map.car_pos = Vector2(track.px[i], track.pz[i])
		ui.prev_map.queue_redraw()
	grade_mat.set_shader_parameter("time", sim_t)
	_perf_tick()


var _skidding := false


func _update_car_visuals(dt: float, x: float, z: float, h: float, speed: float) -> void:
	var hop := sin((1.0 - car.hop_t / 0.22) * PI) * 0.95 if car.hop_t > 0.0 else 0.0
	w_off = U.lerpf2(w_off, -0.38 if car.in_water else 0.0, 0.15)
	car_v.position = Vector3(x, car.y + w_off + hop, z)
	car_v.rotation.y = h
	car_v.rotation.x = U.lerpf2(car_v.rotation.x, -atan(car.slope), 0.3)
	var spin := car.vf * dt / 0.43
	for w in car_v.wheels:
		w.rotation.x += spin
	for f in car_v.fronts:
		f.rotation.y = -car.steer * 0.5 + (-car.drift_dir * 0.3 if car.drift else 0.0)
	var lat_a := car.w * car.vf
	var body := car_v.body
	body.rotation.z = U.lerpf2(body.rotation.z, U.clampf2(lat_a * 0.003 + car.vl * 0.006, -0.14, 0.14), 0.14)
	body.rotation.y = U.lerpf2(body.rotation.y, U.jsign(car.w) * 0.42 if car.drift else U.clampf2(-car.vl * 0.012, -0.12, 0.12), 0.16)
	body.scale.y = U.lerpf2(body.scale.y, 1.1 if car.hop_t > 0.12 else (0.9 if car.hop_t > 0.0 else 1.0), 0.35)
	var lin := last_step_input
	body.rotation.x = U.lerpf2(body.rotation.x, (0.035 if (lin.brake and not car.drift and car.vf > 2.0) else 0.0) - (0.025 if (lin.gas and speed < 40.0) else 0.0) - (0.03 if car.boost_t > 0.0 else 0.0), 0.12)
	var k := 1.0 if car.boost_t > 0.0 else (0.75 if (lin.gas and state != "menu") else 0.35)
	var ec := (U.hexc(0xffb35a) if car.boost_t > 0.0 else car_v.glow_col) * k
	ec.a = 1.0
	car_v.exhaust_m.set_shader_parameter("color", Mats.v3(ec))
	if car_v.ex_glow:
		car_v.ex_glow_m.set_shader_parameter("tint", Mats.v3(ec))
		var sc := (2.4 if car.boost_t > 0.0 else (1.4 if lin.gas else 0.9)) * (0.9 + randf() * 0.2)
		car_v.ex_glow_m.set_shader_parameter("size", sc)
	var L := 1.0 if env.get("dark", false) else 0.0
	car_v.tail_m.set_shader_parameter("color", Mats.v3(U.hexc(0xff2a2a if (lin.brake and state != "menu") else (0xd01818 if L > 0.3 else 0x7a0d0d))))
	car_v.headlight.visible = L > 0.0
	car_v.headlight.light_energy = 2.2 * L * PI
	car_v.lamp.visible = L > 0.0
	car_v.lamp.light_energy = 0.55 * L * PI
	car_v.beam.visible = L > 0.0
	car_v.beam.material_override.set_shader_parameter("opacity", 0.16 * L)
	car_v.underglow.visible = L > 0.5
	car_v.body_m.set_shader_parameter("emissive", Mats.v3(U.css(car_cfg.color) * (0.04 * L)))


func _update_ghost() -> void:
	if (state == "race" or state == "finished") and best != null and best.has("ghost") and best.ghost != null:
		var gt := race_steps * U.STEP * 20.0
		var i := int(floor(gt))
		var f := gt - i
		var G: Array = best.ghost
		var n := G.size() / 3
		if i < n - 1:
			ghost_v.visible = true
			var a := i * 3
			var b := a + 3
			var gx := U.lerpf2(G[a], G[b], f)
			var gz := U.lerpf2(G[a + 1], G[b + 1], f)
			var N := track.n
			var bi := ghost_idx
			var bd := 1e18
			for o in range(-20, 21):
				var kk := (ghost_idx + o + N) % N
				var d := pow(track.px[kk] - gx, 2.0) + pow(track.pz[kk] - gz, 2.0)
				if d < bd:
					bd = d
					bi = kk
			if bd > 900.0:
				var kk2 := 0
				while kk2 < N:
					var d2 := pow(track.px[kk2] - gx, 2.0) + pow(track.pz[kk2] - gz, 2.0)
					if d2 < bd:
						bd = d2
						bi = kk2
					kk2 += 2
			ghost_idx = bi
			ghost_v.position = Vector3(gx, track.py[ghost_idx], gz)
			ghost_v.rotation.y = G[a + 2] + U.ang_diff(G[a + 2], G[b + 2]) * f
			mini_ghost = Vector2(gx, gz)
		else:
			ghost_v.visible = false
			mini_ghost = null
	else:
		ghost_v.visible = false
		mini_ghost = null


func _update_effects(dt: float, x: float, z: float, h: float, speed: float) -> void:
	var lin := last_step_input
	var slip := absf(car.vl)
	var moving := state != "menu" and state != "countdown"
	_skidding = moving and speed > 6.0 and (slip > 3.2 or car.drift or (lin.brake and not car.drift and car.vf > 14.0) or (lin.gas and speed < 9.0 and race_steps < 120))
	var fxx := sin(h)
	var fzz := cos(h)
	var rxx := -fzz
	var rzz := fxx
	var snow: bool = env.weather == "snow"
	for w in 2:
		var s := 1.0 if w == 1 else -1.0
		var wx := x + rxx * s * 1.1 - fxx * 1.4
		var wz := z + rzz * s * 1.1 - fzz * 1.4
		if _skidding and car.on_road and car.hop_t <= 0.0:
			fx.lay_skid(w, wx, wz, car.y)
		else:
			fx.last_wheel[w] = null
		if moving and (_skidding or (not car.on_road and speed > 8.0)) and randf() < (0.55 if car.on_road else 0.4) + (0.3 if (snow and not car.on_road) else 0.0):
			fx.puff(wx, 0.4 + car.y, wz, -car.vx * 0.15, -car.vz * 0.15, 1.6 if car.on_road else 2.2, 1.1 if car.on_road else 0.9)
	# sparks while a mini-turbo charges, flame while boosting
	if moving and car.drift and car.level > 0:
		var pts: Array = []
		for j in 8:
			var s2 := 1.0 if j % 2 == 1 else -1.0
			pts.append(Vector3(x + rxx * s2 * 1.15 - fxx * 1.7 + (randf() - 0.5) * 0.8, 0.3 + randf() * 0.6 + car.y, z + rzz * s2 * 1.15 - fzz * 1.7 + (randf() - 0.5) * 0.8))
		fx.show_sparks(pts, U.hexc(TURBO_COL[car.level]), 1.2 + randf() * 1.3 + car.level * 0.35)
	elif moving and car.boost_t > 0.0:
		var pts2: Array = []
		for j in 8:
			var s3 := 0.45 if j % 2 == 1 else -0.45
			var b := 2.4 + randf() * 1.6
			pts2.append(Vector3(x + rxx * s3 - fxx * b, 0.6 + randf() * 0.3 + car.y, z + rzz * s3 - fzz * b))
		fx.show_sparks(pts2, U.hexc(0xff8a2a), 1.8 + randf() * 1.6)
	else:
		fx.hide_sparks()
	if car.level_up != 0:
		sfx.beep([0, 620, 830, 1100][car.level_up], 0.08, "triangle", 0.14)
		car.level_up = 0
	if car.turbo != 0:
		sfx.whoosh()
		haptic(18)
		ui.boost_fx(U.hexc(TURBO_COL[car.turbo]))
		car.turbo = 0
	if car.boost_t > 0.0 and moving and randf() < 0.5:
		fx.puff(x - fxx * 2.6, 0.6 + car.y, z - fzz * 2.6, -car.vx * 0.3, -car.vz * 0.3, 1.1, 0.45)
	var smoke := U.hexc(env.smoke)
	var sc := smoke if car.on_road else U.hexc(env.gLow).lerp(smoke, 0.4)
	if car.in_water:
		sc = U.hexc(0xff9a4a if env.get("lava", false) else 0xeafcff)
	fx.set_smoke_color(sc)
	if car.in_water and speed > 2.0 and randf() < 0.5:
		fx.puff(x + (randf() - 0.5) * 3.0, 0.2, z + (randf() - 0.5) * 3.0, -car.vx * 0.2, -car.vz * 0.2, 2.4, 0.7)
	# splashes: a burst on entry, then a wake of spray from the wheels and rings on the surface
	var lava: bool = env.get("lava", false)
	var wc := U.hexc(0xffa040 if lava else (0x9fb4cc if env.get("dark", false) else 0xeef8ff))
	var wl := -0.48
	if moving and car.in_water and not was_wet:
		for k in 70:
			var a := randf() * TAU
			var r := 1.0 + randf() * 2.0
			var up := 5.0 + randf() * 8.0
			fx.spray(x + cos(a) * r, wl + 0.3, z + sin(a) * r, cos(a) * (2.0 + randf() * 5.0) + car.vx * 0.25, up, sin(a) * (2.0 + randf() * 5.0) + car.vz * 0.25, 1.3 + randf() * 1.1, 1.0 + randf() * 0.5, wc, wl)
		world.add_ripple(x, z, sim_t)
		sfx.splash(U.clampf2(speed / 40.0, 0.3, 1.0))
		haptic(25)
	if moving and car.in_water and speed > 2.0:
		var n := minf(10.0, 2.0 + speed * 0.16)
		var k2 := 0
		while k2 < n:
			var sd := -1.0 if randf() < 0.5 else 1.0
			var fw := 1.5 if randf() < 0.5 else -1.4
			var wx2 := x + rxx * sd * 1.25 + fxx * fw
			var wz2 := z + rzz * sd * 1.25 + fzz * fw
			var out := 1.5 + randf() * 3.5
			fx.spray(wx2, wl + 0.2, wz2, rxx * sd * out - car.vx * 0.12, 2.5 + randf() * 4.0 + speed * 0.06, rzz * sd * out - car.vz * 0.12, 0.9 + randf() * 0.8, 0.65 + randf() * 0.4, wc, wl)
			k2 += 1
		rip_t -= dt
		if rip_t <= 0.0:
			world.add_ripple(x, z, sim_t)
			rip_t = maxf(0.12, 0.5 - speed * 0.012)
	was_wet = moving and car.in_water
	# crash debris: sparks and chips fly from the point of impact
	if car.impact > 4.0:
		var n2 := minf(36.0, 8.0 + car.impact * 1.2)
		var hx := x + fxx * 2.4
		var hz := z + fzz * 2.4
		var fy := car.y
		var k3 := 0
		while k3 < n2:
			var a := randf() * TAU
			var sp := 3.0 + randf() * 7.0
			fx.spray(hx, fy + 0.6, hz, cos(a) * sp, 2.0 + randf() * 6.0, sin(a) * sp, 0.35 + randf() * 0.45, 0.35 + randf() * 0.4, U.hexc(0xffd27a if k3 % 3 != 0 else 0xff8a3a), fy)
			if k3 % 4 == 0:
				fx.spray(hx, fy + 0.6, hz, cos(a) * sp * 0.6, 3.0 + randf() * 4.0, sin(a) * sp * 0.6, 0.5, 0.7, smoke, fy)
			k3 += 1
	fx.update_smoke(dt)
	fx.update_spray(dt)
	if car.impact > 4.0:
		shake = minf(1.2, car.impact / 25.0)
		sfx.thud(car.impact / 30.0)
		haptic(30)
	car.impact = 0.0


func _update_camera(dt: float, x: float, z: float, h: float, speed: float) -> void:
	var k := 1.0 - exp(-dt * 2.8)
	var W := ui.size.x
	var H := ui.size.y
	if state == "menu":
		if menu_tab == "garage":
			var a := sim_t * 0.35
			var rad := 8.5 if H > W else 9.0
			var tp := Vector3(x + sin(a) * rad, 4.2, z + cos(a) * rad)
			cam_pos = cam_pos.lerp(tp, k * 1.5 if cam_init else 1.0)
			cam_look = cam_look.lerp(Vector3(x, 0.8, z), k * 1.5 if cam_init else 1.0)
		else:
			menu_s = fmod(fmod(menu_s + dt * 14.0 / U.DS, track.n) + track.n, track.n)
			var i := int(floor(menu_s))
			var cx: float = track.px[i]
			var cz: float = track.pz[i]
			var a2 := sim_t * 0.05
			var tp2 := Vector3(cx - sin(a2) * 140.0, 150.0, cz - cos(a2) * 140.0)
			cam_pos = cam_pos.lerp(tp2, k if cam_init else 1.0)
			cam_look = cam_look.lerp(Vector3(cx, 0, cz), k if cam_init else 1.0)
		cam_init = true
	else:
		# fixed-orientation tilted camera that leads the car in the direction it is travelling
		var port := H > W
		var ht := (150.0 if port else 116.0) + speed * 0.55
		var back := ht * 0.78
		var k2 := 0.95 if port else 1.05
		var lx := x + U.clampf2(car.vx * k2 * (0.8 if port else 1.0), -58.0, 58.0)
		var lz := z + U.clampf2(car.vz * k2, -58.0, 58.0) + (8.0 if port else 4.0)
		var look := Vector3(lx, 0, lz)
		var pos := Vector3(lx, ht, lz - back)
		var kk := 1.0 if state == "countdown" else 1.0 - exp(-dt * 3.2)
		cam_pos = cam_pos.lerp(pos, kk)
		cam_look = cam_look.lerp(look, kk)
	if not is_finite(cam_pos.x + cam_pos.z + cam_look.x + cam_look.z):
		cam_pos = Vector3(x, 120, z - 60)
		cam_look = Vector3(x, 0, z)
	var p := cam_pos
	if shake > 0.0:
		shake = maxf(0.0, shake - dt * 3.0)
		p.x += (randf() - 0.5) * shake * 2.0
		p.z += (randf() - 0.5) * shake * 2.0
	cam.look_at_from_position(p, cam_look, Vector3.UP)
	var cdist := cam_pos.distance_to(cam_look)
	var fn: float = cdist + float(env.fogNear) - 70.0
	var ff: float = cdist + float(env.fogFar) - 40.0
	RenderingServer.global_shader_parameter_set("g_fog", Vector2(fn, ff))
	ink_mat.set_shader_parameter("fogr", Vector2(fn, ff))
	var fov := 46.0 + (7.0 if (car.boost_t > 0.0 and state != "menu") else 0.0) + U.clampf2((speed - 42.0) / 30.0, 0.0, 1.0) * 4.0
	cam_fov = U.lerpf2(cam_fov, fov, 0.08)
	cam.fov = cam_fov
	# keep the menu's subject clear of the sheet (setViewOffset in the web build)
	if state == "menu":
		var r := ui.sheet_rect()
		var ox := 0.0
		var oy := 0.0
		if r.position.x < 8.0 and r.size.x > W * 0.8:
			oy = maxf(0.0, H - r.position.y) / 2.0
		else:
			ox = -minf(r.position.x + r.size.x, W * 0.6) / 2.0
		var px_to_m := 2.0 * cdist * tan(deg_to_rad(cam_fov) / 2.0) / maxf(H, 1.0)
		cam.h_offset = ox * px_to_m
		cam.v_offset = -oy * px_to_m
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0


# ================================================================== frame-rate readout and adaptive resolution

func _perf_tick() -> void:
	perf.frames += 1
	var now := Time.get_ticks_msec()
	if perf.last == 0:
		perf.last = now
	var el: int = now - perf.last
	if el < 1000:
		return
	perf.fps = perf.frames * 1000.0 / el
	perf.frames = 0
	perf.last = now
	var ch := 0.0
	if perf.fps < 48.0 and perf.scale > perf.min + 1e-3:
		ch = -0.08
	elif perf.fps > 57.0 and perf.scale < perf.max - 1e-3:
		ch = 0.04
	if ch != 0.0:
		perf.scale = U.clampf2(perf.scale + ch, perf.min, perf.max)
		_apply_resolution()
	if str(opts.stats) != "":
		ui.set_stats(str(int(round(perf.fps))) + " fps · " + str(int(round(perf.scale / perf.max * 100.0))) + "%")
