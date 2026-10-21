class_name Sfx
extends Node
## Synthesised sound (port of the web build's Web Audio graph): a saw+square engine through a resonant low-pass,
## filtered-noise skid and wind loops, and short one-shots rendered on demand and cached.

const RATE := 44100
const MASTER := 0.55

var on := true
var inited := false
var engine_p: AudioStreamPlayer
var skid_p: AudioStreamPlayer
var wind_p: AudioStreamPlayer
var engine_lp: AudioEffectLowPassFilter
var bus_engine := -1
var bus_skid := -1
var bus_wind := -1
var bus_master := -1
var noise: PackedFloat32Array
var _cache := {}
var _pool: Array = []

# smoothed parameters (setTargetAtTime)
var _fr := 40.0
var _cut := 600.0
var _eg := 0.0
var _skg := 0.0
var _wg := 0.0
var _mg := MASTER
var t_fr := 40.0
var t_cut := 600.0
var t_eg := 0.0
var t_skg := 0.0
var t_wg := 0.0
var t_mg := MASTER


func _bus(name: String, effects: Array) -> int:
	var i := AudioServer.get_bus_index(name)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, name)
		AudioServer.set_bus_send(i, "SeedlineMaster")
		for e in effects:
			AudioServer.add_bus_effect(i, e)
	return i


func init(sound_on: bool) -> void:
	on = sound_on
	t_mg = MASTER if on else 0.0
	_mg = t_mg
	if inited:
		return
	inited = true
	bus_master = AudioServer.get_bus_index("SeedlineMaster")
	if bus_master < 0:
		AudioServer.add_bus()
		bus_master = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_master, "SeedlineMaster")
		AudioServer.set_bus_send(bus_master, "Master")
	engine_lp = AudioEffectLowPassFilter.new()
	engine_lp.cutoff_hz = 600.0
	engine_lp.resonance = 0.75
	bus_engine = _bus("SeedlineEngine", [engine_lp])
	var bp := AudioEffectBandPassFilter.new()
	bp.cutoff_hz = 1900.0
	bp.resonance = 0.7
	bus_skid = _bus("SeedlineSkid", [bp])
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 520.0
	lp.resonance = 0.5
	bus_wind = _bus("SeedlineWind", [lp])
	# white noise shared by the loops and one-shots
	noise = PackedFloat32Array()
	noise.resize(RATE * 2)
	for i in noise.size():
		noise[i] = randf() * 2.0 - 1.0
	var nw := _wav(noise, true)
	# engine: one period of a saw at 100 Hz plus a square an octave down (gain .35); pitch_scale sets the note
	var period := RATE / 50
	var eng := PackedFloat32Array()
	eng.resize(period)
	for i in period:
		var ph2 := float(i) / period          # square phase (50 Hz)
		var ph1 := fmod(ph2 * 2.0, 1.0)       # saw phase (100 Hz)
		eng[i] = ((ph1 * 2.0 - 1.0) + (1.0 if ph2 < 0.5 else -1.0) * 0.35) * 0.5
	engine_p = _player(_wav(eng, true), "SeedlineEngine")
	skid_p = _player(nw, "SeedlineSkid")
	wind_p = _player(nw, "SeedlineWind")
	engine_p.volume_db = -80.0
	skid_p.volume_db = -80.0
	wind_p.volume_db = -80.0
	engine_p.play()
	skid_p.play()
	wind_p.play(0.5)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SeedlineMaster"
		add_child(p)
		_pool.append(p)


