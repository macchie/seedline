class_name TrackGen
## Procedural track generator — a line-by-line port of the web build's genTrack(), keeping the exact order of
## random draws so every seed builds the same circuit in both versions. Polylines are kept in 64-bit floats
## (like JS numbers); the resampled centreline is stored in 32-bit arrays (like the JS Float32Arrays).

## Track length range in metres. Must stay inside the server's 1500-5000 m limit
## (server/nakama/modules/seedline.lua, CFG.min_length_m / max_length_m).
const MIN_TRACK_LENGTH := 1000.0
const MAX_TRACK_LENGTH := 3500.0
## Fraction of the range kept clear at both ends when drawing the target length,
## so candidates (which drift after filleting) are not over-rejected.
const LENGTH_MARGIN := 0.06
const MIN_R := 18.0
const BR_H := 8.5
const BR_F := 10
const BR_R := 26
const FAMILIES := [["loop", 0.13], ["eight", 0.11], ["snake", 0.14], ["spiral", 0.10], ["flower", 0.11], ["street", 0.13], ["switchback", 0.10], ["stadium", 0.09], ["dogbone", 0.09]]
## Per-track shape distortion: aspect ratio spread (e^±this/2) and max banana bend.
const ASPECT_SPREAD := 1.2
const BEND_MAX := 0.45


class Poly:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()

	func add(a: float, b: float) -> void:
		x.append(a)
		y.append(b)

	func size() -> int:
		return x.size()


# ---------------------------------------------------------------- base shapes

