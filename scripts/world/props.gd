class_name Props
extends RefCounted
## Scenery for each place (port of buildProps). Random draws happen in exactly the web build's order.

const HW := U.HW
const TAU := U.TAU

var w: World
var e: Dictionary
var t: TrackData
var rng: SeedRng
var boxG: ArrayMesh
var roofG: ArrayMesh


func _init(world: World) -> void:
	w = world
	e = world.e
	t = world.t
	rng = world.rng
	boxG = Geo.box(1, 1, 1).translate(0, 0.5, 0).to_mesh()
	roofG = Geo.prism().to_mesh()


# ------------------------------------------------------------------ helpers (same draw order as the JS closures)

func R() -> float:
	return rng.next()


func T(o: Dictionary = {}) -> ShaderMaterial:
	return Mats.toon(o)


func anim(o: Dictionary, mode: String, amp: float) -> ShaderMaterial:
	var q := o.duplicate()
	q["anim"] = mode
	q["amp"] = amp
	return Mats.toon(q)


func col(h) -> Color:
	return Mats.col_of(h)


func tint(base, v: float) -> Color:
	var dh := (R() - 0.5) * 0.04 * v
	var ds := (R() - 0.5) * 0.1 * v
	var dl := (R() - 0.5) * 0.12 * v
	return U.offset_hsl(col(base), dh, ds, dl)


func pick(a: Array):
	return a[int(floor(R() * a.size()))]


func spaced(list: Array, sep: float, others: Array = [], osep: float = -1.0) -> Array:
	if osep < 0.0:
		osep = sep
	var out: Array = []
	for p in list:
		var ok := true
		for q in out:
			if pow(q.x - p.x, 2.0) + pow(q.z - p.z, 2.0) <= sep * sep:
				ok = false
				break
		if ok:
			for q in others:
				if pow(q.x - p.x, 2.0) + pow(q.z - p.z, 2.0) <= osep * osep:
					ok = false
					break
		if ok:
			out.append(p)
	return out


func land(l: Array) -> Array:
	if not e.get("shore", false):
		return l
	return l.filter(func(p): return p.y > -0.1)


func face(p: Dictionary) -> float:
	return atan2(t.px[p.i] - p.x, t.pz[p.i] - p.z)


func obst(p: Dictionary, r: float) -> void:
	if p.d < HW + 50.0:
		w.add_obstacle(p.x, p.z, r)


func around(count: int, min_d: float, max_d: float, far_frac: float = 0.28) -> Array:
	return w.place_around(count, min_d, max_d, far_frac)


func house(p: Dictionary, o: Dictionary = {}) -> Dictionary:
	var hd := {"x": p.x, "y": maxf(p.y, -0.1), "z": p.z, "rot": face(p), "dist": p.d}
	hd["hw"] = 6.0 + R() * 4.0
	hd["hd"] = 6.0 + R() * 3.0
	hd["hh"] = 3.5 + R() * 3.0
	hd["rh"] = 2.6 + R() * 1.6
	hd["wc"] = col(0xf2eadf)
	hd["rc"] = col(0xb5452f)
	hd["chim"] = R() < 0.5
	for k in o:
		hd[k] = o[k]
	return hd


func slice(a: Array, n: int) -> Array:
	return a.slice(0, n)


func add(n: Node3D) -> Node3D:
	w.add_child(n)
	return n


func group(x: float, y: float, z: float) -> Node3D:
	var g := w.node()
	g.position = Vector3(x, y, z)
	w.add_child(g)
	return g


func mesh(geo, mat, cast := false) -> MeshInstance3D:
	var m: Mesh = geo.to_mesh() if geo is Geo else geo
	return w.mesh_node(m, mat, cast)


# ------------------------------------------------------------------ shared builders

func houses(list: Array) -> void:
	if list.is_empty():
		return
	w.inst(boxG, T(), list, func(p, d, i):
		d.position = Vector3(p.x, p.y - 0.4, p.z)
		d.rotation.y = p.rot
		d.scale = Vector3(p.hw, p.hh + 0.4, p.hd)
		if p.dist < HW + 50.0:
			w.add_obstacle(p.x, p.z, maxf(p.hw, p.hd) * 0.55)
		return p.wc)
	w.inst(roofG, T(), list, func(p, d, i):
		d.position = Vector3(p.x, p.y + p.hh, p.z)
		d.rotation.y = p.rot
		d.scale = Vector3(p.hw * 1.18, p.rh, p.hd * 1.12)
		return p.rc)
	w.inst(boxG, T({"color": 0x4a3328}), list, func(p, d, i):
		var f: float = p.hd / 2.0 + 0.02
		d.position = Vector3(p.x + sin(p.rot) * f, p.y, p.z + cos(p.rot) * f)
		d.rotation.y = p.rot
		d.scale = Vector3(1.3, 2.2, 0.14), false)
	var win: Array = []
	for p in list:
		for s: float in [-1.0, 1.0]:
			win.append({"p": p, "s": s})
	var dark: bool = e.get("dark", false)
	w.inst(boxG, T({"color": 0x8fc6dd, "emissive": 0xffcf7a, "emissive_i": 0.75 if dark else 0.0}), win, func(o, d, i):
		var p: Dictionary = o.p
		var f: float = p.hd / 2.0 + 0.03
		var ox: float = o.s * p.hw * 0.28
		d.position = Vector3(p.x + sin(p.rot) * f + cos(p.rot) * ox, p.y + p.hh * 0.45, p.z + cos(p.rot) * f - sin(p.rot) * ox)
		d.rotation.y = p.rot
		d.scale = Vector3(1.2, 1.2, 0.12), false)
	var ch := list.filter(func(p): return p.chim)
	w.inst(boxG, T({"color": 0x8a5a48}), ch, func(p, d, i):
		var ox: float = p.hw * 0.25
		d.position = Vector3(p.x + cos(p.rot) * ox, p.y + p.hh + p.rh * 0.25, p.z - sin(p.rot) * ox)
		d.rotation.y = p.rot
		d.scale = Vector3(0.9, p.rh * 0.78, 0.9))
	for p in ch:
		if R() < 0.55:
			var ox: float = p.hw * 0.25
			w.emit(p.x + cos(p.rot) * ox, p.y + p.hh + p.rh * 1.05, p.z - sin(p.rot) * ox, 1.1, 1.5, 0xeeeae6)


func round_trees(list: Array, palette: Array, amp: float = 0.035) -> void:
	var trk := Geo.cylinder(0.35, 0.5, 3, 6).translate(0, 1.5, 0)
	var can := Geo.icosahedron(2.7, 1).translate(0, 4.6, 0)
	var set := func(p, d):
		var s: float = 0.8 + p.s * 0.8
		d.position = Vector3(p.x, p.y, p.z)
		d.scalar(s)
		d.rotation.y = p.a
	w.inst(trk, T({"color": 0x5a3d2a}), list, func(p, d, i): set.call(p, d))
	w.inst(can, anim({}, "sway", amp), list, func(p, d, i):
		set.call(p, d)
		obst(p, 1.1 * (0.8 + p.s * 0.8))
		return tint(pick(palette), 1.0))


func rocks(list: Array, base: int, v: float = 1.2) -> void:
	w.inst(Geo.dodecahedron(1, 0), T(), list, func(p, d, i):
		var s: float = 0.9 + p.s * p.s * 3.2
		d.position = Vector3(p.x, p.y + s * 0.25, p.z)
		d.scale = Vector3(s * (0.8 + p.r * 0.5), s * 0.62, s * 1.1)
		d.rotation = Vector3(p.r, p.a, 0)
		obst(p, s * 0.85)
		return tint(base, v))


func balloons(n: int) -> void:
	var B: Dictionary = w.bounds
	for i in n:
		var x := 0.0
		var z := 0.0
		var tries := 0
		while true:
			x = U.lerpf2(B.x0 + 50.0, B.x1 - 50.0, R())
			z = U.lerpf2(B.z0 + 50.0, B.z1 - 50.0, R())
			var again := w.dist_to_track(x, z, 90.0) < 75.0 and tries < 30
			tries += 1
			if not again:
				break
		var sg := Geo.sphere(4.2, 12, 9)
		sg.scale_xyz(1, 1.2, 1)
		sg.to_non_indexed()
		var c1 := col(pick([0xe8402c, 0xf2c230, 0x1fb6c9, 0x7a4dff, 0xff7a59, 0x2ec27e]))
		var c2 := col(0xf8f4ea)
		var j := 0
		while j < sg.pos.size():
			var cx := sg.pos[j].x + sg.pos[j + 1].x + sg.pos[j + 2].x
			var cz := sg.pos[j].z + sg.pos[j + 1].z + sg.pos[j + 2].z
			var sgm := int(floor((atan2(cz, cx) + PI) / (TAU / 12.0))) % 2
			var c := c1 if sgm == 1 else c2
			for q in 3:
				sg.col.append(c)
			j += 3
		sg.compute_normals()
		var g := w.node()
		var env := mesh(sg, T(), true)
		var bk := mesh(Geo.box(1.5, 1.1, 1.5), T({"color": 0x7a5434}), true)
		bk.position.y = -6.4
		var flm := Geo.cone(0.5, 1.2, 6)
		var fl := mesh(flm, Mats.basic({"color": 0xffb347}))
		fl.position.y = -5.2
		fl.rotation.x = PI
		g.add_child(env)
		g.add_child(bk)
		g.add_child(fl)
		var h := 30.0 + R() * 12.0
		var ph := R() * TAU
		var vx := (R() - 0.5) * 1.4
		var vz := (R() - 0.5) * 1.4
		g.position = Vector3(x, h, z)
		w.add_child(g)
		w.anims.append(func(dt, tt):
			g.position.y = h + sin(tt * 0.35 + ph) * 1.6
			g.position.x += vx * dt
			g.position.z += vz * dt
			g.rotation.y += dt * 0.04
			fl.scale = Vector3.ONE * (0.8 + randf() * 0.5))


