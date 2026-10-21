// Cartoon lighting shared by every prop (three.js MeshToonMaterial with a three-step gradient map): hard sun bands
// with shadows, hemisphere ambient, a soft rim, optional vertex animation for foliage, crowds and flags.
#include "res://shaders/common.gdshaderinc"

uniform vec3 albedo = vec3(1.0);
uniform bool use_map = false;
uniform sampler2D tex_map : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 uv_scale = vec2(1.0);
uniform vec3 emissive = vec3(0.0);
uniform float emissive_i = 0.0;
uniform bool use_emissive_map = false;
uniform float anim_amp = 0.0;

varying vec3 v_a;
varying vec3 v_rest;
varying float v_fog;

void vertex() {
#ifdef ANIM_SWAY
	vec2 ip = MODEL_MATRIX[3].xz;
	float sw = max(0.0, VERTEX.y);
	VERTEX.x += sin(g_time * 1.6 + ip.x * 0.11 + ip.y * 0.07) * anim_amp * sw;
	VERTEX.z += cos(g_time * 1.25 + ip.y * 0.13) * anim_amp * 0.6 * sw;
#endif
#ifdef ANIM_HOP
	vec2 ip = MODEL_MATRIX[3].xz;
	VERTEX.y += max(0.0, sin(g_time * 7.0 + ip.x * 1.7 + ip.y * 2.3)) * anim_amp;
#endif
#ifdef ANIM_FLAG
	vec2 ip = MODEL_MATRIX[3].xz;
	float fl = max(0.0, VERTEX.x);
	VERTEX.z += sin(g_time * 7.0 + VERTEX.x * 1.6 + ip.x) * anim_amp * fl;
#endif
}

void fragment() {
	vec3 base = albedo * COLOR.rgb;
	vec4 tm = texture(tex_map, UV * uv_scale);
	if (use_map) {
		base *= tm.rgb;
	}
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
	vec3 em = emissive * emissive_i;
	if (use_emissive_map) {
		em *= tm.rgb;
	}
	v_a = base;
	v_rest = base * hemi_light(wn) + em + g_rim_col * rim * g_rim;
	v_fog = fog_amount(VERTEX);
	ALBEDO = vec3(1.0);
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float c = dot(NORMAL, LIGHT) * 0.5 + 0.5;
		float g = c < 0.3333333 ? 0.4117647 : (c < 0.6666667 ? 0.7254902 : 1.0);
		vec3 d = v_rest + v_a * g * ATTENUATION * g_sun;
		DIFFUSE_LIGHT += to_lin(mix(d, g_fog_col, v_fog));
	} else {
		float c = dot(NORMAL, LIGHT) * 0.5 + 0.5;
		float g = c < 0.3333333 ? 0.4117647 : (c < 0.6666667 ? 0.7254902 : 1.0);
		DIFFUSE_LIGHT += to_lin(v_a * g * ATTENUATION * LIGHT_COLOR / PI) * (1.0 - v_fog);
	}
}
