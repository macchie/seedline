class_name World
extends Node3D
## Everything around the track (port of buildWorld): terrain, water and lava, road ribbons, kerbs, start arch,
## checkpoint gates, bridges, scenery props, trackside furniture, rising smoke and weather.
## Placement uses the same seeded random stream as the web build, so a seed builds the same place.

const CS := 20          # track lookup grid cell (m)
const OCS := 16         # obstacle grid cell (m)
const HW := U.HW
const WHITE := Color(1, 1, 1)

var t: TrackData
var e: Dictionary
var rng: SeedRng
var noise: ValueNoise
var is_touch := false
var prop_density := 1.0     # quality tier: scales scattered scenery counts (set before build())
var weather_density := 1.0  # quality tier: scales weather particle count (set before build())

var grid := {}          # cell key -> PackedInt32Array of sample indices
var obs := {}           # cell key -> Array of Vector3(x, z, r)
var bounds := {}
var last_i := -1        # distToTrack.i
var river_d := 1e9      # side result of terrain_h: metres outside the nearest river or lake

var anims: Array = []   # Callable(dt, tt)
var emitters: Array = []
var pads: Array = []    # {node, x, z, big, r, cd}
var gates: Array = []   # {mesh, mat, flash, k}
var water_mats: Array = []
var ripples := PackedVector3Array()
var rip_i := 0
var lakes := PackedFloat64Array()   # stride 5: x, z, radius, phase a, phase b
var _tstep := 8.0
var cam_look := Vector3.ZERO
var weather_mat: ShaderMaterial = null
var amb := {}           # rising smoke particle state

var _dist_cache := {}


class D:
	## three.js Object3D stand-in used to compose instance matrices (XYZ euler order, like three).
	var position := Vector3.ZERO
	var rotation := Vector3.ZERO
	var scale := Vector3.ONE

	func reset() -> void:
		position = Vector3.ZERO
		rotation = Vector3.ZERO
		scale = Vector3.ONE

	func scalar(s: float) -> void:
		scale = Vector3(s, s, s)

	func xf() -> Transform3D:
		return Transform3D(Basis.from_euler(rotation, EULER_ORDER_XYZ) * Basis.from_scale(scale), position)


# ------------------------------------------------------------------ lookups

func _build_grid() -> void:
	var tmp := {}
	for i in t.n:
		var key := U.grid_key(int(floor(t.px[i] / CS)), int(floor(t.pz[i] / CS)))
		if not tmp.has(key):
			tmp[key] = []
		tmp[key].append(i)
	grid = {}
	for key in tmp:
		grid[key] = PackedInt32Array(tmp[key])


## Distance to the nearest track sample (capped); the sample index is left in last_i
func dist_to_track(x: float, z: float, cap: float) -> float:
	var r := int(ceil(cap / CS))
	var cx := int(floor(x / CS))
	var cz := int(floor(z / CS))
	var best := cap * cap
	var bi := -1
	var px := t.px
	var pz := t.pz
	for i in range(-r, r + 1):
		for j in range(-r, r + 1):
			var a = grid.get(U.grid_key(cx + i, cz + j))
			if a == null:
				continue
			for s in a:
				var dx: float = px[s] - x
				var dz: float = pz[s] - z
				var d := dx * dx + dz * dz
				if d < best:
					best = d
					bi = s
	last_i = bi
	return sqrt(best)


## Distance from (x, z) to road samples far along the lap from sample k (the other road at a crossing)
func other_road_dist(x: float, z: float, k: int) -> float:
	var cx := int(floor(x / CS))
	var cz := int(floor(z / CS))
	var N := t.n
	var best := 1e9
	for i in range(-1, 2):
		for j in range(-1, 2):
			var a = grid.get(U.grid_key(cx + i, cz + j))
			if a == null:
				continue
			for s in a:
				if U.cdist(s, k, N) < 40:
					continue
				var d := U.hypot(t.px[s] - x, t.pz[s] - z)
				if d < best:
					best = d
	return best


func add_obstacle(x: float, z: float, r: float) -> void:
	var key := U.grid_key(int(floor(x / OCS)), int(floor(z / OCS)))
	if not obs.has(key):
		obs[key] = []
	obs[key].append(Vector3(x, z, r))


## River segments bucketed by cell, each cell listing the segments within reach (water width + 9 m).
var _rgrid := {}
const RCS := 16.0


func _build_river_grid() -> void:
	_rgrid = {}
	if t.river == null:
		return
	var rx: PackedFloat64Array = t.river.x
	var ry: PackedFloat64Array = t.river.y
	var reach: float = float(t.river.w) + 9.5
	var tmp := {}
	for k in rx.size() - 1:
		var x0 := minf(rx[k], rx[k + 1]) - reach
		var x1 := maxf(rx[k], rx[k + 1]) + reach
		var z0 := minf(ry[k], ry[k + 1]) - reach
		var z1 := maxf(ry[k], ry[k + 1]) + reach
		for cx in range(int(floor(x0 / RCS)), int(floor(x1 / RCS)) + 1):
			for cz in range(int(floor(z0 / RCS)), int(floor(z1 / RCS)) + 1):
				var key := U.grid_key(cx, cz)
				if not tmp.has(key):
					tmp[key] = []
				tmp[key].append(k)
	for key in tmp:
		_rgrid[key] = PackedInt32Array(tmp[key])


## Distance to the river polyline (exact below water width + 9 m, otherwise a large value). Thread-safe.
func _river_dist(x: float, z: float) -> float:
	var segs = _rgrid.get(U.grid_key(int(floor(x / RCS)), int(floor(z / RCS))))
	if segs == null:
		return 1e9
	var rx: PackedFloat64Array = t.river.x
	var ry: PackedFloat64Array = t.river.y
	var best := 1e18
	for k in segs:
		var ax := rx[k]
		var az := ry[k]
		var dx := rx[k + 1] - ax
		var dz := ry[k + 1] - az
		var L2 := dx * dx + dz * dz
		if L2 == 0.0:
			L2 = 1.0
		var u := U.clampf2(((x - ax) * dx + (z - az) * dz) / L2, 0.0, 1.0)
		var ex := ax + dx * u - x
		var ez := az + dz * u - z
		var d := ex * ex + ez * ez
		if d < best:
			best = d
	return sqrt(best)


## Nearest river point as (distance, tangent x, tangent z); distance is 1e9 when out of reach. Thread-safe.
func _river_near(x: float, z: float) -> Vector3:
	var segs = _rgrid.get(U.grid_key(int(floor(x / RCS)), int(floor(z / RCS))))
	if segs == null:
		return Vector3(1e9, 0.0, 0.0)
	var rx: PackedFloat64Array = t.river.x
	var ry: PackedFloat64Array = t.river.y
	var best := 1e18
	var bt := Vector2.ZERO
	for k in segs:
		var ax := rx[k]
		var az := ry[k]
		var dx := rx[k + 1] - ax
		var dz := ry[k + 1] - az
		var L2 := dx * dx + dz * dz
		if L2 == 0.0:
			L2 = 1.0
		var u := U.clampf2(((x - ax) * dx + (z - az) * dz) / L2, 0.0, 1.0)
		var ex := ax + dx * u - x
		var ez := az + dz * u - z
		var d := ex * ex + ez * ez
		if d < best:
			best = d
			bt = Vector2(dx, dz) / sqrt(L2)
	return Vector3(sqrt(best), bt.x, bt.y)


