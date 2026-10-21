extends SceneTree
## Headless check that rival ghosts follow the replay clock and remain visible while paused.

const MainScript = preload("res://scripts/main.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame
	var main = MainScript.new()
	main.ghost_v = CarModel.new(true)
	main.rival_ghost_fleet = RivalGhostFleet.new()
	root.add_child(main.ghost_v)
	root.add_child(main.rival_ghost_fleet)
	main.track = TrackData.new()
	main.track.n = 5
	main.track.px = PackedFloat32Array([0.0, 1.0, 2.0, 3.0, 4.0])
	main.track.pz = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0])
	main.track.py = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0])
	main.rival_ghost_fleet.set_ghosts([
		{"time_ms": 90000, "path": [0, 0, 0, 10, 0, 0]},
	])
	main.state = "replay"
	main.race_steps = 6
	main._update_ghost()
	assert(main.rival_ghost_fleet.visible)
	assert(main.rival_ghost_fleet._models[0].visible)
	assert(is_equal_approx(main.rival_ghost_fleet._models[0].position.x, 0.25))
	main.state = "paused"
	main.paused_from = "replay"
	main.race_steps = 12
	main._update_ghost()
	assert(main.rival_ghost_fleet.visible)
	assert(is_equal_approx(main.rival_ghost_fleet._models[0].position.x, 0.5))
	main.state = "menu"
	main._update_ghost()
	assert(not main.rival_ghost_fleet.visible)
	main.ghost_v.queue_free()
	main.rival_ghost_fleet.queue_free()
	main.free()
	await process_frame
	print("Replay rival ghost tests passed.")
	quit()
