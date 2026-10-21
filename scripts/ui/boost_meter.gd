class_name BoostMeter
extends Control
## Rocket-League style boost gauge: an arc that fills with the boost amount and a big number in the middle.

var value := 0.0
var cap := 100.0
var active := false
var accent := Color("#ff9a3c")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(v: float, c: float, on: bool) -> void:
	if absf(v - value) < 0.05 and on == active and c == cap:
		return
	value = v
	cap = c
	active = on
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) / 2.0 - 6.0
	var c := size / 2.0
	var a0 := deg_to_rad(135.0)
	var span := deg_to_rad(270.0)
	draw_circle(c, r + 4.0, Color(0.04, 0.05, 0.08, 0.55))
	draw_arc(c, r, a0, a0 + span, 48, Color(1, 1, 1, 0.16), 7.0, true)
	var f := clampf(value / cap, 0.0, 1.0)
	var col := accent if not active else Color("#ffe08a")
	if f <= 0.0:
		col = Color(1, 1, 1, 0.0)
	if f > 0.0:
		draw_arc(c, r, a0, a0 + span * f, maxi(4, int(48.0 * f)), col, 7.0, true)
	var font := ThemeDB.fallback_font
	var txt := str(int(ceil(value)))
	var fs := int(r * 0.9)
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(font, Vector2(c.x - ts.x / 2.0, c.y + fs * 0.32), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if value > 0.0 else Color(1, 1, 1, 0.5))
	var lbl := "BOOST"
	var ls := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, int(r * 0.26))
	draw_string(font, Vector2(c.x - ls.x / 2.0, c.y + r * 0.78), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.26), Color(1, 1, 1, 0.6))
