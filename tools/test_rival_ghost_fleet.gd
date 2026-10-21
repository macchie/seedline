extends SceneTree
## Headless checks for opponent ordering, opacity mapping, and interpolated motion.

const GhostFleet = preload("res://scripts/world/rival_ghost_fleet.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame
	var fleet: RivalGhostFleet = GhostFleet.new()
	root.add_child(fleet)
	var track := TrackData.new()
	track.n = 5
	track.px = PackedFloat32Array([0.0, 1.0, 2.0, 3.0, 4.0])
	track.pz = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0])
	track.py = PackedFloat32Array([0.0, 1.0, 2.0, 3.0, 4.0])
	fleet.set_ghosts([
		{"time_ms": 300, "path": [0, 0, 0, 10, 0, 1000]},
		{"time_ms": 100, "path": [21, 0, 0, 23, 0, 1000]},
		{"time_ms": 200, "path": [20, 0, 0, 30, 0, 1000]},
	])
	assert(is_equal_approx(fleet._models[0].material_override.get_shader_parameter("opacity"), 0.6))
	assert(is_equal_approx(fleet._models[1].material_override.get_shader_parameter("opacity"), 0.3))
	assert(is_equal_approx(fleet._models[2].material_override.get_shader_parameter("opacity"), 0.0))
	fleet.update_at(0.1, track)
	assert(is_equal_approx(fleet._models[0].position.x, 2.2))
	assert(is_equal_approx(fleet._models[0].position.y, 2.12))
	fleet.update_at(1.0, track)
	assert(not fleet._models[0].visible)
	var many: Array = []
	for time in range(12, 0, -1):
		many.append({"time_ms": time * 100, "path": [0, 0, 0, 10, 0, 0]})
	fleet.set_ghosts(many)
	assert(fleet._runs.size() == 10)
	assert(fleet._runs[0].time_ms == 100)
	assert(fleet._runs[9].time_ms == 1000)
	assert(is_equal_approx(fleet._models[9].material_override.get_shader_parameter("opacity"), 0.0))
	print("Rival ghost fleet tests passed.")
	quit()