func birds(cfg: Array) -> void:
	var n: int = cfg[0]
	if n == 0:
		return
	var g := Geo.new()
	var v := [0, 0, 0.5, -1.5, 0.15, -0.35, 0, 0, -0.25, 0, 0, 0.5, 0, 0, -0.25, 1.5, 0.15, -0.35]
	for k in 6:
		g.pos.append(Vector3(v[k * 3], v[k * 3 + 1], v[k * 3 + 2]))
	g.compute_normals()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = g.to_mesh()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Mats.basic({"color": cfg[1], "side": "double"})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-1e4, -100, -1e4), Vector3(2e4, 300, 2e4))
	w.add_child(mi)
	var B: Dictionary = w.bounds
	var flocks: Array = []
	for f in 3:
		flocks.append({"x": U.lerpf2(B.x0 + 80.0, B.x1 - 80.0, R()), "z": U.lerpf2(B.z0 + 80.0, B.z1 - 80.0, R())})
	var BD: Array = []
	for i in n:
		var f: Dictionary = flocks[i % 3]
		var cx: float = f.x + (R() - 0.5) * 30.0
		var cz: float = f.z + (R() - 0.5) * 30.0
		var r := 24.0 + R() * 30.0
		var h := 20.0 + R() * 12.0
		var sp := (0.28 + R() * 0.18) * (-1.0 if (i % 3) % 2 == 1 else 1.0)
		var ph := R() * TAU
		BD.append({"cx": cx, "cz": cz, "r": r, "h": h, "sp": sp, "ph": ph})
	var d := World.D.new()
	w.anims.append(func(dt, tt):
		for i in BD.size():
			var b: Dictionary = BD[i]
			var a: float = b.ph + tt * b.sp
			d.position = Vector3(b.cx + cos(a) * b.r, b.h + sin(tt * 2.0 + i) * 0.6, b.cz + sin(a) * b.r)
			d.rotation = Vector3(0, atan2(-sin(a) * b.sp, cos(a) * b.sp), 0)
			d.scale = Vector3(0.55 + 0.45 * absf(sin(tt * 9.0 + i * 1.7)), 1, 1)
			mm.set_instance_transform(i, d.xf()))


func windmill(p: Dictionary) -> void:
	var g := group(p.x, p.y, p.z)
	var tw := mesh(Geo.cylinder(1.5, 2.6, 13, 8).translate(0, 6.5, 0), T({"color": 0xf1ebe0}), true)
	var cap := mesh(Geo.cone(2.3, 3.2, 8).translate(0, 14.6, 0), T({"color": 0x9a3b2b}), true)
	var hub := w.node()
	hub.position = Vector3(0, 12.2, -2.3)
	var blade := Geo.box(1.4, 10, 0.15).translate(0, 5.4, 0).to_mesh()
	var bm := T({"color": 0xeadfc4})
	for i in 4:
		var b := mesh(blade, bm, true)
		b.rotation.z = i * PI / 2.0
		hub.add_child(b)
	hub.add_child(mesh(Geo.sphere(0.65, 8, 6), T({"color": 0x5a3a2e})))
	g.add_child(tw)
	g.add_child(cap)
	g.add_child(hub)
	obst(p, 2.8)
	var sp := 0.7 + R() * 0.6
	w.anims.append(func(dt, tt): hub.rotation.z -= dt * sp)


func fireflies(n: int, color: int) -> void:
	var base: Array = []
	for i in n:
		var l := around(1, HW + 4.0, 40.0, 0.1)
		if l.is_empty():
			continue
		var p: Dictionary = l[0]
		base.append([p.x, p.y + 1.2 + R() * 3.0, p.z, R() * TAU])
	var pos := PackedVector3Array()
	pos.resize(n)
	var mi := w.sprites(pos, null, 1.3, {"blend": "add", "color": color})
	if mi == null:
		return
	mi.custom_aabb = AABB(Vector3(-1e4, -100, -1e4), Vector3(2e4, 300, 2e4))
	var mm := mi.multimesh
	var mat: ShaderMaterial = mi.material_override
	w.anims.append(func(dt, tt):
		for i in base.size():
			var b: Array = base[i]
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(b[0] + sin(tt * 0.7 + b[3]) * 2.0, b[1] + sin(tt * 1.3 + b[3] * 2.0) * 0.8, b[2] + cos(tt * 0.6 + b[3]) * 2.0)))
		mat.set_shader_parameter("opacity", 0.65 + 0.35 * sin(tt * 3.0)))


func ski_lift() -> void:
	var B: Dictionary = w.bounds
	var ang := R() * PI
	var dx := cos(ang)
	var dz := sin(ang)
	var L := minf(B.x1 - B.x0, B.z1 - B.z0) * 0.4
	var A := [B.cx + dx * L, B.cz + dz * L]
	var Bp := [B.cx - dx * L, B.cz - dz * L]
	var length := U.hypot(Bp[0] - A[0], Bp[1] - A[1])
	var n := maxi(3, int(U.jround(length / 42.0)))
	var ux: float = (Bp[0] - A[0]) / length
	var uz: float = (Bp[1] - A[1]) / length
	var px := -uz
	var pz := ux
	var rot := atan2(ux, uz)
	var tops: Array = []
	var pyl: Array = []
	for j in n + 1:
		var x: float = A[0] + (Bp[0] - A[0]) * j / n
		var z: float = A[1] + (Bp[1] - A[1]) * j / n
		var d := w.dist_to_track(x, z, 60.0)
		var y := w.terrain_h(x, z, d)
		tops.append(Vector3(x, maxf(y, 0.0) + 12.5, z))
		if d > HW + 5.0:
			pyl.append({"x": x, "z": z, "y": y})
			if d < HW + 40.0:
				w.add_obstacle(x, z, 1.0)
	var pm := T({"color": 0x5a6270})
	w.inst(boxG, pm, pyl, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.rotation.y = rot
		d.scale = Vector3(0.7, 13, 0.7))
	w.inst(boxG, pm, pyl, func(p, d, i):
		d.position = Vector3(p.x, p.y + 12.6, p.z)
		d.rotation.y = rot
		d.scale = Vector3(4.6, 0.4, 0.4))
	for s: float in [-1.0, 1.0]:
		var pts := PackedVector3Array()
		for q in tops:
			pts.append(Vector3(q.x + px * 1.9 * s, q.y, q.z + pz * 1.9 * s))
		w.add_child(line_strip(pts, 0x2a2e36))
	var C := 30
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Geo.box(1.6, 0.9, 1).translate(0, -1.4, 0).to_mesh()
	mm.instance_count = C
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = T({"color": 0xd8452c})
	mi.custom_aabb = AABB(Vector3(-1e4, -100, -1e4), Vector3(2e4, 300, 2e4))
	w.add_child(mi)
	var d := World.D.new()
	w.anims.append(func(dt, tt):
		for c in C:
			var s := 1.0 if c % 2 == 1 else -1.0
			var u := fmod(float(c) / C + tt * 0.006 * s, 1.0)
			if u < 0.0:
				u += 1.0
			var f := u * n
			var j := mini(n - 1, int(floor(f)))
			var fr := f - j
			var a: Vector3 = tops[j]
			var b: Vector3 = tops[j + 1]
			d.position = Vector3(U.lerpf2(a.x, b.x, fr) + px * 1.9 * s, U.lerpf2(a.y, b.y, fr), U.lerpf2(a.z, b.z, fr) + pz * 1.9 * s)
			d.rotation = Vector3(0, rot, sin(tt * 1.5 + c) * 0.06)
			mm.set_instance_transform(c, d.xf()))


func line_strip(pts: PackedVector3Array, color: int) -> MeshInstance3D:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pts
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arr)
	return w.mesh_node(m, Mats.basic({"color": color}))