## Irregular lakes, preferably touching the river so the two merge into one body of water.
func _build_lakes() -> void:
	lakes = PackedFloat64Array()
	if e.get("shore", false) or not e.get("river", false) or float(e.get("amp", 0.0)) == 0.0:
		return
	var lr := SeedRng.from_seed(t.seed + "#lakes")
	var want := 1 + (1 if lr.next() < 0.45 else 0)
	for tries in 50:
		if lakes.size() >= want * 5:
			break
		var r := 36.0 + lr.next() * 64.0
		var x: float
		var z: float
		if t.river != null and lr.next() < 0.7:
			var rx: PackedFloat64Array = t.river.x
			var ry: PackedFloat64Array = t.river.y
			var k := mini(rx.size() - 2, int(lr.next() * (rx.size() - 1)))
			var dx := rx[k + 1] - rx[k]
			var dz := ry[k + 1] - ry[k]
			var L := maxf(U.hypot(dx, dz), 0.001)
			var side := 1.0 if lr.next() < 0.5 else -1.0
			var off := float(t.river.w) + r * (0.3 + lr.next() * 0.35)
			x = rx[k] - dz / L * off * side
			z = ry[k] + dx / L * off * side
		else:
			x = U.lerpf2(bounds.x0 + r, bounds.x1 - r, lr.next())
			z = U.lerpf2(bounds.z0 + r, bounds.z1 - r, lr.next())
		if x < bounds.x0 + r or x > bounds.x1 - r or z < bounds.z0 + r or z > bounds.z1 - r:
			continue
		var need := r * 1.36 + 26.0
		if dist_to_track(x, z, need + 4.0) < need:
			continue
		lakes.append_array([x, z, r, lr.next() * U.TAU, lr.next() * U.TAU])


## Metres outside the nearest lake shore (negative inside) and the normalised radius of that lake.
func _lake_sd(x: float, z: float) -> Vector2:
	var best := Vector2(1e9, 2.0)
	for i in range(0, lakes.size(), 5):
		var dx := x - lakes[i]
		var dz := z - lakes[i + 1]
		var dist := sqrt(dx * dx + dz * dz)
		if dist > lakes[i + 2] * 1.4 + 9.0:
			continue
		var a := atan2(dz, dx)
		var rr: float = lakes[i + 2] * (1.0 + 0.22 * sin(3.0 * a + lakes[i + 3]) + 0.12 * sin(5.0 * a + lakes[i + 4]))
		var sd := dist - rr
		if sd < best.x:
			best = Vector2(sd, dist / rr)
	return best


## True when (x, z) is within margin metres of a river or lake.
func water_near(x: float, z: float, margin: float) -> bool:
	if t.river != null and _river_dist(x, z) < float(t.river.w) + margin:
		return true
	return lakes.size() > 0 and _lake_sd(x, z).x < margin


func terrain_base(x: float, z: float, d: float) -> float:
	if e.get("shore", false):
		var lava: bool = e.get("lava", false)
		var shore := HW + (34.0 if lava else 12.0) + noise.noise(x * 0.008 + 5.0, z * 0.008 - 3.0, 3) * (120.0 if lava else 62.0)
		if d < shore:
			var m := U.clampf2((d - HW - 8.0) / 18.0, 0.0, 1.0) * U.clampf2((shore - d) / 14.0, 0.0, 1.0)
			return -0.12 + maxf(0.0, noise.noise(x * 0.02, z * 0.02, 3) - (0.42 if lava else 0.48)) * (30.0 if lava else 18.0) * m
		return -0.12 - minf(7.0, (d - shore) * 0.3)
	var amp: float = e.get("amp", 0.0)
	if amp == 0.0:
		return -0.12
	var m2 := U.clampf2((d - HW - 14.0) / 45.0, 0.0, 1.0)
	var mm := m2 * m2 * (3.0 - 2.0 * m2)
	var n := noise.noise(x * 0.0065, z * 0.0065, 4)
	var h := maxf(0.0, n - 0.36) / 0.64 * amp
	if e.get("terrace", false):
		h = floor(h / 6.0) * 6.0 + maxf(0.0, fmod(h, 6.0) - 4.4) / 1.6 * 6.0
	return -0.12 + (h + (noise.noise(x * 0.03, z * 0.03, 2) - 0.5) * 2.4) * mm


## Ground height; [h, riverD] so worker threads need no shared state
func terrain_hr(x: float, z: float, d: float) -> Vector2:
	var h := terrain_base(x, z, d)
	var sd := 1e9
	if t.river != null:
		var w: float = t.river.w
		var rd := _river_dist(x, z)
		sd = rd - w
		if rd < w + 8.0:
			var bed := -0.6 - 2.4 * maxf(0.0, 1.0 - pow(rd / w, 2.0))
			if rd < w:
				h = minf(h, bed)
			else:
				h = minf(h, U.lerpf2(-0.6, h, U.smooth01((rd - w) / 8.0)))
	if lakes.size() > 0:
		var lk := _lake_sd(x, z)
		if lk.x < 8.0:
			if lk.x < 0.0:
				h = minf(h, -0.6 - 3.2 * (1.0 - lk.y * lk.y))
			else:
				h = minf(h, U.lerpf2(-0.6, h, U.smooth01(lk.x / 8.0)))
			sd = minf(sd, lk.x)
	return Vector2(h, sd)


func terrain_h(x: float, z: float, d: float) -> float:
	var r := terrain_hr(x, z, d)
	river_d = r.y
	return r.x


## Exact capped distance-to-track for every vertex of a regular grid, computed by stamping each track sample
## onto the grid (same result as calling dist_to_track per vertex, but much faster). Bands run in parallel.
func dist_field(x0: float, z0: float, step: float, nx: int, nz: int, cap: float) -> PackedFloat32Array:
	var bands := mini(16, nz)
	var per := int(ceil(float(nz) / bands))
	var res := []
	res.resize(bands)
	var job := func(b: int) -> void:
		var r0 := b * per
		var r1 := mini(nz, r0 + per)
		if r1 <= r0:
			res[b] = PackedFloat32Array()
			return
		var cnt := (r1 - r0) * nx
		var best := PackedFloat64Array()
		best.resize(cnt)
		best.fill(cap * cap)
		var zlo := z0 + r0 * step - cap
		var zhi := z0 + (r1 - 1) * step + cap
		var reach := int(ceil(cap / step)) + 1
		for s in t.n:
			var sz: float = t.pz[s]
			if sz < zlo or sz > zhi:
				continue
			var sx: float = t.px[s]
			var ix0 := maxi(0, int(floor((sx - x0) / step)) - reach)
			var ix1 := mini(nx - 1, int(floor((sx - x0) / step)) + reach)
			var iz0 := maxi(r0, int(floor((sz - z0) / step)) - reach)
			var iz1 := mini(r1 - 1, int(floor((sz - z0) / step)) + reach)
			for iz in range(iz0, iz1 + 1):
				var dz := sz - (z0 + iz * step)
				var dz2 := dz * dz
				var row := (iz - r0) * nx
				for ix in range(ix0, ix1 + 1):
					var dx := sx - (x0 + ix * step)
					var d := dx * dx + dz2
					if d < best[row + ix]:
						best[row + ix] = d
		var out := PackedFloat32Array()
		out.resize(cnt)
		for i in cnt:
			out[i] = sqrt(best[i])
		res[b] = out
	_run_parallel(job, bands)
	var all := PackedFloat32Array()
	for b in bands:
		all.append_array(res[b])
	return all


func _run_parallel(job: Callable, count: int) -> void:
	if OS.has_feature("threads") and count > 1:
		var id := WorkerThreadPool.add_group_task(job, count, -1, true, "seedline world")
		WorkerThreadPool.wait_for_group_task_completion(id)
	else:
		for i in count:
			job.call(i)


# ------------------------------------------------------------------ scene helpers

func add(n: Node3D) -> Node3D:
	add_child(n)
	return n


func node() -> Node3D:
	var n := Node3D.new()
	n.rotation_order = EULER_ORDER_XYZ
	return n


func mesh_node(mesh: Mesh, mat, cast := false) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.rotation_order = EULER_ORDER_XYZ
	m.mesh = mesh
	_apply_mats(m, mesh, mat)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


func _apply_mats(gi: GeometryInstance3D, mesh: Mesh, mat) -> void:
	if mat is Array:
		for s in mesh.get_surface_count():
			mesh.surface_set_material(s, mat[s])
	else:
		gi.material_override = mat


## InstancedMesh port: setup(p, d, i) fills the dummy and may return an instance colour.
func inst(geo, mat, list: Array, setup: Callable, shadow := true, parent: Node3D = null) -> MultiMeshInstance3D:
	if list.is_empty():
		return null
	var mesh: Mesh = geo.to_mesh() if geo is Geo else geo
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = list.size()
	var d := D.new()
	for i in list.size():
		d.reset()
		var c = setup.call(list[i], d, i)
		mm.set_instance_transform(i, d.xf())
		mm.set_instance_color(i, c if c is Color else WHITE)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	_apply_mats(mi, mesh, mat)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(mi)
	return mi


