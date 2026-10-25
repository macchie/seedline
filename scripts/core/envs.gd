class_name Envs
## The sixteen worlds. Colours are 0xRRGGBB display values.

const NIGHT_ENABLED := false  # night mode is built but switched off for now

const KEYS := ["CANYON", "ALPINE", "NEON", "GROVE", "ISLAND", "COUNTRY", "VOLCANO", "GREECE", "TOWN", "WETLANDS", "HARBOR", "SALTFLATS", "NOCTURNE", "DUSKMESA", "SKYWAY", "GRID"]

const DATA := {
	"CANYON": {"name": "Canyon", "accent": "#ff9a3c", "onAccent": "#160b02", "fog": 0xe8ad7c, "fogNear": 130.0, "fogFar": 380.0, "hemiS": 0xffe0bd, "hemiG": 0x8a4a2a, "hemiI": 0.85, "sun": 0xffe6c4, "sunI": 1.2, "sunDir": [-0.8, 1.0, 0.55],
		"gLow": 0xe09c5e, "gHigh": 0xb35a33, "shoulder": 0xc48d58, "road": "#4b403b", "edge": "rgba(245,236,224,.9)", "dash": "rgba(245,226,190,.75)", "curbA": 0xd8352c, "curbB": 0xf3ebe0,
		"amp": 30.0, "terrace": true, "weather": "dust", "grip": 1.0, "smoke": 0xe9c49b, "grade": {"tint": [1.03, 0.98, 0.94], "sat": 1.04, "cloud": 0.3}, "birds": [6, 0x3a2a24],
		"river": true, "riverCol": 0x3f9fb0, "words": [["Ember", "Rust", "Sunfall", "Copper", "Scorch", "Red Rock", "Saltpan", "Vulture"], ["Ridge", "Gulch", "Pass", "Basin", "Wash", "Mesa", "Draw", "Flats"]]},
	"ALPINE": {"name": "Alpine", "accent": "#7fd6ff", "onAccent": "#04131c", "fog": 0xd3e0ec, "fogNear": 110.0, "fogFar": 340.0, "hemiS": 0xeaf3ff, "hemiG": 0x8796aa, "hemiI": 0.9, "sun": 0xffffff, "sunI": 0.95, "sunDir": [0.6, 1.0, 0.35],
		"gLow": 0xf4f7fb, "gHigh": 0xb3c0cd, "shoulder": 0xe1e8ef, "road": "#343a43", "edge": "rgba(240,246,252,.9)", "dash": "rgba(255,214,90,.8)", "curbA": 0x2f6bd9, "curbB": 0xf2f6fa,
		"amp": 34.0, "weather": "snow", "grip": 0.86, "smoke": 0xf4f8fc, "grade": {"tint": [0.97, 1.0, 1.05], "sat": 1.06, "cloud": 0.24}, "birds": [4, 0x2a2f3a],
		"river": true, "riverCol": 0x7cc6df, "words": [["Frost", "Glacier", "Whiteout", "Summit", "Cold", "Avalanche", "Edelweiss", "Spruce"], ["Col", "Ridge", "Hollow", "Bend", "Descent", "Traverse", "Couloir", "Pass"]]},
	"NEON": {"name": "Neon", "accent": "#ff4bd8", "onAccent": "#1a0216", "fog": 0x241a4a, "fogNear": 120.0, "fogFar": 320.0, "hemiS": 0x9a8cff, "hemiG": 0x3c2c6e, "hemiI": 1.15, "sun": 0xc9d4ff, "sunI": 0.75, "sunDir": [0.4, 1.0, -0.6],
		"gLow": 0x2a2250, "gHigh": 0x2a2250, "shoulder": 0x221c44, "road": "#2d2a4a", "edge": "rgba(120,240,255,.95)", "dash": "rgba(255,90,220,.8)", "curbA": 0xff2bd6, "curbB": 0x22e5ff,
		"amp": 0.0, "weather": "drizzle", "grip": 0.95, "smoke": 0xa79bd6, "night": true, "lights": 1.0, "grade": {"tint": [1.02, 0.97, 1.1], "sat": 1.22, "cloud": 0.0, "vig": 0.5},
		"words": [["Chrome", "Pulse", "Midnight", "Static", "Ultra", "Synth", "Vapor", "Kilowatt"], ["Avenue", "Grid", "Strip", "Interchange", "Boulevard", "Underpass", "Arcade", "Loop"]]},
	"GROVE": {"name": "Grove", "accent": "#c6e35a", "onAccent": "#121a02", "fog": 0x8a9a80, "fogNear": 100.0, "fogFar": 300.0, "hemiS": 0xd8e2cf, "hemiG": 0x44542f, "hemiI": 0.95, "sun": 0xfff0d6, "sunI": 0.8, "sunDir": [-0.5, 1.0, -0.4],
		"gLow": 0x6a8c40, "gHigh": 0x46632d, "shoulder": 0x7a6448, "road": "#2c302f", "edge": "rgba(238,233,220,.85)", "dash": "rgba(240,200,80,.7)", "curbA": 0xe2ad37, "curbB": 0xf1ece0,
		"amp": 16.0, "weather": "rain", "grip": 0.9, "smoke": 0xb9bfb3, "lights": 0.25, "grade": {"tint": [0.98, 1.02, 0.95], "sat": 1.1, "cloud": 0.4}, "birds": [8, 0x1e1f22],
		"river": true, "riverCol": 0x4a8c8a, "words": [["Moss", "Amber", "Fern", "Rainy", "Oak", "Mist", "Bramble", "Willow"], ["Lane", "Woods", "Trail", "Glade", "Circuit", "Run", "Hollow", "Copse"]]},
	"ISLAND": {"name": "Island", "accent": "#2ee6c8", "onAccent": "#03201b", "fog": 0xb3e3ec, "fogNear": 130.0, "fogFar": 400.0, "hemiS": 0xeaf9ff, "hemiG": 0x4aa3ab, "hemiI": 0.9, "sun": 0xfff1d6, "sunI": 1.1, "sunDir": [-0.6, 1.0, 0.45],
		"gLow": 0xdcc590, "gHigh": 0x5e9a42, "shoulder": 0xd8c48e, "road": "#3b3e44", "edge": "rgba(250,248,240,.92)", "dash": "rgba(255,214,90,.8)", "curbA": 0x15a8a2, "curbB": 0xf6f2e8,
		"amp": 1.0, "shore": true, "weather": "none", "grip": 0.95, "smoke": 0xf1e3bd, "deep": 0x0e5f73, "grade": {"tint": [0.98, 1.0, 1.01], "sat": 1.04, "cloud": 0.28}, "birds": [12, 0xf4f4f4],
		"words": [["Coral", "Lagoon", "Palm", "Reef", "Tide", "Saltwind", "Mango", "Driftwood"], ["Bay", "Key", "Atoll", "Shore", "Strait", "Point", "Cove", "Reach"]]},
	"COUNTRY": {"name": "Countryside", "accent": "#ffcf3a", "onAccent": "#1d1500", "fog": 0xcfe3ef, "fogNear": 140.0, "fogFar": 420.0, "hemiS": 0xf2f7ff, "hemiG": 0x6b8a3a, "hemiI": 0.9, "sun": 0xfff3d9, "sunI": 1.15, "sunDir": [-0.5, 1.0, 0.6],
		"gLow": 0x7cb048, "gHigh": 0x568c35, "shoulder": 0xc7b58a, "road": "#3d4047", "edge": "rgba(250,248,240,.92)", "dash": "rgba(250,248,240,.85)", "curbA": 0xe8452c, "curbB": 0xf6f2e8,
		"amp": 10.0, "fields": true, "weather": "none", "grip": 1.0, "smoke": 0xe3dccb, "grade": {"tint": [1.0, 1.0, 0.97], "sat": 1.02, "cloud": 0.38}, "birds": [14, 0x24262b],
		"river": true, "riverCol": 0x3f9fc0, "words": [["Meadow", "Harvest", "Clover", "Hay", "Sunny", "Barley", "Orchard", "Windmill"], ["Lane", "Farm", "Fields", "Hill", "Dale", "Acres", "Way", "Green"]]},
	"VOLCANO": {"name": "Volcano", "accent": "#ff6a1f", "onAccent": "#1f0800", "fog": 0x4a3030, "fogNear": 110.0, "fogFar": 320.0, "hemiS": 0xffb592, "hemiG": 0x6a2412, "hemiI": 0.95, "sun": 0xffc9a0, "sunI": 0.85, "sunDir": [0.5, 1.0, 0.3],
		"gLow": 0x4a4140, "gHigh": 0x2c2726, "shoulder": 0x3a3332, "road": "#2a2627", "edge": "rgba(255,200,160,.85)", "dash": "rgba(255,120,40,.85)", "curbA": 0xff5a1f, "curbB": 0x2b2523,
		"amp": 1.0, "shore": true, "lava": true, "weather": "embers", "grip": 0.97, "smoke": 0x8c7f7a, "lights": 0.6, "grade": {"tint": [1.08, 0.96, 0.9], "sat": 1.1, "cloud": 0.18, "vig": 0.48},
		"words": [["Magma", "Obsidian", "Cinder", "Ember", "Ashen", "Basalt", "Inferno", "Sulfur"], ["Caldera", "Rift", "Crater", "Flow", "Vent", "Spire", "Trench", "Pass"]]},
	"GREECE": {"name": "Ancient Greece", "accent": "#2f6bd9", "onAccent": "#ffffff", "fog": 0xd8e6ee, "fogNear": 140.0, "fogFar": 420.0, "hemiS": 0xfff6e6, "hemiG": 0x9a8a6a, "hemiI": 0.9, "sun": 0xfff1d8, "sunI": 1.2, "sunDir": [-0.6, 1.0, 0.5],
		"gLow": 0xc4b088, "gHigh": 0x8a9858, "shoulder": 0xdcd0b4, "road": "#4d4944", "edge": "rgba(250,248,240,.92)", "dash": "rgba(250,248,240,.8)", "curbA": 0x2f6bd9, "curbB": 0xf6f2e8,
		"amp": 1.0, "shore": true, "weather": "none", "grip": 0.98, "smoke": 0xe8dcc0, "deep": 0x0e5a86, "grade": {"tint": [1.03, 1.0, 0.96], "sat": 1.06, "cloud": 0.22}, "birds": [10, 0xf4f4f4],
		"words": [["Olympus", "Athena", "Delphi", "Marble", "Apollo", "Sparta", "Aegean", "Ionian"], ["Agora", "Acropolis", "Stadion", "Temple", "Strait", "Harbor", "Theatre", "Way"]]},
	"TOWN": {"name": "Old Town", "accent": "#ff7a59", "onAccent": "#200a04", "fog": 0xf2c9a0, "fogNear": 130.0, "fogFar": 400.0, "hemiS": 0xffe4c8, "hemiG": 0x6a5a7a, "hemiI": 0.9, "sun": 0xffc88e, "sunI": 1.2, "sunDir": [-0.9, 0.75, 0.35],
		"gLow": 0x6f9e4b, "gHigh": 0x5c8a40, "shoulder": 0xcfc8bc, "road": "#454850", "edge": "rgba(250,246,236,.9)", "dash": "rgba(250,246,236,.8)", "curbA": 0xd8453a, "curbB": 0xf6f2e8,
		"amp": 4.0, "weather": "none", "grip": 1.0, "smoke": 0xd9d2c8, "lights": 0.45, "grade": {"tint": [1.03, 0.99, 0.95], "sat": 1.02, "cloud": 0.24}, "birds": [10, 0x5a5d66],
		"river": true, "riverCol": 0x3f8aa8, "words": [["Market", "Bell", "Cobble", "Harbor", "Clock", "Bakery", "Maple", "Lantern"], ["Street", "Square", "Row", "Corner", "Quarter", "Lane", "Parade", "Circus"]]},
	"WETLANDS": {"name": "Wetlands", "accent": "#76d6a0", "onAccent": "#07170f", "fog": 0x9bb4a7, "fogNear": 80.0, "fogFar": 245.0, "hemiS": 0xd7e8dc, "hemiG": 0x354d40, "hemiI": 0.82, "sun": 0xffe3b5, "sunI": 0.82, "sunDir": [-0.4, 1.0, 0.2],
		"gLow": 0x596f46, "gHigh": 0x344b38, "shoulder": 0x77745a, "road": "#343c3a", "edge": "rgba(219,232,215,.9)", "dash": "rgba(224,212,150,.75)", "curbA": 0x6d9472, "curbB": 0xd9ddc9,
		"amp": 1.0, "shore": true, "deep": 0x173e43, "river": true, "riverCol": 0x315e59, "weather": "rain", "grip": 0.91, "smoke": 0xc1d0c4, "lights": 0.18, "grade": {"tint": [0.95, 1.02, 0.94], "sat": 0.92, "cloud": 0.55}, "birds": [8, 0xc6d2c5],
		"words": [["Cypress", "Mire", "Heron", "Moss", "Willow", "Blackwater", "Reed", "Gator"], ["Bend", "Marsh", "Run", "Slough", "Landing", "Fen", "Reach", "Bayou"]]},
	"HARBOR": {"name": "Harbor", "accent": "#66c8df", "onAccent": "#06151a", "fog": 0xa6c5cf, "fogNear": 115.0, "fogFar": 350.0, "hemiS": 0xe5f0f2, "hemiG": 0x536d75, "hemiI": 0.9, "sun": 0xffe4c2, "sunI": 0.92, "sunDir": [-0.7, 1.0, 0.35],
		"gLow": 0x737c79, "gHigh": 0x596c70, "shoulder": 0x8f8778, "road": "#3d4549", "edge": "rgba(231,239,233,.9)", "dash": "rgba(248,205,112,.8)", "curbA": 0xd65c45, "curbB": 0xe9e3d4,
		"amp": 1.0, "shore": true, "deep": 0x174858, "weather": "drizzle", "grip": 0.94, "smoke": 0xc5cecc, "lights": 0.35, "grade": {"tint": [0.97, 1.01, 1.03], "sat": 0.96, "cloud": 0.38}, "birds": [10, 0xe3e7df],
		"words": [["Cargo", "Beacon", "Anchor", "Trawler", "Quay", "Signal", "Foghorn", "Freight"], ["Terminal", "Docks", "Pier", "Channel", "Yard", "Breakwater", "Jetty", "Port"]]},
	"SALTFLATS": {"name": "Salt Flats", "accent": "#e8d8a2", "onAccent": "#211b0b", "fog": 0xe5ddca, "fogNear": 155.0, "fogFar": 460.0, "hemiS": 0xfff8e9, "hemiG": 0x8e8877, "hemiI": 0.86, "sun": 0xfff0cf, "sunI": 1.28, "sunDir": [-0.55, 1.0, 0.25],
		"gLow": 0xd9d0bc, "gHigh": 0xf1e9d6, "shoulder": 0xbeb49e, "road": "#555451", "edge": "rgba(255,250,235,.95)", "dash": "rgba(255,224,150,.8)", "curbA": 0xc4a66a, "curbB": 0xf5eedc,
		"amp": 0.35, "salt": true, "weather": "dust", "grip": 0.99, "smoke": 0xd8cfbd, "grade": {"tint": [1.05, 1.01, 0.94], "sat": 0.72, "cloud": 0.3}, "birds": [3, 0x77746d],
		"words": [["White", "Mirage", "Alkali", "Prism", "Dry", "Solar", "Glass", "Brine"], ["Pan", "Horizon", "Basin", "Mirror", "Expanse", "Crust", "Reach", "Run"]]},
	"NOCTURNE": {"name": "Nocturne Bloom", "accent": "#ff4bd8", "onAccent": "#1a0216", "fog": 0x0c1a22, "fogNear": 85.0, "fogFar": 300.0, "hemiS": 0x2b3b60, "hemiG": 0x0c1a14, "hemiI": 0.7, "sun": 0x7e8cd6, "sunI": 0.45, "sunDir": [-0.4, 1.0, -0.3],
		"gLow": 0x16301f, "gHigh": 0x0d1d15, "shoulder": 0x13241b, "road": "#1a1f24", "edge": "rgba(120,240,255,.95)", "dash": "rgba(255,90,220,.8)", "curbA": 0xff2bd6, "curbB": 0x22e5ff,
		"amp": 16.0, "weather": "rain", "grip": 0.9, "smoke": 0x6a8c9a, "lights": 0.85, "grade": {"tint": [1.02, 0.97, 1.12], "sat": 1.26, "cloud": 0.35, "vig": 0.5}, "birds": [6, 0x2ee6c8],
		"river": true, "riverCol": 0x1fd6c0, "words": [["Lumen", "Glow", "Spore", "Hollow", "Dusk", "Violet", "Firefly", "Moonlit"], ["Grove", "Thicket", "Hollow", "Canopy", "Mire", "Bloom", "Glade", "Run"]]},
	"DUSKMESA": {"name": "Dusk Mesa", "accent": "#ff7ab8", "onAccent": "#1a0410", "fog": 0x6a3a7a, "fogNear": 140.0, "fogFar": 440.0, "hemiS": 0xffb0d8, "hemiG": 0x5a3a6a, "hemiI": 0.95, "sun": 0xffc07a, "sunI": 1.1, "sunDir": [-0.9, 0.5, 0.3],
		"gLow": 0x9a5a7a, "gHigh": 0x6a3a64, "shoulder": 0x8a5a6a, "road": "#3a2a3a", "edge": "rgba(255,220,240,.9)", "dash": "rgba(255,180,90,.85)", "curbA": 0xff5a9a, "curbB": 0xffd0e4,
		"amp": 22.0, "terrace": true, "weather": "dust", "grip": 0.98, "smoke": 0xd8a0c0, "grade": {"tint": [1.08, 0.95, 1.08], "sat": 1.18, "cloud": 0.2, "vig": 0.42}, "birds": [5, 0x3a2030],
		"words": [["Vapor", "Neon", "Sunset", "Mirage", "Violet", "Afterglow", "Dusk", "Magenta"], ["Mesa", "Bluff", "Butte", "Draw", "Rise", "Flats", "Pass", "Horizon"]]},
	"SKYWAY": {"name": "Skyway", "accent": "#a9c7ff", "onAccent": "#0a1420", "fog": 0xcfe0ff, "fogNear": 120.0, "fogFar": 380.0, "hemiS": 0xfff0f8, "hemiG": 0xcdd8ff, "hemiI": 1.0, "sun": 0xffffff, "sunI": 1.1, "sunDir": [-0.5, 1.0, 0.4],
		"gLow": 0xeef2ff, "gHigh": 0xffffff, "shoulder": 0xdfe6ff, "road": "#3a4258", "edge": "rgba(255,255,255,.95)", "dash": "rgba(170,200,255,.85)", "curbA": 0x7aa0ff, "curbB": 0xffffff,
		"amp": 0.0, "weather": "none", "grip": 0.96, "smoke": 0xeaf0ff, "grade": {"tint": [1.0, 1.0, 1.03], "sat": 1.03, "cloud": 0.5, "vig": 0.0}, "birds": [12, 0xffffff],
		"words": [["Cirrus", "Zephyr", "Halo", "Cloud", "Aether", "Skybound", "Drift", "Celestial"], ["Span", "Causeway", "Terrace", "Reach", "Viaduct", "Arc", "Way", "Heights"]]},
	"GRID": {"name": "Grid", "accent": "#22e5ff", "onAccent": "#02121a", "fog": 0x05060c, "fogNear": 95.0, "fogFar": 360.0, "hemiS": 0x0a1830, "hemiG": 0x02040a, "hemiI": 0.6, "sun": 0x6aa0ff, "sunI": 0.3, "sunDir": [0.3, 1.0, -0.4],
		"gLow": 0x05060e, "gHigh": 0x070a16, "shoulder": 0x0a1018, "road": "#0a0f1a", "edge": "rgba(34,229,255,.95)", "dash": "rgba(255,106,31,.85)", "curbA": 0x22e5ff, "curbB": 0xff6a1f,
		"amp": 0.0, "night": true, "grid": true, "lights": 1.0, "weather": "none", "grip": 1.0, "smoke": 0x3a6a8a, "grade": {"tint": [0.98, 1.0, 1.12], "sat": 1.3, "cloud": 0.0, "vig": 0.6},
		"words": [["Vector", "Cyan", "Lightcycle", "Zero", "Binary", "Neon", "Circuit", "Null"], ["Grid", "Sector", "Node", "Array", "Runtime", "Loop", "Vector", "Void"]]},
}


