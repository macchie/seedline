class_name Fx
extends Node3D
## Skid marks, tyre smoke, spray (water, lava, crash debris) and drift sparks (port of the web build's fx).

const SKID_N := 1800
const SMOKE_N := 320
const SPRAY_N := 520

var skid_mm: MultiMesh
var skid_i := 0
var last_wheel: Array = [null, null]

var sm := {}
var smoke_mm: MultiMesh
var smoke_mat: ShaderMaterial

var sp := {}
var spray_mm: MultiMesh

var sparks: MultiMeshInstance3D
var spark_mat: ShaderMaterial

var ZERO_XF := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
const BIG_AABB := AABB(Vector3(-1e5, -1e3, -1e5), Vector3(2e5, 2e3, 2e5))


func _init() -> void:
	# skid marks: thin dark strips laid between successive wheel positions, recycled oldest first
	var g := Geo.plane(0.34, 1)
	g.rotate_x(-PI / 2.0)
	skid_mm = MultiMesh.new()
	skid_mm.transform_format = MultiMesh.TRANSFORM_3D
	skid_mm.mesh = g.to_mesh()
	skid_mm.instance_count = SKID_N
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = skid_mm
	mi.material_override = Mats.basic({"color": 0x111111, "opacity": 0.42, "blend": "alpha", "priority": 1})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = BIG_AABB
	add_child(mi)
	clear_skids()
	# tyre smoke
	smoke_mm = _sprite_mm(SMOKE_N, false)
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = smoke_mm
	smoke_mat = Mats.sprites({"blend": "mix", "per_instance": true, "fog": false})
	smi.material_override = smoke_mat
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smi.custom_aabb = BIG_AABB
	add_child(smi)
	sm = _particles(SMOKE_N)
	# spray
	spray_mm = _sprite_mm(SPRAY_N, true)
	var pmi := MultiMeshInstance3D.new()
	pmi.multimesh = spray_mm
	pmi.material_override = Mats.sprites({"blend": "mix", "per_instance": true, "fog": false})
	pmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pmi.custom_aabb = BIG_AABB
	add_child(pmi)
	sp = _particles(SPRAY_N)
	sp["floor"] = PackedFloat32Array()
	sp.floor.resize(SPRAY_N)
	# drift sparks / turbo flame
	var smm := MultiMesh.new()
	smm.transform_format = MultiMesh.TRANSFORM_3D
	smm.mesh = World._quad()
	smm.instance_count = 8
	sparks = MultiMeshInstance3D.new()
	sparks.multimesh = smm
	spark_mat = Mats.sprites({"blend": "add", "color": 0x3fa9ff, "size": Mats.points_size(1.6)})
	sparks.material_override = spark_mat
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sparks.custom_aabb = BIG_AABB
	sparks.visible = false
	add_child(sparks)


