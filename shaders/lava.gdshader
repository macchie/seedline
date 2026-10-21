shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
varying vec2 v_w;

void vertex() {
	v_w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float t = g_time;
	float n = texture(noise_tex, v_w * 0.011 + vec2(t * 0.012, t * 0.007)).r;
	float m = texture(noise_tex, v_w * 0.027 - vec2(t * 0.02, -t * 0.01)).r;
	float k = n * 0.62 + m * 0.38;
	vec3 c = mix(vec3(0.24, 0.03, 0.02), vec3(0.95, 0.32, 0.05), smoothstep(0.42, 0.7, k));
	c = mix(c, vec3(1.0, 0.8, 0.35), smoothstep(0.76, 0.88, k));
	ALBEDO = mix(c, g_fog_col, fog_amount(VERTEX));
}
