class_name Geo
extends RefCounted
## Geometry container and generators ported from three.js r128 (same vertex layouts, UVs and normals), so props
## look the same. Triangles are kept in three.js counter-clockwise order and flipped for Godot when baked.

var pos := PackedVector3Array()
var nrm := PackedVector3Array()
var uv := PackedVector2Array()
var col := PackedColorArray()
var idx := PackedInt32Array()        # empty = non-indexed
var groups: Array = []               # [[start, count, material_index]]


func duplicate_geo() -> Geo:
	var g := Geo.new()
	g.pos = pos.duplicate()
	g.nrm = nrm.duplicate()
	g.uv = uv.duplicate()
	g.col = col.duplicate()
	g.idx = idx.duplicate()
	g.groups = groups.duplicate(true)
	return g


func apply(t: Transform3D) -> Geo:
	var nb := t.basis.inverse().transposed()
	for i in pos.size():
		pos[i] = t * pos[i]
	for i in nrm.size():
		nrm[i] = (nb * nrm[i]).normalized()
	return self


func translate(x: float, y: float, z: float) -> Geo:
	return apply(Transform3D(Basis.IDENTITY, Vector3(x, y, z)))


func rotate_x(a: float) -> Geo:
	return apply(Transform3D(Basis(Vector3.RIGHT, a), Vector3.ZERO))


func rotate_y(a: float) -> Geo:
	return apply(Transform3D(Basis(Vector3.UP, a), Vector3.ZERO))


func rotate_z(a: float) -> Geo:
	return apply(Transform3D(Basis(Vector3.BACK, a), Vector3.ZERO))


func scale_xyz(x: float, y: float, z: float) -> Geo:
	return apply(Transform3D(Basis.from_scale(Vector3(x, y, z)), Vector3.ZERO))


func to_non_indexed() -> Geo:
	if idx.is_empty():
		return self
	var p2 := PackedVector3Array()
	var n2 := PackedVector3Array()
	var u2 := PackedVector2Array()
	var c2 := PackedColorArray()
	for i in idx:
		p2.append(pos[i])
		if nrm.size() > i:
			n2.append(nrm[i])
		if uv.size() > i:
			u2.append(uv[i])
		if col.size() > i:
			c2.append(col[i])
	pos = p2
	nrm = n2
	uv = u2
	col = c2
	idx = PackedInt32Array()
	return self


## three.js computeVertexNormals: area-weighted for indexed, per-face for non-indexed
func compute_normals() -> Geo:
	nrm = PackedVector3Array()
	nrm.resize(pos.size())
	if idx.is_empty():
		var i := 0
		while i + 2 < pos.size():
			var n := (pos[i + 2] - pos[i + 1]).cross(pos[i] - pos[i + 1]).normalized()
			nrm[i] = n
			nrm[i + 1] = n
			nrm[i + 2] = n
			i += 3
	else:
		var i := 0
		while i + 2 < idx.size():
			var a := idx[i]
			var b := idx[i + 1]
			var c := idx[i + 2]
			var n := (pos[c] - pos[b]).cross(pos[a] - pos[b])
			nrm[a] += n
			nrm[b] += n
			nrm[c] += n
			i += 3
		for k in nrm.size():
			nrm[k] = nrm[k].normalized()
	return self


func merge(o: Geo) -> Geo:
	var base := pos.size()
	if idx.is_empty() and not o.idx.is_empty():
		_make_indexed()
	var oi := o.idx
	if oi.is_empty() and not idx.is_empty():
		oi = PackedInt32Array(range(o.pos.size()))
	pos.append_array(o.pos)
	nrm.append_array(o.nrm)
	uv.append_array(o.uv)
	col.append_array(o.col)
	for i in oi:
		idx.append(base + i)
	return self


func _make_indexed() -> void:
	idx = PackedInt32Array(range(pos.size()))