static func base_shape(rng: SeedRng, mode: String) -> Poly:
	var q := Poly.new()
	var TAU := U.TAU
	if mode == "eight":
		var n := 10 + int(floor(rng.next() * 6))
		var ay := 0.8 + rng.next() * 0.5
		var lobe := 0.6 + rng.next() * 0.6
		for i in n:
			var t := (i + 0.5) / n * TAU + (rng.next() - 0.5) * 0.18
			var d := 1.0 + pow(sin(t), 2)
			var x := cos(t) / d
			var y := sin(t) * cos(t) / d * ay
			if x < 0.0:
				x *= lobe
			var j := 1.0 + (rng.next() - 0.5) * 0.35
			q.add(x * j, y * j)
	elif mode == "snake":
		var M := 5 + int(floor(rng.next() * 4))
		var W := 0.3 + rng.next() * 0.18
		var spx := PackedFloat64Array()
		var spy := PackedFloat64Array()
		var x := 0.0
		var y := 0.0
		var h := rng.next() * TAU
		var turn := -1.0 if rng.next() < 0.5 else 1.0
		spx.append(x)
		spy.append(y)
		for k in M:
			if rng.next() < 0.45:
				turn = -turn
			h += turn * (0.5 + rng.next() * 0.9)
			x += cos(h)
			y += sin(h)
			spx.append(x)
			spy.append(y)
		var cnt := spx.size()
		var nrm: Array = []
		for k in cnt:
			var a := maxi(0, k - 1)
			var b := mini(cnt - 1, k + 1)
			var dx := spx[b] - spx[a]
			var dy := spy[b] - spy[a]
			var L := sqrt(dx * dx + dy * dy)
			if L == 0.0:
				L = 1.0
			nrm.append([-dy / L, dx / L, dx / L, dy / L])
		var wv := PackedFloat64Array()
		for k in cnt:
			wv.append(W * (0.75 + rng.next() * 0.5))
		var L2 := cnt - 1
		for k in cnt:
			q.add(spx[k] + nrm[k][0] * wv[k], spy[k] + nrm[k][1] * wv[k])
		q.add(spx[L2] + nrm[L2][2] * wv[L2] * 1.2, spy[L2] + nrm[L2][3] * wv[L2] * 1.2)
		var k2 := L2
		while k2 >= 0:
			q.add(spx[k2] - nrm[k2][0] * wv[k2], spy[k2] - nrm[k2][1] * wv[k2])
			k2 -= 1
		q.add(spx[0] - nrm[0][2] * wv[0] * 1.2, spy[0] - nrm[0][3] * wv[0] * 1.2)
	elif mode == "spiral":
		var turns := 1.15 + rng.next() * 0.45
		var n := 14 + int(floor(rng.next() * 6))
		var dir := 1.0 if rng.next() < 0.5 else -1.0
		for i in n + 1:
			var t := float(i) / n
			var a := dir * t * turns * TAU
			var r := 1.0 - 0.62 * t
			var fxx := 1.0 + (rng.next() - 0.5) * 0.12
			var fyy := 1.0 + (rng.next() - 0.5) * 0.12
			q.add(cos(a) * r * fxx, sin(a) * r * fyy)
		var ex := q.x[q.size() - 1]
		var ey := q.y[q.size() - 1]
		var a0 := atan2(ey, ex)
		q.add(cos(a0 + dir * 0.9) * 0.75, sin(a0 + dir * 0.9) * 0.75)
	elif mode == "switchback":
		var K := 3 + int(floor(rng.next() * 3))
		var g := 0.2 + rng.next() * 0.06
		var ret := -(0.28 + rng.next() * 0.15)
		var y := 0.0
		q.add(0.0, 0.0)
		for k in K:
			var xa := 0.0 if k % 2 == 1 else 0.8 + rng.next() * 0.4
			q.add(xa, y)
			y += g * (0.9 + rng.next() * 0.3)
			q.add(xa, y)
		q.add(ret * 0.2 if K % 2 == 1 else 0.15, y + g * 0.6)
		q.add(ret, y * 0.6 + g * 0.3)
		q.add(ret * 0.8, -g * 0.4)
	elif mode == "flower":
		var P := 4 + int(floor(rng.next() * 4))
		var inner := 0.32 + rng.next() * 0.2
		var wob := 0.25 + rng.next() * 0.2
		for i in P:
			var a := float(i) / P * TAU
			var w := TAU / P
			var tip := 0.85 + rng.next() * 0.3
			q.add(cos(a) * inner, sin(a) * inner)
			q.add(cos(a + w * 0.3) * tip, sin(a + w * 0.3) * tip)
			if rng.next() < 0.6:
				q.add(cos(a + w * 0.5) * tip * (1.0 - wob * 0.4), sin(a + w * 0.5) * tip * (1.0 - wob * 0.4))
			q.add(cos(a + w * 0.7) * tip * 0.95, sin(a + w * 0.7) * tip * 0.95)
	elif mode == "street":
		var w := 1.0
		var h := 0.55 + rng.next() * 0.5
		var C := [[-w / 2.0, -h / 2.0], [w / 2.0, -h / 2.0], [w / 2.0, h / 2.0], [-w / 2.0, h / 2.0]]
		for e in 4:
			var p: Array = C[e]
			var o: Array = C[(e + 1) % 4]
			var dx: float = o[0] - p[0]
			var dy: float = o[1] - p[1]
			var L := sqrt(dx * dx + dy * dy)
			var nx := dy / L
			var ny := -dx / L
			q.add(p[0], p[1])
			var k := 1 + int(floor(rng.next() * 2)) if rng.next() < 0.75 else 0
			var t := 0.12
			var j := 0
			while j < k and t < 0.8:
				var t1 := t + rng.next() * 0.15
				var t2 := minf(0.9, t1 + 0.18 + rng.next() * 0.25)
				var sg := -1.0 if rng.next() < 0.55 else 1.0
				var d := sg * (0.12 + rng.next() * 0.22) * minf(w, h)
				var p1x: float = p[0] + dx * t1
				var p1y: float = p[1] + dy * t1
				var p2x: float = p[0] + dx * t2
				var p2y: float = p[1] + dy * t2
				q.add(p1x, p1y)
				q.add(p1x + nx * d, p1y + ny * d)
				q.add(p2x + nx * d, p2y + ny * d)
				q.add(p2x, p2y)
				t = t2 + 0.06
				j += 1
	elif mode == "stadium":
		var n := 5 + int(floor(rng.next() * 4))
		var L := 0.7 + rng.next() * 1.0
		var R := 0.5
		var dent := rng.next()
		for i in n + 1:
			var a := -PI / 2.0 + float(i) / n * PI
			var rj := R * (1.0 + (rng.next() - 0.5) * 0.25)
			q.add(L / 2.0 + cos(a) * rj, sin(a) * rj)
		if dent < 0.6:
			q.add(L * (rng.next() - 0.5) * 0.4, R * (0.55 + rng.next() * 0.3))
		for i in n + 1:
			var a := PI / 2.0 + float(i) / n * PI
			var rj := R * (1.0 + (rng.next() - 0.5) * 0.25)
			q.add(-L / 2.0 + cos(a) * rj, sin(a) * rj)
		if dent >= 0.3:
			q.add(L * (rng.next() - 0.5) * 0.4, -R * (0.55 + rng.next() * 0.3))
	elif mode == "dogbone":
		var c := 0.55 + rng.next() * 0.25
		var r1 := 0.38 + rng.next() * 0.2
		var r2 := 0.28 + rng.next() * 0.2
		var w := 0.18 + rng.next() * 0.12
		var th := 2.1 + rng.next() * 0.3
		var n1 := 5 + int(floor(rng.next() * 3))
		for i in n1 + 1:
			var a := -th + float(i) / n1 * 2.0 * th
			var rj := r1 * (1.0 + (rng.next() - 0.5) * 0.2)
			q.add(c + cos(a) * rj, sin(a) * rj)
		q.add(0.0, w)
		var n2 := 4 + int(floor(rng.next() * 3))
		for i in n2 + 1:
			var a := PI - th + float(i) / n2 * 2.0 * th
			var rj := r2 * (1.0 + (rng.next() - 0.5) * 0.2)
			q.add(-c + cos(a) * rj, sin(a) * rj)
		q.add(0.0, -w)
	else:
		var n := 7 + int(floor(rng.next() * 7))
		var ax := 0.7 + rng.next() * 0.6
		var az := (0.85 + rng.next() * 0.3) / ax
		var bx := PackedFloat64Array()
		var by := PackedFloat64Array()
		for i in n:
			var a := float(i) / n * TAU + (rng.next() - 0.5) * (TAU / n) * 0.7
			var r := 0.38 + rng.next() * 0.62
			if rng.next() < 0.3:
				r *= 0.45
			bx.append(cos(a) * r * ax)
			by.append(sin(a) * r * az)
		for i in n:
			var pxv := bx[i]
			var pyv := by[i]
			var ox := bx[(i + 1) % n]
			var oy := by[(i + 1) % n]
			q.add(pxv, pyv)
			if rng.next() < 0.7:
				var dx := ox - pxv
				var dy := oy - pyv
				var L := sqrt(dx * dx + dy * dy)
				if L == 0.0:
					L = 1.0
				var off := (rng.next() - 0.5) * L * 0.55
				var t := 0.3 + rng.next() * 0.4
				q.add(pxv + dx * t - dy / L * off, pyv + dy * t + dx / L * off)
		if mode == "twist":
			var k := 1 + int(floor(rng.next() * (q.size() - 3)))
			var tx := q.x[k]
			var ty := q.y[k]
			q.x[k] = q.x[k + 1]
			q.y[k] = q.y[k + 1]
			q.x[k + 1] = tx
			q.y[k + 1] = ty
	return q


