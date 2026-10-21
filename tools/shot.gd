extends SceneTree
## Dev helper: run the game, optionally drive it, and save screenshots.
## godot --path . --script res://tools/shot.gd -- seed=K7Q2XM out=/tmp/a.png frames=90 mode=menu|race|garage|finish drive=1

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


func _process(delta: float) -> bool:
	frame += 1
	var mode: String = args.get("mode", "menu")
	if frame == 4 and args.has("touch"):
		main.touch_ui = true
		main.ui.set_touch(true)
		main.ui.relayout()
	if frame == 5:
		if mode == "garage":
			main.set_tab("garage")
		elif mode == "saved":
			main.set_tab("saved")
		elif mode == "options":
			main.set_tab("options")
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