## Bake into a Godot mesh. Each group becomes its own surface (for per-face materials).
func to_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if groups.is_empty():
		_add_surface(mesh, 0, idx.size() if not idx.is_empty() else pos.size())
	else:
		for g in groups:
			_add_surface(mesh, g[0], g[1])
	return mesh


func _add_surface(mesh: ArrayMesh, start: int, count: int) -> void:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	var indexed := not idx.is_empty()
	var vp := PackedVector3Array()
	var vn := PackedVector3Array()
	var vu := PackedVector2Array()
	var vc := PackedColorArray()
	var ii := PackedInt32Array()
	if indexed and groups.is_empty():
		vp = pos
		vn = nrm
		vc = col
		# three.js textures are flipped on upload (v up); Godot samples v down
		vu.resize(uv.size())
		for q in uv.size():
			vu[q] = Vector2(uv[q].x, 1.0 - uv[q].y)
		ii.resize(count)
		var i := 0
		while i + 2 < count:
			ii[i] = idx[start + i]
			ii[i + 1] = idx[start + i + 2]
			ii[i + 2] = idx[start + i + 1]
			i += 3
	else:
		# copy the referenced vertices (non-indexed or a group slice), flipping winding
		var i := 0
		while i + 2 < count:
			for k in [0, 2, 1]:
				var v: int = idx[start + i + k] if indexed else start + i + k
				vp.append(pos[v])
				if nrm.size() > v:
					vn.append(nrm[v])
				if uv.size() > v:
					vu.append(Vector2(uv[v].x, 1.0 - uv[v].y))
				if col.size() > v:
					vc.append(col[v])
			i += 3
	arr[Mesh.ARRAY_VERTEX] = vp
	if vn.size() == vp.size():
		arr[Mesh.ARRAY_NORMAL] = vn
	if vu.size() == vp.size():
		arr[Mesh.ARRAY_TEX_UV] = vu
	if vc.size() == vp.size() and vc.size() > 0:
		arr[Mesh.ARRAY_COLOR] = vc
	if not ii.is_empty():
		arr[Mesh.ARRAY_INDEX] = ii
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)


# ------------------------------------------------------------------ generators (three.js r128)

static func plane(w: float, h: float, ws: int = 1, hs: int = 1) -> Geo:
	var g := Geo.new()
	var gx := ws + 1
	var gy := hs + 1
	var sw := w / ws
	var shh := h / hs
	for iy in gy:
		var y := iy * shh - h / 2.0
		for ix in gx:
			var x := ix * sw - w / 2.0
			g.pos.append(Vector3(x, -y, 0))
			g.nrm.append(Vector3(0, 0, 1))
			g.uv.append(Vector2(float(ix) / ws, 1.0 - float(iy) / hs))
	for iy in hs:
		for ix in ws:
			var a := ix + gx * iy
			var b := ix + gx * (iy + 1)
			var c := (ix + 1) + gx * (iy + 1)
			var d := (ix + 1) + gx * iy
			g.idx.append_array([a, b, d, b, c, d])
	return g


static func box(w: float, h: float, d: float) -> Geo:
	var g := Geo.new()
	# three.js face order: px, nx, py, ny, pz, nz ; buildPlane(u, v, w, udir, vdir, width, height, depth)
	var specs := [["z", "y", "x", -1, -1, d, h, w, 0], ["z", "y", "x", 1, -1, d, h, -w, 1], ["x", "z", "y", 1, 1, w, d, h, 2],
		["x", "z", "y", 1, -1, w, d, -h, 3], ["x", "y", "z", 1, -1, w, h, d, 4], ["x", "y", "z", -1, -1, w, h, -d, 5]]
	for s in specs:
		var start := g.idx.size()
		var vstart := g.pos.size()
		var width: float = s[5]
		var height: float = s[6]
		var depth: float = s[7]
		for iy in 2:
			var y := iy * height - height / 2.0
			for ix in 2:
				var x := ix * width - width / 2.0
				var v := {}
				v[s[0]] = x * s[3]
				v[s[1]] = y * s[4]
				v[s[2]] = depth / 2.0
				g.pos.append(Vector3(v.get("x", 0.0), v.get("y", 0.0), v.get("z", 0.0)))
				var n := {}
				n[s[0]] = 0.0
				n[s[1]] = 0.0
				n[s[2]] = 1.0 if depth > 0 else -1.0
				g.nrm.append(Vector3(n.get("x", 0.0), n.get("y", 0.0), n.get("z", 0.0)))
				g.uv.append(Vector2(ix, 1 - iy))
		var a := vstart
		var b := vstart + 2
		var c := vstart + 3
		var dd := vstart + 1
		g.idx.append_array([a, b, dd, b, c, dd])
		g.groups.append([start, 6, s[8]])
	return g