static func polygon_candidate(rng: SeedRng, target_len: float, mode: String, style: Dictionary) -> Poly:
	var q := base_shape(rng, mode)
	var rot := rng.next() * U.TAU
	var c := cos(rot)
	var s := sin(rot)
	var sx := -1.0 if rng.next() < 0.5 else 1.0
	var m := q.size()
	var r := Poly.new()
	for i in m:
		var a := q.x[i]
		var b := q.y[i]
		r.add((a * c - b * s) * sx, a * s + b * c)
	# Stretch and bend so two tracks of one family rarely share proportions.
	var asp := exp((rng.next() - 0.5) * ASPECT_SPREAD)
	var bend := (rng.next() - 0.5) * 2.0 * BEND_MAX if mode != "street" else 0.0
	for i in m:
		var px := r.x[i] * asp
		var py := r.y[i] / asp
		r.x[i] = px
		r.y[i] = py + bend * px * px
	var per := 0.0
	for i in m:
		var j := (i + 1) % m
		per += U.hypot(r.x[j] - r.x[i], r.y[j] - r.y[i])
	var f := target_len / per
	var pts := Poly.new()
	for i in m:
		pts.add(r.x[i] * f, r.y[i] * f)
	var mg := 40.0 if mode == "street" else 55.0
	for pass_i in 3:
		var nxt := Poly.new()
		var cnt := pts.size()
		for i in cnt:
			var j := (i + 1) % cnt
			if U.hypot(pts.x[j] - pts.x[i], pts.y[j] - pts.y[i]) > mg:
				nxt.add(pts.x[i], pts.y[i])
		pts = nxt
	if pts.size() < 4:
		return null
	return add_features(pts, rng, mode, style)


