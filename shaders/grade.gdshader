shader_type canvas_item;
// Final pass over the 3D view (the web build's post shader): FXAA, tilt-shift softening, bloom, highlight roll-off,
// per-world tint and saturation, a little contrast, vignette and grain. 'full' is off in battery-saver mode.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform bool full = true;
uniform vec3 tint = vec3(1.0);
uniform float sat = 1.1;
uniform float vig = 0.34;
uniform float tilt = 1.0;
uniform float bloom = 0.24;
uniform float bloom_th = 0.95;
uniform float time = 0.0;

vec3 tex(vec2 uv) {
	return textureLod(screen_tex, uv, 0.0).rgb;
}

vec3 fxaa(vec2 uv, vec2 px) {
	vec3 nw = tex(uv + vec2(-1.0, -1.0) * px);
	vec3 ne = tex(uv + vec2(1.0, -1.0) * px);
	vec3 sw = tex(uv + vec2(-1.0, 1.0) * px);
	vec3 se = tex(uv + vec2(1.0, 1.0) * px);
	vec3 m = tex(uv);
	vec3 L = vec3(0.299, 0.587, 0.114);
	float a = dot(nw, L);
	float b = dot(ne, L);
	float c = dot(sw, L);
	float d = dot(se, L);
	float lm = dot(m, L);
	float lo = min(lm, min(min(a, b), min(c, d)));
	float hi = max(lm, max(max(a, b), max(c, d)));
	vec2 dir = vec2(-((a + b) - (c + d)), ((a + c) - (b + d)));
	float red = max((a + b + c + d) * 0.03125, 1.0 / 128.0);
	float rcp = 1.0 / (min(abs(dir.x), abs(dir.y)) + red);
	dir = clamp(dir * rcp, -8.0, 8.0) * px;
	vec3 A = 0.5 * (tex(uv + dir * (1.0 / 3.0 - 0.5)) + tex(uv + dir * (2.0 / 3.0 - 0.5)));
	vec3 B = A * 0.5 + 0.25 * (tex(uv - dir * 0.5) + tex(uv + dir * 0.5));
	float lb = dot(B, L);
	return (lb < lo || lb > hi) ? A : B;
}

vec3 bright(vec2 uv) {
	vec3 c = textureLod(screen_tex, uv, 2.0).rgb;
	float l = max(c.r, max(c.g, c.b));
	return c * smoothstep(bloom_th, bloom_th + 0.22, l);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 c;
	if (full) {
		c = fxaa(uv, px);
		// tilt-shift: soften the top and bottom of the frame (uv.y is flipped compared to WebGL)
		float ts = tilt * (smoothstep(0.62, 1.0, 1.0 - uv.y) + 0.55 * smoothstep(0.22, 0.0, 1.0 - uv.y));
		if (ts > 0.02) {
			vec3 s = vec3(0.0);
			float r = 1.5 + ts * 4.0;
			s += tex(uv + vec2(1.0, 0.0) * px * r);
			s += tex(uv + vec2(-1.0, 0.0) * px * r);
			s += tex(uv + vec2(0.0, 1.0) * px * r);
			s += tex(uv + vec2(0.0, -1.0) * px * r);
			s += tex(uv + vec2(0.7, 0.7) * px * r);
			s += tex(uv + vec2(-0.7, 0.7) * px * r);
			s += tex(uv + vec2(0.7, -0.7) * px * r);
			s += tex(uv + vec2(-0.7, -0.7) * px * r);
			c = mix(c, s / 8.0, clamp(ts, 0.0, 1.0));
		}
		// bloom: bright pass blurred over a quarter-resolution neighbourhood
		vec3 bl = bright(uv) * 0.227;
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.785398;
			vec2 o = vec2(cos(a), sin(a)) * px;
			bl += bright(uv + o * 6.0) * 0.06;
			bl += bright(uv + o * 14.0) * 0.032;
		}
		c += bl * bloom;
		c = c / (1.0 + max(0.0, dot(c, vec3(0.333)) - 1.0) * 0.35);
		c *= tint;
		float l = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(vec3(l), c, sat);
		c = (c - 0.5) * 1.05 + 0.5;
		float v = length((uv - 0.5) * vec2(px.y / px.x, 1.0));
		c *= 1.0 - vig * smoothstep(0.45, 1.25, v);
		c += (fract(sin(dot(uv / px + fract(time), vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.016;
	} else {
		c = tex(uv);
	}
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