## Camera-facing glow sprites (three.js Points). size in PointsMaterial pixels-at-unit-depth.
func sprites(pos: PackedVector3Array, cols, size: float, mat_opts: Dictionary) -> MultiMeshInstance3D:
	if pos.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _quad()
	mm.instance_count = pos.size()
	for i in pos.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos[i]))
		mm.set_instance_color(i, cols[i] if cols != null else WHITE)
	var o := mat_opts.duplicate()
	o["size"] = Mats.points_size(size)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Mats.sprites(o)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


static var _quad_mesh: ArrayMesh = null


static func _quad() -> ArrayMesh:
	if _quad_mesh == null:
		var g := Geo.plane(1, 1)
		_quad_mesh = g.to_mesh()
	return _quad_mesh


## Flat strip following the track between lateral offsets o0..o1 (float or Callable(i))
func ribbon(o0, o1, y: float, v_scale: float, mat, from := 0, to := -1, cast := false) -> MeshInstance3D:
	if to < 0:
		to = t.n
	var g := Geo.new()
	var cnt := to - from + 1
	for n in cnt:
		var i := (from + n) % t.n
		var a: float = o0.call(i) if o0 is Callable else o0
		var b: float = o1.call(i) if o1 is Callable else o1
		var yy: float = y + t.py[i]
		g.pos.append(Vector3(t.px[i] + t.nx[i] * a, yy, t.pz[i] + t.nz[i] * a))
		g.pos.append(Vector3(t.px[i] + t.nx[i] * b, yy, t.pz[i] + t.nz[i] * b))
		var v := (from + n) * U.DS / v_scale
		g.uv.append(Vector2(0, v))
		g.uv.append(Vector2(1, v))
		g.nrm.append(Vector3.UP)
		g.nrm.append(Vector3.UP)
		if n < cnt - 1:
			var q := n * 2
			g.idx.append_array([q, q + 1, q + 2, q + 1, q + 3, q + 2])
	var m := mesh_node(g.to_mesh(), mat, cast)
	add_child(m)
	return m


func emit(x: float, y: float, z: float, rate: float, size: float, color: int, life: float = 4.0) -> void:
	emitters.append({"x": x, "y": y, "z": z, "rate": rate, "size": size, "color": U.hexc(color), "life": life, "acc": randf()})


func place_around(count: int, min_d: float, max_d: float, far_frac: float = 0.28) -> Array:
	count = maxi(0, int(round(count * prop_density)))
	var out: Array = []
	var tries := count * 8
	var shore: bool = e.get("shore", false)
	while out.size() < count and tries > 0:
		tries -= 1
		var x: float
		var z: float
		var i0 := int(floor(rng.next() * t.n))
		if rng.next() > far_frac:
			var i := i0
			var s := -1.0 if rng.next() < 0.5 else 1.0
			var off := min_d + pow(rng.next(), 1.7) * (max_d - min_d)
			x = t.px[i] + t.nx[i] * off * s + (rng.next() - 0.5) * 6.0
			z = t.pz[i] + t.nz[i] * off * s + (rng.next() - 0.5) * 6.0
		else:
			x = U.lerpf2(bounds.x0 + 20.0, bounds.x1 - 20.0, rng.next())
			z = U.lerpf2(bounds.z0 + 20.0, bounds.z1 - 20.0, rng.next())
		var d := dist_to_track(x, z, 110.0 if shore else maxf(min_d + 40.0, max_d + 10.0))
		if d < min_d:
			continue
		if water_near(x, z, 5.0):
			continue
		var ii := last_i if last_i >= 0 else i0
		var y := terrain_h(x, z, d)
		var r := rng.next()
		var s2 := rng.next()
		var a := rng.next() * U.TAU
		out.append({"x": x, "z": z, "d": d, "i": ii, "y": y, "r": r, "s": s2, "a": a})
	return out


# ------------------------------------------------------------------ build

func build(track: TrackData, env: Dictionary, touch: bool) -> void:
	t = track
	e = env
	is_touch = touch
	rng = SeedRng.from_seed(t.seed + "#world")
	noise = ValueNoise.new(rng)
	anims = []
	emitters = []
	gates = []
	water_mats = []
	obs = {}
	ripples = PackedVector3Array()
	for i in 8:
		ripples.append(Vector3(0, 0, -99))
	_build_grid()
	_build_river_grid()
	var x0 := 1e9
	var x1 := -1e9
	var z0 := 1e9
	var z1 := -1e9
	for i in t.n:
		x0 = minf(x0, t.px[i])
		x1 = maxf(x1, t.px[i])
		z0 = minf(z0, t.pz[i])
		z1 = maxf(z1, t.pz[i])
	bounds = {"x0": x0 - 150.0, "x1": x1 + 150.0, "z0": z0 - 150.0, "z1": z1 + 150.0, "cx": (x0 + x1) / 2.0, "cz": (z0 + z1) / 2.0}
	_build_lakes()
	_build_terrain()
	_build_road()
	_build_start()
	_build_gates()
	_build_pads()
	_build_bridges()
	_build_water()
	var props := Props.new(self)
	props.build()
	_build_common()
	_build_ambient()
	_build_weather()


