class_name CarModel
extends Node3D
## Futuristic formula racer (port of buildCar): sculpted wedge body, bubble canopy, blade wings, faired wheels with
## light rings and a turbine exhaust. The ghost is the same model in a single translucent material.

var ghost := false
var body: Node3D
var wheels: Array = []
var fronts: Array = []
var tail_m: ShaderMaterial
var helmet_m: ShaderMaterial
var glow_m: ShaderMaterial
var exhaust_m: ShaderMaterial
var ex_glow: MeshInstance3D = null
var ex_glow_m: ShaderMaterial = null
var body_m: ShaderMaterial
var stripe_m: ShaderMaterial
var glow_col := Color(0x38 / 255.0, 0xe8 / 255.0, 1.0)
var boost_col := Color(0x38 / 255.0, 0xe8 / 255.0, 1.0)
var underglow: MeshInstance3D = null
var beam: MeshInstance3D = null
var headlight: SpotLight3D = null
var lamp: OmniLight3D = null


static func pbr(color: int, roughness: float, metallic: float, env_i: float = 1.0, alpha: float = 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = Mats.shader("pbr_alpha" if alpha < 1.0 else "pbr")
	m.set_shader_parameter("albedo", Mats.v3(U.hexc(color)))
	m.set_shader_parameter("roughness", roughness)
	m.set_shader_parameter("metallic", metallic)
	m.set_shader_parameter("env_i", env_i)
	if alpha < 1.0:
		m.set_shader_parameter("opacity", alpha)
	return m


const MODELS := [["formula", "Formula"], ["pickup", "Pickup"], ["classic", "City Classic"], ["cab", "London Cab"]]

var model_id := "formula"
var carbon: Material
var tyre: Material
var bm: Material
var sm: Material
var gl: Material
var exm: Material
var helmet: Material
var glass: Material
var flame: MeshInstance3D
var flame_m: ShaderMaterial
var flame_base_z := 0.0
var tm: Material
var rim: Material
var trim: Material
var lamp_m: Material
var head_z := 2.6
var head_y := 1.2


static func valid_model(id: String) -> String:
	for m in MODELS:
		if m[0] == id:
			return id
	return "formula"


func _init(is_ghost: bool, model := "formula") -> void:
	ghost = is_ghost
	rotation_order = EULER_ORDER_YXZ
	build(model)


## (Re)builds the whole car for a model; paint, finish and booster colour are re-applied by the caller.
func build(model: String) -> void:
	model_id = valid_model(model)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	wheels.clear()
	fronts.clear()
	ex_glow = null
	ex_glow_m = null
	flame = null
	flame_m = null
	underglow = null
	beam = null
	headlight = null
	lamp = null
	head_z = 2.6
	head_y = 1.2
	body = Node3D.new()
	body.rotation_order = EULER_ORDER_XYZ
	add_child(body)
	var gm: Material = null
	if ghost:
		gm = Mats.basic({"color": 0xffffff, "opacity": 0.26, "blend": "alpha"})
	body_m = pbr(0xe8402c, 0.22, 0.15)
	stripe_m = pbr(0xf4f4f4, 0.4, 0.0)
	carbon = gm if gm else pbr(0x16181e, 0.45, 0.3)
	tyre = gm if gm else pbr(0x15161a, 0.85, 0.0)
	rim = gm if gm else pbr(0xc9ced6, 0.25, 0.9)
	trim = gm if gm else pbr(0xd7dbe2, 0.2, 0.9)
	lamp_m = gm if gm else Mats.basic({"color": 0xfff1c4})
	bm = gm if gm else body_m
	sm = gm if gm else stripe_m
	glow_m = Mats.basic({"color": 0x38e8ff})
	exhaust_m = Mats.basic({"color": 0x38e8ff})
	gl = gm if gm else glow_m
	exm = gm if gm else exhaust_m
	helmet_m = pbr(0xf2f2f2, 0.3, 0.0)
	helmet = gm if gm else helmet_m
	glass = gm if gm else pbr(0x0c1a2c, 0.08, 0.85, 1.0, 0.72)
	tail_m = Mats.basic({"color": 0x7a0d0d})
	tm = gm if gm else tail_m
	match model_id:
		"pickup":
			_build_pickup()
		"classic":
			_build_classic()
		"cab":
			_build_cab()
		_:
			_build_formula()
	_build_kit()


func _build_formula() -> void:
	# side profile (forward, height) extruded across the car's width, with rounded bevels
	add(Geo.extrude_profile([[3.05, 0.3], [2.1, 0.4], [1.05, 0.6], [0.2, 0.74], [-1.2, 0.84], [-2.25, 0.78], [-2.45, 0.5], [-2.35, 0.26], [2.95, 0.22]], 0.78, 0.09), bm, 0, 0, 0)
	add(Geo.extrude_profile([[1.05, 0.28], [0.7, 0.5], [-0.4, 0.6], [-1.7, 0.62], [-2.15, 0.46], [-2.1, 0.26], [1.05, 0.26]], 1.9, 0.12), bm, 0, 0, 0)
	# nose stripe and side light strips
	add(Geo.box(0.2, 0.025, 1.9), sm, 0, 0.53, 1.85, body, 0.17)
	for s: float in [-1.0, 1.0]:
		add(Geo.box(0.05, 0.05, 2.5), gl, s * 1.06, 0.56, -0.55)
		add(Geo.box(0.04, 0.04, 0.9), gl, s * 0.47, 0.66, 0.55, body, 0.15)
	# bubble canopy with the driver inside
	add(Geo.sphere(0.25, 12, 10), helmet, 0, 0.86, 0.3)
	add(Geo.sphere(1, 18, 12).scale_xyz(0.44, 0.34, 1.15), glass, 0, 0.78, 0.45)
	# engine spine and fin
	add(Geo.box(0.05, 0.42, 1.5), bm, 0, 1.0, -1.4, body, -0.1)
	add(Geo.box(0.055, 0.04, 1.45), gl, 0, 1.22, -1.42, body, -0.1)
	# front wing: two swept blades with glowing tips
	for s: float in [-1.0, 1.0]:
		add(Geo.box(1.45, 0.06, 0.45), bm, s * 0.72, 0.2, 2.62, body, 0, s * 0.28)
		add(Geo.box(1.3, 0.05, 0.22), sm, s * 0.66, 0.3, 2.52, body, -0.3, s * 0.28)
		add(Geo.box(0.06, 0.22, 0.5), gl, s * 1.36, 0.26, 2.24, body, 0, s * 0.28)
	# floating rear wing on swept pylons, full-width light bar
	add(Geo.box(2.2, 0.07, 0.52), bm, 0, 1.32, -2.25, body, 0.12)
	add(Geo.box(2.2, 0.05, 0.3), sm, 0, 1.52, -2.38, body, 0.28)
	for s: float in [-1.0, 1.0]:
		add(Geo.box(0.06, 0.62, 0.8), bm, s * 1.1, 1.3, -2.27)
		add(Geo.box(0.05, 0.62, 0.05), gl, s * 1.135, 1.3, -1.9)
		add(Geo.box(0.08, 0.7, 0.1), carbon, s * 0.3, 0.98, -2.0, body, 0.35)
	add(Geo.box(1.5, 0.07, 0.05), tm, 0, 0.6, -2.58)
	add(Geo.box(2.1, 0.035, 0.04), tm, 0, 1.3, -2.52)
	# turbine exhaust
	add(Geo.cylinder(0.2, 0.24, 0.3, 14).rotate_x(PI / 2.0), carbon, 0, 0.48, -2.55)
	var ex := add(Geo.circle(0.15, 14), exm, 0, 0.48, -2.71)
	ex.rotation.y = PI
	ex.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not ghost:
		ex_glow_m = Mats.sprites({"blend": "add", "color": 0x38e8ff, "size": 1.2})
		ex_glow = MeshInstance3D.new()
		ex_glow.mesh = World._quad()
		ex_glow.material_override = ex_glow_m
		ex_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ex_glow.position = Vector3(0, 0.48, -2.85)
		body.add_child(ex_glow)
		_flame(0.0, 0.48, -2.55, 0.15)
	# floor and suspension blades
	add(Geo.box(1.7, 0.08, 4.4), carbon, 0, 0.2, -0.1)
	for s: float in [-1.0, 1.0]:
		add(Geo.box(0.75, 0.05, 0.16), carbon, s * 0.82, 0.45, 1.55, body, 0, 0, s * 0.1)
		add(Geo.box(0.7, 0.05, 0.16), carbon, s * 0.9, 0.5, -1.38, body, 0, 0, s * 0.08)
	# faired wheels: body-coloured covers, glowing rims, blade fenders over the fronts
	for wd in [[-1.22, 1.55, 1], [1.22, 1.55, 1], [-1.26, -1.38, 0], [1.26, -1.38, 0]]:
		var f: bool = wd[2] == 1
		var r := 0.46 if f else 0.54
		var w := 0.42 if f else 0.56
		var piv := Node3D.new()
		piv.rotation_order = EULER_ORDER_XYZ
		var sx := signf(wd[0])
		piv.position = Vector3(wd[0], r, wd[1])
		add_child(piv)
		var wh := add(Geo.cylinder(r, r, w, 20).rotate_z(PI / 2.0), tyre, 0, 0, 0, piv)
		var cover := _mesh(Geo.cylinder(r * 0.78, r * 0.78, 0.05, 20).rotate_z(PI / 2.0), bm, false)
		cover.position.x = sx * (w / 2.0 + 0.01)
		wh.add_child(cover)
		var ring := _mesh(Geo.torus(r * 0.8, 0.035, 6, 28).rotate_y(PI / 2.0), gl, false)
		ring.position.x = sx * (w / 2.0 + 0.03)
		wh.add_child(ring)
		var spoke := _mesh(Geo.box(0.02, r * 1.2, 0.1), sm, false)
		spoke.position.x = sx * (w / 2.0 + 0.04)
		wh.add_child(spoke)
		if f:
			add(Geo.box(0.3, 0.04, 0.85), bm, 0, r + 0.1, -0.05, piv, 0.12)
			add(Geo.box(0.31, 0.045, 0.12), gl, 0, r + 0.15, 0.33, piv, 0.12)
		wheels.append(wh)
		if f:
			fronts.append(piv)


func _build_kit() -> void:
	if not ghost:
		var sh := _mesh(Geo.plane(3.9, 6.8), Mats.basic({"map": Tex.blob(), "blend": "alpha", "priority": -1}), false)
		sh.rotation.x = -PI / 2.0
		sh.position.y = 0.1
		add_child(sh)
		# night kit (only switched on after dark)
		headlight = SpotLight3D.new()
		headlight.light_color = U.hexc(0xfff2dd)
		headlight.spot_range = 75.0
		headlight.spot_angle = rad_to_deg(0.6)
		headlight.spot_angle_attenuation = 0.55
		headlight.transform = Transform3D(Basis.looking_at(Vector3(0, 0, 24) - Vector3(0, head_y, head_z), Vector3.UP), Vector3(0, head_y, head_z))
		headlight.visible = false
		add_child(headlight)
		lamp = OmniLight3D.new()
		lamp.light_color = U.hexc(0xfff0dd)
		lamp.omni_range = 30.0
		lamp.position = Vector3(0, 6, 0)
		lamp.visible = false
		add_child(lamp)
		var ug := Geo.plane(6, 8)
		underglow = _mesh(ug, Mats.basic({"map": Tex.radial(), "blend": "add", "opacity": 0.22}), false)
		underglow.rotation.x = -PI / 2.0
		underglow.position.y = 0.12
		underglow.visible = false
		add_child(underglow)
		beam = _mesh(Geo.plane(13, 30), Mats.basic({"map": Tex.beam(), "blend": "add", "opacity": 0.5, "side": "double"}), false)
		beam.rotation.x = PI / 2.0
		beam.position = Vector3(0, 0.16, 18)
		beam.visible = false
		add_child(beam)


## Road-car wheel: tyre, bright rim and dark spokes; fronts steer through their pivot.
func _road_wheel(x: float, z: float, r: float, w: float, front: bool) -> void:
	var piv := Node3D.new()
	piv.rotation_order = EULER_ORDER_XYZ
	piv.position = Vector3(x, r, z)
	add_child(piv)
	var wh := add(Geo.cylinder(r, r, w, 20).rotate_z(PI / 2.0), tyre, 0, 0, 0, piv)
	var sx := signf(x)
	var hub := _mesh(Geo.cylinder(r * 0.62, r * 0.62, 0.04, 16).rotate_z(PI / 2.0), rim, false)
	hub.position.x = sx * (w / 2.0 + 0.005)
	wh.add_child(hub)
	var spoke := _mesh(Geo.box(0.02, r * 1.0, r * 0.14), carbon, false)
	spoke.position.x = sx * (w / 2.0 + 0.03)
	wh.add_child(spoke)
	var spoke2 := _mesh(Geo.box(0.02, r * 0.14, r * 1.0), carbon, false)
	spoke2.position.x = sx * (w / 2.0 + 0.03)
	wh.add_child(spoke2)
	wheels.append(wh)
	if front:
		fronts.append(piv)


## Dark tailpipe with the glowing exhaust disc (the boost flame sprite sits behind it).
func _tailpipe(x: float, y: float, z: float, r: float) -> void:
	add(Geo.cylinder(r * 1.2, r * 1.3, 0.3, 14).rotate_x(PI / 2.0), carbon, x, y, z)
	var ex := add(Geo.circle(r, 14), exm, x, y, z - 0.16)
	ex.rotation.y = PI
	ex.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not ghost:
		ex_glow_m = Mats.sprites({"blend": "add", "color": 0x38e8ff, "size": 1.2})
		ex_glow = MeshInstance3D.new()
		ex_glow.mesh = World._quad()
		ex_glow.material_override = ex_glow_m
		ex_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ex_glow.position = Vector3(x, y, z - 0.35)
		body.add_child(ex_glow)
		_flame(x, y, z, r)


## Cel-shaded booster flame cone behind a tailpipe; main.gd scales it with throttle and boost.
func _flame(x: float, y: float, z: float, r: float) -> void:
	flame_m = ShaderMaterial.new()
	flame_m.shader = Mats.shader("boost_flame")
	flame = MeshInstance3D.new()
	flame.mesh = Geo.cylinder(0.0, r * 1.9, 1.0, 14).to_mesh()
	flame.material_override = flame_m
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.rotation.x = -PI / 2.0
	flame_base_z = z - 0.12
	flame.position = Vector3(x, y, flame_base_z)
	flame.scale = Vector3(1, 0.01, 1)
	body.add_child(flame)


## Round or square headlamp pair and the two tail lamps.
func _lamps(x: float, y: float, z_front: float, z_rear: float, ty: float, size: Vector3) -> void:
	for s: float in [-1.0, 1.0]:
		add(Geo.box(size.x, size.y, size.z), lamp_m, s * x, y, z_front)
		add(Geo.box(size.x * 0.8, size.y * 1.4, size.z), tm, s * x, ty, z_rear)


func _build_pickup() -> void:
	head_z = 2.7
	head_y = 1.15
	# chassis, hood, cab and open bed
	add(Geo.box(2.0, 0.55, 5.2), bm, 0, 0.9, 0)
	add(Geo.box(1.96, 0.3, 1.75), bm, 0, 1.32, 1.65)
	add(Geo.extrude_profile([[1.0, 1.05], [0.65, 1.9], [0.45, 1.98], [-0.6, 1.98], [-0.8, 1.9], [-0.8, 1.05]], 1.9, 0.1), bm, 0, 0, 0)
	add(Geo.box(1.9, 0.12, 1.9), carbon, 0, 1.2, -1.65)
	for s: float in [-1.0, 1.0]:
		add(Geo.box(0.1, 0.5, 1.95), bm, s * 0.95, 1.45, -1.62)
		add(Geo.box(0.04, 0.5, 1.15), glass, s * 0.96, 1.62, -0.1)
		add(Geo.box(0.34, 0.14, 1.5), bm, s * 1.0, 1.3, 1.6)
		add(Geo.box(0.34, 0.14, 1.5), bm, s * 1.0, 1.3, -1.55)
		add(Geo.box(0.05, 0.06, 2.5), gl, s * 1.02, 0.62, 0)
		add(Geo.cylinder(0.06, 0.06, 1.3, 8), trim, s * 0.9, 2.0, -0.95)
	add(Geo.box(1.9, 0.5, 0.1), bm, 0, 1.45, -0.7)
	add(Geo.box(1.9, 0.5, 0.1), bm, 0, 1.45, -2.58)
	add(Geo.box(1.72, 0.92, 0.04), glass, 0, 1.483, 0.833, body, -0.39)
	add(Geo.box(1.72, 0.04, 0.12), carbon, 0, 1.2, 0.0)
	add(Geo.box(0.9, 0.06, 0.9), sm, 0, 1.99, 0.0)
	add(Geo.sphere(0.22, 12, 10), helmet, 0.4, 1.62, 0.05)
	# grille, bumpers, lamps
	add(Geo.box(1.5, 0.38, 0.08), carbon, 0, 1.0, 2.55)
	add(Geo.box(1.56, 0.06, 0.1), trim, 0, 1.2, 2.56)
	add(Geo.box(2.1, 0.22, 0.3), trim, 0, 0.62, 2.6)
	add(Geo.box(2.1, 0.22, 0.3), trim, 0, 0.62, -2.7)
	add(Geo.box(1.75, 0.04, 0.5), sm, 0, 1.47, 1.3, body, 0.0)
	_lamps(0.78, 1.12, 2.58, -2.62, 1.32, Vector3(0.28, 0.2, 0.05))
	_tailpipe(0.6, 0.48, -2.65, 0.1)
	for wd in [[-1.04, 1.65, 1], [1.04, 1.65, 1], [-1.04, -1.55, 0], [1.04, -1.55, 0]]:
		_road_wheel(wd[0], wd[1], 0.62, 0.5, wd[2] == 1)


func _build_classic() -> void:
	head_z = 1.95
	head_y = 0.9
	# tall boxy city hatchback
	add(Geo.extrude_profile([[1.95, 0.45], [1.95, 0.95], [1.5, 1.08], [1.0, 1.1], [0.7, 1.62], [0.5, 1.68], [-1.5, 1.68], [-1.72, 1.62], [-1.95, 0.95], [-1.95, 0.45]], 1.7, 0.1), bm, 0, 0, 0)
	for s: float in [-1.0, 1.0]:
		add(Geo.box(0.04, 0.44, 2.2), glass, s * 0.97, 1.38, -0.42)
		add(Geo.box(0.04, 0.05, 3.4), sm, s * 0.86, 0.82, 0)
		add(Geo.box(0.05, 0.05, 3.3), gl, s * 0.87, 0.56, 0)
		add(Geo.box(0.12, 0.1, 0.18), carbon, s * 0.95, 1.12, 0.78)
	add(Geo.box(1.52, 0.64, 0.04), glass, 0, 1.36, 0.93, body, -0.5)
	add(Geo.box(1.42, 0.58, 0.04), glass, 0, 1.306, -1.95, body, 0.32)
	add(Geo.sphere(0.2, 12, 10), helmet, 0.3, 1.38, 0.05)
	add(Geo.box(1.5, 0.05, 0.9), sm, 0, 1.7, -0.4)
	# flat grille, square lamps, plastic bumpers
	add(Geo.box(1.1, 0.2, 0.05), carbon, 0, 0.75, 1.98)
	add(Geo.box(1.76, 0.2, 0.18), carbon, 0, 0.5, 1.95)
	add(Geo.box(1.76, 0.2, 0.18), carbon, 0, 0.5, -1.95)
	_lamps(0.6, 0.95, 1.97, -1.97, 0.9, Vector3(0.3, 0.22, 0.05))
	_tailpipe(0.5, 0.42, -2.0, 0.07)
	for wd in [[-0.86, 1.2, 1], [0.86, 1.2, 1], [-0.86, -1.2, 0], [0.86, -1.2, 0]]:
		_road_wheel(wd[0], wd[1], 0.4, 0.28, wd[2] == 1)


func _build_cab() -> void:
	head_z = 2.4
	head_y = 0.9
	# tall, rounded hackney carriage with a lit roof sign
	add(Geo.extrude_profile([[2.4, 0.6], [2.3, 0.95], [2.0, 1.1], [1.35, 1.2], [0.95, 1.85], [0.8, 1.95], [-1.7, 1.95], [-2.1, 1.8], [-2.4, 1.0], [-2.4, 0.42], [2.4, 0.42]], 1.85, 0.12), bm, 0, 0, 0)
	for s: float in [-1.0, 1.0]:
		add(Geo.box(0.04, 0.55, 3.0), glass, s * 1.07, 1.55, -0.4)
		add(Geo.box(0.06, 0.6, 0.1), bm, s * 1.07, 1.55, -0.5)
		add(Geo.box(0.1, 0.06, 1.9), carbon, s * 0.98, 0.5, 0)
		add(Geo.box(0.05, 0.05, 3.0), gl, s * 0.95, 0.62, 0)
	add(Geo.box(1.66, 0.76, 0.04), glass, 0, 1.58, 1.24, body, -0.55)
	add(Geo.box(1.5, 0.5, 0.04), glass, 0, 1.45, -2.33, body, 0.36)
	add(Geo.sphere(0.21, 12, 10), helmet, -0.35, 1.5, 0.5)
	add(Geo.box(0.8, 0.2, 0.3), lamp_m, 0, 2.08, 0.45)
	add(Geo.box(0.84, 0.04, 0.34), carbon, 0, 1.97, 0.45)
	# grille, bumpers, round lamps
	add(Geo.box(0.9, 0.3, 0.05), carbon, 0, 0.68, 2.4)
	add(Geo.box(1.9, 0.14, 0.2), trim, 0, 0.5, 2.38)
	add(Geo.box(1.9, 0.14, 0.2), trim, 0, 0.5, -2.4)
	for s: float in [-1.0, 1.0]:
		add(Geo.sphere(0.2, 12, 8).scale_xyz(1, 1, 0.4), lamp_m, s * 0.68, 0.86, 2.3)
		add(Geo.box(0.14, 0.4, 0.05), tm, s * 0.8, 1.0, -2.42)
	_tailpipe(0.5, 0.4, -2.45, 0.07)
	for wd in [[-0.97, 1.4, 1], [0.97, 1.4, 1], [-0.97, -1.45, 0], [0.97, -1.45, 0]]:
		_road_wheel(wd[0], wd[1], 0.45, 0.3, wd[2] == 1)


func _mesh(geo: Geo, mat: Material, cast: bool) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.rotation_order = EULER_ORDER_XYZ
	m.mesh = geo.to_mesh()
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (cast and not ghost) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


func add(geo: Geo, mat: Material, x: float, y: float, z: float, p: Node3D = null, rx := 0.0, ry := 0.0, rz := 0.0) -> MeshInstance3D:
	var o := _mesh(geo, mat, true)
	o.position = Vector3(x, y, z)
	o.rotation = Vector3(rx, ry, rz)
	(p if p else body).add_child(o)
	return o


## Paint, finish and the matching light-strip colour (applyCarCfg)
func apply_cfg(color_css: String, finish: String, boost_css := "#38e8ff") -> void:
	var c := U.css(color_css)
	boost_col = U.css(boost_css)
	body_m.set_shader_parameter("albedo", Mats.v3(c))
	var f: Array = {"gloss": [0.22, 0.15], "metal": [0.32, 0.55], "matte": [0.85, 0.0], "satin": [0.5, 0.1], "brushed": [0.45, 0.85], "pearl": [0.18, 0.75], "candy": [0.08, 0.3], "chrome": [0.06, 1.0]}.get(finish, [0.22, 0.15])
	body_m.set_shader_parameter("roughness", f[0])
	body_m.set_shader_parameter("metallic", f[1])
	var hsl := U.to_hsl(c)
	stripe_m.set_shader_parameter("albedo", Mats.v3(U.hexc(0x15171c if hsl.z > 0.7 else 0xf4f4f4)))
	# light strips glow in the colour opposite the paint; neutral paints get cyan
	glow_col = U.from_hsl(0.52 if hsl.y < 0.25 else fmod(hsl.x + 0.5, 1.0), 1.0, 0.6)
	glow_m.set_shader_parameter("color", Mats.v3(glow_col))
	helmet_m.set_shader_parameter("albedo", Mats.v3(U.hexc(0x22252c if hsl.z > 0.75 else 0xf2f2f2)))
	if underglow:
		underglow.material_override.set_shader_parameter("color", Mats.v3(c))
