shader_type spatial;
// Full-screen pass drawn first among transparents: ink outlines where depth jumps, and drifting cloud shadows on the
// ground. It multiplies the opaque image (blend_mul), so water, particles and glows drawn later stay clean.
render_mode unshaded, blend_mul, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

global uniform float g_time;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float cloud = 0.3;
uniform float ink = 0.62;
uniform vec2 fogr = vec2(200.0, 400.0);

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

vec3 view_pos(vec2 uv, float d, mat4 inv_proj) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
#endif
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return v.xyz / v.w;
}

float lin(vec2 uv, mat4 inv_proj) {
	return -view_pos(uv, texture(depth_tex, uv).r, inv_proj).z;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float d = texture(depth_tex, uv).r;
	vec3 vp = view_pos(uv, d, INV_PROJECTION_MATRIX);
	float z = -vp.z;
	vec3 m = vec3(1.0);
	bool geo = z < 1300.0;
	if (geo && cloud > 0.0) {
		vec3 wp = (INV_VIEW_MATRIX * vec4(vp, 1.0)).xyz;
		float n = texture(noise_tex, wp.xz * 0.0032 + g_time * vec2(0.0042, 0.0024)).r * 0.65 + texture(noise_tex, wp.xz * 0.0085 - g_time * vec2(0.003, 0.0021)).r * 0.35;
		m *= 1.0 - cloud * smoothstep(0.47, 0.64, n);
	}
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float k = max(1.0, VIEWPORT_SIZE.y / 950.0);
	float e = 0.0;
	e = max(e, lin(uv + vec2(k, 0.0) * px, INV_PROJECTION_MATRIX) - z);
	e = max(e, lin(uv - vec2(k, 0.0) * px, INV_PROJECTION_MATRIX) - z);
	e = max(e, lin(uv + vec2(0.0, k) * px, INV_PROJECTION_MATRIX) - z);
	e = max(e, lin(uv - vec2(0.0, k) * px, INV_PROJECTION_MATRIX) - z);
	e = geo ? smoothstep(0.012, 0.045, e / z) * ink * (1.0 - smoothstep(fogr.x, fogr.y, z)) : 0.0;
	m *= mix(vec3(1.0), vec3(0.2, 0.17, 0.24), e);
	ALBEDO = m;
}
