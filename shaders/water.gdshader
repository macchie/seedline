shader_type spatial;
// Water: colour from depth, fresnel sky reflection, sun glints, shallow caustics, animated shore foam, flow along
// rivers and expanding ripple rings from the car. UV = flow coords (metres along, metres across), UV2.x = depth.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 rip[8];
uniform float river = 0.0;
uniform vec3 shallow = vec3(0.28, 0.86, 0.8);
uniform vec3 deep = vec3(0.04, 0.31, 0.47);
uniform vec3 foam_col = vec3(0.95, 0.98, 1.0);
uniform vec3 sky = vec3(0.7, 0.85, 0.95);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_col = vec3(1.0);

varying float v_depth;
varying vec2 v_w;
varying vec2 v_flow;
varying vec3 v_world;

float nz(vec2 p) { return texture(noise_tex, p).r; }
float hgt(vec2 a, vec2 b) { return nz(a) + nz(b) * 0.6; }

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wv = sin(wp.x * 0.08 + g_time * 1.3) * 0.5 + sin(wp.z * 0.11 - g_time * 1.05) * 0.5;
	float dy = wv * 0.1 * smoothstep(0.0, 2.0, UV2.x);
	VERTEX.y += dy;
	v_depth = UV2.x;
	v_w = wp.xz;
	v_flow = UV;
	v_world = wp + vec3(0.0, dy, 0.0);
}

void fragment() {
	float t = g_time;
	vec2 f1;
	vec2 f2;
	if (river > 0.5) {
		f1 = vec2(v_flow.y * 0.045, v_flow.x * 0.018 - t * 0.11);
		f2 = vec2(v_flow.y * 0.09 + 0.3, v_flow.x * 0.04 - t * 0.19);
	} else {
		f1 = v_w * 0.011 + t * vec2(0.006, 0.004);
		f2 = v_w * 0.026 - t * vec2(0.004, 0.009);
	}
	float e = 0.0035;
	float h = hgt(f1, f2);
	float hx = hgt(f1 + vec2(e, 0.0), f2 + vec2(e, 0.0));
	float hz = hgt(f1 + vec2(0.0, e), f2 + vec2(0.0, e));
	float rp = 0.0;
	vec2 rg = vec2(0.0);
	for (int i = 0; i < 8; i++) {
		vec3 r = rip[i];
		float age = t - r.z;
		if (age > 0.0 && age < 4.0) {
			vec2 dv = v_w - r.xy;
			float d = length(dv);
			float w = d - age * 6.0;
			float a = exp(-w * w * 0.12) * exp(-age * 0.9);
			rp += a;
			rg += normalize(dv + 1e-4) * a * sin(w * 1.6);
		}
	}
	vec3 N = normalize(vec3((h - hx) * 4.5 + rg.x * 0.5, 1.0, (h - hz) * 4.5 + rg.y * 0.5));
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 V = normalize(cam - v_world);
	float fres = 0.04 + 0.96 * pow(1.0 - max(dot(N, V), 0.0), 5.0);
	float dep = clamp(v_depth / 4.5, 0.0, 1.0);
	vec3 c = mix(shallow, deep, smoothstep(0.0, 1.0, dep));
	float ca = smoothstep(0.6, 0.76, nz(v_w * 0.055 + vec2(h, hz) * 0.25 + t * 0.018)) * (1.0 - dep) * 0.14;
	c += ca * vec3(1.0, 1.0, 0.9) * (sun_col.r * 0.8 + 0.2);
	c = mix(c, sky, clamp(fres * 1.4, 0.0, 0.75));
	vec3 H = normalize(sun_dir + V);
	float sp = pow(max(dot(N, H), 0.0), 260.0) * 0.9;
	c += sun_col * sp;
	float sh = 1.0 - smoothstep(0.04, 0.95, v_depth);
	float fn = nz(v_w * 0.07 + t * vec2(0.03, 0.012));
	float foam = smoothstep(0.5, 0.62, sh * (0.55 + fn * 0.85) + sin(v_depth * 7.0 - t * 2.2) * 0.14 * sh) + clamp(rp, 0.0, 1.0) * 1.1;
	if (river > 0.5) {
		foam += smoothstep(0.64, 0.8, nz(vec2(v_flow.y * 0.11, v_flow.x * 0.05 - t * 0.32))) * 0.3 * (0.4 + sh);
	}
	c = mix(c, foam_col, clamp(foam, 0.0, 1.0));
	float a = mix(0.5, 0.9, smoothstep(0.0, 1.8, v_depth)) + clamp(foam, 0.0, 1.0) * 0.35 + fres * 0.2;
	ALBEDO = mix(c, g_fog_col, fog_amount(VERTEX));
	ALPHA = clamp(a, 0.0, 1.0);
}
