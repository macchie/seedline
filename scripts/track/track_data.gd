class_name TrackData
extends RefCounted
## A closed track sampled every DS metres: centreline, tangents, normals, curvature and height profile.

var n: int = 0
var px := PackedFloat32Array()
var pz := PackedFloat32Array()
var tx := PackedFloat32Array()
var tz := PackedFloat32Array()
var nx := PackedFloat32Array()
var nz := PackedFloat32Array()
var k := PackedFloat32Array()
var py := PackedFloat32Array()
var min_radius: float = 0.0
var length: float = 0.0

var bridges: Array = []      # [{c:int, lo:int (-1 for none), kind:"over"|"river"}]
var river = null             # {pts: PackedVector2Array, w: float} or null
var seed: String = ""
var env_key: String = ""
var family: String = ""
var complexity: float = 0.0
var name: String = ""
var cps := PackedInt32Array()
var medals: Dictionary = {}
var pads: Array = []   # {i: sample index, lat: lateral offset, big: bool}


## Tangents, normals and smoothed curvature from a resampled centreline (port of analyze()).
static func analyze(p_x: PackedFloat32Array, p_z: PackedFloat32Array) -> TrackData:
	var t := TrackData.new()
	var N := p_x.size()
	t.n = N
	t.px = p_x
	t.pz = p_z
	t.tx.resize(N)
	t.tz.resize(N)
	t.nx.resize(N)
	t.nz.resize(N)
	t.k.resize(N)
	var k0 := PackedFloat32Array()
	k0.resize(N)
	for i in N:
		var a := (i - 1 + N) % N
		var b := (i + 1) % N
		var dx := float(p_x[b]) - float(p_x[a])
		var dz := float(p_z[b]) - float(p_z[a])
		var L := sqrt(dx * dx + dz * dz)
		if L == 0.0:
			L = 1.0
		t.tx[i] = dx / L
		t.tz[i] = dz / L
		t.nx[i] = -t.tz[i]
		t.nz[i] = t.tx[i]
	var two_ds := 2.0 * U.DS
	for i in N:
		var a := (i - 1 + N) % N
		var b := (i + 1) % N
		k0[i] = asin(U.clampf2(float(t.tx[a]) * float(t.tz[b]) - float(t.tz[a]) * float(t.tx[b]), -1.0, 1.0)) / two_ds
	var max_k := 0.0
	for i in N:
		var s := 0.0
		for j in range(-2, 3):
			s += k0[(i + j + N) % N]
		t.k[i] = s / 5.0
		max_k = maxf(max_k, absf(t.k[i]))
	t.min_radius = 1.0 / maxf(max_k, 1e-5)
	t.length = N * U.DS
	t.py.resize(N)
	return t


func bounds_rect() -> Rect2:
	var x0 := 1e9
	var x1 := -1e9
	var z0 := 1e9
	var z1 := -1e9
	for i in n:
		x0 = minf(x0, px[i])
		x1 = maxf(x1, px[i])
		z0 = minf(z0, pz[i])
		z1 = maxf(z1, pz[i])
	return Rect2(x0, z0, x1 - x0, z1 - z0)
