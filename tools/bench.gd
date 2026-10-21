extends SceneTree
## Dev helper: time track generation and world building per place.
func _init() -> void:
	for k in Envs.KEYS:
		var seed: String = k + "-BENCH1"
		var t0 := Time.get_ticks_msec()
		var tr := TrackGen.generate(seed, k)
		var t1 := Time.get_ticks_msec()
		var w := World.new()
		root.add_child(w)
		w.build(tr, Envs.variant(k, false), false)
		var t2 := Time.get_ticks_msec()
		var n := 0
		for c in w.get_children():
			n += 1
		print("%-8s track %4d ms  world %5d ms  nodes %d" % [k, t1 - t0, t2 - t1, n])
		w.queue_free()
	quit()