## Chicanes, esses, kinks and hairpin tongues cut into long edges.
static func add_features(P: Poly, rng: SeedRng, mode: String, style: Dictionary) -> Poly:
	var out := Poly.new()
	var n := P.size()
	var base := 2.0 if (mode == "eight" or mode == "spiral") else (1.0 if mode == "street" else 3.0)
	var budget := int(U.jround(base + float(style["busy"]) * 4.0))
	for i in n:
		var p0 := P.x[i]
		var p1 := P.y[i]
		var o0 := P.x[(i + 1) % n]
		var o1 := P.y[(i + 1) % n]
		var dx := o0 - p0
		var dy := o1 - p1
		var L := sqrt(dx * dx + dy * dy)
		out.add(p0, p1)
		if budget <= 0 or L < 150.0:
			continue
		var nx := -dy / L
		var ny := dx / L
		var side := -1.0 if rng.next() < 0.5 else 1.0
		var r := rng.next()
		if L > 300.0 and r < 0.22:
			var D := (55.0 + rng.next() * 45.0) * side
			var a := 0.34 + rng.next() * 0.08
			var w := maxf(0.14, 48.0 / L)
			for spec in [[a, 0.0], [a + 0.02, D * 0.55], [a + 0.04, D], [a + w - 0.04, D], [a + w - 0.02, D * 0.55], [a + w, 0.0]]:
				out.add(p0 + dx * spec[0] + nx * spec[1], p1 + dy * spec[0] + ny * spec[1])
			budget -= 2
		elif L > 200.0 and r < 0.5:
			var D := (16.0 + rng.next() * 14.0) * side
			var a := 0.3 + rng.next() * 0.25
			var g := maxf(0.12, 30.0 / L)
			out.add(p0 + dx * a + nx * D, p1 + dy * a + ny * D)
			out.add(p0 + dx * (a + g) + nx * (-D * 0.8), p1 + dy * (a + g) + ny * (-D * 0.8))
			budget -= 1
		elif L > 240.0 and r < 0.75:
			var k := 3 + int(floor(rng.next() * 2))
			var D := 12.0 + rng.next() * 10.0
			var a := 0.18
			var g := 0.64 / k
			for j in k:
				var off := D * (-1.0 if j % 2 == 1 else 1.0) * side
				var t := a + g * (j + 0.5)
				out.add(p0 + dx * t + nx * off, p1 + dy * t + ny * off)
			budget -= 1
		elif r < 0.92:
			var big := rng.next() < 0.5
			var D := (35.0 + rng.next() * 45.0 if big else 16.0 + rng.next() * 16.0) * side
			var t := 0.35 + rng.next() * 0.3
			out.add(p0 + dx * t + nx * D, p1 + dy * t + ny * D)
			budget -= 1
	return out


# ---------------------------------------------------------------- fillets & resampling

static func fillet_path(P: Poly, rng: SeedRng, min_r: float, style: Dictionary) -> Poly:
	var n := P.size()
	var seq: Array = []
	for i in n:
		var ia := (i - 1 + n) % n
		var ib := (i + 1) % n
		var cx := P.x[i]
		var cy := P.y[i]
		var d1x := cx - P.x[ia]
		var d1y := cy - P.y[ia]
		var d2x := P.x[ib] - cx
		var d2y := P.y[ib] - cy
		var L1 := sqrt(d1x * d1x + d1y * d1y)
		var L2 := sqrt(d2x * d2x + d2y * d2y)
		if L1 == 0.0 or L2 == 0.0:
			return null
		d1x /= L1
		d1y /= L1
		d2x /= L2
		d2y /= L2
		var cr := d1x * d2y - d1y * d2x
		var th := atan2(absf(cr), d1x * d2x + d1y * d2y)
		if th < 0.04:
			seq.append([cx, cy, cx, cy, null])
			continue
		var rr := rng.next()
		var tan_h := tan(th / 2.0)
		var r_want: float
		if rr < float(style["tight"]):
			r_want = min_r + rng.next() * 10.0
		elif rr < 1.0 - float(style["sweep"]):
			r_want = min_r + 12.0 + rng.next() * 35.0
		else:
			r_want = min_r + 50.0 + rng.next() * 90.0
		var r_max := 0.48 * minf(L1, L2) / tan_h
		var r := minf(r_want, r_max)
		if r < min_r:
			return null
		var t := r * tan_h
		var Ax := cx - d1x * t
		var Ay := cy - d1y * t
		var Bx := cx + d2x * t
		var By := cy + d2y * t
		var s := 1.0 if cr > 0.0 else -1.0
		var Cx := Ax - d1y * r * s
		var Cy := Ay + d1x * r * s
		seq.append([Ax, Ay, Bx, By, [Cx, Cy, r, atan2(Ay - Cy, Ax - Cx), s * th]])
	var out := Poly.new()
	for v in seq:
		out.add(v[0], v[1])
		if v[4] != null:
			var arc: Array = v[4]
			var Cx: float = arc[0]
			var Cy: float = arc[1]
			var r: float = arc[2]
			var a0: float = arc[3]
			var sw: float = arc[4]
			var m := maxi(2, int(ceil(r * absf(sw) / 1.2)))
			for j in range(1, m):
				var a := a0 + sw * j / m
				out.add(Cx + cos(a) * r, Cy + sin(a) * r)
			out.add(v[2], v[3])
	return out


