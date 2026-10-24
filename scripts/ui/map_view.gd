class_name MapView
extends Control
## Track map for the HUD minimap and the menu preview (drawn in the web build's 224-px canvas space, scaled).

const S := 224.0

var t: TrackData = null
var accent := Color.WHITE
var sc := 1.0
var ox := 0.0
var oz := 0.0
var line_pts := PackedVector2Array()
var bridge_segs: Array = []
var cp_pts: Array = []
var start := Vector2.ZERO
var car_pos = null          # Vector2 world x,z
var car_col := Color.WHITE
var ghost_pos = null
var preview := false        # menu preview draws a bigger dot


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func map(x: float, z: float) -> Vector2:
	return Vector2(S - (x * sc + ox), S - (z * sc + oz))


func set_track(track: TrackData, acc: Color) -> void:
	t = track
	accent = acc
	var x0 := 1e9
	var x1 := -1e9
	var z0 := 1e9
	var z1 := -1e9
	for i in t.n:
		x0 = minf(x0, t.px[i])
		x1 = maxf(x1, t.px[i])
		z0 = minf(z0, t.pz[i])
		z1 = maxf(z1, t.pz[i])
	sc = (S - 36.0) / maxf(x1 - x0, z1 - z0)
	ox = S / 2.0 - (x0 + x1) / 2.0 * sc
	oz = S / 2.0 - (z0 + z1) / 2.0 * sc
	line_pts = PackedVector2Array()
	for i in t.n + 1:
		line_pts.append(map(t.px[i % t.n], t.pz[i % t.n]))
	cp_pts = []
	for i in t.cps:
		cp_pts.append(map(t.px[i], t.pz[i]))
	bridge_segs = []
	for i in t.n:
		var j := (i + 1) % t.n
		if t.py[i] < 2.0 or t.py[j] < 2.0:
			continue
		bridge_segs.append([map(t.px[i], t.pz[i]), map(t.px[j], t.pz[j])])
	start = map(t.px[0], t.pz[0])
	queue_redraw()


func _draw() -> void:
	if t == null:
		return
	# scale by the shorter side and centre, so a non-square control never spills the map outside it
	var k := minf(size.x, size.y) / S
	draw_set_transform((size - Vector2(S, S) * k) / 2.0, 0.0, Vector2(k, k))
	draw_polyline(line_pts, Color(1, 1, 1, 0.18), 10.0, true)
	draw_polyline(line_pts, Color(1, 1, 1, 0.75), 3.0, true)
	for p in cp_pts:
		draw_circle(p, 4.0, accent)
	for s in bridge_segs:
		draw_line(s[0], s[1], Color(10 / 255.0, 12 / 255.0, 18 / 255.0, 0.9), 9.0, true)
		draw_line(s[0], s[1], Color.WHITE, 3.4, true)
	draw_rect(Rect2(start - Vector2(5, 5), Vector2(10, 10)), Color.WHITE)
	if ghost_pos != null:
		draw_circle(map(ghost_pos.x, ghost_pos.y), 5.0, Color(1, 1, 1, 0.7))
	if car_pos != null:
		var p := map(car_pos.x, car_pos.y)
		var r := 8.0 if preview else 7.0
		draw_circle(p, r, car_col)
		draw_arc(p, r, 0, TAU, 24, Color.WHITE, 3.0 if preview else 2.5, true)
	draw_set_transform(Vector2.ZERO)
