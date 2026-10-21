class_name U
## Shared constants and small helpers, ported 1:1 from the web build.

const TAU := PI * 2.0
const STEP := 1.0 / 120.0   # fixed physics step
const LAPS := 3
const HW := 14.25           # half road width (m)
const DS := 2.5             # track sample spacing (m)

const CODE := "ABCDEFGHJKMNPQRSTUVWXYZ23456789"


static func clampf2(v: float, a: float, b: float) -> float:
	return a if v < a else (b if v > b else v)


static func lerpf2(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


static func smooth01(x: float) -> float:
	x = clampf2(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func ang_diff(a: float, b: float) -> float:
	var d := b - a
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	return d


static func hypot(a: float, b: float) -> float:
	return sqrt(a * a + b * b)


## JS Math.round: halves round towards +infinity.
static func jround(x: float) -> float:
	return floor(x + 0.5)


static func jsign(x: float) -> float:
	return 1.0 if x > 0.0 else (-1.0 if x < 0.0 else 0.0)


static func pad(n: int, l: int) -> String:
	return str(n).pad_zeros(l)


## Race time as m:ss.mmm (– placeholders for no time)
static func fmt(t) -> String:
	if t == null or not is_finite(float(t)):
		return "–:––.–––"
	var ms := int(jround(float(t) * 1000.0))
	return str(ms / 60000) + ":" + pad((ms / 1000) % 60, 2) + "." + pad(ms % 1000, 3)


static func fmt_delta(d: float) -> String:
	return ("−" if d < 0.0 else "+") + ("%.3f" % absf(d))


static func rand_code(length: int = 5) -> String:
	var s := ""
	for i in length:
		s += CODE[randi() % CODE.length()]
	return s


static func rand_seed_code() -> String:
	return rand_code(6)


static func hexc(h: int) -> Color:
	return Color(((h >> 16) & 255) / 255.0, ((h >> 8) & 255) / 255.0, (h & 255) / 255.0, 1.0)


static func css(s: String) -> Color:
	## '#rrggbb' or 'rgba(r,g,b,a)'
	s = s.strip_edges()
	if s.begins_with("rgba(") or s.begins_with("rgb("):
		var inner := s.substr(s.find("(") + 1, s.rfind(")") - s.find("(") - 1)
		var p := inner.split(",")
		var a := 1.0
		if p.size() > 3:
			a = float(p[3])
		return Color(float(p[0]) / 255.0, float(p[1]) / 255.0, float(p[2]) / 255.0, a)
	return Color.html(s)


## three.js Color.offsetHSL
static func offset_hsl(c: Color, dh: float, ds: float, dl: float) -> Color:
	var hsl := to_hsl(c)
	return from_hsl(hsl.x + dh, hsl.y + ds, hsl.z + dl)


static func to_hsl(c: Color) -> Vector3:
	var r := c.r
	var g := c.g
	var b := c.b
	var mx := maxf(r, maxf(g, b))
	var mn := minf(r, minf(g, b))
	var h := 0.0
	var s := 0.0
	var l := (mn + mx) / 2.0
	if mn == mx:
		h = 0.0
		s = 0.0
	else:
		var delta := mx - mn
		s = delta / (mx + mn) if l <= 0.5 else delta / (2.0 - mx - mn)
		if mx == r:
			h = (g - b) / delta + (6.0 if g < b else 0.0)
		elif mx == g:
			h = (b - r) / delta + 2.0
		else:
			h = (r - g) / delta + 4.0
		h /= 6.0
	return Vector3(h, s, l)


static func _hue2rgb(p: float, q: float, t: float) -> float:
	if t < 0.0:
		t += 1.0
	if t > 1.0:
		t -= 1.0
	if t < 1.0 / 6.0:
		return p + (q - p) * 6.0 * t
	if t < 1.0 / 2.0:
		return q
	if t < 2.0 / 3.0:
		return p + (q - p) * 6.0 * (2.0 / 3.0 - t)
	return p


static func from_hsl(h: float, s: float, l: float) -> Color:
	h = fposmod(h, 1.0)
	s = clampf2(s, 0.0, 1.0)
	l = clampf2(l, 0.0, 1.0)
	if s == 0.0:
		return Color(l, l, l)
	var p := l * (1.0 + s) if l <= 0.5 else l + s - (l * s)
	var q := 2.0 * l - p
	return Color(_hue2rgb(q, p, h + 1.0 / 3.0), _hue2rgb(q, p, h), _hue2rgb(q, p, h - 1.0 / 3.0))


static func grid_key(ix: int, iz: int) -> int:
	return ix * 100003 + iz


static func cdist(a: int, b: int, n: int) -> int:
	var d := absi(a - b) % n
	return mini(d, n - d)
