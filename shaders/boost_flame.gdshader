shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// Cel-shaded booster flame: a cone (base at y=-0.5, tip at y=+0.5) painted in three hard bands.
uniform vec3 tint : source_color = vec3(0.2, 0.9, 1.0);
uniform float power = 1.0;
uniform float flicker = 0.0;

varying float t;

void vertex() {
	t = clamp(VERTEX.y + 0.5, 0.0, 1.0);
	float w = sin(TIME * 38.0 + t * 9.0) * 0.07 + sin(TIME * 23.0 - t * 5.0 + flicker * 6.0) * 0.05;
	VERTEX.x += w * t;
	VERTEX.z += w * 0.6 * t;
}

void fragment() {
	float f = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float len = 0.72 + 0.28 * sin(TIME * 31.0 + flicker * 7.0);
	if (t > len) discard;
	float tip = smoothstep(0.0, 1.0, t / len);
	float band = f - tip * 0.35;
	vec3 col;
	if (band > 0.8) {
		col = mix(tint, vec3(1.0), 0.88);
	} else if (band > 0.45) {
		col = mix(tint, vec3(1.0), 0.25) * 0.95;
	} else {
		col = tint * 0.55;
	}
	ALBEDO = col * power;
}
