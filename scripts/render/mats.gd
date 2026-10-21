class_name Mats
## Material factory mirroring the web build's material helpers (toon(), animMat(), MeshBasicMaterial, ...).

static var _shaders := {}


static func shader(name: String) -> Shader:
	if not _shaders.has(name):
		_shaders[name] = load("res://shaders/%s.gdshader" % name)
	return _shaders[name]


static func v3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)


static func col_of(c) -> Color:
	if c is Color:
		return c
	if c is String:
		return U.css(c)
	return U.hexc(int(c))


## Toon material. opts: color, map (Texture2D), uv_scale (Vector2), emissive, emissive_i, emissive_map (bool),
## side "double", anim "sway"|"hop"|"flag", amp
static func toon(opts: Dictionary = {}) -> ShaderMaterial:
	var sh := "toon"
	var anim: String = opts.get("anim", "")
	if anim == "sway":
		sh = "toon_sway"
	elif anim == "hop":
		sh = "toon_hop"
	elif anim == "flag":
		sh = "toon_flag"
	elif opts.get("side", "") == "double":
		sh = "toon_ds"
	var m := ShaderMaterial.new()
	m.shader = shader(sh)
	m.set_shader_parameter("albedo", v3(col_of(opts.get("color", 0xffffff))))
	if opts.has("map"):
		m.set_shader_parameter("use_map", true)
		m.set_shader_parameter("tex_map", opts["map"])
		m.set_shader_parameter("uv_scale", opts.get("uv_scale", Vector2.ONE))
	if opts.has("emissive"):
		m.set_shader_parameter("emissive", v3(col_of(opts["emissive"])))
		m.set_shader_parameter("emissive_i", float(opts.get("emissive_i", 1.0)))
		m.set_shader_parameter("use_emissive_map", bool(opts.get("emissive_map", false)))
	if opts.has("amp"):
		m.set_shader_parameter("anim_amp", float(opts["amp"]))
	return m


## Unlit material. opts: color, opacity, map, uv_scale, blend "opaque"|"alpha"|"add", side "double"
static func basic(opts: Dictionary = {}) -> ShaderMaterial:
	var blend: String = opts.get("blend", "opaque")
	var sh := "basic"
	if blend == "alpha":
		sh = "basic_alpha"
	elif blend == "add":
		sh = "basic_add"
	elif opts.get("side", "") == "double":
		sh = "basic_ds"
	var m := ShaderMaterial.new()
	m.shader = shader(sh)
	m.set_shader_parameter("color", v3(col_of(opts.get("color", 0xffffff))))
	m.set_shader_parameter("opacity", float(opts.get("opacity", 1.0)))
	if opts.has("map"):
		m.set_shader_parameter("use_tex", true)
		m.set_shader_parameter("tex", opts["map"])
		m.set_shader_parameter("uv_scale", opts.get("uv_scale", Vector2.ONE))
	if blend != "opaque":
		m.render_priority = int(opts.get("priority", 0))
	if opts.has("fog"):
		m.set_shader_parameter("use_fog", bool(opts["fog"]))
	return m


## Camera-facing sprites (three.js Points). size is in world metres.
static func sprites(opts: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader("billboard_add" if opts.get("blend", "add") == "add" else "billboard_mix")
	m.set_shader_parameter("tint", v3(col_of(opts.get("color", 0xffffff))))
	m.set_shader_parameter("opacity", float(opts.get("opacity", 1.0)))
	m.set_shader_parameter("size", float(opts.get("size", 1.0)))
	m.set_shader_parameter("per_instance", bool(opts.get("per_instance", false)))
	m.set_shader_parameter("tex", opts.get("map", Tex.radial()))
	m.set_shader_parameter("use_fog", bool(opts.get("fog", true)))
	return m


## three.js PointsMaterial size (screen-space with attenuation) expressed as world metres for our 46-degree camera
static func points_size(px_size: float) -> float:
	return px_size * tan(deg_to_rad(23.0))
