class_name Sfx
extends Node
## Synthesised sound (port of the web build's Web Audio graph): a harmonic engine through a low-pass,
## filtered-noise skid and wind loops, and short one-shots rendered on demand and cached.

const RATE := 44100
const MASTER := 0.48

# Procedural music beds: a soft sustained chord pad (plus a gentle pulse for the driving moods), one
# per mood. root Hz, chord semitone intervals, pulse bpm (0 = none), brightness 0..1.
const MUSIC_MOODS := {
	"warm": {"root": 110.0, "ivals": [0, 7, 12, 16], "bpm": 0, "bright": 0.5},
	"calm": {"root": 98.0, "ivals": [0, 7, 12, 14], "bpm": 0, "bright": 0.4},
	"dark": {"root": 82.4, "ivals": [0, 3, 7, 10], "bpm": 90, "bright": 0.32},
	"neon": {"root": 130.8, "ivals": [0, 4, 7, 11], "bpm": 120, "bright": 0.72},
}
const ENV_MOOD := {
	"CANYON": "warm", "ALPINE": "calm", "NEON": "neon", "GROVE": "calm",
	"ISLAND": "warm", "COUNTRY": "warm", "VOLCANO": "dark", "GREECE": "warm",
	"TOWN": "calm", "WETLANDS": "dark", "HARBOR": "calm", "SALTFLATS": "warm",
	"NOCTURNE": "neon", "DUSKMESA": "neon", "VENICE": "warm", "GRID": "neon",
}

var on := true
var inited := false
var engine_p: AudioStreamPlayer
var skid_p: AudioStreamPlayer
var wind_p: AudioStreamPlayer
var music_p: AudioStreamPlayer
var engine_lp: AudioEffectLowPassFilter
var bus_engine := -1
var bus_skid := -1
var bus_wind := -1
var bus_sfx := -1
var bus_music := -1
var bus_master := -1
var noise: PackedFloat32Array
var _cache := {}
var _pool: Array = []
var _sfx_vol := 1.0
var _music_vol := 0.55
var _music_mood := ""
var _music_cache := {}

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


func _bus(name: String, effects: Array, send: String = "SeedlineMaster") -> int:
	var i := AudioServer.get_bus_index(name)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, name)
		AudioServer.set_bus_send(i, send)
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
	# a sfx group and a music group hang off the master so each has its own level (volume split),
	# while the master bus still carries the global on/off mute for everything
	bus_sfx = _bus("SeedlineSfx", [])
	bus_music = _bus("SeedlineMusic", [])
	AudioServer.set_bus_volume_db(bus_sfx, _db(_sfx_vol))
	AudioServer.set_bus_volume_db(bus_music, _db(_music_vol))
	engine_lp = AudioEffectLowPassFilter.new()
	engine_lp.cutoff_hz = 600.0
	engine_lp.resonance = 0.35
	bus_engine = _bus("SeedlineEngine", [engine_lp], "SeedlineSfx")
	var bp := AudioEffectBandPassFilter.new()
	bp.cutoff_hz = 1900.0
	bp.resonance = 0.7
	bus_skid = _bus("SeedlineSkid", [bp], "SeedlineSfx")
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 520.0
	lp.resonance = 0.5
	bus_wind = _bus("SeedlineWind", [lp], "SeedlineSfx")
	# white noise shared by the loops and one-shots
	noise = PackedFloat32Array()
	noise.resize(RATE * 2)
	for i in noise.size():
		noise[i] = randf() * 2.0 - 1.0
	var nw := _wav(noise, true)
	# A harmonic-rich engine cycle; pitch_scale moves its fundamental with simulated RPM.
	var period := RATE / 50
	var eng := PackedFloat32Array()
	eng.resize(period)
	for i in period:
		var phase := TAU * float(i) / period
		eng[i] = (sin(phase) + sin(phase * 2.0) * 0.48 + sin(phase * 3.0) * 0.24 + sin(phase * 4.0) * 0.12 + sin(phase * 5.0) * 0.06) * 0.28
	engine_p = _player(_wav(eng, true), "SeedlineEngine")
	skid_p = _player(nw, "SeedlineSkid")
	wind_p = _player(nw, "SeedlineWind")
	engine_p.volume_db = -80.0
	skid_p.volume_db = -80.0
	wind_p.volume_db = -80.0
	engine_p.play()
	skid_p.play()
	wind_p.play(0.5)
	music_p = AudioStreamPlayer.new()
	music_p.bus = "SeedlineMusic"
	add_child(music_p)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SeedlineSfx"
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


func set_sfx_vol(f: float) -> void:
	_sfx_vol = clampf(f, 0.0, 1.0)
	if bus_sfx >= 0:
		AudioServer.set_bus_volume_db(bus_sfx, _db(_sfx_vol))


func set_music_vol(f: float) -> void:
	_music_vol = clampf(f, 0.0, 1.0)
	if bus_music >= 0:
		AudioServer.set_bus_volume_db(bus_music, _db(_music_vol))