static func g(e: Dictionary, k: String, d = null):
	return e[k] if e.has(k) else d


static func is_night_seed(seed: String) -> bool:
	return NIGHT_ENABLED and SeedRng.hash_str(seed + "|tod") % 100 < 38


## Day/dusk/night variant of a world (Neon's other mode is a violet dusk)
static func variant(key: String, night: bool) -> Dictionary:
	var base: Dictionary = DATA[key]
	var e := base.duplicate(true)
	e["key"] = key
	if base.get("night", false):
		if night:
			e["dark"] = true
			e["tod"] = "Night"
		elif key == "NEON":
			# Neon's day-cycle mode is a violet dusk (overrides its own night palette)
			e["tod"] = "Dusk"
			e["dark"] = false
			e["fog"] = 0x8a6cc0
			e["hemiS"] = 0xffd2ec
			e["hemiG"] = 0x5a3c8c
			e["hemiI"] = 1.25
			e["sun"] = 0xffb59a
			e["sunI"] = 1.1
			e["gLow"] = 0x3a2f6a
			e["gHigh"] = 0x3a2f6a
			e["shoulder"] = 0x30285a
			e["grade"] = {"tint": [1.04, 0.98, 1.04], "sat": 1.15, "cloud": 0.12, "vig": 0.42}
		else:
			# other night worlds render their own palette as a permanent night
			e["dark"] = true
			e["tod"] = "Night"
		return e
	if not night:
		e["dark"] = false
		e["tod"] = "Day"
		return e
	var gr: Dictionary = base.get("grade", {})
	var f := U.hexc(base["fog"]).lerp(U.hexc(0x0a0f24), 0.84)
	e["tod"] = "Night"
	e["dark"] = true
	e["fog"] = f.to_rgba32() >> 8
	e["fogNear"] = base["fogNear"] * 0.9
	e["fogFar"] = base["fogFar"] * 0.92
	e["hemiS"] = 0x5a6cb8
	var hg := U.hexc(base["hemiG"]) * 0.25
	e["hemiG"] = Color(hg.r, hg.g, hg.b, 1.0).to_rgba32() >> 8
	e["hemiI"] = 0.52
	e["sun"] = 0x9fb6ff
	e["sunI"] = 0.55
	e["grade"] = {"tint": [0.9, 0.96, 1.14], "sat": gr.get("sat", 1.1) * 0.92, "cloud": gr.get("cloud", 0.0) * 0.35, "vig": 0.5}
	return e
