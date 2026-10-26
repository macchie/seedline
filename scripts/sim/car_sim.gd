class_name CarSim
extends RefCounted
## Arcade kart model (snappy steering, hop-drift, three-level mini-turbo) — same constants and maths as the web build.

const VMAX := 64.0
const VMAX_OFF := 28.0
const BOOST_MAX := 84.0
const BOOST_CAP := 100.0
const BOOST_START := BOOST_CAP * 2.0 / 3.0
const BOOST_DRAIN := 33.4
const ACCEL := 46.0
const BRAKE := 54.0
const COAST := 3.4
const REVERSE_MAX := 13.0
const YAW_LOW := 3.35
const YAW_HIGH := 1.78
const GRIP := 13.0
const GRIP_OFF := 4.5
const GRIP_DRIFT := 2.3
const STEER_RATE := 11.0
const STEER_RETURN := 15.0
## seconds of continuous drifting for the blue, orange and purple mini-turbo, and the boost each gives
const TURBO := [0.6, 1.25, 1.95]
const TURBO_T := [0.0, 0.45, 0.8, 1.15]

# --- state (the "car" object of the web build)
var x := 0.0
var y := 0.0
var z := 0.0
var h := 0.0
var vx := 0.0
var vz := 0.0
var w := 0.0
var steer := 0.0
var drift := false
var drift_t := 0.0
var drift_dir := 0.0
var level := 0
var level_up := 0
var turbo := 0
var hop_t := 0.0
var drift_latch := false
var boost_t := 0.0
var boost_amt := BOOST_START
var boost_held := false
var on_road := true
var in_water := false
var idx := 0
var lat := 0.0
var slope := 0.0
var px := 0.0
var pz := 0.0
var ph := 0.0
var vf := 0.0
var vl := 0.0
var impact := 0.0


static func yaw_at(v: float) -> float:
	return U.lerpf2(YAW_LOW, YAW_HIGH, U.clampf2(v / VMAX, 0.0, 1.0)) * minf(1.0, v / 6.0)


## One fixed physics step. inp: {gas, brake, drift, steer, analog}
func step(dt: float, inp: Dictionary, env_grip: float) -> void:
	var tgt: float = inp["steer"]
	var rate: float
	if inp.get("analog", false):
		rate = 32.0
	elif absf(tgt) < 0.01 or U.jsign(tgt) != U.jsign(steer):
		rate = STEER_RETURN
	else:
		rate = STEER_RATE
	steer += U.clampf2(tgt - steer, -rate * dt, rate * dt)
	var fx := sin(h)
	var fz := cos(h)
	var rx := -fz
	var rz := fx
	var f := vx * fx + vz * fz
	var l := vx * rx + vz * rz
	if hop_t > 0.0:
		hop_t -= dt
	# hop-drift: press drift while turning at speed; hold to keep sliding, steer in to tighten, out to widen
	if not inp["drift"]:
		drift_latch = false
	if not drift and inp["drift"] and not drift_latch and absf(steer) > 0.28 and f > 13.0 and on_road:
		drift = true
		drift_t = 0.0
		drift_dir = U.jsign(steer)
		hop_t = 0.22
		level = 0
	if drift:
		drift_t += dt
		var lv := 3 if drift_t >= TURBO[2] else (2 if drift_t >= TURBO[1] else (1 if drift_t >= TURBO[0] else 0))
		if lv > level:
			level = lv
			level_up = lv
		var lost := f < 9.0 or not on_road
		if not inp["drift"] or lost:
			if not lost and level > 0:
				boost_t = maxf(boost_t, TURBO_T[level])
				turbo = level
			if inp["drift"]:
				drift_latch = true
			drift = false
			level = 0
	if boost_t > 0.0:
		boost_t -= dt
	boost_held = inp.get("boost", false) and boost_amt > 0.0
	if boost_held:
		boost_amt = maxf(0.0, boost_amt - BOOST_DRAIN * dt)
	var boosting := boost_t > 0.0 or boost_held
	var a0slope := 9.8 * slope * 0.85 if slope != 0.0 else 0.0
	var vmax := 11.0 if in_water else (BOOST_MAX if boosting else (VMAX if on_road else VMAX_OFF))
	var a := 0.0
	if inp["gas"]:
		if f < vmax:
			a += ACCEL * (1.0 - pow(U.clampf2(f / vmax, 0.0, 1.0), 3.0)) + (32.0 if boosting else 0.0)
		if f < 0.0:
			a += BRAKE * 0.7
	elif boosting and f < vmax:
		a += 32.0
	var braking: bool = inp["brake"] and not drift
	if braking:
		if f > 0.5:
			a -= BRAKE
		elif not inp["gas"] and f > -REVERSE_MAX:
			a -= 18.0
	if drift:
		a -= 1.5
	a -= a0slope
	if not inp["gas"] and not braking and not boosting:
		a -= U.jsign(f) * minf(absf(f) / dt, COAST)
	if f > vmax:
		a -= (f - vmax) * (1.4 if on_road else 2.4)
	if not on_road:
		a -= f * (1.8 if in_water else 0.6)
	var nvf := f + a * dt
	f = 0.0 if (f > 0.0 and braking and nvf < 0.0) else nvf
	# lateral grip; scrubbed sideways speed is partly returned as forward speed so corners keep their flow
	var grip := GRIP_DRIFT if drift else (GRIP if on_road else GRIP_OFF) * env_grip
	var l2 := l * exp(-grip * dt)
	var kk := 0.82 if drift else (0.95 if on_road else 0.4)
	var gain := (l * l - l2 * l2) * kk
	f = sqrt(f * f + gain) if f >= 0.0 else -sqrt(f * f + gain)
	l = l2
	# yaw
	var sp := absf(f)
	var yaw := yaw_at(sp)
	var st := steer
	if drift:
		st = drift_dir * (0.55 + 0.45 * U.clampf2(steer * drift_dir, -1.0, 1.0))
		yaw *= 1.5
	if not on_road:
		yaw *= 0.55 if in_water else 0.85
	var tw := -st * yaw * (1.0 if f >= -0.5 else -1.0)
	w += (tw - w) * minf(1.0, dt * (8.0 if drift else 17.0))
	vx = fx * f + rx * l
	vz = fz * f + rz * l
	vf = f
	vl = l
	h += w * dt
	x += vx * dt
	z += vz * dt


