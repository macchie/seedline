class_name UiFonts
## The web build's three families: Saira (body), Saira Condensed (display, slanted for the italic cuts) and
## JetBrains Mono (numbers and seeds). Symbol glyphs the subsets lack come from two tiny Noto fallbacks.

static var _files := {}
static var _vars := {}


static func _file(name: String) -> FontFile:
	if not _files.has(name):
		var f: FontFile = load("res://fonts/%s.ttf" % name)
		f.fallbacks = [load("res://fonts/NotoSansSymbols2-Subset.ttf"), load("res://fonts/NotoSansMath-Subset.ttf")]
		_files[name] = f
	return _files[name]


## family: "body" | "display" | "mono"; weight like CSS; italic slants the outline; spacing in pixels between glyphs
static func get_font(family: String, weight: int = 400, italic: bool = false, spacing: int = 0) -> Font:
	var key := "%s|%d|%s|%d" % [family, weight, italic, spacing]
	if _vars.has(key):
		return _vars[key]
	var file := ""
	match family:
		"display":
			file = "SairaCondensed-ExtraBold" if weight >= 700 else "SairaCondensed-SemiBold"
		"mono":
			file = "JetBrainsMono-Bold" if weight >= 600 else "JetBrainsMono-Medium"
		_:
			file = "Saira-SemiBold" if weight >= 600 else ("Saira-Medium" if weight >= 500 else "Saira-Regular")
	var v := FontVariation.new()
	v.base_font = _file(file)
	if italic:
		v.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	v.spacing_glyph = spacing
	_vars[key] = v
	return v


static func sign_font() -> Font:
	return get_font("display", 800, true)