## Swap the music bed to the given environment's mood (no-op if it is already playing). The pad is
## rendered once per mood on a worker thread and cached, so the first use of a mood never hitches.
func play_music(env_key: String) -> void:
	if not inited or music_p == null:
		return
	var mood_id: String = ENV_MOOD.get(env_key, "calm")
	if mood_id == _music_mood and music_p.playing:
		return
	_music_mood = mood_id
	if not _music_cache.has(mood_id):
		var mood: Dictionary = MUSIC_MOODS[mood_id]
		var result := {}
		var tid := WorkerThreadPool.add_task(func(): result["buf"] = _render_music(mood), false, "seedline music bed")
		while not WorkerThreadPool.is_task_completed(tid):
			await get_tree().process_frame
		WorkerThreadPool.wait_for_task_completion(tid)
		if not (result.get("buf") is PackedFloat32Array):
			return
		_music_cache[mood_id] = _wav(result["buf"], true)
	if _music_mood != mood_id:
		return  # env changed again while rendering
	music_p.stream = _music_cache[mood_id]
	music_p.play()


# A seamless 12s ambient pad: detuned chord voices with a slow per-voice swell, plus a soft beat pulse
# for driving moods. All oscillator frequencies are quantised to whole cycles over the loop so it tiles
# without a click. Pure and deterministic, so it is safe to render on a worker thread.
func _render_music(mood: Dictionary) -> PackedFloat32Array:
	var dur := 12.0
	var n := int(dur * RATE)
	var root: float = mood.root
	var ivals: Array = mood.ivals
	var bright: float = mood.bright
	var bpm: float = mood.bpm
	var freqs: Array = []
	for s in ivals:
		var f: float = round(root * pow(2.0, float(s) / 12.0) * dur) / dur
		freqs.append(f)
		freqs.append(round(f * 1.004 * dur) / dur)   # detuned partner for slow chorus beating
		freqs.append(round(f * 2.0 * dur) / dur)      # octave harmonic for brightness
	var pulse_f: float = round(root * 0.5 * dur) / dur
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for fi in freqs.size():
			var f: float = freqs[fi]
			var is_harm := fi % 3 == 2
			var amp := (0.18 * bright) if is_harm else (1.0 if fi % 3 == 0 else 0.8)
			var swell := 0.6 + 0.4 * sin(TAU * t / dur + fi * 0.7)
			s += sin(TAU * f * t) * amp * swell
		s *= 0.14 / float(ivals.size())
		if bpm > 0.0:
			var beat := t * bpm / 60.0
			var ph := beat - floorf(beat)
			s += sin(TAU * pulse_f * t) * 0.09 * exp(-ph * 9.0)
		out[i] = clampf(s, -1.0, 1.0)
	return out


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
	t_eg = 0.075 + load * 0.07 + (0.025 if boost else 0.0) if active else 0.0


func skid(v: float) -> void:
	t_skg = v * 0.55


func wind(v: float) -> void:
	t_wg = v * 0.72


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
			var attack := minf(t / 0.006, 1.0)
			out[i] = s * vol * attack * pow(0.001 / vol, t / d)
		return out)


func chime(up: bool) -> void:
	beep(880.0 if up else 660.0, 0.12, "triangle", 0.15)
	get_tree().create_timer(0.07).timeout.connect(func(): beep(1320.0 if up else 990.0, 0.18, "triangle", 0.13))


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
	var g := clampf(v, 0.0, 1.0) * 0.4
	_play("thud", func():
		var n := int(0.34 * RATE)
		var f := _biquad(noise.slice(0, n), "lowpass", func(t): return 420.0, 0.7071)
		for i in n:
			var t := float(i) / RATE
			var tail := exp(-t * 18.0)
			var cycles := 105.0 * t + (48.0 - 105.0) * t * t / 0.4 if t < 0.2 else 15.3 + 48.0 * (t - 0.2)
			var phase := TAU * cycles
			f[i] = f[i] * 0.55 * exp(-t * 30.0) + sin(phase) * 0.38 * tail
			if t > 0.24:
				f[i] *= exp(-(t - 0.24) * 35.0)
		return f, g)


func splash(v: float) -> void:
	_play("splash", func():
		var n := int(0.65 * RATE)
		var f := _biquad(noise.slice(0, n), "bandpass", func(t): return 1800.0 * pow(500.0 / 1800.0, minf(t / 0.5, 1.0)), 0.8)
		for i in n:
			var t := float(i) / RATE
			f[i] *= pow(0.001 / 0.35, minf(t / 0.6, 1.0)) if t < 0.6 else 0.0
		return f, 0.24 * v)


func whoosh() -> void:
	_play("whoosh", func():
		var n := int(0.65 * RATE)
		var f := _biquad(noise.slice(0, n), "bandpass", func(t): return 400.0 * pow(3000.0 / 400.0, minf(t / 0.5, 1.0)), 1.2)
		for i in n:
			var t := float(i) / RATE
			f[i] *= pow(0.001 / 0.25, minf(t / 0.6, 1.0)) if t < 0.6 else 0.0
		return f, 0.18)
