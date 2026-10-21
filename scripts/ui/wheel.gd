class_name Wheel
extends Control
## Touch steering wheel (the web build's SVG wheel), rotated with the hidden slider's value.

var accent := Color.WHITE
var on := false
var rot := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var k := size.x / 100.0
	var c := size / 2.0
	# soft dark disc behind the wheel (#wheel::before, not rotated)
	var R := (size.x + 20.0) / 2.0 * sqrt(2.0)
	var dark := Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.35)
	draw_circle(c, R * 0.55, dark)
	var ring_in := PackedVector2Array()
	var ring_out := PackedVector2Array()
	var n := 48
	for i in n + 1:
		var a := TAU * i / n
		ring_in.append(c + Vector2(cos(a), sin(a)) * R * 0.55)
		ring_out.append(c + Vector2(cos(a), sin(a)) * R * 0.72)
	for i in n:
		draw_polygon(PackedVector2Array([ring_in[i], ring_out[i], ring_out[i + 1], ring_in[i + 1]]),
			PackedColorArray([dark, Color(dark, 0.0), Color(dark, 0.0), dark]))
	draw_set_transform(c, rot, Vector2(k, k))
	var o := Vector2(-50, -50)
	draw_arc(o + Vector2(50, 50), 44.0, 0, TAU, 64, Color(1, 1, 1, 0.2) if on else Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.72), 13.0, true)
	var circ := TAU * 44.0
	var d := 0.0
	while d < circ:
		var a0 := d / 44.0
		var a1 := minf(d + 3.0, circ) / 44.0
		draw_arc(o + Vector2(50, 50), 44.0, a0, a1, 3, Color(1, 1, 1, 0.3), 2.0, true)
		d += 7.0
	var spk := Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.75)
	var q := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		var p := (1.0 - t) * (1.0 - t) * Vector2(8, 52) + 2.0 * (1.0 - t) * t * Vector2(50, 40) + t * t * Vector2(92, 52)
		q.append(o + p)
	draw_polyline(q, spk, 9.0, true)
	draw_circle(q[0], 4.5, spk)
	draw_circle(q[q.size() - 1], 4.5, spk)
	draw_line(o + Vector2(50, 58), o + Vector2(50, 93), spk, 9.0, true)
	draw_circle(o + Vector2(50, 93), 4.5, spk)
	draw_circle(o + Vector2(50, 54), 11.0, Color(10 / 255.0, 13 / 255.0, 19 / 255.0, 0.88))
	draw_arc(o + Vector2(50, 54), 11.0, 0, TAU, 32, Color(1, 1, 1, 0.25), 1.5, true)
	draw_rect(Rect2(o + Vector2(46, 3), Vector2(8, 10)), accent)
	draw_set_transform(Vector2.ZERO)