static func cylinder(rt: float, rb: float, h: float, rs: int = 8, hs: int = 1, open_ended: bool = false, theta_start: float = 0.0, theta_len: float = TAU) -> Geo:
	var g := Geo.new()
	var hh := h / 2.0
	var grid: Array = []
	var slope := (rb - rt) / h
	for y in hs + 1:
		var row: Array = []
		var v := float(y) / hs
		var r := v * (rb - rt) + rt
		for x in rs + 1:
			var u := float(x) / rs
			var theta := u * theta_len + theta_start
			var st := sin(theta)
			var ct := cos(theta)
			g.pos.append(Vector3(r * st, -v * h + hh, r * ct))
			g.nrm.append(Vector3(st, slope, ct).normalized())
			g.uv.append(Vector2(u, 1.0 - v))
			row.append(g.pos.size() - 1)
		grid.append(row)
	for x in rs:
		for y in hs:
			var a: int = grid[y][x]
			var b: int = grid[y + 1][x]
			var c: int = grid[y + 1][x + 1]
			var d: int = grid[y][x + 1]
			g.idx.append_array([a, b, d, b, c, d])
	if not open_ended:
		if rt > 0.0:
			_cyl_cap(g, true, rt, hh, rs, theta_start, theta_len)
		if rb > 0.0:
			_cyl_cap(g, false, rb, hh, rs, theta_start, theta_len)
	return g


static func _cyl_cap(g: Geo, top: bool, radius: float, hh: float, rs: int, ts: float, tl: float) -> void:
	var sgn := 1.0 if top else -1.0
	var center_start := g.pos.size()
	for x in range(1, rs + 1):
		g.pos.append(Vector3(0, hh * sgn, 0))
		g.nrm.append(Vector3(0, sgn, 0))
		g.uv.append(Vector2(0.5, 0.5))
	var center_end := g.pos.size()
	for x in rs + 1:
		var u := float(x) / rs
		var theta := u * tl + ts
		var ct := cos(theta)
		var st := sin(theta)
		g.pos.append(Vector3(radius * st, hh * sgn, radius * ct))
		g.nrm.append(Vector3(0, sgn, 0))
		g.uv.append(Vector2(ct * 0.5 + 0.5, st * 0.5 * sgn + 0.5))
	for x in rs:
		var c := center_start + x
		var i := center_end + x
		if top:
			g.idx.append_array([i, i + 1, c])
		else:
			g.idx.append_array([i + 1, i, c])


static func cone(r: float, h: float, rs: int = 8, hs: int = 1, open_ended: bool = false) -> Geo:
	return cylinder(0.0, r, h, rs, hs, open_ended)