static func resample_closed(poly: Poly) -> TrackData:
	var m := poly.size()
	var cum := PackedFloat64Array()
	cum.resize(m + 1)
	cum[0] = 0.0
	for i in m:
		var j := (i + 1) % m
		cum[i + 1] = cum[i] + U.hypot(poly.x[j] - poly.x[i], poly.y[j] - poly.y[i])
	var total := cum[m]
	var N := int(U.jround(total / U.DS))
	if N < 300:
		return null
	var p_x := PackedFloat32Array()
	var p_z := PackedFloat32Array()
	p_x.resize(N)
	p_z.resize(N)
	var seg := 0
	for i in N:
		var d := i * total / N
		while cum[seg + 1] < d:
			seg += 1
		var j := (seg + 1) % m
		var L := cum[seg + 1] - cum[seg]
		if L == 0.0:
			L = 1.0
		var t := (d - cum[seg]) / L
		p_x[i] = poly.x[seg] + (poly.x[j] - poly.x[seg]) * t
		p_z[i] = poly.y[seg] + (poly.y[j] - poly.y[seg]) * t
	return TrackData.analyze(p_x, p_z)


# ---------------------------------------------------------------- crossings & elevation

## Every place where the road comes near itself must be a clean crossing (steep angle, short contact).
static func contacts(t: TrackData):
	var N := t.n
	var min_sep := int(ceil(70.0 / U.DS))
	var R := 2.0 * U.HW + 7.0
	var lim := R * R
	var cs := 40.0
	var grid := {}
	var i := 0
	while i < N:
		var key := U.grid_key(int(floor(t.px[i] / cs)), int(floor(t.pz[i] / cs)))
		if not grid.has(key):
			grid[key] = []
		grid[key].append(i)
		i += 2
	var pairs: Array = []
	i = 0
	while i < N:
		var cx := int(floor(t.px[i] / cs))
		var cz := int(floor(t.pz[i] / cs))
		for a in range(-1, 2):
			for b in range(-1, 2):
				var key := U.grid_key(cx + a, cz + b)
				if not grid.has(key):
					continue
				for j in grid[key]:
					if j <= i or U.cdist(i, j, N) < min_sep:
						continue
					var dx := float(t.px[i]) - float(t.px[j])
					var dz := float(t.pz[i]) - float(t.pz[j])
					var d := dx * dx + dz * dz
					if d < lim:
						pairs.append([i, j, d])
		i += 2
	var cl: Array = []
	for p in pairs:
		var c = null
		for cc in cl:
			if U.cdist(cc["i"], p[0], N) < 44 and U.cdist(cc["j"], p[1], N) < 44:
				c = cc
				break
		if c == null:
			c = {"i": p[0], "j": p[1], "d": p[2], "n": 0}
			cl.append(c)
		c["n"] += 1
		if p[2] < c["d"]:
			c["i"] = p[0]
			c["j"] = p[1]
			c["d"] = p[2]
	for c in cl:
		var ci: int = c["i"]
		var cj: int = c["j"]
		var dot := absf(float(t.tx[ci]) * float(t.tx[cj]) + float(t.tz[ci]) * float(t.tz[cj]))
		var ang := acos(U.clampf2(dot, 0.0, 1.0))
		c["ang"] = ang
		var allow := (R / maxf(sin(ang), 0.2)) * 1.6 / (2.0 * U.DS) + 4.0
		if c["d"] > 49.0 or ang < 0.8 or sqrt(float(c["n"])) > allow:
			return null
	return cl


static func longest_straight(t: TrackData) -> float:
	var best := 0.0
	var run := 0.0
	for i in 2 * t.n:
		if absf(t.k[i % t.n]) < 0.004:
			run += U.DS
			if run > best:
				best = run
		else:
			run = 0.0
	return minf(best, t.length)