func boats(cnt: int) -> void:
	var B: Dictionary = w.bounds
	var made := 0
	var tries := 0
	while made < cnt and tries < 400:
		tries += 1
		var x := U.lerpf2(B.x0 + 20.0, B.x1 - 20.0, R())
		var z := U.lerpf2(B.z0 + 20.0, B.z1 - 20.0, R())
		var dd := w.dist_to_track(x, z, 110.0)
		var y := w.terrain_h(x, z, dd)
		if y > -2.6 or dd < HW + 30.0:
			continue
		made += 1
		var g := w.node()
		var hull_g := Geo.cylinder(1.25, 0.85, 5.6, 6, 1)
		hull_g.rotate_x(PI / 2.0)
		hull_g.scale_xyz(1, 0.55, 1)
		var hull := mesh(hull_g, T({"color": pick([0xf4f1ea, 0xd8452c, 0x2f6bd9, 0xf2c230])}), true)
		hull.position.y = 0.3
		var cab := mesh(Geo.box(1.4, 0.9, 1.6), T({"color": 0xf4f1ea}), true)
		cab.position = Vector3(0, 1, -0.6)
		g.add_child(hull)
		g.add_child(cab)
		if R() < 0.55:
			var mast := mesh(Geo.cylinder(0.08, 0.08, 6, 5), T({"color": 0x6a4a32}), true)
			mast.position = Vector3(0, 3.6, 0.6)
			var sail_g := Geo.new()
			sail_g.pos.append_array([Vector3(0, 0, 0), Vector3(2.6, 0, 0), Vector3(0, 5.2, 0)])
			sail_g.nrm.append_array([Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1)])
			sail_g.uv.append_array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)])
			var sail := mesh(sail_g, T({"color": 0xfbf8f0, "side": "double"}), true)
			sail.rotation.y = PI / 2.0
			sail.position = Vector3(0, 1.1, 0.7)
			g.add_child(mast)
			g.add_child(sail)
		g.position = Vector3(x, -0.55, z)
		g.rotation.y = R() * TAU
		w.add_child(g)
		var ph := R() * TAU
		w.anims.append(func(dt, tt):
			g.position.y = -0.55 + sin(tt * 1.4 + ph) * 0.14
			g.rotation.z = sin(tt * 1.1 + ph) * 0.07
			g.rotation.x = sin(tt * 1.3 + ph * 2.0) * 0.04)


func lighthouse() -> void:
	var B: Dictionary = w.bounds
	var at = null
	var tries := 0
	while tries < 300 and at == null:
		tries += 1
		var x := U.lerpf2(B.x0 + 30.0, B.x1 - 30.0, R())
		var z := U.lerpf2(B.z0 + 30.0, B.z1 - 30.0, R())
		var dd := w.dist_to_track(x, z, 110.0)
		var y := w.terrain_h(x, z, dd)
		if y > 0.2 and dd > HW + 22.0 and dd < 100.0:
			at = {"x": x, "z": z, "y": y}
	if at == null:
		return
	var g := group(at.x, at.y, at.z)
	for j in 5:
		g.add_child(mesh(Geo.cylinder(2.6 - (j + 1) * 0.3, 2.6 - j * 0.3, 3, 12).translate(0, 1.5 + j * 3, 0), T({"color": 0xf6f2e8 if j % 2 == 1 else 0xd8352c}), true))
	var top := mesh(Geo.cylinder(1.6, 1.6, 1.8, 10).translate(0, 15.9, 0), T({"color": 0x2a2e36}))
	var lamp := mesh(Geo.sphere(0.9, 10, 8), Mats.basic({"color": 0xfff2b0}))
	var cap := mesh(Geo.cone(1.9, 1.6, 10).translate(0, 17.6, 0), T({"color": 0xd8352c}))
	lamp.position.y = 16
	var bg := Geo.cone(4, 44, 16, 1, true)
	bg.rotate_z(PI / 2.0)
	bg.translate(22, 0, 0)
	var beam := mesh(bg, Mats.basic({"color": 0xfff2b0, "opacity": 0.16, "blend": "add"}))
	beam.position.y = 16
	g.add_child(top)
	g.add_child(lamp)
	g.add_child(cap)
	g.add_child(beam)
	w.add_obstacle(at.x, at.z, 2.8)
	w.anims.append(func(dt, tt): beam.rotation.y += dt * 0.9)


## NEON billboard: dark panel with a glowing frame and the word (canvas sign in the web build)
func neon_sign(text: String, c1: String, c2: String) -> Node3D:
	var root := w.node()
	var tex := _sign_frame(U.css(c2))
	var mat := Mats.basic({"map": tex, "blend": "alpha"})
	var pn := mesh(Geo.plane(12, 6), mat)
	root.add_child(pn)
	var lb := Label3D.new()
	lb.text = text
	lb.font = UiFonts.sign_font()
	lb.font_size = 50
	lb.pixel_size = 12.0 / 256.0
	lb.outline_size = 14
	var a := U.css(c1)
	lb.outline_modulate = Color(a.r, a.g, a.b, 0.55)
	lb.modulate = a.lerp(Color.WHITE, 0.55)
	lb.double_sided = false
	lb.position = Vector3(0, -2.0 / 256.0 * 12.0, 0.03)
	lb.render_priority = 1
	lb.outline_render_priority = 0
	root.add_child(lb)
	root.set_meta("mat", mat)
	root.set_meta("label", lb)
	return root


static var _frames := {}


static func _sign_frame(c: Color) -> ImageTexture:
	var key := c.to_html()
	if _frames.has(key):
		return _frames[key]
	var w2 := 256
	var h2 := 128
	var img := Image.create(w2, h2, false, Image.FORMAT_RGBA8)
	var bg := Color("#0a0814")
	for y in h2:
		for x in w2:
			# distance to the stroked rectangle (centre line 10px in, 6px wide) with a soft glow
			var dx := minf(absf(x + 0.5 - 10.0), absf(x + 0.5 - (w2 - 10.0)))
			var dy := minf(absf(y + 0.5 - 10.0), absf(y + 0.5 - (h2 - 10.0)))
			var inside_x := x + 0.5 >= 10.0 and x + 0.5 <= w2 - 10.0
			var inside_y := y + 0.5 >= 10.0 and y + 0.5 <= h2 - 10.0
			var dd := 1e9
			if inside_y:
				dd = minf(dd, dx)
			if inside_x:
				dd = minf(dd, dy)
			if not inside_x and not inside_y:
				dd = Vector2(dx, dy).length()
			var stroke := 1.0 if dd <= 3.0 else 0.0
			var glow := exp(-pow(maxf(dd - 3.0, 0.0) / 6.0, 2.0)) * 0.8
			var k := maxf(stroke, glow)
			img.set_pixel(x, y, bg.lerp(c, k))
	var t2 := ImageTexture.create_from_image(img)
	_frames[key] = t2
	return t2


# ------------------------------------------------------------------ environment scenery

func build() -> void:
	match t.env_key:
		"ALPINE":
			alpine()
		"NEON":
			neon()
		"GROVE":
			grove()
		"ISLAND":
			island()
		"COUNTRY":
			country()
		"VOLCANO":
			volcano()
		"WETLANDS":
			wetlands()
		"HARBOR":
			harbor()
		"SALTFLATS":
			saltflats()
		"GREECE":
			greece()
		"TOWN":
			town()
		_:
			canyon()


