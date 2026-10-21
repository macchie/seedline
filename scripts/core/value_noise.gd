class_name ValueNoise
extends RefCounted
## Seeded 2D value noise with octaves (port of makeNoise). Pure and thread-safe after construction.

var perm := PackedInt32Array()
var val := PackedFloat32Array()


func _init(rng: SeedRng) -> void:
	var p := PackedInt32Array()
	p.resize(256)
	for i in 256:
		p[i] = i
	var i := 255
	while i > 0:
		var j := int(floor(rng.next() * (i + 1)))
		var tmp := p[i]
		p[i] = p[j]
		p[j] = tmp
		i -= 1
	perm.resize(512)
	for k in 512:
		perm[k] = p[k & 255]
	val.resize(256)
	for k in 256:
		val[k] = rng.next()


func n2(x: float, y: float) -> float:
	var fx := floorf(x)
	var fy := floorf(y)
	var xi := int(fx)
	var yi := int(fy)
	var u := x - fx
	var v := y - fy
	u = u * u * (3.0 - 2.0 * u)
	v = v * v * (3.0 - 2.0 * v)
	var X := xi & 255
	var Y := yi & 255
	var a := val[perm[X + perm[Y]]]
	var b := val[perm[X + 1 + perm[Y]]]
	var c := val[perm[X + perm[Y + 1]]]
	var d := val[perm[X + 1 + perm[Y + 1]]]
	var ab := a + (b - a) * u
	var cd := c + (d - c) * u
	return ab + (cd - ab) * v


func noise(x: float, y: float, oct: int = 4) -> float:
	var s := 0.0
	var amp := 1.0
	var fr := 1.0
	var n := 0.0
	for o in oct:
		s += n2(x * fr + o * 17.3, y * fr - o * 9.1) * amp
		n += amp
		amp *= 0.5
		fr *= 2.0
	return s / n