## Each crossing lifts one of its two passes onto a bridge with ramps.
static func elevate(t: TrackData, xs: Array, rng: SeedRng) -> bool:
	var N := t.n
	var py := PackedFloat32Array()
	py.resize(N)
	var W := BR_F + BR_R
	t.bridges = []
	for x in xs:
		var cand := [x["i"], x["j"]] if rng.next() < 0.5 else [x["j"], x["i"]]
		var u := -1
		for c in cand:
			var ok := true
			for o in xs:
				for v in [o["i"], o["j"]]:
					if not (v == c or U.cdist(v, c, N) > W + 6):
						ok = false
						break
				if not ok:
					break
			if ok:
				u = c
				break
		if u < 0:
			return false
		for o in range(-W, W + 1):
			var kk := (u + o + N) % N
			var d := absi(o)
			var f := 1.0 if d <= BR_F else U.smooth01(1.0 - float(d - BR_F) / BR_R)
			py[kk] = maxf(py[kk], BR_H * f)
		t.bridges.append({"c": u, "lo": x["j"] if u == x["i"] else x["i"], "kind": "over"})
	t.py = py
	return true


static func dist_poly(rx: PackedFloat64Array, ry: PackedFloat64Array, x: float, z: float) -> float:
	var best := 1e18
	var bi := 0
	var m := rx.size()
	for k in m - 1:
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
			bi = k
	return sqrt(best)


## Index of the polyline segment nearest to (x, z). Split out from dist_poly so the generator keeps
## no shared mutable state and can run on worker threads for parallel track-preview generation.
static func nearest_seg(rx: PackedFloat64Array, ry: PackedFloat64Array, x: float, z: float) -> int:
	var best := 1e18
	var bi := 0
	var m := rx.size()
	for k in m - 1:
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
			bi = k
	return bi


## A meandering river across the map; where the road meets it a short bridge lifts the road over the water.
static func make_river(t: TrackData, rng: SeedRng):
	var N := t.n
	var x0 := 1e9
	var x1 := -1e9
	var z0 := 1e9
	var z1 := -1e9
	for i in N:
		x0 = minf(x0, t.px[i])
		x1 = maxf(x1, t.px[i])
		z0 = minf(z0, t.pz[i])
		z1 = maxf(z1, t.pz[i])
	var cx := (x0 + x1) / 2.0
	var cz := (z0 + z1) / 2.0
	var L := maxf(x1 - x0, z1 - z0) / 2.0 + 160.0
	for tries in 14:
		var ang := rng.next() * PI
		var w := 6.5 + rng.next() * 3.5
		var rx := PackedFloat64Array()
		var ry := PackedFloat64Array()
		var h := ang
		var x := cx - cos(ang) * (L + 120.0) + (rng.next() - 0.5) * L * 0.5
		var z := cz - sin(ang) * (L + 120.0) + (rng.next() - 0.5) * L * 0.5
		var s := 0.0
		while s < 2.0 * L + 240.0:
			rx.append(x)
			ry.append(z)
			h = U.clampf2(h + (rng.next() - 0.5) * 0.32, ang - 0.7, ang + 0.7)
			x += cos(h) * 12.0
			z += sin(h) * 12.0
			s += 12.0
		var near := PackedByteArray()
		near.resize(N)
		var any := false
		for i in N:
			if dist_poly(rx, ry, t.px[i], t.pz[i]) < w + U.HW + 3.0:
				near[i] = 1
				any = true
		if not any:
			continue
		var runs: Array = []
		for i in N:
			if near[i] and not near[(i - 1 + N) % N]:
				var j := i
				while near[(j + 1) % N] and j - i < N:
					j += 1
				runs.append([i, j])
		if runs.size() > 3:
			continue
		var ok := true
		var hits: Array = []
		for run in runs:
			var a: int = run[0]
			var b: int = run[1]
			var bi := a
			var bd := 1e9
			for i in range(a, b + 1):
				var d := dist_poly(rx, ry, t.px[i % N], t.pz[i % N])
				if d < bd:
					bd = d
					bi = i % N
			var k := nearest_seg(rx, ry, t.px[bi], t.pz[bi])
			var sx := rx[k + 1] - rx[k]
			var sz := ry[k + 1] - ry[k]
			var sl := sqrt(sx * sx + sz * sz)
			if sl == 0.0:
				sl = 1.0
			var ang2 := acos(U.clampf2(absf((sx * t.tx[bi] + sz * t.tz[bi]) / sl), 0.0, 1.0))
			if bd > 5.0 or ang2 < 0.6 or (b - a + 1) * U.DS > (2.0 * (w + U.HW)) / sin(ang2) + 40.0 or t.py[bi] > 0.0:
				ok = false
				break
			hits.append([bi, ang2])
		if not ok:
			continue
		for hb in hits:
			var F := int(ceil((w + 5.0) / sin(hb[1]) / U.DS)) + 2
			var R := 11
			for o in range(-(F + R), F + R + 1):
				var kk: int = (hb[0] + o + N) % N
				var d := absi(o)
				var f := 1.0 if d <= F else U.smooth01(1.0 - float(d - F) / R)
				t.py[kk] = maxf(t.py[kk], 2.6 * f)
			t.bridges.append({"c": hb[0], "lo": -1, "kind": "river"})
		return {"x": rx, "y": ry, "w": w}
	return null


