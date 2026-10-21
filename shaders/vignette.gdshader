shader_type canvas_item;
// #app::after: radial-gradient(120% 90% at 50% 50%, transparent 55%, rgba(0,0,0,.42) 100%)
void fragment() {
	vec2 d = (UV - 0.5) / vec2(1.2, 0.9);
	float r = length(d);
	COLOR = vec4(0.0, 0.0, 0.0, 0.42 * clamp((r - 0.55) / 0.45, 0.0, 1.0));
}
