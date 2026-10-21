class_name SeedRng
extends RefCounted
## Bit-exact ports of the web build's hashStr (cyrb-style) and mulberry32, so a seed string produces the same
## random sequence — and therefore the same track — in both versions.

const M32 := 0xFFFFFFFF

var a: int = 0


func _init(state: int = 0) -> void:
	a = state & M32


static func from_seed(s: String) -> SeedRng:
	return SeedRng.new(hash_str(s))


## 32-bit multiply keeping the low 32 bits (Math.imul on unsigned representations)
static func imul(x: int, y: int) -> int:
	x &= M32
	y &= M32
	var lo := (x * (y & 0xFFFF)) & M32
	var hi := ((x * (y >> 16)) & 0xFFFF) << 16
	return (lo + hi) & M32


static func hash_str(s: String) -> int:
	var h := (1779033703 ^ s.length()) & M32
	for i in s.length():
		h = imul(h ^ s.unicode_at(i), 3432918353)
		h = ((h << 13) | (h >> 19)) & M32
	h = imul(h ^ (h >> 16), 2246822507)
	h = imul(h ^ (h >> 13), 3266489909)
	return (h ^ (h >> 16)) & M32


## next float in [0,1)
func next() -> float:
	a = (a + 0x6D2B79F5) & M32
	var t := imul(a ^ (a >> 15), 1 | a)
	t = (((t + imul(t ^ (t >> 7), 61 | t)) & M32) ^ t) & M32
	return float((t ^ (t >> 14)) & M32) / 4294967296.0
