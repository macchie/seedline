class_name Tex
## Procedural textures (the web build drew these on <canvas>).

static var _cache := {}


static func _to_tex(img: Image, mip: bool = true) -> ImageTexture:
	if mip:
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## canvas noisePaint(): Park-Miller LCG noise added to every pixel (8-bit, clamped like Uint8ClampedArray)
static func _noise_bytes(d: PackedByteArray, amt: float, seed: int) -> void:
	var s := seed
	var i := 0
	var n := d.size()
	while i < n:
		s = (s * 16807) % 2147483647
		var v := (float(s) / 2147483647.0 - 0.5) * amt
		d[i] = clampi(roundi(d[i] + v), 0, 255)
		d[i + 1] = clampi(roundi(d[i + 1] + v), 0, 255)
		d[i + 2] = clampi(roundi(d[i + 2] + v), 0, 255)
		i += 4


static func _noise_paint(img: Image, amt: float, seed: int) -> void:
	var d := img.get_data()
	_noise_bytes(d, amt, seed)
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, d)


## source-over fill of a rectangle with a translucent colour, on raw RGBA8 bytes
static func _blend_bytes(d: PackedByteArray, w: int, h: int, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var r := c.r * 255.0
	var g := c.g * 255.0
	var b := c.b * 255.0
	var a := c.a
	for y in range(maxi(0, y0), mini(h, y1)):
		var row := y * w * 4
		for x in range(maxi(0, x0), mini(w, x1)):
			var i := row + x * 4
			d[i] = roundi(d[i] + (r - d[i]) * a)
			d[i + 1] = roundi(d[i + 1] + (g - d[i + 1]) * a)
			d[i + 2] = roundi(d[i + 2] + (b - d[i + 2]) * a)


static func radial() -> ImageTexture:
	if _cache.has("radial"):
		return _cache["radial"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r := Vector2(x + 0.5 - 32.0, y + 0.5 - 32.0).length() / 32.0
			var a := 0.0
			if r < 0.35:
				a = lerpf(1.0, 0.55, r / 0.35)
			elif r < 1.0:
				a = lerpf(0.55, 0.0, (r - 0.35) / 0.65)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var t := _to_tex(img)
	_cache["radial"] = t
	return t


static func blob() -> ImageTexture:
	if _cache.has("blob"):
		return _cache["blob"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r := Vector2(x + 0.5 - 32.0, y + 0.5 - 32.0).length()
			var a := 0.7 if r <= 4.0 else (lerpf(0.7, 0.0, (r - 4.0) / 28.0) if r < 32.0 else 0.0)
			img.set_pixel(x, y, Color(0, 0, 0, a))
	var t := _to_tex(img)
	_cache["blob"] = t
	return t


static func _blend(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var d := img.get_data()
	_blend_bytes(d, img.get_width(), img.get_height(), x0, y0, x1, y1, c)
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, d)


## Asphalt with worn racing grooves, edge lines and a centre dash. encode=true pre-encodes for StandardMaterial3D.
static func road(e: Dictionary, encode: bool) -> ImageTexture:
	var w := 256
	var h := 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(U.css(e["road"]))
	var d := img.get_data()
	_noise_bytes(d, 26.0, 7)
	for cx: float in [0.3, 0.7]:
		var xa := int(w * (cx - 0.12))
		var xb := int(w * (cx + 0.12)) + 1
		for x in range(xa, xb):
			var t := (x + 0.5 - w * (cx - 0.12)) / (w * 0.24)
			var a := 0.16 * (1.0 - absf(t - 0.5) * 2.0)
			if a > 0.0:
				_blend_bytes(d, w, h, x, 0, x + 1, h, Color(0, 0, 0, a))
	var edge := U.css(e["edge"])
	_blend_bytes(d, w, h, 9, 0, 16, h, edge)
	_blend_bytes(d, w, h, w - 16, 0, w - 9, h, edge)
	_blend_bytes(d, w, h, w / 2 - 3, 0, w / 2 + 3, int(h * 0.42), U.css(e["dash"]))
	if encode:
		var lut := PackedByteArray()
		lut.resize(256)
		for i in 256:
			var v := Color(i / 255.0, 0, 0).linear_to_srgb().r
			lut[i] = clampi(roundi(v * 255.0), 0, 255)
		var i := 0
		while i < d.size():
			d[i] = lut[d[i]]
			d[i + 1] = lut[d[i + 1]]
			d[i + 2] = lut[d[i + 2]]
			i += 4
	img.set_data(w, h, false, Image.FORMAT_RGBA8, d)
	return _to_tex(img)


static func ground(e: Dictionary) -> ImageTexture:
	if e.get("grid", false):
		var key := "ground_grid"
		if _cache.has(key):
			return _cache[key]
		var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
		img.fill(Color("#0a1325"))
		_noise_paint(img, 5.0, 2)
		var halo := Color(50 / 255.0, 188 / 255.0, 1.0, 0.12)
		var c1 := Color(58 / 255.0, 237 / 255.0, 1.0, 0.92)
		var c2 := Color(103 / 255.0, 116 / 255.0, 1.0, 0.32)
		# A soft cyan halo under the cell borders keeps the distant lightgrid readable.
		_blend(img, 0, 0, 256, 8, halo)
		_blend(img, 0, 248, 256, 256, halo)
		_blend(img, 0, 0, 8, 256, halo)
		_blend(img, 248, 0, 256, 256, halo)
		_blend(img, 0, 0, 256, 3, c1)
		_blend(img, 0, 253, 256, 256, c1)
		_blend(img, 0, 0, 3, 256, c1)
		_blend(img, 253, 0, 256, 256, c1)
		_blend(img, 127, 0, 129, 256, c2)
		_blend(img, 0, 127, 256, 129, c2)
		var t := _to_tex(img)
		_cache[key] = t
		return t
	if e.get("space", false):
		var key := "ground_orbital"
		if _cache.has(key):
			return _cache[key]
		var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
		img.fill(Color("#111b2a"))
		_noise_paint(img, 9.0, 19)
		var seam := Color("#25384d")
		var inlay := Color("#182b40")
		_blend(img, 0, 0, 256, 2, seam)
		_blend(img, 0, 254, 256, 256, seam)
		_blend(img, 0, 0, 2, 256, seam)
		_blend(img, 254, 0, 256, 256, seam)
		_blend(img, 8, 8, 248, 10, inlay)
		_blend(img, 8, 246, 248, 248, inlay)
		_blend(img, 8, 10, 10, 246, inlay)
		_blend(img, 246, 10, 248, 246, inlay)
		_blend(img, 127, 10, 129, 246, Color("#172639"))
		_blend(img, 10, 127, 246, 129, Color("#172639"))
		var t := _to_tex(img)
		_cache[key] = t
		return t
	if e.get("night", false):
		var key := "ground_night"
		if _cache.has(key):
			return _cache[key]
		var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
		img.fill(Color("#0f0c1d"))
		_noise_paint(img, 10.0, 3)
		var c1 := Color(140 / 255.0, 90 / 255.0, 1.0, 0.55)
		var c2 := Color(140 / 255.0, 90 / 255.0, 1.0, 0.18)
		# 3px border (strokeRect centred on the edge) and 1px centre cross
		_blend(img, 0, 0, 256, 2, c1)
		_blend(img, 0, 254, 256, 256, c1)
		_blend(img, 0, 0, 2, 256, c1)
		_blend(img, 254, 0, 256, 256, c1)
		_blend(img, 127, 0, 129, 256, c2)
		_blend(img, 0, 127, 256, 129, c2)
		var t := _to_tex(img)
		_cache[key] = t
		return t
	if _cache.has("ground"):
		return _cache["ground"]
	var img2 := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img2.fill(Color.WHITE)
	_noise_paint(img2, 46.0, 11)
	var t2 := _to_tex(img2)
	_cache["ground"] = t2
	return t2


static func orbital_planet() -> ImageTexture:
	if _cache.has("orbital_planet"):
		return _cache["orbital_planet"]
	var width := 256
	var height := 128
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var bands := [
		[0.0, 0.16, Color("#b8919a")],
		[0.16, 0.24, Color("#d4b2a3")],
		[0.24, 0.43, Color("#755f82")],
		[0.43, 0.51, Color("#d39b83")],
		[0.51, 0.73, Color("#8c718f")],
		[0.73, 0.8, Color("#d5b39a")],
		[0.8, 1.0, Color("#655a7d")],
	]
	for y in height:
		var v := float(y) / height
		var base := Color("#755f82")
		for band in bands:
			if v >= band[0] and v < band[1]:
				base = band[2]
				break
		for x in width:
			var wave := sin(float(x) * 0.075 + sin(v * 18.0) * 2.0) * 0.035
			var storm := exp(-pow((float(x) - 176.0) / 17.0, 2.0) - pow((float(y) - 70.0) / 6.0, 2.0)) * 0.28
			var color := base.lightened(wave + storm)
			img.set_pixel(x, y, color)
	_noise_paint(img, 12.0, 31)
	var texture := _to_tex(img)
	_cache["orbital_planet"] = texture
	return texture


static func checker() -> ImageTexture:
	if _cache.has("checker"):
		return _cache["checker"]
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	for x in 16:
		for y in 4:
			img.fill_rect(Rect2i(x * 8, y * 8, 8, 8), Color("#111111") if (x + y) % 2 == 1 else Color("#f4f4f4"))
	var t := ImageTexture.create_from_image(img)
	_cache["checker"] = t
	return t


static func windows() -> ImageTexture:
	var img := Image.create(64, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color("#0d0b18"))
	var cols := [Color("#ff4bd8"), Color("#38e8ff"), Color("#ffd27a"), Color("#7a6bff")]
	var y := 4
	while y < 128:
		var x := 4
		while x < 64:
			if randf() < 0.32:
				var c: Color = cols[randi() % 4]
				c.a = 0.5 + randf() * 0.5
				_blend(img, x, y, x + 4, y + 5, c)
			x += 8
		y += 8
	return _to_tex(img)


## Tileable value noise for cloud shadows, water and lava (same lattice values as the web build).
static func noise() -> ImageTexture:
	if _cache.has("noise"):
		return _cache["noise"]
	var S := 128
	var G := [8, 16, 32]
	var L: Array = []
	for g in G:
		var r := SeedRng.new(g * 31)
		var arr := PackedFloat32Array()
		arr.resize(g * g)
		for i in g * g:
			arr[i] = r.next()
		L.append(arr)
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in S:
		for x in S:
			var v := 0.0
			var a := 0.55
			for o in 3:
				var n: int = G[o]
				var lat: PackedFloat32Array = L[o]
				var fx := float(x) / S * n
				var fy := float(y) / S * n
				var x0 := int(floor(fx))
				var y0 := int(floor(fy))
				var u := fx - x0
				var w := fy - y0
				var A := lat[(y0 % n) * n + (x0 % n)]
				var B := lat[(y0 % n) * n + ((x0 + 1) % n)]
				var C := lat[((y0 + 1) % n) * n + (x0 % n)]
				var D := lat[((y0 + 1) % n) * n + ((x0 + 1) % n)]
				var su := u * u * (3.0 - 2.0 * u)
				var sw := w * w * (3.0 - 2.0 * w)
				var ab := A + (B - A) * su
				v += (ab + ((C + (D - C) * su) - ab) * sw) * a
				a *= 0.5
			var c := roundf(clampf(v / 0.9625, 0.0, 1.0) * 255.0) / 255.0
			img.set_pixel(x, y, Color(c, c, c, 1.0))
	var t := _to_tex(img)
	_cache["noise"] = t
	return t


static func beam() -> ImageTexture:
	if _cache.has("beam"):
		return _cache["beam"]
	var w := 64
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / h          # 0 at top (far end), 1 at the lamp
		var half := lerpf(0.5, 0.1, t) * w
		var a := 0.95 * t
		for x in w:
			var inside := absf(x + 0.5 - w * 0.5) <= half
			img.set_pixel(x, y, Color(1.0, 246 / 255.0, 224 / 255.0, a if inside else 0.0))
	var tx := _to_tex(img)
	_cache["beam"] = tx
	return tx