static func sphere(r: float, ws: int = 8, hs: int = 6, phi_start: float = 0.0, phi_len: float = TAU, theta_start: float = 0.0, theta_len: float = PI) -> Geo:
	var g := Geo.new()
	ws = maxi(3, ws)
	hs = maxi(2, hs)
	var theta_end := minf(theta_start + theta_len, PI)
	var grid: Array = []
	for iy in hs + 1:
		var row: Array = []
		var v := float(iy) / hs
		var u_off := 0.0
		if iy == 0 and theta_start == 0.0:
			u_off = 0.5 / ws
		elif iy == hs and theta_end == PI:
			u_off = -0.5 / ws
		for ix in ws + 1:
			var u := float(ix) / ws
			var p := Vector3(-r * cos(phi_start + u * phi_len) * sin(theta_start + v * theta_len), r * cos(theta_start + v * theta_len), r * sin(phi_start + u * phi_len) * sin(theta_start + v * theta_len))
			g.pos.append(p)
			g.nrm.append(p.normalized() if p.length() > 0.0 else Vector3.UP)
			g.uv.append(Vector2(u + u_off, 1.0 - v))
			row.append(g.pos.size() - 1)
		grid.append(row)
	for iy in hs:
		for ix in ws:
			var a: int = grid[iy][ix + 1]
			var b: int = grid[iy][ix]
			var c: int = grid[iy + 1][ix]
			var d: int = grid[iy + 1][ix + 1]
			if iy != 0 or theta_start > 0.0:
				g.idx.append_array([a, b, d])
			if iy != hs - 1 or theta_end < PI:
				g.idx.append_array([b, c, d])
	return g


static func circle(r: float, segs: int = 8) -> Geo:
	var g := Geo.new()
	g.pos.append(Vector3.ZERO)
	g.nrm.append(Vector3(0, 0, 1))
	g.uv.append(Vector2(0.5, 0.5))
	for s in segs + 1:
		var a := float(s) / segs * TAU
		g.pos.append(Vector3(r * cos(a), r * sin(a), 0))
		g.nrm.append(Vector3(0, 0, 1))
		g.uv.append(Vector2((cos(a) + 1.0) / 2.0, (sin(a) + 1.0) / 2.0))
	for i in range(1, segs + 1):
		g.idx.append_array([i, i + 1, 0])
	return g


static func torus(radius: float, tube: float, rad_segs: int, tub_segs: int) -> Geo:
	var g := Geo.new()
	for j in rad_segs + 1:
		for i in tub_segs + 1:
			var u := float(i) / tub_segs * TAU
			var v := float(j) / rad_segs * TAU
			var p := Vector3((radius + tube * cos(v)) * cos(u), (radius + tube * cos(v)) * sin(u), tube * sin(v))
			var c := Vector3(radius * cos(u), radius * sin(u), 0)
			g.pos.append(p)
			g.nrm.append((p - c).normalized())
			g.uv.append(Vector2(float(i) / tub_segs, float(j) / rad_segs))
	for j in range(1, rad_segs + 1):
		for i in range(1, tub_segs + 1):
			var a := (tub_segs + 1) * j + i - 1
			var b := (tub_segs + 1) * (j - 1) + i - 1
			var c := (tub_segs + 1) * (j - 1) + i
			var d := (tub_segs + 1) * j + i
			g.idx.append_array([a, b, d, b, c, d])
	return g


static func lathe(points: Array, segs: int = 12) -> Geo:
	var g := Geo.new()
	var n := points.size()
	for i in segs + 1:
		var phi := float(i) / segs * TAU
		var s := sin(phi)
		var c := cos(phi)
		for j in n:
			var p: Vector2 = points[j]
			g.pos.append(Vector3(p.x * s, p.y, p.x * c))
			g.uv.append(Vector2(float(i) / segs, float(j) / (n - 1)))
	for i in segs:
		for j in n - 1:
			var base := j + i * n
			var a := base
			var b := base + n
			var c := base + n + 1
			var d := base + 1
			g.idx.append_array([a, b, d, c, d, b])
	g.compute_normals()
	return g


