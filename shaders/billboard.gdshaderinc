// Camera-facing sprites in world units (three.js Points with size attenuation). Each MultiMesh instance's origin
// is the particle centre; INSTANCE_CUSTOM.x is its size and .y its alpha when per_instance is on.
#include "res://shaders/common.gdshaderinc"
uniform vec3 tint = vec3(1.0);
uniform float opacity = 1.0;
uniform float size = 1.0;
uniform bool per_instance = false;
uniform bool use_fog = true;
uniform sampler2D tex : hint_default_white, filter_linear;
varying float v_alpha;

void vertex() {
	float sz = per_instance ? INSTANCE_CUSTOM.x : size;
	v_alpha = per_instance ? INSTANCE_CUSTOM.y : 1.0;
	VERTEX *= sz;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float a = texture(tex, UV).a * v_alpha * opacity;
	if (a < 0.01) {
		discard;
	}
	vec3 c = tint * COLOR.rgb;
	ALBEDO = use_fog ? mix(c, g_fog_col, fog_amount(VERTEX)) : c;
	ALPHA = a;
}
