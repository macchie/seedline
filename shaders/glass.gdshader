shader_type canvas_item;
// Rounded panel with optional backdrop blur, vertical gradient fill and (dashed) border: the web build's glass
// panels (rgba fills over backdrop-filter: blur()).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 rect_size = vec2(100.0);
uniform vec4 radius = vec4(12.0);       // top-left, top-right, bottom-right, bottom-left
uniform vec4 fill_top = vec4(0.0);
uniform vec4 fill_bot = vec4(0.0);
uniform vec4 border_col = vec4(0.0);
uniform float border_w = 0.0;
uniform float blur = 0.0;               // backdrop blur as a mip level (0 = none)
uniform float dash = 0.0;               // dashed border period in px (0 = solid)
uniform vec4 inset_col = vec4(0.0);     // inner bottom shade (swatch bevel)
uniform float inset_h = 0.0;
uniform float conic = 0.0;              // custom-colour swatch: conic-gradient(#f43,#fb3,#4d6,#3bf,#86f,#f4b,#f43)
varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec2 half_size = rect_size * 0.5;
	vec2 p = lp - half_size;
	float rr = p.x < 0.0 ? (p.y < 0.0 ? radius.x : radius.w) : (p.y < 0.0 ? radius.y : radius.z);
	rr = min(rr, min(half_size.x, half_size.y));
	vec2 q = abs(p) - half_size + rr;
	float d = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rr;
	vec4 fill = mix(fill_top, fill_bot, clamp(lp.y / max(rect_size.y, 1.0), 0.0, 1.0));
	if (conic > 0.5) {
		vec3 st[7] = vec3[7](vec3(1.0, 0.267, 0.2), vec3(1.0, 0.733, 0.2), vec3(0.267, 0.867, 0.4), vec3(0.2, 0.733, 1.0), vec3(0.533, 0.4, 1.0), vec3(1.0, 0.267, 0.733), vec3(1.0, 0.267, 0.2));
		float ang = atan(p.x, -p.y);
		float u = fract(ang / 6.2831853) * 6.0;
		int k = int(floor(u));
		fill = vec4(mix(st[k], st[min(k + 1, 6)], u - float(k)), 1.0);
	}
	if (inset_h > 0.0 && lp.y > rect_size.y - inset_h) {
		fill.rgb = mix(fill.rgb, inset_col.rgb, inset_col.a);
	}
	vec3 rgb = fill.rgb;
	float a = fill.a;
	if (blur > 0.0) {
		vec3 under = textureLod(screen_tex, SCREEN_UV, blur).rgb;
		rgb = mix(under, fill.rgb, fill.a);
		a = 1.0;
	}
	if (border_w > 0.0 && border_col.a > 0.0) {
		float b = clamp(d + border_w + 0.5, 0.0, 1.0);
		if (dash > 0.0) {
			float s = (abs(p.y) > half_size.y - border_w - rr * 0.3) ? lp.x : lp.y;
			b *= step(0.5, fract(s / dash));
		}
		rgb = mix(rgb, border_col.rgb, b * border_col.a);
		a = max(a, b * border_col.a);
	}
	a *= clamp(0.5 - d, 0.0, 1.0);
	COLOR = vec4(rgb, a) * COLOR;
}