func canyon() -> void:
	rocks(around(200, HW + 6.0, 90.0), 0xa8512f, 1.5)
	var cacti := around(110, HW + 7.0, 70.0)
	var cg := Geo.cylinder(0.42, 0.5, 1, 7).translate(0, 0.5, 0).to_mesh()
	var arms: Array = []
	for p in cacti:
		if p.r < 0.7:
			var q: Dictionary = p.duplicate()
			q["side"] = 1.0
			arms.append(q)
		if p.r < 0.35:
			var q: Dictionary = p.duplicate()
			q["side"] = -1.0
			arms.append(q)
	w.inst(cg, anim({}, "sway", 0.01), cacti, func(p, d, i):
		var h: float = 3.0 + p.s * 4.0
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(1, h, 1)
		obst(p, 0.7)
		return tint(0x5d8a3e, 1.0))
	w.inst(cg, T(), arms, func(p, d, i):
		var h: float = 3.0 + p.s * 4.0
		d.position = Vector3(p.x + cos(p.a) * 0.7 * p.side, p.y + h * 0.45, p.z + sin(p.a) * 0.7 * p.side)
		d.scale = Vector3(0.7, h * 0.35, 0.7)
		return tint(0x5d8a3e, 1.0))
	w.inst(Geo.icosahedron(0.8, 0), T(), around(240, HW + 5.0, 60.0, 0.5), func(p, d, i):
		d.position = Vector3(p.x, p.y + 0.2, p.z)
		d.scalar(0.6 + p.s)
		return tint(0x9a8a50, 1.5), false)
	# mesas: flat-topped stepped buttes on the horizon
	var mesas := slice(spaced(around(60, HW + 50.0, 190.0, 0.6), 46.0), 16)
	var mg := Geo.cylinder(1, 1.12, 1, 7).translate(0, 0.5, 0).to_mesh()
	w.inst(mg, T(), mesas, func(p, d, i):
		var Rr: float = 10.0 + p.s * 14.0
		var H: float = 12.0 + p.r * 20.0
		d.position = Vector3(p.x, p.y - 1.0, p.z)
		d.scale = Vector3(Rr, H, Rr * (0.8 + p.r * 0.4))
		d.rotation.y = p.a
		return tint(0xb85f3c, 1.2))
	w.inst(mg, T(), mesas.filter(func(p): return p.r > 0.35), func(p, d, i):
		var Rr: float = 10.0 + p.s * 14.0
		var H: float = 12.0 + p.r * 20.0
		d.position = Vector3(p.x, p.y - 1.0 + H, p.z)
		d.scale = Vector3(Rr * 0.62, H * 0.45, Rr * (0.8 + p.r * 0.4) * 0.62)
		d.rotation.y = p.a
		return tint(0xc9744a, 1.2))
	# water towers
	for p in slice(spaced(around(10, HW + 14.0, 50.0), 60.0), 3):
		var g := group(p.x, p.y, p.z)
		var wood := T({"color": 0x7a5236})
		for ab in [[-1, -1], [1, -1], [-1, 1], [1, 1]]:
			var l := mesh(boxG, wood, true)
			l.scale = Vector3(0.35, 8, 0.35)
			l.position = Vector3(ab[0] * 1.6, 0, ab[1] * 1.6)
			g.add_child(l)
		g.add_child(mesh(Geo.cylinder(2.6, 2.6, 4, 10).translate(0, 10, 0), T({"color": 0x9a6a44}), true))
		g.add_child(mesh(Geo.cone(2.9, 1.6, 10).translate(0, 12.8, 0), T({"color": 0x5a3b2a}), true))
		obst(p, 2.6)
	# tumbleweeds rolling with the wind
	for i in 9:
		var ico := Geo.icosahedron(1.1, 1)
		var m: MeshInstance3D
		if i % 2 == 0:
			m = w.mesh_node(_wire(ico), T({"color": 0xa07c4a}), true)
		else:
			m = mesh(ico, T({"color": 0xa07c4a}), true)
		w.add_child(m)
		var sp := 7.0 + R() * 5.0
		var ph := R() * TAU
		var st := {"x": w.bounds.cx, "z": w.bounds.cz, "init": false}
		w.anims.append(func(dt, tt):
			if not st.init or st.x > w.cam_look.x + 170.0:
				st.x = w.cam_look.x - 150.0 - randf() * 60.0
				st.z = w.cam_look.z + (randf() - 0.5) * 180.0
				st.init = true
			st.x += sp * dt
			m.position = Vector3(st.x, 0.9 + absf(sin(tt * 3.2 + ph)) * 1.4, st.z + sin(tt * 0.6 + ph) * 3.0)
			m.rotation.z -= dt * sp / 1.1)
	balloons(3)
	birds(e.birds)


func wetlands() -> void:
	var trees := land(around(300, HW + 8.0, 95.0, 0.3))
	var trunk := Geo.cylinder(0.35, 0.7, 1, 7).translate(0, 0.5, 0)
	var crown := Geo.cone(2.5, 7.5, 7).translate(0, 5.3, 0)
	var crown_top := Geo.cone(1.7, 5.0, 7).translate(0, 9.0, 0)
	w.inst(trunk, T({"color": 0x554333}), trees, func(p, d, i):
		var s: float = 0.8 + p.s * 0.8
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(s, s * 1.5, s)
		d.rotation.y = p.a
		obst(p, 1.1 * s))
	w.inst(crown, anim({}, "sway", 0.012), trees, func(p, d, i):
		var s: float = 0.8 + p.s * 0.8
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(s, s, s)
		d.rotation.y = p.a
		return tint(0x365b43, 0.8))
	w.inst(crown_top, anim({}, "sway", 0.014), trees, func(p, d, i):
		var s: float = 0.8 + p.s * 0.8
		d.position = Vector3(p.x, p.y + 5.0 * s, p.z)
		d.scale = Vector3(s, s, s)
		d.rotation.y = p.a
		return tint(0x496c4b, 0.8))
	var reeds := land(around(260, HW + 5.0, 46.0, 0.05))
	w.inst(Geo.cylinder(0.08, 0.14, 1, 5).translate(0, 0.5, 0), anim({"color": 0x8c9860}, "sway", 0.04), reeds, func(p, d, i):
		var h: float = 1.8 + p.s * 2.8
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(1, h, 1)
		d.rotation.z = (p.r - 0.5) * 0.16
		return tint(0x87905b, 0.65), false)
	rocks(land(around(100, HW + 6.0, 72.0, 0.35)), 0x625e4c, 0.8)
	var cabins: Array = []
	for p in slice(spaced(land(around(32, HW + 18.0, 72.0, 0.2)), 28.0, trees, 8.0), 7):
		cabins.append(house(p, {"wc": col(0x78634b), "rc": col(0x3e4c43), "hw": 5.5, "hd": 5.0, "hh": 3.2, "rh": 2.6, "chim": false}))
	houses(cabins)
	fireflies(190, 0xd8e58a)
	birds(e.birds)


func harbor() -> void:
	var buildings := land(slice(spaced(around(70, HW + 22.0, 125.0, 0.3), 15.0), 46))
	var container_colors := [0xb64f3b, 0x476b78, 0xb88c45, 0x4d6352, 0x74757a]
	w.inst(boxG, T(), buildings, func(p, d, i):
		var h: float = 5.0 + p.s * 5.0
		d.position = Vector3(p.x, p.y, p.z)
		d.rotation.y = p.a
		d.scale = Vector3(9.0 + p.r * 4.0, h, 6.0 + p.s * 2.0)
		if p.d < HW + 55.0:
			w.add_obstacle(p.x, p.z, 5.0)
		return tint(0x8c8272, 0.5))
	var stacks: Array = []
	for p in slice(spaced(land(around(72, HW + 20.0, 110.0, 0.2)), 10.0, buildings, 12.0), 56):
		var base_h: float = 2.6
		for row in range(2 if p.r > 0.42 else 1):
			stacks.append({"x": p.x, "y": p.y + row * base_h, "z": p.z, "a": p.a, "c": pick(container_colors), "h": base_h})
	w.inst(boxG, T(), stacks, func(p, d, i):
		d.position = Vector3(p.x, p.y + p.h * 0.5, p.z)
		d.rotation.y = p.a
		d.scale = Vector3(8.0, p.h, 2.8)
		if p.y < 3.0 and w.dist_to_track(p.x, p.z, 60.0) < HW + 48.0:
			w.add_obstacle(p.x, p.z, 2.3)
		return tint(p.c, 0.25))
	var cranes := slice(spaced(land(around(14, HW + 45.0, 135.0, 0.4)), 24.0, buildings, 20.0), 5)
	for p in cranes:
		var g := group(p.x, p.y, p.z)
		var steel := T({"color": 0x48585b})
		for side: float in [-1.0, 1.0]:
			var leg := mesh(boxG, steel, true)
			leg.scale = Vector3(0.8, 22.0, 0.8)
			leg.position = Vector3(side * 7.0, 0.0, 0.0)
			g.add_child(leg)
		var beam := mesh(boxG, steel, true)
		beam.scale = Vector3(18.0, 0.9, 1.0)
		beam.position.y = 22.0
		g.add_child(beam)
		var boom := mesh(boxG, T({"color": 0xd4a34e}), true)
		boom.scale = Vector3(1.0, 0.7, 23.0)
		boom.position = Vector3(0.0, 21.0, -11.0)
		g.add_child(boom)
		var cable := mesh(Geo.cylinder(0.08, 0.08, 1.0, 5), T({"color": 0x242d30}))
		cable.position = Vector3(0.0, 14.0, -18.0)
		cable.scale.y = 12.0
		g.add_child(cable)
		obst(p, 2.0)
	# Mooring bollards and dock lamps give the road edge a working-pier scale.
	var bollards := around(42, HW + 5.0, 22.0, 0.0)
	w.inst(Geo.cylinder(0.42, 0.55, 0.9, 8).translate(0, 0.45, 0), T({"color": 0x3a4242}), bollards, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.rotation.y = p.a
		obst(p, 0.55))
	var tanks := slice(spaced(land(around(12, HW + 34.0, 118.0, 0.4)), 18.0, buildings, 15.0), 5)
	w.inst(Geo.cylinder(5.0, 5.0, 9.0, 16).translate(0, 4.5, 0), T({"color": 0x9a9c92}), tanks, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.scalar(0.8 + p.s * 0.4)
		d.rotation.y = p.a
		obst(p, 4.0))
	birds(e.birds)