static func _poly_detail(verts: Array, faces: Array, r: float, detail: int) -> Geo:
	var g := Geo.new()
	var cols := detail + 1
	var f := 0
	while f < faces.size():
		var a: Vector3 = verts[faces[f]]
		var b: Vector3 = verts[faces[f + 1]]
		var c: Vector3 = verts[faces[f + 2]]
		var v: Array = []
		for i in cols + 1:
			v.append([])
			var aj := a.lerp(c, float(i) / cols)
			var bj := b.lerp(c, float(i) / cols)
			var rows := cols - i
			for j in rows + 1:
				if j == 0 and i == cols:
					v[i].append(aj)
				else:
					v[i].append(aj.lerp(bj, float(j) / rows))
		for i in cols:
			for j in 2 * (cols - i) - 1:
				var k := int(floor(j / 2.0))
				if j % 2 == 0:
					g.pos.append(v[i][k + 1])
					g.pos.append(v[i + 1][k])
					g.pos.append(v[i][k])
				else:
					g.pos.append(v[i][k + 1])
					g.pos.append(v[i + 1][k + 1])
					g.pos.append(v[i + 1][k])
		f += 3
	for i in g.pos.size():
		g.pos[i] = g.pos[i].normalized() * r
	if detail == 0:
		g.compute_normals()
	else:
		g.nrm = PackedVector3Array()
		for p in g.pos:
			g.nrm.append(p.normalized())
	return g


static func icosahedron(r: float, detail: int = 0) -> Geo:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var f := [0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1]
	return _poly_detail(v, f, r, detail)


static func dodecahedron(r: float, detail: int = 0) -> Geo:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var q := 1.0 / t
	var v := [Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, -1), Vector3(-1, 1, 1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(1, 1, -1), Vector3(1, 1, 1),
		Vector3(0, -q, -t), Vector3(0, -q, t), Vector3(0, q, -t), Vector3(0, q, t), Vector3(-q, -t, 0), Vector3(-q, t, 0), Vector3(q, -t, 0), Vector3(q, t, 0),
		Vector3(-t, 0, -q), Vector3(t, 0, -q), Vector3(-t, 0, q), Vector3(t, 0, q)]
	var f := [3, 11, 7, 3, 7, 15, 3, 15, 13, 7, 19, 17, 7, 17, 6, 7, 6, 15, 17, 4, 8, 17, 8, 10, 17, 10, 6, 8, 0, 16, 8, 16, 2, 8, 2, 10, 0, 12, 1, 0, 1, 18, 0, 18, 16,
		6, 10, 2, 6, 2, 13, 6, 13, 15, 2, 16, 18, 2, 18, 3, 2, 3, 13, 18, 1, 9, 18, 9, 11, 18, 11, 3, 4, 14, 12, 4, 12, 0, 4, 0, 8, 11, 9, 5, 11, 5, 19, 11, 19, 7,
		19, 5, 14, 19, 14, 4, 19, 4, 17, 1, 12, 14, 1, 14, 5, 1, 5, 9]
	return _poly_detail(v, f, r, detail)


## Roof prism (prismGeo): 1 m wide base at y=0, ridge at y=1, 1 m long in z, flat shaded.
static func prism() -> Geo:
	var g := cylinder(1.0, 1.0, 1.0, 3, 1)
	g.rotate_x(-PI / 2.0)
	g.scale_xyz(1.0 / 1.732, 1.0 / 1.5, 1.0)
	g.translate(0.0, 1.0 / 3.0, 0.0)
	g.to_non_indexed()
	g.compute_normals()
	return g


