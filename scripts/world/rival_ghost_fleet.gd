class_name RivalGhostFleet
extends Node3D
## Renders remote racers as one shared low-poly car mesh per opponent.

const MAX_GHOSTS := 10
const SAMPLE_HZ := 5.0
const MAX_POINTS := 5000
const MAX_OPACITY := 0.6

var _runs: Array[Dictionary] = []
var _models: Array[MeshInstance3D] = []


func _init() -> void:
	var mesh := _build_mesh()
	var shader := _build_shader()
	for _i in MAX_GHOSTS:
		var model := MeshInstance3D.new()
		model.mesh = mesh
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("opacity", 0.0)
		model.material_override = material
		model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		model.visible = false
		add_child(model)
		_models.append(model)


func set_ghosts(ghosts: Array) -> void:
	_runs.clear()
	for item in ghosts:
		if not item is Dictionary:
			continue
		var path: Variant = item.get("path", [])
		if not path is Array or path.size() < 6 or path.size() % 3 != 0 or path.size() / 3 > MAX_POINTS:
			continue
		_runs.append({"time_ms": int(item.get("time_ms", 0)), "path": path, "track_index": 0})
	_runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time_ms < b.time_ms)
	if _runs.size() > MAX_GHOSTS:
		_runs.resize(MAX_GHOSTS)
	for i in MAX_GHOSTS:
		var model := _models[i]
		model.visible = i < _runs.size()
		var opacity := MAX_OPACITY
		if _runs.size() > 1:
			opacity = lerpf(MAX_OPACITY, 0.0, float(i) / float(_runs.size() - 1))
		model.material_override.set_shader_parameter("opacity", opacity if i < _runs.size() else 0.0)
	visible = not _runs.is_empty()


func update_at(time_s: float, track: TrackData) -> void:
	if time_s < 0.0 or _runs.is_empty() or track == null or track.n <= 0:
		visible = false
		return
	visible = true
	for i in _runs.size():
		var path: Array = _runs[i].path
		var point_count := path.size() / 3
		var sample := time_s * SAMPLE_HZ
		var point := int(floor(sample))
		if point >= point_count - 1:
			_models[i].visible = false
			continue
		_models[i].visible = true
		var fraction := sample - float(point)
		var start := point * 3
		var x0 := float(path[start]) * 0.1
		var z0 := float(path[start + 1]) * 0.1
		var x := lerpf(x0, float(path[start + 3]) * 0.1, fraction)
		var z := lerpf(z0, float(path[start + 4]) * 0.1, fraction)
		var h0 := float(path[start + 2]) * 0.001
		var h1 := float(path[start + 5]) * 0.001
		var heading := h0 + U.ang_diff(h0, h1) * fraction
		var previous_index := int(_runs[i].track_index)
		var nearest_index := _nearest_track_index(x, z, track, previous_index)
		_runs[i].track_index = nearest_index
		var position := Vector3(x, track.py[nearest_index] + 0.12, z)
		_models[i].transform = Transform3D(Basis(Vector3.UP, heading), position)


func _nearest_track_index(x: float, z: float, track: TrackData, previous_index: int) -> int:
	var center_index := posmod(previous_index, track.n)
	var best_index := center_index
	var best_distance := INF
	for offset in range(-16, 17):
		var candidate := posmod(center_index + offset, track.n)
		var dx: float = track.px[candidate] - x
		var dz: float = track.pz[candidate] - z
		var distance := dx * dx + dz * dz
		if distance < best_distance:
			best_distance = distance
			best_index = candidate
	if best_distance > 900.0:
		for candidate in range(0, track.n, 2):
			var dx: float = track.px[candidate] - x
			var dz: float = track.pz[candidate] - z
			var distance := dx * dx + dz * dz
			if distance < best_distance:
				best_distance = distance
				best_index = candidate
	return best_index


func _build_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_box(surface, Vector3(0.0, 0.48, 0.0), Vector3(1.65, 0.52, 3.8))
	_append_box(surface, Vector3(0.0, 0.83, -0.1), Vector3(0.96, 0.42, 1.45))
	_append_box(surface, Vector3(0.0, 0.62, 1.34), Vector3(1.02, 0.22, 1.18))
	_append_box(surface, Vector3(0.0, 0.74, -1.78), Vector3(2.12, 0.1, 0.34))
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			_append_box(surface, Vector3(side * 0.91, 0.28, end * 1.22), Vector3(0.3, 0.46, 0.68))
	surface.generate_normals()
	return surface.commit()


func _append_box(surface: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var half := size * 0.5
	var corners := [
		Vector3(-half.x, -half.y, -half.z), Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, half.y, -half.z), Vector3(-half.x, half.y, -half.z),
		Vector3(-half.x, -half.y, half.z), Vector3(half.x, -half.y, half.z),
		Vector3(half.x, half.y, half.z), Vector3(-half.x, half.y, half.z),
	]
	var faces := [
		[0, 3, 2, 0, 2, 1], [4, 5, 6, 4, 6, 7], [0, 4, 7, 0, 7, 3],
		[1, 2, 6, 1, 6, 5], [0, 1, 5, 0, 5, 4], [3, 7, 6, 3, 6, 2],
	]
	for face in faces:
		for index in face:
			surface.add_vertex(center + corners[index])


func _build_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

uniform float opacity : hint_range(0.0, 0.6) = 0.0;

void fragment() {
	vec3 tint = vec3(0.48, 0.86, 1.0);
	ALBEDO = tint;
	EMISSION = tint * 0.45;
	ALPHA = opacity;
}
"""
	return shader
