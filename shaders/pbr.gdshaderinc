// three.js r128 MeshStandardMaterial in display space: GGX sun specular with shadows, hemisphere light, and the
// painted gradient sky as the environment map (envMapIntensity scales its diffuse and reflected light).
#include "res://shaders/common.gdshaderinc"

uniform vec3 albedo = vec3(1.0);
uniform bool use_tex = false;
uniform sampler2D tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 uv_scale = vec2(1.0);
uniform float roughness = 0.5;
uniform float metallic = 0.0;
uniform float env_i = 1.0;
uniform vec3 emissive = vec3(0.0);
uniform float opacity = 1.0;

varying vec3 v_dc;
varying vec3 v_f0;
varying vec3 v_rest;
varying float v_fog;
varying float v_rough;

vec2 dfg_approx(float dot_nv, float r) {
	vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
	vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
	vec4 q = r * c0 + c1;
	float a004 = min(q.x * q.x, exp2(-9.28 * dot_nv)) * q.x + q.y;
	return vec2(-1.04, 1.04) * a004 + q.zw;
}

void fragment() {
	vec3 a = albedo * COLOR.rgb;
	if (use_tex) {
		a *= texture(tex, UV * uv_scale).rgb;
	}
	float r = clamp(max(roughness, 0.0525), 0.0, 1.0);
	vec3 dc = a * (1.0 - metallic);
	vec3 f0 = mix(vec3(0.04), a, metallic);
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 wv = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float dot_nv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// environment: blurred gradient sky
	vec3 sky_avg = mix(g_sky_hor, g_sky_top, 0.5);
	vec3 gnd_avg = g_sky_gnd * 0.8;
	vec3 env_irr = mix(gnd_avg, sky_avg, wn.y * 0.5 + 0.5) * env_i;
	vec3 rd = reflect(-wv, wn);
	vec3 rad = mix(sky_color(rd), mix(gnd_avg, sky_avg, rd.y * 0.5 + 0.5), r * r) * env_i;
	vec3 irr = hemi_light(wn) + env_irr;
	// multiscattering environment BRDF (BRDF_Specular_Multiscattering_Environment)
	vec2 fab = dfg_approx(dot_nv, r);
	vec3 fss = f0 * fab.x + fab.y;
	float ess = fab.x + fab.y;
	float ems = 1.0 - ess;
	vec3 favg = f0 + (1.0 - f0) * 0.047619;
	vec3 fms = fss * favg / (1.0 - ems * favg);
	vec3 diffuse = dc * (1.0 - (fss + fms * ems));
	v_rest = fss * rad + fms * ems * irr + diffuse * irr + emissive;
	v_dc = dc;
	v_f0 = f0;
	v_rough = r;
	v_fog = fog_amount(VERTEX);
	ALBEDO = vec3(1.0);
#ifdef PBR_ALPHA
	ALPHA = opacity;
#endif
}

void light() {
	float dot_nl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	vec3 h = normalize(LIGHT + VIEW);
	float dot_nv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float dot_nh = clamp(dot(NORMAL, h), 0.0, 1.0);
	float dot_lh = clamp(dot(LIGHT, h), 0.0, 1.0);
	float al = v_rough * v_rough;
	float a2 = al * al;
	float gv = dot_nl * sqrt(a2 + (1.0 - a2) * dot_nv * dot_nv);
	float gl = dot_nv * sqrt(a2 + (1.0 - a2) * dot_nl * dot_nl);
	float G = 0.5 / max(gv + gl, 1e-6);
	float dn = dot_nh * dot_nh * (a2 - 1.0) + 1.0;
	float D = 0.31830989 * a2 / (dn * dn);
	float fr = exp2((-5.55473 * dot_lh - 6.98316) * dot_lh);
	vec3 F = (1.0 - v_f0) * fr + v_f0;
	vec3 spec = F * (G * D);
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 irr = dot_nl * g_sun * ATTENUATION;
		vec3 d = v_rest + irr * v_dc + irr * spec * 3.14159265;
		DIFFUSE_LIGHT += to_lin(mix(d, g_fog_col, v_fog));
	} else {
		vec3 irr = dot_nl * LIGHT_COLOR * ATTENUATION / 3.14159265;
		DIFFUSE_LIGHT += to_lin(irr * v_dc + irr * spec * 3.14159265) * (1.0 - v_fog);
	}
}