func saltflats() -> void:
	# Low crystalline ridges and scattered mineral outcrops break up the broad, flat horizon.
	var crystals := around(220, HW + 12.0, 135.0, 0.55)
	w.inst(Geo.cone(1.0, 1.0, 5).translate(0, 0.5, 0), T(), crystals, func(p, d, i):
		var s: float = 0.6 + p.s * 1.2
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(s, 0.35 + p.r * 1.1, s)
		d.rotation.y = p.a
		return tint(0xe6dec9, 0.35), false)
	var outcrops := around(80, HW + 8.0, 92.0, 0.35)
	w.inst(Geo.icosahedron(1.0, 0), T(), outcrops, func(p, d, i):
		d.position = Vector3(p.x, p.y + 0.3, p.z)
		d.scale = Vector3(1.4 + p.s * 2.2, 0.35 + p.r * 0.9, 1.2 + p.s * 1.8)
		d.rotation.y = p.a
		return tint(0xb9ae94, 0.5), false)
	rocks(slice(spaced(around(60, HW + 45.0, 175.0, 0.6), 25.0), 22), 0x8b806c, 0.45)
	# Sparse survey markers make the immense pale landscape legible at speed.
	var markers := slice(spaced(around(26, HW + 35.0, 115.0, 0.35), 24.0), 10)
	w.inst(Geo.cylinder(0.18, 0.22, 4.5, 6).translate(0, 2.25, 0), T({"color": 0x756b5a}), markers, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.rotation.y = p.a
		w.add_obstacle(p.x, p.z, 0.4))
	w.inst(Geo.box(1.0, 0.8, 0.12).translate(0, 0.4, 0), T({"color": 0xe2a24b}), markers, func(p, d, i):
		d.position = Vector3(p.x, p.y + 3.4, p.z)
		d.rotation.y = p.a
		return tint(0xe2a24b, 0.2), false)
	birds(e.birds)


## Wireframe version of a mesh (three.js wireframe: every triangle edge)
func _wire(g: Geo) -> ArrayMesh:
	var p := PackedVector3Array()
	var n := PackedVector3Array()
	var src := g.duplicate_geo().to_non_indexed()
	var seen := {}
	var i := 0
	while i + 2 < src.pos.size():
		for k in 3:
			var a := src.pos[i + k]
			var b := src.pos[i + (k + 1) % 3]
			var key := str(a.snapped(Vector3.ONE * 0.001)) + str(b.snapped(Vector3.ONE * 0.001))
			var key2 := str(b.snapped(Vector3.ONE * 0.001)) + str(a.snapped(Vector3.ONE * 0.001))
			if seen.has(key) or seen.has(key2):
				continue
			seen[key] = true
			p.append(a)
			p.append(b)
			n.append(a.normalized())
			n.append(b.normalized())
		i += 3
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = p
	arr[Mesh.ARRAY_NORMAL] = n
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
	return m


func alpine() -> void:
	var pines := around(420, HW + 6.0, 85.0)
	var c1 := Geo.cone(2.3, 4.4, 7).translate(0, 3.6, 0)
	var c2 := Geo.cone(1.6, 3.6, 7).translate(0, 6.2, 0)
	var tr := Geo.cylinder(0.3, 0.4, 1.6, 6).translate(0, 0.8, 0)
	var set := func(p, d):
		var s: float = 0.75 + p.s * 0.85
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(s, s * (0.9 + p.r * 0.4), s)
		d.rotation.y = p.a
	w.inst(tr, T({"color": 0x4a3628}), pines, func(p, d, i): set.call(p, d))
	w.inst(c1, anim({}, "sway", 0.02), pines, func(p, d, i):
		set.call(p, d)
		obst(p, 1.5 * (0.75 + p.s * 0.85))
		return tint(0x2a5040, 1.0))
	var snow := col(0xf2f6fa)
	w.inst(c2, anim({}, "sway", 0.02), pines, func(p, d, i):
		set.call(p, d)
		return col(0x2f5444).lerp(snow, 0.4 + p.r * 0.45))
	rocks(around(90, HW + 6.0, 80.0), 0x7d8896, 1.0)
	# chalets with snowy roofs
	var ch := slice(spaced(around(60, HW + 16.0, 70.0, 0.1), 22.0, pines, 6.0), 12)
	var hl: Array = []
	for p in ch:
		var wc := tint(0x8a5a3a, 1.0)
		var rh := 3.2 + R() * 1.4
		hl.append(house(p, {"wc": wc, "rc": col(0xf4f8fb), "rh": rh, "chim": true}))
	houses(hl)
	# frozen ponds
	for p in slice(spaced(around(12, HW + 30.0, 140.0, 0.6), 60.0), 3):
		var m := mesh(Geo.circle(10.0 + p.s * 12.0, 20), T({"color": 0xbfe3f2}))
		m.rotation.x = -PI / 2.0
		m.scale.y = 0.6 + p.r * 0.5
		m.position = Vector3(p.x, p.y + 0.08, p.z)
		w.add_child(m)
	ski_lift()
	birds(e.birds)


func neon() -> void:
	var bl := around(150, HW + 22.0, 110.0, 0.35)
	var wt := Tex.windows()
	var side := T({"map": wt, "emissive": 0xffffff, "emissive_map": true, "emissive_i": 1.1})
	var roof := T({"color": 0x2a2448})
	var bm := Geo.box(1, 1, 1).translate(0, 0.5, 0).to_mesh()
	w.inst(bm, [side, side, roof, roof, side, side], bl, func(p, d, i):
		var ww: float = 8.0 + p.r * 12.0
		var h: float = 8.0 + p.s * p.s * 40.0
		d.position = Vector3(p.x, 0, p.z)
		d.scale = Vector3(ww, h, 8.0 + fmod(p.r * 7.0, 1.0) * 12.0)
		d.rotation.y = p.a
		return col(0xffffff))
	var glow_p := PackedVector3Array()
	var glow_c: Array = []
	var lamps: Array = []
	var pal := [col(0xff4bd8), col(0x38e8ff), col(0xffcf6a)]
	for i in bl.size():
		if i % 3 != 0:
			continue
		var p: Dictionary = bl[i]
		var h: float = 8.0 + p.s * p.s * 40.0
		glow_p.append(Vector3(p.x, h + 1.0, p.z))
		glow_c.append(pal[i % 3])
	var i2 := 6
	while i2 < t.n:
		if t.py[i2] <= 0.05:
			# (i/18)%2 is never an integer for these i in the web build, so the lamps all sit on the same side
			var s := 1.0 if fmod(i2 / 18.0, 2.0) != 0.0 else -1.0
			var o := s * (HW + 3.2)
			lamps.append({"x": t.px[i2] + t.nx[i2] * o, "z": t.pz[i2] + t.nz[i2] * o, "c": pal[(i2 / 18) % 2]})
		i2 += 18
	w.inst(Geo.cylinder(0.18, 0.22, 7, 6).translate(0, 3.5, 0), T({"color": 0x3a3660}), lamps, func(p, d, i):
		d.position = Vector3(p.x, 0, p.z)
		w.add_obstacle(p.x, p.z, 0.5))
	for p in lamps:
		glow_p.append(Vector3(p.x, 7.3, p.z))
		glow_c.append(p.c)
	w.sprites(glow_p, glow_c, 7.0, {"blend": "add"})
	var pool := Geo.plane(16, 16)
	pool.rotate_x(-PI / 2.0)
	w.inst(pool, Mats.basic({"map": Tex.radial(), "opacity": 0.24, "blend": "add"}), lamps, func(p, d, i):
		d.position = Vector3(p.x, 0.11, p.z)
		return p.c, false)
	# light arches spanning the road, pulsing in a chase pattern
	var arches: Array = []
	var i3 := 30
	while i3 < t.n - 30:
		var skip := false
		for c in t.cps:
			if absi(c - i3) < 10:
				skip = true
		for o in [-8, 0, 8]:
			if t.py[(i3 + o + t.n) % t.n] > 0.0:
				skip = true
		if not skip and w.other_road_dist(t.px[i3], t.pz[i3], i3) < HW * 2.0 + 6.0:
			skip = true
		if not skip:
			arches.append(i3)
		i3 += 46
	var pil: Array = []
	for j in arches.size():
		var i: int = arches[j]
		for s: float in [-1.0, 1.0]:
			pil.append({"x": t.px[i] + t.nx[i] * s * (HW + 2.4), "z": t.pz[i] + t.nz[i] * s * (HW + 2.4)})
		var m := Mats.basic({"color": pal[j % 3], "blend": "add"})
		var b := mesh(Geo.box(HW * 2.0 + 5.4, 0.55, 0.55), m)
		b.position = Vector3(t.px[i], 10.2, t.pz[i])
		b.rotation.y = atan2(t.tx[i], t.tz[i]) + PI / 2.0
		w.add_child(b)
		var jj := j
		w.anims.append(func(dt, tt): m.set_shader_parameter("opacity", 0.35 + 0.65 * maxf(0.0, sin(tt * 3.0 - jj * 0.9))))
	w.inst(boxG, T({"color": 0x3a3660}), pil, func(p, d, i):
		d.position = Vector3(p.x, 0, p.z)
		d.scale = Vector3(0.9, 10.5, 0.9)
		w.add_obstacle(p.x, p.z, 0.8))
	# billboards leaning towards the camera
	var words := [["SEEDLINE", "#ff4bd8", "#38e8ff"], ["RAMEN", "#ffcf6a", "#ff4bd8"], ["OPEN 24/7", "#38e8ff", "#7a6bff"], ["DRIFT CLUB", "#ff4bd8", "#ffcf6a"],
		["HOTEL", "#7af0c0", "#38e8ff"], ["ARCADE", "#ffcf6a", "#7a6bff"], ["NOODLES", "#38e8ff", "#ff4bd8"], ["TURBO", "#ff6a6a", "#ffcf6a"]]
	var signs := slice(spaced(around(40, HW + 9.0, 34.0, 0.0), 40.0), 10)
	for j in signs.size():
		var p: Dictionary = signs[j]
		var wd: Array = words[j % words.size()]
		var gr := group(p.x, 0, p.z)
		gr.rotation.y = PI
		for s: float in [-1.0, 1.0]:
			var po := mesh(boxG, T({"color": 0x3a3660}))
			po.scale = Vector3(0.5, 7, 0.5)
			po.position.x = s * 4.5
			gr.add_child(po)
		var sign := neon_sign(wd[0], wd[1], wd[2])
		sign.position.y = 9.2
		sign.rotation.x = -0.55
		gr.add_child(sign)
		obst(p, 1.0)
		if j % 3 == 1:
			var sm: ShaderMaterial = sign.get_meta("mat")
			var lb: Label3D = sign.get_meta("label")
			w.anims.append(func(dt, tt):
				var o := 0.25 if (sin(tt * 23.0) > 0.92 or sin(tt * 1.7) > 0.97) else 1.0
				sm.set_shader_parameter("opacity", o)
				lb.modulate.a = o
				lb.outline_modulate.a = 0.55 * o)


