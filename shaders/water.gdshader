shader_type spatial;
// Water: one surface for sea, lakes and rivers. Colour from depth, fresnel sky reflection, sun glints, shallow caustics,
// shore foam, flow-map advection (two-phase, so it never stretches) and car ripple rings.
// UV = flow vector (zero in still water), UV2.x = depth, UV2.y = river weight (blends the river palette in).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 rip[8];
uniform vec3 shallow = vec3(0.28, 0.86, 0.8);
uniform vec3 deep = vec3(0.04, 0.31, 0.47);
uniform vec3 r_shallow = vec3(0.4, 0.7, 0.7);
uniform vec3 r_deep = vec3(0.1, 0.3, 0.35);
uniform vec3 foam_col = vec3(0.95, 0.98, 1.0);
uniform vec3 sky = vec3(0.7, 0.85, 0.95);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_col = vec3(1.0);
uniform float shimmer = 1.0;
uniform float chop = 1.0;

varying float v_depth;
varying float v_river;
varying vec2 v_w;
varying vec2 v_flow;
varying vec3 v_world;

float nz(vec2 p) { return texture(noise_tex, p).r; }

// height and two forward differences for the normal, three octaves advected by the flow
vec3 hgt3(vec2 w, vec2 fv, float c, float t) {
	vec2 a = w * 0.011 + t * vec2(0.006, 0.004) - fv * c * 0.25;
	vec2 b = w * 0.026 - t * vec2(0.004, 0.009) - fv * c * 0.4;
	vec2 d = w * 0.075 + t * vec2(0.012, -0.007) - fv * c * 0.6;
	float e = 0.0035;
	float h0 = nz(a) + nz(b) * 0.6 + nz(d) * 0.3;
	float hx = nz(a + vec2(e, 0.0)) + nz(b + vec2(e, 0.0)) * 0.6 + nz(d + vec2(e, 0.0)) * 0.3;
	float hz = nz(a + vec2(0.0, e)) + nz(b + vec2(0.0, e)) * 0.6 + nz(d + vec2(0.0, e)) * 0.3;
	return vec3(h0, hx, hz);
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wv = sin(wp.x * 0.08 + g_time * 1.3) * 0.5 + sin(wp.z * 0.11 - g_time * 1.05) * 0.5;
	float dy = wv * 0.1 * smoothstep(0.0, 2.0, UV2.x);
	VERTEX.y += dy;
	v_depth = UV2.x;
	v_river = UV2.y;
	v_w = wp.xz;
	v_flow = UV;
	v_world = wp + vec3(0.0, dy, 0.0);
}

void fragment() {
	float t = g_time;
	float fmag = clamp(length(v_flow), 0.0, 1.0);
	float c0 = fract(t * 0.13);
	float c1 = fract(t * 0.13 + 0.5);
	float w0 = 1.0 - abs(1.0 - 2.0 * c0);
	vec3 hh = mix(hgt3(v_w, v_flow, c1, t), hgt3(v_w, v_flow, c0, t), w0);
	float h = hh.x;
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
	float choppy = (4.5 + fmag * 2.0) * chop;
	vec3 N = normalize(vec3((h - hh.y) * choppy + rg.x * 0.5, 1.0, (h - hh.z) * choppy + rg.y * 0.5));
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 V = normalize(cam - v_world);
	float fres = 0.04 + 0.96 * pow(1.0 - max(dot(N, V), 0.0), 5.0);
	float dep = clamp(v_depth / 4.5, 0.0, 1.0);
	vec3 shc = mix(shallow, r_shallow, v_river);
	vec3 dpc = mix(deep, r_deep, v_river);
	vec3 c = mix(shc, dpc, smoothstep(0.0, 1.0, pow(dep, 0.8)));
	// sun light scattering through the water, strongest where it is thin
	c *= 0.86 + 0.28 * clamp(dot(N, sun_dir) * 0.5 + 0.5, 0.0, 1.0);
	float ca = smoothstep(0.6, 0.76, nz(v_w * 0.055 + hh.yz * 0.02 + t * 0.018)) * (1.0 - dep) * 0.14;
	c += ca * vec3(1.0, 1.0, 0.9) * (sun_col.r * 0.8 + 0.2);
	float skyk = clamp(fres * 1.4, 0.0, 0.8);
	c = mix(c, sky, skyk);
	vec3 H = normalize(sun_dir + V);
	float sp = pow(max(dot(N, H), 0.0), 260.0) * 0.9 + pow(max(dot(N, H), 0.0), 40.0) * 0.08;
	float spk = smoothstep(0.78, 0.95, nz(v_w * 0.35 + t * vec2(0.05, -0.04)) * nz(v_w * 0.21 - t * 0.03) * 1.9) * pow(max(dot(N, H), 0.0), 6.0);
	c += sun_col * (sp * shimmer + spk * 0.6 * shimmer * shimmer);
	float sh = 1.0 - smoothstep(0.04, 0.95, v_depth);
	float fn = nz(v_w * 0.07 + t * vec2(0.03, 0.012));
	float foam = smoothstep(0.5, 0.62, sh * (0.55 + fn * 0.85) + sin(v_depth * 7.0 - t * 2.2) * 0.14 * sh) + clamp(rp, 0.0, 1.0) * 1.1;
	// white-water streaks that travel with the current, plus a little wash on the banks
	vec2 fa = v_w * 0.09 - v_flow * c0 * 0.9;
	vec2 fb = v_w * 0.09 - v_flow * c1 * 0.9;
	float st = mix(nz(fb), nz(fa), w0);
	foam += smoothstep(0.66, 0.82, st) * fmag * (0.25 + sh * 0.9) * 0.5;
	c = mix(c, foam_col, clamp(foam, 0.0, 1.0));
	float a = mix(0.5, 0.92, smoothstep(0.0, 1.8, v_depth)) + clamp(foam, 0.0, 1.0) * 0.35 + fres * 0.2;
	ALBEDO = mix(c, g_fog_col, fog_amount(VERTEX));
	ALPHA = clamp(a, 0.0, 1.0);
}
