// Unlit colour (three.js MeshBasicMaterial): flat colour x optional texture x vertex/instance colour, with fog.
#include "res://shaders/common.gdshaderinc"
uniform vec3 color = vec3(1.0);
uniform float opacity = 1.0;
uniform bool use_tex = false;
uniform sampler2D tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0);
uniform bool use_fog = true;

void fragment() {
	vec4 t = use_tex ? texture(tex, UV * uv_scale) : vec4(1.0);
	vec3 c = color * COLOR.rgb * t.rgb;
	ALBEDO = use_fog ? mix(c, g_fog_col, fog_amount(VERTEX)) : c;
#ifdef BASIC_ALPHA
	ALPHA = opacity * t.a * COLOR.a;
#endif
}