## Technicality: number of distinct corners (by size) and left/right changes between them.
static func complexity(t: TrackData) -> float:
	var N := t.n
	var corners := 0
	var flips := 0
	var last := 0
	var acc := 0.0
	var sign := 0
	var hair := 0
	for i in N + 1:
		var kv: float = t.k[i % N]
		var s := 1 if kv > 0.01 else (-1 if kv < -0.01 else 0)
		if s != 0 and s == sign:
			acc += absf(kv) * U.DS
		else:
			if acc > 0.45:
				corners += 1
				if acc > 2.2:
					hair += 1
				if last != 0 and sign != last:
					flips += 1
				last = sign
			acc = absf(kv) * U.DS if s != 0 else 0.0
			sign = s
	return corners * 0.5 + flips * 0.6 + hair * 0.5


# ---------------------------------------------------------------- main entry

static func generate(seed: String, env_key: String) -> TrackData:
	var rng := SeedRng.from_seed("v5|" + seed)
	var tr: TrackData = null
	var best_score := -1.0
	var valid := 0
	var r := rng.next()
	var fam := "loop"
	var city := env_key == "TOWN" or env_key == "NEON" or env_key == "HARBOR"
	if city and rng.next() < 0.45:
		fam = "street"
	else:
		for fp in FAMILIES:
			r -= fp[1]
			if r < 0.0:
				fam = fp[0]
				break
	var style := {"tight": 0.15 + rng.next() * 0.6, "busy": rng.next()}
	var lo := MIN_TRACK_LENGTH * (1.0 + LENGTH_MARGIN)
	var hi := MAX_TRACK_LENGTH * (1.0 - LENGTH_MARGIN)
	var target_len := lerpf(lo, hi, rng.next())
	style["sweep"] = maxf(0.05, (1.0 - float(style["tight"])) * 0.35)
	var at := 0
	while at < 300 and valid < 12:
		var mode := fam if at < 220 else "loop"
		at += 1
		var want_cross := mode == "eight" or mode == "twist" or mode == "spiral"
		var P := polygon_candidate(rng, target_len * (0.9 + rng.next() * 0.2), mode, style)
		if P == null:
			continue
		if rng.next() < 0.5:
			P.x.reverse()
			P.y.reverse()
		var path := fillet_path(P, rng, MIN_R, style)
		if path == null:
			continue
		var t := resample_closed(path)
		if t == null:
			continue
		if t.min_radius < MIN_R * 0.85 or t.length < MIN_TRACK_LENGTH or t.length > MAX_TRACK_LENGTH:
			continue
		var xs = contacts(t)
		if xs == null or xs.size() > 2 or (xs.size() > 0) != want_cross:
			continue
		if not elevate(t, xs, rng):
			continue
		valid += 1
		var sc := complexity(t) - maxf(0.0, longest_straight(t) - 280.0) / 60.0 + rng.next() * 4.0
		if sc > best_score:
			best_score = sc
			tr = t
			tr.family = mode
	if tr == null:
		var NN := 700
		var fx := PackedFloat32Array()
		var fz := PackedFloat32Array()
		fx.resize(NN)
		fz.resize(NN)
		var RR := NN * U.DS / U.TAU
		for i in NN:
			var a := float(i) / NN * U.TAU
			fx[i] = cos(a) * RR * (1.0 + 0.25 * sin(3.0 * a))
			fz[i] = sin(a) * RR * 0.7
		tr = TrackData.analyze(fx, fz)
		tr.bridges = []
	var river = null
	if Envs.DATA[env_key].get("river", false) and rng.next() < 0.75:
		river = make_river(tr, rng)
	# start on the straightest ground-level stretch
	var N := tr.n
	var best := -1
	var bs := 1e9
	var i := 0
	while i < N:
		var s := 0.0
		var flat := true
		for b in tr.bridges:
			if b["lo"] >= 0 and U.cdist(b["lo"], i, N) < 44:
				flat = false
				break
		var j := -24
		while j <= 34 and flat:
			var kk := (i + j + N) % N
			s += absf(tr.k[kk])
			if tr.py[kk] > 0.0:
				flat = false
			j += 1
		if flat and s < bs:
			bs = s
			best = i
		i += 2
	if best < 0:
		best = 0
	var px := PackedFloat32Array()
	var pz := PackedFloat32Array()
	var py := PackedFloat32Array()
	px.resize(N)
	pz.resize(N)
	py.resize(N)
	for q in N:
		var kk := (q + best) % N
		px[q] = tr.px[kk]
		pz[q] = tr.pz[kk]
		py[q] = tr.py[kk]
	var bridges: Array = []
	for b in tr.bridges:
		var nb: Dictionary = b.duplicate()
		nb["c"] = (int(b["c"]) - best + N) % N
		nb["lo"] = -1 if int(b["lo"]) < 0 else (int(b["lo"]) - best + N) % N
		bridges.append(nb)
	var fam0 := tr.family
	tr = TrackData.analyze(px, pz)
	tr.family = fam0
	tr.py = py
	tr.bridges = bridges
	tr.river = river
	tr.seed = seed
	tr.env_key = env_key
	tr.complexity = complexity(tr)
	var w: Array = Envs.DATA[env_key]["words"]
	var w0: Array = w[0]
	var w1: Array = w[1]
	tr.name = w0[int(floor(rng.next() * w0.size()))] + " " + w1[int(floor(rng.next() * w1.size()))]
	# checkpoints stay on the ground so their gates have somewhere to stand
	var K := int(U.clampf2(U.jround(tr.length / 540.0), 3.0, 8.0))
	tr.cps = PackedInt32Array()
	for kq in range(1, K + 1):
		var c := int(U.jround(float(kq * N) / (K + 1)))
		var nn := 0
		while py[c % N] > 0.0:
			var go := nn < 90
			nn += 1
			if not go:
				break
			c += 1
		tr.cps.append(c % N)
	tr.pads = _gen_pads(tr)
	tr.medals = CarSim.medal_times(tr)
	return tr


