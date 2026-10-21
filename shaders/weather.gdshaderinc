// Weather runs entirely on the GPU: every particle carries a fixed random seed (VERTEX = seed.xyz, UV2.x = seed.w)
// and the vertex shader moves it with time, wrapping it in a 520 m box that follows the camera.
#include "res://shaders/common.gdshaderinc"
uniform vec2 center = vec2(0.0);
uniform vec3 vel = vec3(0.0, -10.0, 0.0);
uniform float wob = 0.0;
uniform float top = 70.0;
uniform float size = 1.0;
uniform float len = 0.0;
uniform vec3 col = vec3(1.0);
uniform float op = 1.0;
uniform sampler2D tex : hint_default_white, filter_linear;

void vertex() {
	vec4 sd = vec4(VERTEX, UV2.x);
	float sp = 0.7 + sd.w * 0.6;
	vec3 p = sd.xyz * vec3(520.0, top, 520.0) + vel * g_time * sp;
	p.x += sin(g_time * 0.8 + sd.w * 40.0) * wob;
	p.z += cos(g_time * 0.6 + sd.w * 31.0) * wob * 0.6;
	p.y = mod(p.y, top);
	if (p.y < 0.0) {
		p.y += top;
	}
	p.x = center.x + mod(p.x - center.x + 260.0, 520.0) - 260.0;
	p.z = center.y + mod(p.z - center.y + 260.0, 520.0) - 260.0;
#ifdef WEATHER_LINES
	p += normalize(vel + vec3(0.0, 0.001, 0.0)) * -len * UV.x;
	VERTEX = p;
#else
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	VERTEX = p + (right * (UV.x - 0.5) + up * (0.5 - UV.y)) * size;
#endif
}

void fragment() {
#ifdef WEATHER_LINES
	ALBEDO = col;
	ALPHA = op;
#else
	float a = texture(tex, UV).a * op;
	if (a < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = a;
#endif
}
