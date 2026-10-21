shader_type spatial;
render_mode cull_back, blend_mix, depth_draw_never, specular_disabled, ambient_light_disabled, fog_disabled;
#define PBR_ALPHA
#include "res://shaders/pbr.gdshaderinc"