## Boost pads from their own RNG stream so the track itself never changes. Same seed, same pads.
static func _gen_pads(tr: TrackData) -> Array:
	var rng := SeedRng.from_seed("pads|" + tr.seed)
	var N := tr.n
	var blocked := PackedByteArray()
	blocked.resize(N)
	var guard := int(ceil(24.0 / U.DS))
	for c in [0] + Array(tr.cps):
		for d in range(-guard, guard + 1):
			blocked[(int(c) + d + N * 4) % N] = 1
	var pads: Array = []
	var used := PackedByteArray()
	used.resize(N)
	var lat_max := U.HW - 2.6
	var n_big := int(U.clampf2(U.jround(tr.length / 1600.0), 1.0, 3.0))
	var n_small := int(U.clampf2(U.jround(tr.length / 260.0), 4.0, 16.0))
	var tries := 0
	var placed_big := 0
	while placed_big < n_big and tries < 600:
		tries += 1
		var i := int(rng.next() * N) % N
		var lat := (rng.next() * 2.0 - 1.0) * lat_max * 0.8
		if _pad_ok(tr, blocked, used, i, 5, 0.004):
			pads.append({"i": i, "lat": lat, "big": true})
			_mark(used, i, int(ceil(120.0 / U.DS)), N)
			placed_big += 1
	var placed_small := 0
	tries = 0
	while placed_small < n_small and tries < 1200:
		tries += 1
		var i := int(rng.next() * N) % N
		var lat := (rng.next() * 2.0 - 1.0) * lat_max
		var cluster := 3 if rng.next() < 0.45 else 1
		if not _pad_ok(tr, blocked, used, i, 5 + 5 * (cluster - 1), 0.009):
			continue
		for c in cluster:
			var j := (i + c * 5) % N
			pads.append({"i": j, "lat": lat, "big": false})
		_mark(used, i, int(ceil(50.0 / U.DS)), N)
		placed_small += 1
	return pads


static func _pad_ok(tr: TrackData, blocked: PackedByteArray, used: PackedByteArray, i: int, span: int, kmax: float) -> bool:
	for d in range(-2, span + 3):
		var j := (i + d) % tr.n
		if blocked[j] == 1 or used[j] == 1 or tr.py[j] > 0.3 or absf(tr.k[j]) > kmax:
			return false
	return true


static func _mark(used: PackedByteArray, i: int, r: int, N: int) -> void:
	for d in range(-r, r + 1):
		used[(i + d + N * 4) % N] = 1
