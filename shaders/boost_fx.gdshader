shader_type canvas_item;
// Turbo flash: an inner glow around the screen edge (box-shadow: inset 0 0 120px 18px).
uniform vec4 glow = vec4(1.0);
uniform vec2 rect_size = vec2(100.0);
varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float d = min(min(lp.x, rect_size.x - lp.x), min(lp.y, rect_size.y - lp.y));
	float a = clamp(1.0 - (d - 18.0) / 120.0, 0.0, 1.0);
	a = a * a * (3.0 - 2.0 * a);
	COLOR = vec4(glow.rgb, glow.a * a);
}
