extends SceneTree
## Dev helper: run the game, optionally drive it, and save screenshots.
## godot --path . --script res://tools/shot.gd -- seed=K7Q2XM out=/tmp/a.png frames=90 mode=menu|garage|tracks|options|seed|race|finish recent_preview=1 res=412x915

var args := {}
var main
var frame := 0
var shots: Array = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("clear"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://seedline.json"))
	if args.has("seed"):
		Store.set_value("last", args.seed)
		Store.set_value("lastEnv", null)
	if args.has("gfx"):
		var o = Store.get_value("opts", {})
		o["gfx"] = args.gfx
		o["v4"] = 1
		o["sensV"] = 75
		Store.set_value("opts", o)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _force_res() -> void:
	# Pin the logical UI size to the pixel window so mobile/desktop breakpoints can be shot.
	var wh = args.res.split("x")
	DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
	root.size = Vector2i(int(wh[0]), int(wh[1]))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	main.ui.safe = {"t": 0.0, "b": 0.0, "l": 16.0, "r": 16.0}
	main.ui.relayout()


func _process(delta: float) -> bool:
	frame += 1
	var mode: String = args.get("mode", "menu")
	if frame == 2 and args.has("res") and args.res.split("x").size() == 2:
		_force_res()
	if frame == 4 and args.has("touch"):
		main.touch_ui = true
		main.ui.set_touch(true)
		main.ui.relayout()
	if frame == 5:
		if mode == "garage":
			main.set_tab("garage")
		elif mode == "tracks" or mode == "saved" or mode == "trackaction":
			main.favs = []
			for sc in ["K7Q2XM", "ZX9M42", "QW3RT8", "AB12CD"]:
				var tt = TrackGen.generate(sc, main.parse_seed(sc).env)
				main.favs.append({"seed": sc, "name": tt.name, "env": tt.env_key, "best": null, "medals": tt.medals, "v": 5})
			main.recent_tracks = [{"seed": main.track.seed, "name": main.track.name, "env": main.track.env_key}]
			main.ui.show_section("tracks")
			if mode == "trackaction":
				main.ui.show_track_action("K7Q2XM", main.parse_seed("K7Q2XM").env, "Tide Atoll", true)
		elif mode == "options":
			main.ui.show_options(true)
		elif mode == "events":
			main.ui.show_section("events")
		elif mode == "ranks":
			main.ui.show_leaderboards_dialog()
			main.ui.render_leaderboards_data(_ranks_sample())
		elif mode == "seed":
			main.ui.show_seed_dialog(true)
		elif mode == "debug":
			main.ui.show_debug(true)
		elif mode == "leaderboard":
			main.ui.render_leaderboard(_lb_sample())
			main.ui.show_leaderboard(true)
		elif mode == "optionsmodal":
			main.ui.show_options(true)
		elif mode == "account":
			main.net.global_pp = 1240.0
			main.ui.show_account(true)
			main.ui.render_pp({"global_pp": 1240.0, "rank": 42})
		elif mode == "race" or mode == "finish" or mode == "pause":
			main.start_race()
	if mode in ["race", "finish", "pause"] and frame > 5 and args.has("drive"):
		main.keys["gas"] = true
		# simple autopilot: steer towards a point ahead on the track
		var t: TrackData = main.track
		var c: CarSim = main.car
		var j := (c.idx + 14) % t.n
		var dx: float = t.px[j] - c.x
		var dz: float = t.pz[j] - c.z
		var want := atan2(dx, dz)
		var d := U.ang_diff(c.h, want)
		main.keys["left"] = d > 0.08
		main.keys["right"] = d < -0.08
	if mode == "finish" and frame == int(args.get("frames", "120")) - 5:
		main.ui.set_finish_pp({"track_pp": 164.0, "global_pp": 1240.0, "improved": true})
	if mode == "account" and frame == int(args.get("frames", "120")) - 5:
		main.net.global_pp = 1240.0
		main.ui.render_pp({"global_pp": 1240.0, "rank": 42})
	if mode == "ranks" and frame == int(args.get("frames", "120")) - 5:
		main.ui.render_leaderboards_data(_ranks_sample())
	if mode == "leaderboard" and frame == int(args.get("frames", "120")) - 6:
		main.ui.render_leaderboard(_lb_sample())
	if mode == "pause" and frame == int(args.get("frames", "120")) - 10:
		main.toggle_pause()
	if mode == "finish" and frame == 20:
		main.finish_race(123.456)
	var total := int(args.get("frames", "120"))
	if frame == total:
		var img := root.get_texture().get_image()
		img.save_png(args.get("out", "/tmp/shot.png"))
		print("saved ", args.get("out", "/tmp/shot.png"), " ", img.get_size(), " fps=", Engine.get_frames_per_second())
		quit()
	return false


func _lb_sample() -> Dictionary:
	return {
		"stats": {"runs": 128, "players": 64},
		"me": {"rank": 7, "name": "MACCHIE8", "time_ms": 83456},
		"pp": {"players": 64, "me_pp": 142.0, "top_pp": 193.0, "max_pp": 300.0},
		"top": [
			{"rank": 1, "name": "Vortex", "time_ms": 79123},
			{"rank": 2, "name": "Nova", "time_ms": 80044},
			{"rank": 3, "name": "Blaze", "time_ms": 80890},
			{"rank": 4, "name": "Quartz", "time_ms": 81550},
			{"rank": 5, "name": "Echo", "time_ms": 82010},
		],
	}


func _ranks_sample() -> Dictionary:
	return {
		"global": {
			"me": {"rank": 42, "value": 1240.0},
			"top": [
				{"rank": 1, "name": "Vortex", "value": 3980.0},
				{"rank": 2, "name": "Nova", "value": 3610.0},
				{"rank": 3, "name": "Blaze", "value": 3120.0},
				{"rank": 4, "name": "Quartz", "value": 2740.0},
				{"rank": 5, "name": "Echo", "value": 2210.0},
				{"rank": 6, "name": "Drift", "value": 1980.0},
			],
		},
		"explorers": {
			"me": {"rank": 12, "value": 87.0},
			"top": [
				{"rank": 1, "name": "Nomad", "value": 342.0},
				{"rank": 2, "name": "Vortex", "value": 288.0},
				{"rank": 3, "name": "Rook", "value": 201.0},
			],
		},
	}