func _player(stream: AudioStream, bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	add_child(p)
	return p


func _wav(data: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w


static func _db(g: float) -> float:
	return -80.0 if g <= 0.00001 else linear_to_db(g)


func set_on(v: bool) -> void:
	on = v
	t_mg = MASTER if on else 0.0


func _process(dt: float) -> void:
	if not inited:
		return
	_mg = _approach(_mg, t_mg, dt, 0.05)
	_fr = _approach(_fr, t_fr, dt, 0.04)
	_cut = _approach(_cut, t_cut, dt, 0.05)
	_eg = _approach(_eg, t_eg, dt, 0.08)
	_skg = _approach(_skg, t_skg, dt, 0.05)
	_wg = _approach(_wg, t_wg, dt, 0.2)
	AudioServer.set_bus_volume_db(bus_master, _db(_mg))
	engine_p.pitch_scale = clampf(_fr / 100.0, 0.05, 16.0)
	engine_lp.cutoff_hz = clampf(_cut, 20.0, 20000.0)
	engine_p.volume_db = _db(_eg)
	skid_p.volume_db = _db(_skg)
	wind_p.volume_db = _db(_wg)


static func _approach(v: float, target: float, dt: float, tc: float) -> float:
	return target + (v - target) * exp(-dt / tc)


func engine(speed: float, load: float, boost: bool, active: bool) -> void:
	if not inited:
		return
	var G := [0.0, 13.0, 23.0, 34.0, 45.0, 56.0, 110.0]
	var g := 1
	while g < G.size() - 1 and speed > G[g]:
		g += 1
	var rpm := U.clampf2((speed - G[g - 1]) / (G[g] - G[g - 1]), 0.0, 1.0) * 0.75 + 0.25 + (load * 0.35 if speed < 1.0 else 0.0)
	t_fr = 40.0 + rpm * (110.0 + g * 12.0)
	t_cut = 300.0 + load * 1100.0 + rpm * 900.0 + (900.0 if boost else 0.0)
	t_eg = 0.055 + load * 0.06 if active else 0.0


func skid(v: float) -> void:
	t_skg = v


func wind(v: float) -> void:
	t_wg = v


func _play(key: String, make: Callable, vol: float = 1.0) -> void:
	if not inited:
		return
	if not _cache.has(key):
		_cache[key] = _wav(make.call(), false)
	for p in _pool:
		if not p.playing:
			p.stream = _cache[key]
			p.volume_db = _db(vol)
			p.play()
			return
	var q: AudioStreamPlayer = _pool[0]
	q.stream = _cache[key]
	q.volume_db = _db(vol)
	q.play()


func beep(f: float, d: float = 0.15, type: String = "square", vol: float = 0.18) -> void:
	_play("beep|%s|%s|%s|%s" % [f, d, type, vol], func():
		var n := int(d * RATE)
		var out := PackedFloat32Array()
		out.resize(n)
		for i in n:
			var t := float(i) / RATE
			var ph := fmod(t * f, 1.0)
			var s := (1.0 if ph < 0.5 else -1.0) if type == "square" else (1.0 - 4.0 * absf(ph - 0.5))
			out[i] = s * vol * pow(0.001 / vol, t / d)
		return out)


func chime(up: bool) -> void:
	beep(880.0 if up else 660.0, 0.12, "triangle", 0.22)
	get_tree().create_timer(0.07).timeout.connect(func(): beep(1320.0 if up else 990.0, 0.18, "triangle", 0.2))


## RBJ biquad over a buffer; f0 may vary per sample (Callable(t) -> Hz)
func _biquad(src: PackedFloat32Array, kind: String, f0: Callable, q: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(src.size())
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in src.size():
		var w0 := TAU * float(f0.call(float(i) / RATE)) / RATE
		var cw := cos(w0)
		var al := sin(w0) / (2.0 * q)
		var b0: float
		var b1: float
		var b2: float
		if kind == "lowpass":
			b0 = (1.0 - cw) / 2.0
			b1 = 1.0 - cw
			b2 = (1.0 - cw) / 2.0
		else:
			b0 = al
			b1 = 0.0
			b2 = -al
		var a0 := 1.0 + al
		var a1 := -2.0 * cw
		var a2 := 1.0 - al
		var x := src[i]
		var y := (b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] = y
	return out


func thud(v: float) -> void:
	var g := minf(0.6, v)
	_play("thud", func():
		var n := int(0.3 * RATE)
		var f := _biquad(noise.slice(0, n), "lowpass", func(t): return 260.0, 0.7071)
		for i in n:
			var t := float(i) / RATE
			f[i] *= 1.0 * pow(0.001, minf(t / 0.25, 1.0)) if t < 0.25 else 0.0
		return f, g)


func splash(v: float) -> void:
	_play("splash", func():
		var n := int(0.65 * RATE)
		var f := _biquad(noise.slice(0, n), "bandpass", func(t): return 1800.0 * pow(500.0 / 1800.0, minf(t / 0.5, 1.0)), 0.8)
		for i in n:
			var t := float(i) / RATE
			f[i] *= pow(0.001 / 0.35, minf(t / 0.6, 1.0)) if t < 0.6 else 0.0
		return f, 0.35 * v)


func whoosh() -> void:
	_play("whoosh", func():
		var n := int(0.65 * RATE)
		var f := _biquad(noise.slice(0, n), "bandpass", func(t): return 400.0 * pow(3000.0 / 400.0, minf(t / 0.5, 1.0)), 1.2)
		for i in n:
			var t := float(i) / RATE
			f[i] *= pow(0.001 / 0.25, minf(t / 0.6, 1.0)) if t < 0.6 else 0.0
		return f, 0.25)
