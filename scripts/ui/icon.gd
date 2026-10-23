class_name Icon
extends Control
## The web build's inline SVG icons (24-unit viewBox, 2-unit round strokes), drawn with canvas primitives.

var kind := ""
var color := Color.WHITE
var filled := false
var wave_alpha := 1.0
var px := 20.0


func _init(k: String = "", p: float = 20.0) -> void:
	kind = k
	px = p
	custom_minimum_size = Vector2(p, p)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := px / 24.0
	var o := (size - Vector2(px, px)) / 2.0
	draw_set_transform(o, 0.0, Vector2(s, s))
	var w := 2.0
	var c := color
	match kind:
		"sound":
			var sp := PackedVector2Array([Vector2(4, 9), Vector2(8, 9), Vector2(13, 5), Vector2(13, 19), Vector2(8, 15), Vector2(4, 15)])
			if filled:
				draw_colored_polygon(sp, c)
			sp.append(Vector2(4, 9))
			draw_polyline(sp, c, w, true)
			var wc := Color(c.r, c.g, c.b, c.a * wave_alpha)
			draw_arc(Vector2(12.93, 12), 5.0, deg_to_rad(-44.4), deg_to_rad(44.4), 12, wc, w, true)
			draw_arc(Vector2(12.98, 12), 8.5, deg_to_rad(-44.9), deg_to_rad(44.9), 16, wc, w, true)
		"star":
			var pts := PackedVector2Array([Vector2(12, 3.5), Vector2(14.6, 8.9), Vector2(20.5, 9.7), Vector2(16.2, 13.8), Vector2(17.2, 19.7), Vector2(12, 16.9), Vector2(6.8, 19.7), Vector2(7.8, 13.8), Vector2(3.5, 9.7), Vector2(9.4, 8.9)])
			if filled:
				draw_colored_polygon(pts, c)
			pts.append(pts[0])
			draw_polyline(pts, c, w, true)
		"dice":
			_round_rect(Rect2(4, 4, 16, 16), 3.0, c, w)
			for p in [Vector2(9, 9), Vector2(15, 15), Vector2(15, 9), Vector2(9, 15)]:
				draw_circle(p, 1.6, c)
		"pause":
			draw_line(Vector2(9, 6), Vector2(9, 18), c, w, true)
			draw_line(Vector2(15, 6), Vector2(15, 18), c, w, true)
		"respawn":
			draw_arc(Vector2(12, 12), 8.0, PI, deg_to_rad(-134.5), 32, c, w, true)
			draw_polyline(PackedVector2Array([Vector2(4, 4), Vector2(4, 8.5), Vector2(8.5, 8.5)]), c, w, true)
		"user":
			draw_arc(Vector2(12, 8.5), 3.8, 0.0, TAU, 20, c, w, true)
			draw_arc(Vector2(12, 21), 8.0, PI + 0.35, TAU - 0.35, 16, c, w, true)
		"x":
			draw_line(Vector2(7, 7), Vector2(17, 17), c, w, true)
			draw_line(Vector2(17, 7), Vector2(7, 17), c, w, true)
		"bug":
			draw_arc(Vector2(12, 13), 5.0, 0.0, TAU, 24, c, w, true)
			draw_arc(Vector2(12, 6.2), 2.2, 0.0, TAU, 16, c, w, true)
			draw_line(Vector2(10.6, 4.6), Vector2(9, 2.8), c, w, true)
			draw_line(Vector2(13.4, 4.6), Vector2(15, 2.8), c, w, true)
			draw_line(Vector2(12, 8.3), Vector2(12, 18), c, w, true)
			for i in 3:
				var yy := 10.0 + i * 2.6
				draw_line(Vector2(7.2, yy), Vector2(3.8, yy + 1.4), c, w, true)
				draw_line(Vector2(16.8, yy), Vector2(20.2, yy + 1.4), c, w, true)
		"play":
			var tp := PackedVector2Array([Vector2(8, 5), Vector2(19, 12), Vector2(8, 19)])
			if filled:
				draw_colored_polygon(tp, c)
			tp.append(tp[0])
			draw_polyline(tp, c, w, true)
	draw_set_transform(Vector2.ZERO)


func _round_rect(r: Rect2, rad: float, c: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var corners := [[r.position + Vector2(r.size.x - rad, rad), -PI / 2.0], [r.position + r.size - Vector2(rad, rad), 0.0],
		[r.position + Vector2(rad, r.size.y - rad), PI / 2.0], [r.position + Vector2(rad, rad), PI]]
	for k in 4:
		var cc: Vector2 = corners[k][0]
		var a0: float = corners[k][1]
		for i in 7:
			var a := a0 + PI / 2.0 * i / 6.0
			pts.append(cc + Vector2(cos(a), sin(a)) * rad)
	pts.append(pts[0])
	draw_polyline(pts, c, w, true)