func grove() -> void:
	var trees := around(330, HW + 6.0, 85.0)
	round_trees(trees, [0xd9762b, 0xc2452d, 0xe8b23a, 0x6f8f3a, 0x9a5a2a, 0x55772f], 0.03)
	w.inst(Geo.icosahedron(1, 0), T(), around(240, HW + 5.0, 60.0, 0.4), func(p, d, i):
		d.position = Vector3(p.x, p.y + 0.3, p.z)
		d.scale = Vector3(1.0 + p.s, 0.7 + p.s * 0.5, 1.0 + p.r)
		return tint(0x4f6a2e, 1.4), false)
	var hl: Array = []
	for p in slice(spaced(around(40, HW + 15.0, 60.0, 0.1), 24.0, trees, 6.0), 7):
		var wc := tint(0x7a5434, 1.0)
		var rc := col(pick([0x3d5a2e, 0x8a3b2b, 0x5a4a3a]))
		var hw := 5.0 + R() * 2.0
		var hd := 5.0 + R() * 2.0
		var hh := 3.0 + R()
		hl.append(house(p, {"wc": wc, "rc": rc, "hw": hw, "hd": hd, "hh": hh, "chim": true}))
	houses(hl)
	# mushrooms by the road
	var mush := around(80, HW + 4.0, 26.0, 0.0)
	w.inst(Geo.cylinder(0.25, 0.32, 1, 7).translate(0, 0.5, 0), T({"color": 0xf1ece0}), mush, func(p, d, i):
		var s: float = 0.8 + p.s * 1.2
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(s, s * 1.1, s), false)
	w.inst(Geo.sphere(0.8, 10, 6, 0, TAU, 0, PI / 2.0), T(), mush, func(p, d, i):
		var s: float = 0.8 + p.s * 1.2
		d.position = Vector3(p.x, p.y + s * 1.05, p.z)
		d.scale = Vector3(s, s * 0.8, s)
		return col(0xd23b2b if p.r < 0.6 else 0xc8913a), false)
	# fallen logs
	w.inst(Geo.cylinder(0.6, 0.6, 1, 8).rotate_z(PI / 2.0), T({"color": 0x6a4a32}), around(18, HW + 6.0, 40.0), func(p, d, i):
		d.position = Vector3(p.x, p.y + 0.5, p.z)
		d.rotation.y = p.a
		d.scale = Vector3(4.0 + p.s * 5.0, 1, 1)
		obst(p, 1.2))
	fireflies(160, 0xd8ff6a)
	birds(e.birds)


func island() -> void:
	var palms := land(around(320, HW + 5.0, 70.0, 0.15))
	var tr := Geo.cylinder(0.22, 0.38, 7.4, 6).translate(0, 3.7, 0)
	var crown := Geo.cone(3.8, 1.7, 7).rotate_x(PI).translate(0, 7.3, 0)
	var nut := Geo.icosahedron(0.7, 0).translate(0, 6.9, 0)
	var set := func(p, d):
		var s: float = 0.75 + p.s * 0.6
		d.position = Vector3(p.x, p.y, p.z)
		d.scalar(s)
		d.rotation = Vector3((p.r - 0.5) * 0.55, p.a, (p.s - 0.5) * 0.55)
	w.inst(tr, anim({}, "sway", 0.012), palms, func(p, d, i):
		set.call(p, d)
		obst(p, 0.9)
		return tint(0x8a6a45, 1.0))
	w.inst(crown, anim({}, "sway", 0.012), palms, func(p, d, i):
		set.call(p, d)
		return tint(0x3f9a3a if p.r < 0.5 else 0x5ab83c, 1.2))
	w.inst(nut, anim({"color": 0x5a4027}, "sway", 0.012), palms, func(p, d, i): set.call(p, d))
	rocks(land(around(120, HW + 6.0, 80.0, 0.3)), 0x9a8f80, 1.0)
	w.inst(Geo.icosahedron(1, 0), T(), land(around(200, HW + 5.0, 50.0, 0.2)), func(p, d, i):
		d.position = Vector3(p.x, p.y + 0.3, p.z)
		d.scale = Vector3(1.0 + p.s, 0.6 + p.s * 0.4, 1.0 + p.r)
		return tint(0x5e9a3c, 1.3), false)
	var hl: Array = []
	for p in slice(spaced(land(around(60, HW + 14.0, 40.0, 0.0)), 22.0, palms, 5.0), 8):
		var wc := tint(0xe2c48a, 1.0)
		var rc := tint(0xa07a3c, 1.0)
		var hw := 5.0 + R() * 2.0
		var hd := 5.0 + R() * 2.0
		var hh := 2.8 + R()
		hl.append(house(p, {"wc": wc, "rc": rc, "hw": hw, "hd": hd, "hh": hh, "rh": 3.0, "chim": false}))
	houses(hl)
	boats(10)
	lighthouse()
	birds(e.birds)


func country() -> void:
	var farms := slice(spaced(around(40, HW + 30.0, 110.0, 0.4), 80.0), 5)
	var built: Array = []
	for p in farms:
		var r := face(p)
		var fx := cos(r)
		var fz := -sin(r)
		built.append(house(p, {"wc": col(0xc23b2b), "rc": col(0x4a3a34), "hw": 12.0, "hd": 9.0, "hh": 6.0, "rh": 4.2, "chim": false}))
		var rc := col(pick([0x8a3b2b, 0x3d5a8a]))
		built.append(house({"x": p.x + fx * 16.0, "z": p.z + fz * 16.0, "y": p.y, "d": p.d + 4.0, "i": p.i}, {"wc": col(0xf6f1e6), "rc": rc, "chim": true}))
		var sx: float = p.x - fx * 11.0
		var sz: float = p.z - fz * 11.0
		var g := group(sx, p.y, sz)
		g.add_child(mesh(Geo.cylinder(2.4, 2.4, 12, 12).translate(0, 6, 0), T({"color": 0xc9ced6}), true))
		g.add_child(mesh(Geo.sphere(2.4, 12, 6, 0, TAU, 0, PI / 2.0).translate(0, 12, 0), T({"color": 0x9aa3ad}), true))
		if p.d < HW + 60.0:
			w.add_obstacle(sx, sz, 2.6)
	houses(built)
	for p in slice(spaced(around(20, HW + 25.0, 120.0, 0.5), 70.0, farms, 30.0), 4):
		windmill(p)
	var trees := spaced(around(240, HW + 7.0, 90.0, 0.3), 3.5, farms, 22.0)
	round_trees(slice(trees, 170), [0x5aa83c, 0x4a9a34, 0x7ab84a, 0x3f8a30], 0.035)
	var bales := around(60, HW + 8.0, 90.0, 0.4)
	w.inst(Geo.cylinder(1.1, 1.1, 1.6, 12).rotate_z(PI / 2.0).translate(0, 1.1, 0), T({"color": 0xe3c05a}), bales, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.rotation.y = p.a
		obst(p, 1.3))
	var cows := slice(spaced(around(60, HW + 12.0, 70.0, 0.2), 3.0), 30)
	w.inst(boxG, T(), cows, func(p, d, i):
		d.position = Vector3(p.x, p.y + 0.6, p.z)
		d.rotation.y = p.a
		d.scale = Vector3(1.3, 1.1, 2.5)
		obst(p, 1.4)
		return col(0xf4f1ea if p.r < 0.5 else 0x7a4a2e))
	w.inst(boxG, T({"color": 0x2a2420}), cows, func(p, d, i):
		d.position = Vector3(p.x + sin(p.a) * 1.5, p.y + 1.1, p.z + cos(p.a) * 1.5)
		d.rotation.y = p.a
		d.scale = Vector3(0.8, 0.75, 0.9))
	balloons(4)
	birds(e.birds)