func is_boosting() -> bool:
	return boost_t > 0.0 or boost_held


func add_boost(v: float) -> void:
	boost_amt = minf(BOOST_CAP, boost_amt + v)


func place(t: TrackData, i: int, back: int = 0) -> void:
	var j := (i - back + t.n) % t.n
	x = t.px[j]
	z = t.pz[j]
	h = atan2(t.tx[j], t.tz[j])
	vx = 0.0
	vz = 0.0
	w = 0.0
	steer = 0.0
	drift = false
	drift_latch = false
	level = 0
	level_up = 0
	turbo = 0
	hop_t = 0.0
	boost_t = 0.0
	idx = j
	lat = 0.0
	on_road = true
	vf = 0.0
	vl = 0.0
	px = x
	pz = z
	ph = h


## Nearest track sample, lateral offset, road height and slope (port of updateProgress). Returns previous index.
func update_progress(t: TrackData) -> int:
	var N := t.n
	var bi := idx
	var bd := 1e18
	for o in range(-16, 17):
		var i := (idx + o + N) % N
		var dx := x - t.px[i]
		var dz := z - t.pz[i]
		var d := dx * dx + dz * dz
		if d < bd:
			bd = d
			bi = i
	if bd > (U.HW + 30.0) * (U.HW + 30.0):
		for i in N:
			var dx := x - t.px[i]
			var dz := z - t.pz[i]
			var d := dx * dx + dz * dz
			if d < bd:
				bd = d
				bi = i
	var prev := idx
	idx = bi
	lat = (x - t.px[bi]) * t.nx[bi] + (z - t.pz[bi]) * t.nz[bi]
	var al := (x - t.px[bi]) * t.tx[bi] + (z - t.pz[bi]) * t.tz[bi]
	var along := absf(al)
	var nb := (bi + (1 if al >= 0.0 else -1) + N) % N
	y = U.lerpf2(t.py[bi], t.py[nb], U.clampf2(along / U.DS, 0.0, 1.0))
	slope = (t.py[(bi + 1) % N] - t.py[(bi - 1 + N) % N]) / (2.0 * U.DS) * (sin(h) * t.tx[bi] + cos(h) * t.tz[bi])
	on_road = t.py[bi] > 0.3 or (absf(lat) < U.HW + (1.4 if absf(t.k[bi]) > 0.022 else 0.5) and along < U.DS)
	return prev