## Side profile (forward, height) extruded across the car's width with a rounded bevel (three.js ExtrudeGeometry,
## then rotateY(-90°) and centred).
static func extrude_profile(pts: Array, width: float, bev: float, segs: int = 3) -> Geo:
	var g := Geo.new()
	var n := pts.size()
	var shape: Array = []
	for p in pts:
		shape.append(Vector2(p[0], p[1]))
	# make the outline counter-clockwise
	var area := 0.0
	for i in n:
		var a: Vector2 = shape[i]
		var b: Vector2 = shape[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		shape.reverse()
	# outward bevel vectors (miter of the two edge normals)
	var mv: Array = []
	for i in n:
		var p: Vector2 = shape[i]
		var pa: Vector2 = shape[(i - 1 + n) % n]
		var pb: Vector2 = shape[(i + 1) % n]
		var e1 := (p - pa).normalized()
		var e2 := (pb - p).normalized()
		var n1 := Vector2(e1.y, -e1.x)
		var n2 := Vector2(e2.y, -e2.x)
		var m := (n1 + n2)
		if m.length() < 1e-5:
			m = n1
		m = m.normalized()
		var d := maxf(m.dot(n1), 0.35)
		mv.append(m / d)
	# layers: (z, expansion) from the front cap through the walls to the back cap
	var layers: Array = []
	for s in segs + 1:
		var t := float(s) / segs
		layers.append([-bev * cos(t * PI / 2.0), bev * sin(t * PI / 2.0)])
	for s in range(segs, -1, -1):
		var t := float(s) / segs
		layers.append([width + bev * cos(t * PI / 2.0), bev * sin(t * PI / 2.0)])
	var rings: Array = []
	for L in layers:
		var ring: Array = []
		for i in n:
			var p: Vector2 = shape[i] + mv[i] * float(L[1])
			ring.append(Vector3(p.x, p.y, L[0]))
		rings.append(ring)
	# walls
	for li in rings.size() - 1:
		var r0: Array = rings[li]
		var r1: Array = rings[li + 1]
		for i in n:
			var j := (i + 1) % n
			var a: Vector3 = r0[i]
			var b: Vector3 = r0[j]
			var c: Vector3 = r1[j]
			var d: Vector3 = r1[i]
			g.pos.append_array([a, b, c, a, c, d])
	# caps (outline is counter-clockwise; the front cap faces -z, the back cap +z)
	var tri := Geometry2D.triangulate_polygon(PackedVector2Array(shape))
	var front: Array = rings[0]
	var back: Array = rings[rings.size() - 1]
	var k := 0
	while k + 2 < tri.size():
		var ia := tri[k]
		var ib := tri[k + 1]
		var ic := tri[k + 2]
		var A: Vector2 = shape[ia]
		var B: Vector2 = shape[ib]
		var C: Vector2 = shape[ic]
		if (B - A).cross(C - A) < 0.0:
			var tmp := ib
			ib = ic
			ic = tmp
		g.pos.append_array([front[ia], front[ic], front[ib]])
		g.pos.append_array([back[ia], back[ib], back[ic]])
		k += 3
	g.compute_normals()
	g.rotate_y(-PI / 2.0)
	g.translate(width / 2.0, 0.0, 0.0)
	return g


## Straight extrusion of a 2D outline along +Z (no bevel), with outward-facing triangles in three.js winding.
static func extrude_flat(outline: Array, depth: float) -> Geo:
	var pts: Array = outline.duplicate()
	var area := 0.0
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		pts.reverse()
	var g := Geo.new()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var p0 := Vector3(a.x, a.y, 0)
		var p1 := Vector3(b.x, b.y, 0)
		var p2 := Vector3(b.x, b.y, depth)
		var p3 := Vector3(a.x, a.y, depth)
		g.pos.append_array([p0, p1, p2, p0, p2, p3])
	var tri := Geometry2D.triangulate_polygon(PackedVector2Array(pts))
	var k := 0
	while k + 2 < tri.size():
		var A: Vector2 = pts[tri[k]]
		var B: Vector2 = pts[tri[k + 1]]
		var C: Vector2 = pts[tri[k + 2]]
		if (B - A).cross(C - A) < 0.0:
			var tmp := B
			B = C
			C = tmp
		g.pos.append_array([Vector3(A.x, A.y, depth), Vector3(B.x, B.y, depth), Vector3(C.x, C.y, depth)])
		g.pos.append_array([Vector3(A.x, A.y, 0), Vector3(C.x, C.y, 0), Vector3(B.x, B.y, 0)])
		k += 3
	g.compute_normals()
	return g