func volcano() -> void:
	var cones := slice(spaced(around(30, HW + 70.0, 210.0, 0.6), 130.0), 4)
	for p in cones:
		var Rr: float = 36.0 + p.s * 30.0
		var H: float = 30.0 + p.r * 24.0
		var m := mesh(Geo.cylinder(Rr * 0.18, Rr, H, 14, 1).translate(0, H / 2.0, 0), T({"color": tint(0x3a302e, 1.0)}), true)
		m.position = Vector3(p.x, p.y - 1.0, p.z)
		w.add_child(m)
		var cr := mesh(Geo.circle(Rr * 0.16, 14), Mats.basic({"color": 0xff7a2a}))
		cr.rotation.x = -PI / 2.0
		cr.position = Vector3(p.x, p.y + H - 0.9, p.z)
		w.add_child(cr)
		w.emit(p.x, p.y + H, p.z, 2.2, 9.0, 0x5a4a48, 7.0)
		w.emit(p.x, p.y + H, p.z, 0.8, 5.0, 0xff7a2a, 2.2)
	var sp := around(80, HW + 6.0, 90.0)
	w.inst(Geo.cone(1, 1, 5).translate(0, 0.5, 0), T(), sp, func(p, d, i):
		d.position = Vector3(p.x, p.y - 0.3, p.z)
		d.scale = Vector3(1.4 + p.s * 1.8, 5.0 + p.r * 10.0, 1.4 + p.s * 1.8)
		d.rotation.y = p.a
		obst(p, 1.5 + p.s)
		return tint(0x2a2230, 1.0))
	rocks(land(around(140, HW + 6.0, 80.0, 0.3)), 0x4a4140, 1.0)
	var dead := land(around(50, HW + 6.0, 60.0, 0.2))
	w.inst(Geo.cylinder(0.25, 0.45, 5, 5).translate(0, 2.5, 0), T({"color": 0x231d1c}), dead, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.rotation = Vector3((p.r - 0.5) * 0.3, p.a, (p.s - 0.5) * 0.3)
		obst(p, 0.6))
	w.inst(Geo.cylinder(0.12, 0.2, 2.6, 4).translate(0, 1.3, 0), T({"color": 0x231d1c}), dead, func(p, d, i):
		d.position = Vector3(p.x, p.y + 3.0, p.z)
		d.rotation = Vector3(0, p.a, 0.9))
	# vents along the lava shore
	for p in land(around(14, HW + 12.0, 40.0, 0.0)):
		w.emit(p.x, p.y + 0.5, p.z, 0.7, 2.5, 0x6a5a56, 3.0)


func greece() -> void:
	var marble := 0xf1ece0
	var stoneT := T({"color": marble})
	var boxG2 := boxG
	var colG := Geo.cylinder(0.55, 0.62, 1, 12).translate(0, 0.5, 0).to_mesh()
	# olive groves and cypress lines on the dry hills
	var olives := land(around(240, HW + 6.0, 80.0, 0.2))
	w.inst(Geo.cylinder(0.3, 0.55, 2.6, 6).translate(0, 1.3, 0), T({"color": 0x6a5a48}), olives, func(p, d, i):
		var s: float = 0.8 + p.s * 0.6
		d.position = Vector3(p.x, p.y, p.z)
		d.scalar(s)
		d.rotation = Vector3((p.r - 0.5) * 0.4, p.a, (p.s - 0.5) * 0.4))
	w.inst(Geo.icosahedron(2.4, 1).scale_xyz(1, 0.62, 1).translate(0, 3.3, 0), anim({}, "sway", 0.025), olives, func(p, d, i):
		var s: float = 0.8 + p.s * 0.6
		d.position = Vector3(p.x, p.y, p.z)
		d.scalar(s)
		d.rotation.y = p.a
		obst(p, 1.2 * s)
		return tint(0x8a9a62 if p.r < 0.5 else 0x9aa874, 1.0))
	var cyp := land(around(90, HW + 8.0, 70.0, 0.1))
	w.inst(Geo.cone(1.2, 9, 8).translate(0, 4.5, 0), anim({}, "sway", 0.012), cyp, func(p, d, i):
		var s: float = 0.8 + p.s * 0.5
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(s, s * (0.9 + p.r * 0.5), s)
		obst(p, 1.0)
		return tint(0x2f5a32, 1.0))
	rocks(land(around(110, HW + 6.0, 80.0, 0.3)), 0xd8d0bc, 1.0)
	# temples: stepped platform, a ring of columns, entablature and pediment roof
	var temples := slice(spaced(land(around(30, HW + 24.0, 90.0, 0.3)).filter(func(p): return p.y > 0.2), 70.0), 2)
	for ti in temples.size():
		var p: Dictionary = temples[ti]
		var cw := 5 if ti > 0 else 6
		var cl := 9 if ti > 0 else 11
		var sp := 3.2
		var W2 := (cw - 1) * sp
		var L2 := (cl - 1) * sp
		var H := 9.0
		var g := group(p.x, p.y - 0.3, p.z)
		g.rotation.y = face(p) + PI / 2.0
		for k in 3:
			var m := mesh(boxG2, stoneT, true)
			m.scale = Vector3(W2 + 6.0 - k * 1.4, 0.6, L2 + 6.0 - k * 1.4)
			m.position.y = k * 0.6
			g.add_child(m)
		var cols: Array = []
		for i in cw:
			for j in cl:
				if i == 0 or j == 0 or i == cw - 1 or j == cl - 1:
					cols.append([i * sp - W2 / 2.0, j * sp - L2 / 2.0])
		w.inst(colG, stoneT, cols, func(c, d, i):
			d.position = Vector3(c[0], 1.8, c[1])
			d.scale = Vector3(1, H, 1), true, g)
		var ent := mesh(boxG2, stoneT, true)
		ent.scale = Vector3(W2 + 2.4, 1.5, L2 + 2.4)
		ent.position.y = 1.8 + H
		g.add_child(ent)
		var fr := mesh(boxG2, T({"color": 0x2f6bd9}))
		fr.scale = Vector3(W2 + 2.5, 0.35, L2 + 2.5)
		fr.position.y = 1.8 + H + 0.9
		g.add_child(fr)
		var rf := mesh(roofG, T({"color": 0xc0653a if ti > 0 else marble}), true)
		rf.scale = Vector3(W2 + 2.8, 2.6, L2 + 2.8)
		rf.position.y = 1.8 + H + 1.5
		g.add_child(rf)
		if p.d < HW + 60.0:
			w.add_obstacle(p.x, p.z, maxf(W2, L2) / 2.0 + 2.0)
	# ruins: broken columns, fallen drums and scattered blocks
	var ruins := land(around(70, HW + 7.0, 60.0, 0.2))
	w.inst(colG, stoneT, ruins.filter(func(p): return p.r < 0.55), func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(1, 1.5 + p.s * 5.0, 1)
		obst(p, 0.9)
		return tint(marble, 0.8))
	w.inst(Geo.cylinder(0.55, 0.55, 1.4, 12).rotate_z(PI / 2.0).translate(0, 0.55, 0), stoneT, ruins.filter(func(p): return p.r >= 0.55), func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.rotation.y = p.a
		obst(p, 1.0)
		return tint(marble, 0.8))
	w.inst(boxG2, stoneT, land(around(40, HW + 6.0, 50.0, 0.2)), func(p, d, i):
		d.position = Vector3(p.x, p.y - 0.1, p.z)
		d.rotation = Vector3(0, p.a, (p.r - 0.5) * 0.3)
		d.scale = Vector3(1.2 + p.s, 0.8 + p.r * 0.6, 1.6 + p.r)
		obst(p, 1.0)
		return tint(0xe8e0cc, 1.0))
	# amphorae
	var vp: Array = []
	for q in [[0, 0], [0.25, 0.05], [0.42, 0.5], [0.38, 0.95], [0.18, 1.15], [0.2, 1.35], [0, 1.35]]:
		vp.append(Vector2(q[0], q[1]))
	w.inst(Geo.lathe(vp, 10), T({"color": 0xc0653a}), land(around(36, HW + 5.0, 30.0, 0.0)), func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.scalar(0.9 + p.s * 0.6)
		d.rotation.z = 1.4 if p.r < 0.2 else 0.0, false)
	# marble statues on plinths
	var st := slice(spaced(land(around(30, HW + 6.0, 22.0, 0.0)), 40.0), 8)
	w.inst(boxG2, stoneT, st, func(p, d, i):
		d.position = Vector3(p.x, p.y, p.z)
		d.scale = Vector3(1.4, 1.4, 1.4)
		d.rotation.y = face(p)
		obst(p, 1.0))
	w.inst(Geo.cylinder(0.32, 0.45, 2.2, 8).translate(0, 2.5, 0), stoneT, st, func(p, d, i): d.position = Vector3(p.x, p.y, p.z))
	w.inst(Geo.sphere(0.34, 10, 8).translate(0, 3.9, 0), stoneT, st, func(p, d, i): d.position = Vector3(p.x, p.y, p.z))
	# open-air theatre: stepped half rings facing the road
	var thl := spaced(land(around(20, HW + 40.0, 100.0, 0.3)).filter(func(p): return p.y > 0.2), 10.0, temples, 50.0)
	if not thl.is_empty():
		var th: Dictionary = thl[0]
		var g := group(th.x, th.y - 0.2, th.z)
		g.rotation.y = face(th)
		for k in 7:
			var ri := 7.0 + k * 2.2
			var ro := ri + 2.2
			var m := mesh(_half_ring(ri, ro, 0.7 + k * 0.7), stoneT, true)
			m.rotation.y = PI
			g.add_child(m)
		var stage := mesh(boxG2, T({"color": 0xe2d8c2}))
		stage.scale = Vector3(18, 0.5, 5)
		stage.position.z = -3
		g.add_child(stage)
		obst(th, 20.0)
	# aqueduct striding across the hills
	var B: Dictionary = w.bounds
	var ang := R() * PI
	var dx := cos(ang)
	var dz := sin(ang)
	var L := minf(B.x1 - B.x0, B.z1 - B.z0) * 0.38
	var ox: float = B.cx + (R() - 0.5) * 60.0
	var oz: float = B.cz + (R() - 0.5) * 60.0
	var piers: Array = []
	var spans: Array = []
	var s := -L
	while s <= L:
		var x := ox + dx * s
		var z := oz + dz * s
		var dd := w.dist_to_track(x, z, 40.0)
		if dd >= HW + 7.0:
			var y := w.terrain_h(x, z, dd)
			if y >= -0.2:
				piers.append({"x": x, "z": z, "y": y})
				spans.append({"x": x + dx * 4.5, "z": z + dz * 4.5, "y": y})
		s += 9.0
	var rot := atan2(dx, dz)
	w.inst(boxG2, stoneT, piers, func(p, d, i):
		d.position = Vector3(p.x, p.y - 0.5, p.z)
		d.rotation.y = rot
		d.scale = Vector3(2.4, 12.5, 2.4)
		if w.dist_to_track(p.x, p.z, 60.0) < HW + 45.0:
			w.add_obstacle(p.x, p.z, 1.6))
	w.inst(boxG2, stoneT, spans, func(p, d, i):
		d.position = Vector3(p.x, 12, p.z)
		d.rotation.y = rot
		d.scale = Vector3(2.6, 2.2, 9.2))
	w.inst(boxG2, T({"color": 0x5aa8c8}), spans, func(p, d, i):
		d.position = Vector3(p.x, 14.15, p.z)
		d.rotation.y = rot
		d.scale = Vector3(1.2, 0.1, 9.2), false)
	boats(7)
	birds(e.birds)


