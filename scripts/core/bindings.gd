class_name Bindings
extends RefCounted
## Rebindable controls. Two slots per action for keyboard and for gamepad, persisted in Store.
## Keyboard slots hold physical keycodes (int, 0 = empty). Gamepad slots hold "b:<button>" or "a:<axis>:<+|->" ("" = empty).

const ACTIONS := [
	["gas", "Accelerate"],
	["brake", "Brake / reverse"],
	["left", "Steer left"],
	["right", "Steer right"],
	["boost", "Boost"],
	["respawn", "Respawn"],
	["restart", "Restart"],
	["pause", "Pause"],
	["drift", "Drift"],
]
const EDGE := ["respawn", "restart", "pause"]
const DEADZONE := 0.15
const TRIGGER_ON := 0.3
const KEY_DEFAULTS := {
	"gas": [KEY_UP, KEY_W], "brake": [KEY_DOWN, KEY_S], "left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D],
	"boost": [KEY_SPACE, KEY_SHIFT], "respawn": [KEY_BACKSPACE, KEY_DELETE], "restart": [KEY_R, 0],
	"pause": [KEY_ESCAPE, KEY_P], "drift": [KEY_K, 0],
}
const PAD_DEFAULTS := {
	"gas": ["a:5:+", ""], "brake": ["a:4:+", "b:1"], "left": ["a:0:-", "b:13"], "right": ["a:0:+", "b:14"],
	"boost": ["b:0", ""], "respawn": ["b:3", ""], "restart": ["", ""], "pause": ["b:6", ""],
	"drift": ["b:2", "b:9"],
}

static var kb := {}
static var pad := {}
static var _loaded := false


static func visible_actions(drift_enabled: bool) -> Array:
	var out: Array = []
	for a in ACTIONS:
		if a[0] != "drift" or drift_enabled:
			out.append(a)
	return out


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	reset_all(false)
	var saved: Dictionary = Store.get_value("binds", {})
	var skb: Dictionary = saved.get("kb", {})
	var spad: Dictionary = saved.get("pad", {})
	for a in ACTIONS:
		var id: String = a[0]
		if skb.has(id) and skb[id] is Array and skb[id].size() == 2:
			kb[id] = [int(skb[id][0]), int(skb[id][1])]
		if spad.has(id) and spad[id] is Array and spad[id].size() == 2:
			pad[id] = [str(spad[id][0]), str(spad[id][1])]


static func reset_all(save := true) -> void:
	for a in ACTIONS:
		kb[a[0]] = (KEY_DEFAULTS[a[0]] as Array).duplicate()
		pad[a[0]] = (PAD_DEFAULTS[a[0]] as Array).duplicate()
	if save:
		_save()


static func reset_device(device: String) -> void:
	_ensure()
	for a in ACTIONS:
		if device == "kb":
			kb[a[0]] = (KEY_DEFAULTS[a[0]] as Array).duplicate()
		else:
			pad[a[0]] = (PAD_DEFAULTS[a[0]] as Array).duplicate()
	_save()


static func _save() -> void:
	Store.set_value("binds", {"kb": kb, "pad": pad})


static func get_slot(device: String, action: String, slot: int):
	_ensure()
	return (kb if device == "kb" else pad)[action][slot]


## Assign a binding; the same input is removed from any other action on that device.
static func set_slot(device: String, action: String, slot: int, value) -> void:
	_ensure()
	var d: Dictionary = kb if device == "kb" else pad
	var empty = 0 if device == "kb" else ""
	if value != empty:
		for a in ACTIONS:
			for s in 2:
				if d[a[0]][s] == value:
					d[a[0]][s] = empty
	d[action][slot] = value
	_save()


# ------------------------------------------------------------------ keyboard

static func key_held(action: String) -> bool:
	_ensure()
	for code in kb[action]:
		if code != 0 and Input.is_physical_key_pressed(code):
			return true
	return false


static func key_matches(ev: InputEventKey, action: String) -> bool:
	_ensure()
	var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
	return code != 0 and code in kb[action]


static func key_label(code: int) -> String:
	if code == 0:
		return "—"
	var kc: int = 0 if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(code)
	var s := OS.get_keycode_string(kc if kc != 0 else code)
	return s if s != "" else "Key %d" % code


# ------------------------------------------------------------------ gamepad

static func pad_value(device: int, action: String) -> float:
	_ensure()
	var best := 0.0
	for b in pad[action]:
		best = maxf(best, _binding_value(device, b))
	return best


static func pad_pressed(device: int, action: String) -> bool:
	return pad_value(device, action) > TRIGGER_ON


static func _binding_value(device: int, b: String) -> float:
	if b == "":
		return 0.0
	var p := b.split(":")
	if p[0] == "b":
		return 1.0 if Input.is_joy_button_pressed(device, int(p[1])) else 0.0
	var v := Input.get_joy_axis(device, int(p[1])) * (1.0 if p[2] == "+" else -1.0)
	if v < DEADZONE:
		return 0.0
	return minf(1.0, v)


static func pad_has_axis(action: String) -> bool:
	_ensure()
	for b in pad[action]:
		if (b as String).begins_with("a:"):
			return true
	return false


## Binding string for a gamepad event, or "" if it is not a deliberate press.
static func pad_from_event(ev: InputEvent) -> String:
	if ev is InputEventJoypadButton and ev.pressed:
		return "b:%d" % ev.button_index
	if ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.7:
		return "a:%d:%s" % [ev.axis, "+" if ev.axis_value > 0.0 else "-"]
	return ""


static func pad_event_matches(ev: InputEvent, action: String) -> bool:
	_ensure()
	var s := pad_from_event(ev)
	return s != "" and s in pad[action]


static func sony_connected() -> bool:
	for d in Input.get_connected_joypads():
		var n := Input.get_joy_name(int(d)).to_lower()
		if "ps" in n or "sony" in n or "dualshock" in n or "dualsense" in n or "playstation" in n:
			return true
	return false


static func pad_label(b: String) -> String:
	if b == "":
		return "—"
	var sony := sony_connected()
	var any := Input.get_connected_joypads().is_empty()
	var p := b.split(":")
	if p[0] == "b":
		var i := int(p[1])
		var face := {
			0: ["A", "Cross"], 1: ["B", "Circle"], 2: ["X", "Square"], 3: ["Y", "Triangle"],
			4: ["Back", "Share"], 6: ["Start", "Options"], 7: ["L-Stick click", "L3"], 8: ["R-Stick click", "R3"],
			9: ["LB", "L1"], 10: ["RB", "R1"], 11: ["D-pad up", "D-pad up"], 12: ["D-pad down", "D-pad down"],
			13: ["D-pad left", "D-pad left"], 14: ["D-pad right", "D-pad right"],
		}
		if not face.has(i):
			return "Button %d" % i
		var pair: Array = face[i]
		if any and pair[0] != pair[1]:
			return "%s / %s" % pair
		return pair[1] if sony else pair[0]
	var axis := int(p[1])
	var sign_s: String = p[2]
	match axis:
		0: return "L-Stick " + ("right" if sign_s == "+" else "left")
		1: return "L-Stick " + ("down" if sign_s == "+" else "up")
		2: return "R-Stick " + ("right" if sign_s == "+" else "left")
		3: return "R-Stick " + ("down" if sign_s == "+" else "up")
		4: return "L2" if sony else "LT"
		5: return "R2" if sony else "RT"
	return "Axis %d%s" % [axis, sign_s]