func _build_terrain() -> void:
	var S: float = maxf(bounds.x1 - bounds.x0, bounds.z1 - bounds.z0) + 40.0
	var amp: float = e.get("amp", 0.0)
	var shore: bool = e.get("shore", false)
	var lava: bool = e.get("lava", false)
	var seg := 190 if t.river != null else (130 if shore else 150) if amp != 0.0 else 2
	var vn := seg + 1
	var step := S / seg
	_tstep = step
	var gx0: float = bounds.cx - S / 2.0
	var gz0: float = bounds.cz - S / 2.0
	var cap := 110.0 if shore else 80.0
	var dist := PackedFloat32Array()
	if amp != 0.0:
		dist = dist_field(gx0, gz0, step, vn, vn, cap)
	var cL := U.hexc(e.gLow)
	var cH := U.hexc(e.gHigh)
	var deep := U.hexc(e.get("deep", 0))
	var field_pal: Array = []
	for c in [0x86b84c, 0x6c9e3c, 0xcdb350, 0xbb9a42, 0x5f9236, 0x9fbd58, 0x8c6a42, 0xafc35c]:
		field_pal.append(U.hexc(c))
	# shallow-water edge and shoreline blend colours; most worlds use white foam over beach sand,
	# stone cities (Venice) override them for a greyed quayside instead
	var foam := U.hexc(e.get("foamCol", 0xf4f1e6))
	var glow := U.hexc(0xd2501a)
	var sand := U.hexc(e.get("sandCol", 0xc2a878))
	var fields: bool = e.get("fields", false)
	var bands := mini(16, vn)
	var per := int(ceil(float(vn) / bands))
	var hs := []
	var cs := []
	hs.resize(bands)
	cs.resize(bands)
	var job := func(b: int) -> void:
		var r0 := b * per
		var r1 := mini(vn, r0 + per)
		var hh := PackedFloat32Array()
		var cc := PackedColorArray()
		if r1 <= r0:
			hs[b] = hh
			cs[b] = cc
			return
		for iz in range(r0, r1):
			for ix in vn:
				# PlaneGeometry vertex order: x = ix*step - S/2, z (after rotateX(-90)) = iy*step - S/2
				var x := gx0 + ix * step
				var z := gz0 + iz * step
				var d := dist[iz * vn + ix] if amp != 0.0 else 80.0
				var hr := terrain_hr(x, z, d)
				var h := hr.x
				var rd := hr.y
				hh.append(h)
				var nn := noise.noise(x * 0.03 + 40.0, z * 0.03, 2)
				var c: Color
				if lava:
					if h < -0.45:
						c = U.hexc(0x3a1206)
					else:
						c = cL.lerp(cH, U.clampf2(h / 9.0 + (nn - 0.5) * 0.6, 0.0, 1.0))
						if d > HW + 10.0:
							c = c.lerp(glow, U.clampf2(1.0 - (h + 0.12) / 0.9, 0.0, 1.0) * 0.75)
				elif shore:
					if h < -0.45:
						c = cL.lerp(deep, U.clampf2(-h / 5.5, 0.0, 1.0))
						if h > -1.1:
							c = c.lerp(foam, 0.55)
					else:
						c = cL.lerp(cH, U.clampf2((h - 0.25) / 1.2 + (nn - 0.5) * 0.6, 0.0, 1.0))
				elif e.get("salt", false):
					var salt_x := int(floor((x + nn * 5.0) / 18.0))
					var salt_z := int(floor((z + nn * 5.0) / 18.0))
					var cell := SeedRng.hash_str(str(salt_x) + "," + str(salt_z)) % 3
					var salt_v := clampf(nn * 0.45 + float(cell) * 0.18, 0.0, 1.0)
					c = cL.lerp(cH, salt_v)
				elif fields and d > HW + 12.0:
					var fx := int(floor((x + noise.noise(x * 0.01, z * 0.01, 2) * 30.0) / 46.0))
					var fz := int(floor((z + noise.noise(z * 0.01 + 9.0, x * 0.01, 2) * 30.0) / 46.0))
					c = U.offset_hsl(field_pal[SeedRng.hash_str(str(fx) + "," + str(fz)) % field_pal.size()], 0.0, 0.0, (nn - 0.5) * 0.07)
				else:
					var v := U.clampf2(h / (amp if amp != 0.0 else 1.0) * 1.1 + (noise.noise(x * 0.02 + 40.0, z * 0.02, 2) - 0.5) * 0.5, 0.0, 1.0)
					c = cL.lerp(cH, v)
				if rd < 9.0:
					c = c.lerp(sand, U.clampf2(1.0 - rd / 9.0, 0.0, 1.0) * 0.8)
				if h < -0.35 and not shore:
					c = c.lerp(sand.darkened(0.4), U.clampf2((-0.35 - h) / 1.6, 0.0, 1.0))
				cc.append(c)
		hs[b] = hh
		cs[b] = cc
	_run_parallel(job, bands)
	var g := Geo.plane(S, S, seg, seg)
	g.rotate_x(-PI / 2.0)
	g.translate(bounds.cx, 0.0, bounds.cz)
	var k := 0
	for b in bands:
		var hh: PackedFloat32Array = hs[b]
		var cc: PackedColorArray = cs[b]
		for j in hh.size():
			var p := g.pos[k]
			p.y = hh[j]
			g.pos[k] = p
			g.col.append(cc[j])
			k += 1
	g.compute_normals()
	var night: bool = e.get("night", false)
	var rep := S / (20.0 if night else 24.0)
	var opts := {"map": Tex.ground(e), "uv_scale": Vector2(rep, rep)}
	if night:
		opts["emissive"] = 0xffffff
		opts["emissive_i"] = 0.5
		opts["emissive_map"] = true
	add_child(mesh_node(g.to_mesh(), Mats.toon(opts)))
	if shore:
		if lava:
			var WS := S * 3.0
			var lg := Geo.plane(WS, WS)
			lg.rotate_x(-PI / 2.0)
			var lm := ShaderMaterial.new()
			lm.shader = Mats.shader("lava")
			lm.set_shader_parameter("noise_tex", Tex.noise())
			var liq := mesh_node(lg.to_mesh(), lm)
			liq.position = Vector3(bounds.cx, -0.6, bounds.cz)
			add_child(liq)


# Per-environment water look: sea palette [shallow, deep], glint strength and wave choppiness.
const WATER_LOOK := {
	"ISLAND": {"sea": [0x4de6d0, 0x07668a], "shimmer": 1.35, "chop": 1.0},
	"GREECE": {"sea": [0x3cc8e0, 0x0a4a9a], "shimmer": 1.45, "chop": 0.8},
	"VOLCANO": {"sea": [0x3a6a70, 0x0c2a33], "shimmer": 0.55, "chop": 1.3},
	"WETLANDS": {"sea": [0x5a8a6a, 0x1c3f3a], "shimmer": 0.4, "chop": 0.5},
	"HARBOR": {"sea": [0x4aa0a8, 0x16445a], "shimmer": 0.8, "chop": 1.1},
	"CANYON": {"shimmer": 0.8, "chop": 0.9},
	"ALPINE": {"shimmer": 1.3, "chop": 1.0},
	"GROVE": {"shimmer": 0.5, "chop": 0.6},
	"COUNTRY": {"shimmer": 0.9, "chop": 0.8},
	"TOWN": {"shimmer": 0.7, "chop": 0.7},
}


func water_material(shallow: Color, deep: Color, r_shallow: Color, r_deep: Color) -> ShaderMaterial:
	var dark: bool = e.get("dark", false)
	var dk := 0.32 if dark else 1.0
	var sky := U.hexc(e.fog).lerp(U.hexc(0x1a2350 if dark else 0x8ac4f0), 0.5)
	var m := ShaderMaterial.new()
	m.shader = Mats.shader("water")
	m.render_priority = 2
	m.set_shader_parameter("noise_tex", Tex.noise())
	m.set_shader_parameter("rip", ripples)
	m.set_shader_parameter("r_shallow", Mats.v3(r_shallow * dk))
	m.set_shader_parameter("r_deep", Mats.v3(r_deep * dk))
	m.set_shader_parameter("shallow", Mats.v3(shallow * dk))
	m.set_shader_parameter("deep", Mats.v3(deep * dk))
	m.set_shader_parameter("foam_col", Mats.v3(U.hexc(0xf2fbff) * (0.55 if dark else 1.0)))
	m.set_shader_parameter("sky", Mats.v3(sky))
	var sd: Array = e.sunDir
	m.set_shader_parameter("sun_dir", Vector3(sd[0], sd[1], sd[2]).normalized())
	m.set_shader_parameter("sun_col", Mats.v3(U.hexc(e.sun) * (0.35 if dark else 1.0)))
	var look: Dictionary = WATER_LOOK.get(t.env_key, {})
	m.set_shader_parameter("shimmer", look.get("shimmer", 1.0))
	m.set_shader_parameter("chop", look.get("chop", 1.0))
	water_mats.append(m)
	return m


func add_ripple(x: float, z: float, time: float) -> void:
	ripples[rip_i] = Vector3(x, z, time)
	rip_i = (rip_i + 1) % 8
	for m in water_mats:
		m.set_shader_parameter("rip", ripples)


