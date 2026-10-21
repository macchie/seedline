// Shared scene state. Lighting and fog are computed in display space, like three.js r128 without colour
// management; the Compatibility renderer linearises ALBEDO and re-encodes the result, so lit shaders hand their
// final display colour to DIFFUSE_LIGHT through to_lin() with ALBEDO = 1.
global uniform vec3 g_hemi_sky;
global uniform vec3 g_hemi_ground;
global uniform float g_hemi_i;
global uniform float g_rim;
global uniform vec3 g_rim_col;
global uniform float g_time;
global uniform vec3 g_sun;        // sun colour x intensity (display)
global uniform vec3 g_fog_col;
global uniform vec2 g_fog;        // linear fog near, far (view depth)
global uniform vec3 g_sky_top;
global uniform vec3 g_sky_hor;
global uniform vec3 g_sky_gnd;

vec3 to_lin(vec3 c) {
	c = max(c, vec3(0.0));
	vec3 lo = c / 12.92;
	vec3 hi = pow((c + 0.055) / 1.055, vec3(2.4));
	return mix(lo, hi, step(vec3(0.04045), c));
}

float fog_amount(vec3 view_pos) {
	return smoothstep(g_fog.x, g_fog.y, -view_pos.z);
}

vec3 hemi_light(vec3 world_n) {
	return mix(g_hemi_ground, g_hemi_sky, world_n.y * 0.5 + 0.5) * g_hemi_i;
}

// the painted gradient sky (setSky), sampled like an equirectangular map
vec3 sky_color(vec3 d) {
	float f = 0.5 - asin(clamp(d.y, -1.0, 1.0)) / 3.14159265;
	if (f < 0.48) {
		return mix(g_sky_top, g_sky_hor, f / 0.48);
	} else if (f < 0.52) {
		return mix(g_sky_hor, g_sky_gnd, (f - 0.48) / 0.04);
	}
	return mix(g_sky_gnd, g_sky_gnd * 0.6, (f - 0.52) / 0.48);
}
