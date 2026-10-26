extends SceneTree
## Headless check: generate tracks and print checksums comparable with the web build's harness.

func _init() -> void:
	var seeds := OS.get_cmdline_user_args()
	var out := {}
	for sd in seeds:
		var env: String = Envs.KEYS[SeedRng.hash_str(sd) % Envs.KEYS.size()]
		var t0 := Time.get_ticks_msec()
		var tr := TrackGen.generate(sd, env)
		var ms := Time.get_ticks_msec() - t0
		var ck := func(a: PackedFloat32Array) -> float:
			var s := 0.0
			for i in a.size():
				s += float(a[i]) * (i % 7 + 1)
			return s
		out[sd] = {"env": env, "ms": ms, "N": tr.n, "fam": tr.family, "name": tr.name, "len": tr.length, "minR": tr.min_radius, "cx": tr.complexity,
			"cps": Array(tr.cps), "px0": tr.px[0], "pz0": tr.pz[0], "pxs": ck.call(tr.px), "pzs": ck.call(tr.pz), "pys": ck.call(tr.py), "ks": ck.call(tr.k),
			"bridges": tr.bridges, "river": null if tr.river == null else {"w": tr.river.w, "n": tr.river.x.size(), "x0": tr.river.x[0]}}
	print(JSON.stringify(out))
	quit()