## One continuous water surface for sea, lakes and river, shaded from the terrain depth so they merge on their own.
func _build_water() -> void:
	var shore: bool = e.get("shore", false)
	if e.get("lava", false) or float(e.get("amp", 0.0)) == 0.0 or not (shore or t.river != null or lakes.size() > 0):
		return
	var S: float = maxf(bounds.x1 - bounds.x0, bounds.z1 - bounds.z0) + 40.0
	var step := _tstep
	var seg := roundi((S * 1.35 if shore else S) / step)
	var vn := seg + 1
	var WS := seg * step
	var x0: float = bounds.cx - WS / 2.0
	var z0: float = bounds.cz - WS / 2.0
	var half := S / 2.0
	var dist := dist_field(x0, z0, step, vn, vn, 110.0 if shore else 80.0)
	var has_river := t.river != null
	var rw: float = t.river.w if has_river else 0.0
	var bands := mini(16, vn)
	var per := int(ceil(float(vn) / bands))
	var res := []
	res.resize(bands)
	var job := func(b: int) -> void:
		var out := PackedFloat32Array()
		for iz in range(b * per, mini(vn, b * per + per)):
			for ix in vn:
				var x := x0 + ix * step
				var z := z0 + iz * step
				var outside: bool = shore and (absf(x - bounds.cx) > half or absf(z - bounds.cz) > half)
				var depth := 7.0
				if not outside:
					depth = maxf(0.0, -0.5 - terrain_hr(x, z, dist[iz * vn + ix]).x)
				var riv := 0.0
				var fx := 0.0
				var fz := 0.0
				if has_river:
					var rn := _river_near(x, z)
					riv = 1.0 - U.smooth01((rn.x - rw) / 10.0)
					var fw := (1.0 - U.smooth01((rn.x - rw * 0.8) / (rw * 0.2 + 4.0))) * (0.3 + 0.7 * U.clampf2(depth / 1.5, 0.0, 1.0))
					fx = rn.y * fw
					fz = rn.z * fw
				out.append_array([depth, riv, fx, fz])
		res[b] = out
	_run_parallel(job, bands)
	var pos := PackedVector3Array()
	var dep := PackedVector2Array()
	var fl := PackedVector2Array()
	for b in bands:
		var o: PackedFloat32Array = res[b]
		for j in range(0, o.size(), 4):
			var k := pos.size()
			pos.append(Vector3(x0 + (k % vn) * step, 0.0, z0 + (k / vn) * step))
			dep.append(Vector2(o[j], o[j + 1]))
			fl.append(Vector2(o[j + 2], o[j + 3]))
	var idx := PackedInt32Array()
	for iz in seg:
		for ix in seg:
			var a := ix + vn * iz
			var b2 := ix + vn * (iz + 1)
			var c := ix + 1 + vn * (iz + 1)
			var d := ix + 1 + vn * iz
			idx.append_array([a, d, b2, b2, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos
	var nrm := PackedVector3Array()
	nrm.resize(pos.size())
	nrm.fill(Vector3.UP)
	arr[Mesh.ARRAY_NORMAL] = nrm
	arr[Mesh.ARRAY_TEX_UV] = fl
	arr[Mesh.ARRAY_TEX_UV2] = dep
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var rc := U.hexc(e.get("riverCol", 0x2f9fc0))
	var rsh := rc.lerp(U.hexc(0x9ae8e0), 0.45)
	var rdp := rc * 0.45
	rdp.a = 1.0
	var sea: Array = WATER_LOOK.get(t.env_key, {}).get("sea", [0x48dccc, 0x0a4f78])
	var m: MeshInstance3D
	if shore:
		m = mesh_node(mesh, water_material(U.hexc(sea[0]), U.hexc(sea[1]), rsh, rdp))
	else:
		m = mesh_node(mesh, water_material(rsh, rdp, rsh, rdp))
	m.position.y = -0.5
	m.custom_aabb = AABB(Vector3(x0, -2, z0), Vector3(WS, 4, WS))
	add_child(m)


func _build_road() -> void:
	var py := t.py
	ribbon(func(i): return -HW - 0.5 if py[i] > 0.3 else -HW - 4.0, func(i): return HW + 0.5 if py[i] > 0.3 else HW + 4.0, 0.03, 10.0, Mats.toon({"color": e.shoulder}))
	var dark: bool = e.get("dark", false)
	var wet: bool = e.weather == "rain" or e.weather == "drizzle"
	var rm := ShaderMaterial.new()
	rm.shader = Mats.shader("pbr")
	rm.set_shader_parameter("use_tex", true)
	rm.set_shader_parameter("tex", Tex.road(e, false))
	var grid: bool = e.get("grid", false)
	rm.set_shader_parameter("roughness", 0.24 if grid else (0.38 if (dark or wet) else 0.82))
	rm.set_shader_parameter("metallic", 0.18 if grid else (0.3 if dark else 0.05))
	rm.set_shader_parameter("env_i", 0.92 if grid else (0.6 if dark else 0.35))
	if grid:
		rm.set_shader_parameter("emissive", Mats.v3(U.hexc(0x091226)))
	ribbon(-HW, HW, 0.06, 20.0, rm)
	# kerbs on the outside of tight corners
	var g := Geo.new()
	var A := U.hexc(e.curbA)
	var B := U.hexc(e.curbB)
	for i in t.n:
		if absf(t.k[i]) < 0.022 or t.py[i] > 0.3:
			continue
		var j := (i + 1) % t.n
		var c := A if int(floor(i / 1.5)) % 2 == 1 else B
		for s: float in [-1.0, 1.0]:
			var o0: float = s * HW
			var o1: float = s * (HW + 1.4)
			var q := [Vector2(t.px[i] + t.nx[i] * o0, t.pz[i] + t.nz[i] * o0), Vector2(t.px[i] + t.nx[i] * o1, t.pz[i] + t.nz[i] * o1),
				Vector2(t.px[j] + t.nx[j] * o0, t.pz[j] + t.nz[j] * o0), Vector2(t.px[j] + t.nx[j] * o1, t.pz[j] + t.nz[j] * o1)]
			var tri := [0, 1, 2, 1, 3, 2] if s < 0 else [0, 2, 1, 1, 2, 3]
			for v in tri:
				g.pos.append(Vector3(q[v].x, 0.075 + t.py[i], q[v].y))
				g.col.append(c)
	if not g.pos.is_empty():
		g.compute_normals()
		add_child(mesh_node(g.to_mesh(), Mats.toon({"side": "double"})))
	if e.get("night", false):
		var left_glow: int = 0x72dfff if e.get("space", false) else 0x22e5ff
		var right_glow: int = 0xffc982 if e.get("space", false) else 0xff2bd6
		var center_glow: int = 0x274c70 if e.get("space", false) else 0x5a26a0
		ribbon(-HW + 0.25, -HW + 0.7, 0.08, 10.0, Mats.basic({"color": left_glow, "blend": "add"}))
		ribbon(HW - 0.7, HW - 0.25, 0.08, 10.0, Mats.basic({"color": right_glow, "blend": "add"}))
		ribbon(-HW - 5.0, HW + 5.0, 0.035, 10.0, Mats.basic({"color": center_glow, "opacity": 0.3, "blend": "add"}))


func _build_start() -> void:
	var accent := U.css(e.accent)
	var g := Geo.plane(HW * 2.0, 3.0)
	g.rotate_x(-PI / 2.0)
	var m := mesh_node(g.to_mesh(), Mats.toon({"map": Tex.checker()}))
	m.position = Vector3(t.px[0], 0.09, t.pz[0])
	m.rotation.y = atan2(t.tx[0], t.tz[0])
	add_child(m)
	var arch := node()
	arch.position = m.position
	arch.rotation.y = m.rotation.y
	var pm := Mats.toon({"color": 0x2a2e36})
	for s: float in [-1.0, 1.0]:
		var p := mesh_node(Geo.box(1.2, 9, 1.2).to_mesh(), pm, true)
		p.position = Vector3(s * (HW + 1.6), 4.5, 0)
		arch.add_child(p)
	var bt := Mats.basic({"map": Tex.checker(), "uv_scale": Vector2(2, 1)})
	var am := Mats.basic({"color": accent})
	var beam := mesh_node(Geo.box(HW * 2.0 + 4.4, 1.6, 1).to_mesh(), [pm, pm, bt, pm, am, am], true)
	beam.position.y = 8.6
	arch.add_child(beam)
	add_child(arch)
	add_obstacle(t.px[0] + t.nx[0] * (HW + 1.6), t.pz[0] + t.nz[0] * (HW + 1.6), 1.0)
	add_obstacle(t.px[0] - t.nx[0] * (HW + 1.6), t.pz[0] - t.nz[0] * (HW + 1.6), 1.0)


## Chevron pointing +z, built from two slanted bars.
func _chevron(tip: float, arm: float, thick: float, ang: float) -> Geo:
	var g: Geo = null
	for sgn: float in [1.0, -1.0]:
		var bar := Geo.box(thick, 0.03, arm)
		var th := PI - sgn * ang
		bar.rotate_y(th)
		bar.translate(sin(th) * arm / 2.0, 0.0, tip + cos(th) * arm / 2.0)
		g = bar if g == null else g.merge(bar)
	return g


func _flat_ring(r: float, tube: float, segs: int) -> Mesh:
	return Geo.torus(r, tube, 6, segs).rotate_x(PI / 2.0).to_mesh()


func _flat_disc(r: float, segs: int) -> Mesh:
	return Geo.circle(r, segs).rotate_x(-PI / 2.0).to_mesh()


## Big pads: dark hex plate, glowing rim, three chasing chevrons, a spinning crystal in a gyro ring and a light beam.
## Small pads: round plate, one chevron, a small bobbing shard.
func _build_pads() -> void:
	pads = []
	if t.pads.is_empty():
		return
	var orange := 0xff8a1f
	var cyan := 0x3fd0ff
	var mats := {}
	for kind in ["big", "small"]:
		var col: int = orange if kind == "big" else cyan
		var hot: int = 0xffc27a if kind == "big" else 0xb8f1ff
		mats[kind] = {
			"plate": Mats.toon({"color": 0x15181f, "emissive": U.hexc(col), "emissive_i": 0.22}),
			"rim": Mats.basic({"color": col, "opacity": 0.95, "blend": "add"}),
			"glow": Mats.basic({"color": col, "opacity": 0.28, "blend": "add"}),
			"hot": Mats.basic({"color": hot, "opacity": 0.95, "blend": "add"}),
			"beam": Mats.basic({"color": col, "opacity": 0.13, "blend": "add"}),
			"chev": [Mats.basic({"color": hot, "opacity": 0.2, "blend": "add"}), Mats.basic({"color": hot, "opacity": 0.2, "blend": "add"}), Mats.basic({"color": hot, "opacity": 0.2, "blend": "add"})],
		}
	var big := {
		"plate": Geo.cylinder(3.6, 3.75, 0.1, 6).to_mesh(),
		"rim": _flat_ring(3.45, 0.11, 6),
		"rim2": _flat_ring(2.55, 0.05, 40),
		"glow": _flat_disc(3.3, 6),
		"chev": [_chevron(-0.9, 1.5, 0.36, 0.95).to_mesh(), _chevron(0.35, 1.5, 0.36, 0.95).to_mesh(), _chevron(1.6, 1.5, 0.36, 0.95).to_mesh()],
		"crystal": Geo.icosahedron(0.7, 0).scale_xyz(0.8, 1.45, 0.8).to_mesh(),
		"gyro": Geo.torus(1.25, 0.05, 6, 36).to_mesh(),
		"beam": Geo.cylinder(1.3, 2.3, 6.0, 20, 1, true).to_mesh(),
	}
	var small := {
		"plate": Geo.cylinder(2.25, 2.35, 0.08, 24).to_mesh(),
		"rim": _flat_ring(2.05, 0.08, 32),
		"glow": _flat_disc(1.95, 24),
		"chev": [_chevron(-0.3, 1.0, 0.28, 0.95).to_mesh()],
		"crystal": Geo.icosahedron(0.32, 0).scale_xyz(0.8, 1.3, 0.8).to_mesh(),
	}
	for pd in t.pads:
		var i: int = pd.i
		var is_big: bool = pd.big
		var x: float = t.px[i] + t.nx[i] * pd.lat
		var z: float = t.pz[i] + t.nz[i] * pd.lat
		var node := Node3D.new()
		node.position = Vector3(x, t.py[i] + 0.1, z)
		node.rotation.y = atan2(t.tx[i], t.tz[i])
		var m: Dictionary = mats["big" if is_big else "small"]
		var g: Dictionary = big if is_big else small
		node.add_child(mesh_node(g.plate, m.plate))
		var live := Node3D.new()
		node.add_child(live)
		var glow := mesh_node(g.glow, m.glow)
		glow.position.y = 0.07
		live.add_child(glow)
		var rim := mesh_node(g.rim, m.rim)
		rim.position.y = 0.09
		live.add_child(rim)
		if is_big:
			var rim2 := mesh_node(g.rim2, m.rim)
			rim2.position.y = 0.08
			live.add_child(rim2)
		for k in (g.chev as Array).size():
			var c := mesh_node(g.chev[k], m.chev[k])
			c.position.y = 0.09
			live.add_child(c)
		var crystal := mesh_node(g.crystal, m.hot)
		var hover := 1.9 if is_big else 1.05
		crystal.position.y = hover
		live.add_child(crystal)
		var gyro: MeshInstance3D = null
		if is_big:
			gyro = mesh_node(g.gyro, m.rim)
			gyro.position.y = hover
			live.add_child(gyro)
			var beam := mesh_node(g.beam, m.beam)
			beam.position.y = 3.1
			live.add_child(beam)
		add_child(node)
		var entry := {"node": node, "x": x, "z": z, "big": is_big, "r": 3.6 if is_big else 2.4, "cd": 0}
		pads.append(entry)
		var phase: float = float(i) * 0.37
		anims.append(func(_dt: float, tt: float):
			var cool: bool = entry.cd > 0
			live.visible = not cool
			if cool:
				return
			crystal.position.y = hover + 0.18 * sin(tt * 2.4 + phase)
			crystal.rotation.y = tt * 2.0 + phase
			if gyro != null:
				gyro.position.y = crystal.position.y
				gyro.rotation = Vector3(tt * 1.3 + phase, tt * 0.9, 0.0)
			var pulse := 1.0 + 0.03 * sin(tt * 5.0 + phase)
			glow.scale = Vector3(pulse, 1.0, pulse))
	# chevrons chase forward, shared by every pad of a kind
	for kind in ["big", "small"]:
		var cm: Array = mats[kind].chev
		anims.append(func(_dt: float, tt: float):
			for k in cm.size():
				var ph := fposmod(tt * 1.6 - float(k) * 0.28, 1.0)
				(cm[k] as ShaderMaterial).set_shader_parameter("opacity", 0.3 + 0.7 * pow(maxf(0.0, 1.0 - ph * 1.6), 1.5)))


func _build_gates() -> void:
	var accent := U.css(e.accent)
	var gp := PackedVector3Array()
	var gc: Array = []
	var post := Geo.cylinder(0.35, 0.45, 4.2, 10).to_mesh()
	var pmat := Mats.toon({"color": 0x2a2e36, "emissive": accent, "emissive_i": 0.35})
	for k in t.cps.size():
		var i: int = t.cps[k]
		var g := Geo.plane(HW * 2.0, 1.4)
		g.rotate_x(-PI / 2.0)
		var mat := Mats.basic({"color": accent, "opacity": 0.5, "blend": "add"})
		var m := mesh_node(g.to_mesh(), mat)
		m.position = Vector3(t.px[i], 0.1, t.pz[i])
		m.rotation.y = atan2(t.tx[i], t.tz[i])
		add_child(m)
		for s: float in [-1.0, 1.0]:
			var x: float = t.px[i] + t.nx[i] * s * (HW + 1.3)
			var z: float = t.pz[i] + t.nz[i] * s * (HW + 1.3)
			var p := mesh_node(post, pmat, true)
			p.position = Vector3(x, 2.1, z)
			add_child(p)
			gp.append(Vector3(x, 4.6, z))
			gc.append(accent)
			add_obstacle(x, z, 0.6)
		gates.append({"mesh": m, "mat": mat, "flash": 0.0, "k": k})
	sprites(gp, gc, 9.0, {"blend": "add"})


func _build_bridges() -> void:
	var N := t.n
	var any := false
	for v in t.py:
		if v > 0.04:
			any = true
			break
	if not any:
		return
	var night: bool = e.get("night", false)
	var lava: bool = e.get("lava", false)
	var conc := Mats.toon({"color": 0x55507e if night else (0x5a4e4a if lava else 0xd2cdc3), "side": "double"})
	var trim := Mats.toon({"color": e.curbA, "side": "double"})
	var under := Mats.toon({"color": 0x3a3660 if night else 0x9a958c})
	var runs: Array = []
	var i0 := -1
	for i in N + 1:
		var el := i < N and t.py[i] > 0.04
		if el and i0 < 0:
			i0 = i
		if not el and i0 >= 0:
			runs.append([i0 - 1, i])
			i0 = -1
	var py := t.py
	for r in runs:
		var a: int = r[0]
		var b: int = r[1]
		for s: float in [-1.0, 1.0]:
			_wall(s * (HW + 0.45), a, b, func(k): return maxf(-0.12, py[k] - 1.4), func(k): return py[k] + 0.95, conc)
			_wall(s * (HW + 0.5), a, b, func(k): return py[k] + 0.68, func(k): return py[k] + 1.02, trim)
		var from := (a + N) % N
		ribbon(-HW - 0.45, HW + 0.45, -0.35, 10.0, under, from, from + (b - a), true)
	var box := Geo.box(1, 1, 1).translate(0, 0.5, 0).to_mesh()
	var pil: Array = []
	var beams: Array = []
	for r in runs:
		var a: int = r[0]
		var b: int = r[1]
		var i := a
		while i <= b:
			var k := (i + N) % N
			if t.py[k] >= 2.0:
				var pp: Array = []
				for s: float in [-1.0, 1.0]:
					var o: float = s * (HW - 1.4)
					var x: float = t.px[k] + t.nx[k] * o
					var z: float = t.pz[k] + t.nz[k] * o
					if other_road_dist(x, z, k) < HW + 2.4:
						continue
					pp.append({"x": x, "z": z, "h": t.py[k] - 1.35})
				for p in pp:
					pil.append(p)
					add_obstacle(p.x, p.z, 1.1)
				if pp.size() == 2:
					beams.append({"x": t.px[k], "z": t.pz[k], "h": t.py[k] - 1.35, "a": atan2(t.tx[k], t.tz[k])})
			i += 5
	inst(box, Mats.toon({"color": 0x4a4670 if night else 0xc4bfb5}), pil, func(p, d, i):
		d.position = Vector3(p.x, -0.2, p.z)
		d.scale = Vector3(1.5, p.h + 0.2, 1.5))
	inst(box, Mats.toon({"color": 0x4a4670 if night else 0xbab5ab}), beams, func(p, d, i):
		d.position = Vector3(p.x, p.h - 0.9, p.z)
		d.rotation.y = p.a
		d.scale = Vector3(HW * 2.0 - 0.6, 0.9, 1.6))


func _wall(o: float, a: int, b: int, y0f: Callable, y1f: Callable, mat) -> void:
	var N := t.n
	var g := Geo.new()
	for i in range(a, b + 1):
		var k := (i + N) % N
		var x: float = t.px[k] + t.nx[k] * o
		var z: float = t.pz[k] + t.nz[k] * o
		g.pos.append(Vector3(x, y0f.call(k), z))
		g.pos.append(Vector3(x, y1f.call(k), z))
		if i < b:
			var q := (i - a) * 2
			g.idx.append_array([q, q + 1, q + 2, q + 1, q + 3, q + 2])
	g.compute_normals()
	add_child(mesh_node(g.to_mesh(), mat, true))


# ------------------------------------------------------------------ trackside furniture shared by every place

func _build_common() -> void:
	var boxG := Geo.box(1, 1, 1).translate(0, 0.5, 0).to_mesh()
	var pick := func(a: Array): return a[int(floor(rng.next() * a.size()))]
	var s := 1.0 if SeedRng.hash_str(t.seed) % 2 == 1 else -1.0
	var th := atan2(t.tx[0], t.tz[0])
	var ox := -s
	var lx := [t.tz[0], -t.tx[0]]
	var lz := [t.tx[0], t.tz[0]]
	var gs := node()
	gs.position = Vector3(t.px[0] + t.nx[0] * s * (HW + 9.0), 0, t.pz[0] + t.nz[0] * s * (HW + 9.0))
	gs.rotation.y = th
	add_child(gs)
	var step_m := Mats.toon({"color": 0xb9bec8})
	for j in 4:
		var m := mesh_node(boxG, step_m, true)
		m.scale = Vector3(2.6, 1.1 * (j + 1), 46)
		m.position = Vector3(ox * (2.5 * j + 1.3), 0, 8)
		gs.add_child(m)
	var crowd: Array = []
	var skins := [0xf1c9a5, 0xd9a37c, 0xa86f4a, 0x6e4630, 0xf6dcc2]
	var accent_hex := U.css(e.accent).to_rgba32() >> 8
	for j in 4:
		var z := -14.0
		while z <= 30.0:
			if rng.next() < 0.8:
				var cx: float = ox * (2.5 * j + 1.3) + (rng.next() - 0.5) * 0.5
				var cy := 1.1 * (j + 1)
				var cz := z + (rng.next() - 0.5) * 0.3
				var c := U.hexc(pick.call([0xe8402c, 0x2f6bd9, 0xf2c230, 0x2ec27e, 0xff7a59, 0x7a4dff, 0xf4f1ea, accent_hex]))
				var kc := U.hexc(pick.call(skins))
				crowd.append({"x": cx, "y": cy, "z": cz, "c": c, "k": kc})
			z += 1.05
	inst(Geo.box(0.72, 1.05, 0.55).translate(0, 0.52, 0), Mats.toon({"anim": "hop", "amp": 0.4}), crowd, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		return p.c, true, gs)
	inst(Geo.sphere(0.33, 8, 6).translate(0, 1.36, 0), Mats.toon({"anim": "hop", "amp": 0.4}), crowd, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		return p.k, true, gs)
	var dark: bool = e.get("dark", false)
	var roof := mesh_node(boxG, Mats.toon({"color": 0x8a8fa0 if dark else 0xd4d6dc}), true)
	roof.scale = Vector3(6.5, 0.3, 47)
	roof.position = Vector3(ox * 8.2, 7.8, 8)
	var trim := mesh_node(boxG, Mats.toon({"color": e.curbA}))
	trim.scale = Vector3(0.6, 0.9, 47)
	trim.position = Vector3(ox * 5.2, 7.4, 8)
	gs.add_child(trim)
	gs.add_child(roof)
	for z in [-14.0, 2.0, 18.0, 30.0]:
		var p := mesh_node(boxG, Mats.toon({"color": 0x2a2e36}))
		p.scale = Vector3(0.4, 7.8, 0.4)
		p.position = Vector3(ox * 10.6, 0, z)
		gs.add_child(p)
	var z2 := -14.0
	while z2 <= 30.0:
		var wx: float = gs.position.x + lx[0] * ox * 1.3 + lz[0] * z2
		var wz: float = gs.position.z + lx[1] * ox * 1.3 + lz[1] * z2
		add_obstacle(wx, wz, 1.6)
		z2 += 4.0
	# flags on the opposite side of the start straight
	var flags: Array = []
	for j in range(-2, 5):
		var i := (j * 5 + t.n) % t.n
		var o := -s * (HW + 4.5)
		flags.append({"x": t.px[i] + t.nx[i] * o, "z": t.pz[i] + t.nz[i] * o, "a": atan2(t.tx[i], t.tz[i])})
	inst(Geo.cylinder(0.12, 0.14, 8, 6).translate(0, 4, 0), Mats.toon({"color": 0xe9e9ee}), flags, func(p, d, i):
		d.position = Vector3(p.x, 0, p.z)
		add_obstacle(p.x, p.z, 0.4))
	var acc := U.css(e.accent)
	var cb := U.hexc(e.curbB)
	inst(Geo.plane(3.4, 2, 6, 1).translate(1.7, 7, 0), Mats.toon({"side": "double", "anim": "flag", "amp": 0.18}), flags, func(p, d, i):
		d.position = Vector3(p.x, 0, p.z)
		d.rotation.y = p.a + PI / 2.0
		return acc if i % 2 == 1 else cb, false)
	# After-dark worlds get trackside lamps unless they provide their own.
	if dark and t.env_key != "NEON" and t.env_key != "TOWN" and t.env_key != "GRID" and t.env_key != "ORBITAL":
		var lamps: Array = []
		var i := 8
		while i < t.n:
			if t.py[i] <= 0.05:
				var sd := 1.0 if (i / 18) % 2 == 1 else -1.0
				var o := sd * (HW + 3.6)
				var x: float = t.px[i] + t.nx[i] * o
				var z: float = t.pz[i] + t.nz[i] * o
				if not (e.get("shore", false) and terrain_h(x, z, HW + 3.6) < -0.3):
					lamps.append({"x": x, "z": z})
			i += 18
		inst(Geo.cylinder(0.15, 0.2, 6, 6).translate(0, 3, 0), Mats.toon({"color": 0x2a2e36}), lamps, func(p, d, i2):
			d.position = Vector3(p.x, 0, p.z)
			add_obstacle(p.x, p.z, 0.45))
		var gp := PackedVector3Array()
		for p in lamps:
			gp.append(Vector3(p.x, 6.2, p.z))
		sprites(gp, null, 2.4, {"blend": "add", "color": 0xffe0a8, "opacity": 0.75})
		var pool := Geo.plane(15, 15)
		pool.rotate_x(-PI / 2.0)
		inst(pool, Mats.basic({"map": Tex.radial(), "color": 0xc98a40, "opacity": 0.11, "blend": "add"}), lamps, func(p, d, i2):
			d.position = Vector3(p.x, 0.13, p.z), false)
	# tyre walls on the outside of tight corners
	var tires: Array = []
	var ti := 0
	while ti < t.n:
		if absf(t.k[ti]) >= 0.03 and t.py[ti] <= 0.05:
			var sg := -U.jsign(t.k[ti])
			var off := HW + 4.4
			var x: float = t.px[ti] + t.nx[ti] * off * sg
			var z: float = t.pz[ti] + t.nz[ti] * off * sg
			if dist_to_track(x, z, off + 3.0) >= off - 1.5:
				tires.append({"x": x, "z": z})
		ti += 3
	var tw: Array = []
	var sp: Array = []
	for p in tires:
		var ok := true
		for q in sp:
			if pow(q.x - p.x, 2.0) + pow(q.z - p.z, 2.0) <= 4.8 * 4.8:
				ok = false
				break
		if ok:
			sp.append(p)
			if sp.size() > 160:
				break
	for j in sp.size():
		var p: Dictionary = sp[j]
		for l in 3:
			tw.append({"x": p.x, "z": p.z, "l": l, "j": j})
		add_obstacle(p.x, p.z, 1.1)
	var tc := [U.hexc(0x1d1f24), U.hexc(e.curbA), U.hexc(0xf4f1ea)]
	inst(Geo.cylinder(0.8, 0.8, 0.55, 12).translate(0, 0.28, 0), Mats.toon(), tw, func(p, d, i):
		d.position = Vector3(p.x, p.l * 0.56, p.z)
		return tc[1 + (p.j % 2)] if p.l == 1 else tc[0])


# ------------------------------------------------------------------ rising smoke from chimneys, craters and vents

func _build_ambient() -> void:
	if emitters.is_empty():
		return
	var n := 380
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = _quad()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Mats.sprites({"blend": "mix", "per_instance": true, "fog": false})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-5000, -100, -5000), Vector3(10000, 400, 10000))
	add_child(mi)
	var max_arr := PackedFloat32Array()
	max_arr.resize(n)
	max_arr.fill(1.0)
	amb = {"n": n, "i": 0, "mm": mm, "pos": PackedVector3Array(), "vel": PackedVector3Array(), "life": PackedFloat32Array(), "max": max_arr,
		"sz0": PackedFloat32Array(), "col": PackedColorArray(), "buf": PackedFloat32Array()}
	amb.pos.resize(n)
	amb.vel.resize(n)
	amb.life.resize(n)
	amb.sz0.resize(n)
	amb.col.resize(n)
	amb.buf.resize(n * 20)
	anims.append(_tick_ambient)