func _sprite_mm(n: int, colors: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = World._quad()
	mm.instance_count = n
	return mm


func _particles(n: int) -> Dictionary:
	var s := {"n": n, "i": 0, "busy": false, "pos": PackedVector3Array(), "vel": PackedVector3Array(), "life": PackedFloat32Array(), "max": PackedFloat32Array(),
		"sz0": PackedFloat32Array(), "col": PackedColorArray(), "buf": PackedFloat32Array()}
	s.pos.resize(n)
	s.vel.resize(n)
	s.life.resize(n)
	s.max.resize(n)
	s.max.fill(1.0)
	s.sz0.resize(n)
	s.col.resize(n)
	s.col.fill(Color.WHITE)
	s.buf.resize(n * 20)
	return s


func clear_skids() -> void:
	for i in SKID_N:
		skid_mm.set_instance_transform(i, ZERO_XF)
	last_wheel = [null, null]
	if not sm.is_empty():
		sm.life.fill(0.0)


func lay_skid(w: int, x: float, z: float, y: float = 0.0) -> void:
	var L = last_wheel[w]
	last_wheel[w] = Vector2(x, z)
	if L == null:
		return
	var dx: float = x - L.x
	var dz: float = z - L.y
	var d := U.hypot(dx, dz)
	if d < 0.05 or d > 4.0:
		return
	var b := Basis(Vector3.UP, atan2(dx, dz)) * Basis.from_scale(Vector3(1, 1, d + 0.05))
	skid_mm.set_instance_transform(skid_i, Transform3D(b, Vector3((x + L.x) / 2.0, 0.1 + y, (z + L.y) / 2.0)))
	skid_i = (skid_i + 1) % SKID_N


func puff(x: float, y: float, z: float, vx: float, vz: float, size: float, life: float) -> void:
	var s := sm
	var i: int = s.i
	s.busy = true
	s.i = (i + 1) % SMOKE_N
	s.pos[i] = Vector3(x, y, z)
	s.vel[i] = Vector3(vx + (randf() - 0.5) * 2.0, 1.2 + randf(), vz + (randf() - 0.5) * 2.0)
	s.life[i] = life
	s.max[i] = life
	s.sz0[i] = size


func spray(x: float, y: float, z: float, vx: float, vy: float, vz: float, size: float, life: float, c: Color, floor_y: float) -> void:
	var s := sp
	var i: int = s.i
	s.busy = true
	s.i = (i + 1) % SPRAY_N
	s.pos[i] = Vector3(x, y, z)
	s.vel[i] = Vector3(vx, vy, vz)
	s.life[i] = life
	s.max[i] = life
	s.sz0[i] = size
	s.col[i] = c
	s.floor[i] = floor_y


func _write(buf: PackedFloat32Array, i: int, p: Vector3, c: Color, size: float, alpha: float) -> void:
	var o := i * 20
	buf[o] = 1.0
	buf[o + 1] = 0.0
	buf[o + 2] = 0.0
	buf[o + 3] = p.x
	buf[o + 4] = 0.0
	buf[o + 5] = 1.0
	buf[o + 6] = 0.0
	buf[o + 7] = p.y
	buf[o + 8] = 0.0
	buf[o + 9] = 0.0
	buf[o + 10] = 1.0
	buf[o + 11] = p.z
	buf[o + 12] = c.r
	buf[o + 13] = c.g
	buf[o + 14] = c.b
	buf[o + 15] = 1.0
	buf[o + 16] = size
	buf[o + 17] = alpha
	buf[o + 18] = 0.0
	buf[o + 19] = 0.0


func update_smoke(dt: float) -> void:
	var s := sm
	if not s.busy:
		return
	var live := 0
	var pos: PackedVector3Array = s.pos
	var vel: PackedVector3Array = s.vel
	var life: PackedFloat32Array = s.life
	var mx: PackedFloat32Array = s.max
	var sz0: PackedFloat32Array = s.sz0
	var buf: PackedFloat32Array = s.buf
	var damp := 1.0 - dt * 1.6
	for i in SMOKE_N:
		if life[i] <= 0.0:
			_write(buf, i, pos[i], Color.WHITE, 0.0, 0.0)
			continue
		live += 1
		life[i] -= dt
		var t := 1.0 - life[i] / mx[i]
		pos[i] += vel[i] * dt
		vel[i] *= damp
		_write(buf, i, pos[i], Color.WHITE, sz0[i] * (1.0 + t * 2.2), sin(minf(1.0, t * 4.0) * PI / 2.0) * (1.0 - t) * 0.5)
	if live == 0:
		s.busy = false
	s.pos = pos
	s.vel = vel
	s.life = life
	s.buf = buf
	smoke_mm.buffer = buf


func update_spray(dt: float) -> void:
	var s := sp
	if not s.busy:
		return
	var live := 0
	var pos: PackedVector3Array = s.pos
	var vel: PackedVector3Array = s.vel
	var life: PackedFloat32Array = s.life
	var mx: PackedFloat32Array = s.max
	var sz0: PackedFloat32Array = s.sz0
	var col: PackedColorArray = s.col
	var fl: PackedFloat32Array = s.floor
	var buf: PackedFloat32Array = s.buf
	var damp := 1.0 - dt * 0.8
	for i in SPRAY_N:
		if life[i] <= 0.0:
			_write(buf, i, pos[i], col[i], 0.0, 0.0)
			continue
		live += 1
		life[i] -= dt
		var t := 1.0 - life[i] / mx[i]
		var v := vel[i]
		v.y -= 22.0 * dt
		v *= damp
		vel[i] = v
		pos[i] += v * dt
		if pos[i].y < fl[i]:
			life[i] = 0.0
			_write(buf, i, pos[i], col[i], 0.0, 0.0)
			continue
		_write(buf, i, pos[i], col[i], sz0[i] * (1.0 + t * 0.6), (1.0 - t * t) * 0.9)
	if live == 0:
		s.busy = false
	s.pos = pos
	s.vel = vel
	s.life = life
	s.buf = buf
	spray_mm.buffer = buf


func set_smoke_color(c: Color) -> void:
	smoke_mat.set_shader_parameter("tint", Mats.v3(c))


func show_sparks(pts: Array, color: Color, size_px: float) -> void:
	sparks.visible = true
	spark_mat.set_shader_parameter("tint", Mats.v3(color))
	spark_mat.set_shader_parameter("size", Mats.points_size(size_px))
	for j in 8:
		sparks.multimesh.set_instance_transform(j, Transform3D(Basis.IDENTITY, pts[j]))


func hide_sparks() -> void:
	sparks.visible = false