## Theatre step: extruded half annulus (three.js Shape + ExtrudeGeometry, rotated to lie flat)
func _half_ring(ri: float, ro: float, depth: float) -> Geo:
	var segs := 16
	var outline: Array = []
	for k in segs + 1:
		var a := PI * k / segs
		outline.append(Vector2(cos(a) * ro, sin(a) * ro))
	for k in segs + 1:
		var a := PI - PI * k / segs
		outline.append(Vector2(cos(a) * ri, sin(a) * ri))
	return Geo.extrude_flat(outline, depth).rotate_x(PI / 2.0).translate(0, depth, 0)


func town() -> void:
	var walls := [0xf6e7c8, 0xf2c6b4, 0xcfe3d9, 0xf7d9a0, 0xd9e2f0, 0xf0b8a8, 0xe8e0f5, 0xfbefd9]
	var roofs := [0xc2452d, 0x8a3b2b, 0x3d5a8a, 0x5a5f6a, 0xb5652f, 0x7a3b5a]
	var cand: Array = []
	var i := 0
	while i < t.n:
		for s: float in [-1.0, 1.0]:
			for row in [0, 1]:
				if row == 1 and R() < 0.3:
					continue
				var off: float = HW + 11.0 + R() * 4.0 + row * 17.0
				var x: float = t.px[i] + t.nx[i] * off * s
				var z: float = t.pz[i] + t.nz[i] * off * s
				var d := w.dist_to_track(x, z, off + 12.0)
				if d < HW + 9.0 or (t.river != null and w._river_dist(x, z) < float(t.river.w) + 8.0):
					continue
				var y := w.terrain_h(x, z, d)
				var r := R()
				var s2 := R()
				cand.append({"x": x, "z": z, "d": d, "i": i, "y": y, "r": r, "s": s2, "a": 0.0})
		i += 8
	var hs := spaced(cand, 10.5)
	var hl: Array = []
	for p in hs:
		var wc := col(pick(walls))
		var rc := col(pick(roofs))
		var hw := 7.0 + R() * 3.0
		var hd := 6.5 + R() * 2.5
		var hh := 4.0 + R() * 5.0
		var chim := R() < 0.4
		hl.append(house(p, {"wc": wc, "rc": rc, "hw": hw, "hd": hd, "hh": hh, "chim": chim}))
	houses(hl)
	var trees := spaced(around(200, HW + 6.0, 70.0, 0.3), 4.0, hs, 8.0)
	round_trees(slice(trees, 110), [0x5aa83c, 0x4a9a34, 0x7ab84a], 0.03)
	# street lamps with warm pools of light
	var lamps: Array = []
	var li := 4
	while li < t.n:
		if t.py[li] <= 0.05:
			var s := 1.0 if (li / 16) % 2 == 1 else -1.0
			var o := s * (HW + 3.4)
			lamps.append({"x": t.px[li] + t.nx[li] * o, "z": t.pz[li] + t.nz[li] * o})
		li += 16
	w.inst(Geo.cylinder(0.15, 0.2, 6, 6).translate(0, 3, 0), T({"color": 0x2a2e36}), lamps, func(p, d, i2):
		d.position = Vector3(p.x, 0, p.z)
		w.add_obstacle(p.x, p.z, 0.45))
	var gp := PackedVector3Array()
	for p in lamps:
		gp.append(Vector3(p.x, 6.2, p.z))
	w.sprites(gp, null, 3.0, {"blend": "add", "color": 0xffd59a, "opacity": 0.8})
	var pool := Geo.plane(13, 13)
	pool.rotate_x(-PI / 2.0)
	w.inst(pool, Mats.basic({"map": Tex.radial(), "color": 0xe0a050, "opacity": 0.12, "blend": "add"}), lamps, func(p, d, i2):
		d.position = Vector3(p.x, 0.12, p.z), false)
	# parked cars on the kerb
	var pk: Array = []
	var ci := 10
	while ci < t.n:
		if R() < 0.55 or absf(t.k[ci]) > 0.012 or t.py[ci] > 0.05:
			ci += 7
			continue
		var s := -1.0 if R() < 0.5 else 1.0
		var o := s * (HW + 6.0)
		pk.append({"x": t.px[ci] + t.nx[ci] * o, "z": t.pz[ci] + t.nz[ci] * o, "a": atan2(t.tx[ci], t.tz[ci]), "c": col(pick([0xe8402c, 0x2f6bd9, 0xf2c230, 0xf4f1ea, 0x2ec27e, 0x3a3f4a]))})
		ci += 7
	var pks := spaced(pk, 6.0)
	w.inst(boxG, T(), pks, func(p, d, i2):
		d.position = Vector3(p.x, 0.25, p.z)
		d.rotation.y = p.a
		d.scale = Vector3(2, 1, 4.3)
		w.add_obstacle(p.x, p.z, 1.5)
		return p.c)
	w.inst(boxG, T({"color": 0x2a3a4a}), pks, func(p, d, i2):
		d.position = Vector3(p.x, 1.25, p.z)
		d.rotation.y = p.a
		d.scale = Vector3(1.7, 0.7, 2.2))
	# church tower
	var chl := spaced(around(10, HW + 40.0, 90.0, 0.3), 10.0, hs, 14.0)
	if not chl.is_empty():
		var ch: Dictionary = chl[0]
		var g := group(ch.x, ch.y, ch.z)
		var tw := mesh(boxG, T({"color": 0xe9dcc6}), true)
		tw.scale = Vector3(6, 22, 6)
		var spm := mesh(Geo.cone(4.6, 11, 4).translate(0, 27.5, 0), T({"color": 0x3d5a8a}), true)
		spm.rotation.y = PI / 4.0
		var clk := mesh(Geo.circle(1.6, 16), Mats.basic({"color": 0xfff2cc}))
		clk.position = Vector3(0, 17, -3.05)
		clk.rotation.y = PI
		g.add_child(tw)
		g.add_child(spm)
		g.add_child(clk)
		obst(ch, 4.5)
	balloons(2)
	birds(e.birds)