func _tick_ambient(dt: float, tt: float) -> void:
	var s := amb
	var n: int = s.n
	var pos: PackedVector3Array = s.pos
	var vel: PackedVector3Array = s.vel
	var life: PackedFloat32Array = s.life
	var mx: PackedFloat32Array = s.max
	var sz0: PackedFloat32Array = s.sz0
	var col: PackedColorArray = s.col
	for em in emitters:
		em.acc += dt * em.rate
		while em.acc >= 1.0:
			em.acc -= 1.0
			var i: int = s.i
			s.i = (i + 1) % n
			pos[i] = Vector3(em.x + (randf() - 0.5) * em.size * 0.3, em.y, em.z + (randf() - 0.5) * em.size * 0.3)
			vel[i] = Vector3(1.4 + randf() * 0.8, 2.0 + randf() * 1.4, (randf() - 0.5) * 0.8)
			life[i] = em.life * (0.8 + randf() * 0.4)
			mx[i] = life[i]
			sz0[i] = em.size
			col[i] = em.color
	var buf: PackedFloat32Array = s.buf
	for i in n:
		var o := i * 20
		var alpha := 0.0
		var size := 0.0
		if life[i] > 0.0:
			life[i] -= dt
			var tq := 1.0 - life[i] / mx[i]
			pos[i] += vel[i] * dt
			size = sz0[i] * (1.0 + tq * 2.4)
			alpha = sin(minf(1.0, tq * 5.0) * PI / 2.0) * (1.0 - tq) * 0.6
		var p := pos[i]
		buf[o] = 1.0
		buf[o + 1] = 0.0
		buf[o + 2] = 0.0
		buf[o + 3] = p.x
		buf[o + 4] = 0.0
		buf[o + 5] = 1.0
		buf[o + 6] = 0.0
		buf[o + 7] = p.y
		buf[o + 8] = 0.0
		buf[o + 9] = 0.0
		buf[o + 10] = 1.0
		buf[o + 11] = p.z
		var c := col[i]
		buf[o + 12] = c.r
		buf[o + 13] = c.g
		buf[o + 14] = c.b
		buf[o + 15] = 1.0
		buf[o + 16] = size
		buf[o + 17] = maxf(alpha, 0.0)
		buf[o + 18] = 0.0
		buf[o + 19] = 0.0
	s.pos = pos
	s.vel = vel
	s.life = life
	s.max = mx
	s.sz0 = sz0
	s.col = col
	s.buf = buf
	(s.mm as MultiMesh).buffer = buf


# ------------------------------------------------------------------ weather (GPU-driven particles)

const WEATHER := {
	"rain": {"n": 3600, "vel": [8, -52, 0], "wob": 0.0, "top": 70.0, "lines": true, "len": 2.7, "color": 0xcfe0f0, "op": 0.38},
	"drizzle": {"n": 1700, "vel": [8, -30, 0], "wob": 0.0, "top": 70.0, "lines": true, "len": 1.7, "color": 0xc8b8ff, "op": 0.32},
	"snow": {"n": 4600, "vel": [2, -6, 0], "wob": 1.6, "top": 70.0, "size": 1.7, "color": 0xffffff, "op": 0.95},
	"dust": {"n": 1400, "vel": [12, 0, 0], "wob": 1.2, "top": 20.0, "size": 1.1, "color": 0xf6d2a8, "op": 0.6},
	"embers": {"n": 1100, "vel": [1.2, 4, 0], "wob": 2.0, "top": 40.0, "size": 1.2, "color": 0xff8a3a, "op": 0.9, "add": true},
}


func _build_weather() -> void:
	weather_mat = null
	if not WEATHER.has(e.weather):
		return
	var k: Dictionary = WEATHER[e.weather]
	var lines: bool = k.get("lines", false)
	var n := maxi(1, int(k.n * (0.6 if is_touch else 1.0) * weather_density))
	# VERTEX carries each particle's random seed (xyz), UV2.x its fourth seed value and UV the corner / line end
	var pos := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in n:
		var sd := Vector3(randf() - 0.5, randf(), randf() - 0.5)
		var w := randf()
		if lines:
			for j in 2:
				pos.append(sd)
				uv.append(Vector2(j, 0))
				uv2.append(Vector2(w, 0))
		else:
			var b := pos.size()
			for c in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				pos.append(sd)
				uv.append(c)
				uv2.append(Vector2(w, 0))
			idx.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	if not lines:
		arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES if lines else Mesh.PRIMITIVE_TRIANGLES, arr)
	var m := ShaderMaterial.new()
	m.shader = Mats.shader("weather_lines" if lines else ("weather_points_add" if k.get("add", false) else "weather_points"))
	var v: Array = k.vel
	m.set_shader_parameter("vel", Vector3(v[0], v[1], v[2]))
	m.set_shader_parameter("wob", k.wob)
	m.set_shader_parameter("top", k.top)
	m.set_shader_parameter("size", k.get("size", 1.0))
	m.set_shader_parameter("len", k.get("len", 0.0))
	m.set_shader_parameter("col", Mats.v3(U.hexc(k.color)))
	m.set_shader_parameter("op", k.op)
	m.set_shader_parameter("tex", Tex.radial())
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-1e5, -1e3, -1e5), Vector3(2e5, 2e3, 2e5))
	add_child(mi)
	weather_mat = m


func update_weather(cx: float, cz: float) -> void:
	if weather_mat:
		weather_mat.set_shader_parameter("center", Vector2(cx, cz))


func tick(dt: float, tt: float) -> void:
	for f in anims:
		f.call(dt, tt)
