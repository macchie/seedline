class_name Glass
extends MarginContainer
## Rounded panel drawn by glass.gdshader; children are laid out inside its margins.

var radius := Vector4(12, 12, 12, 12)
var fill_top := Color(0, 0, 0, 0)
var fill_bot := Color(0, 0, 0, 0)
var border_col := Color(0, 0, 0, 0)
var border_w := 0.0
var blur := 0.0
var dash := 0.0
var inset_col := Color(0, 0, 0, 0)
var inset_h := 0.0
var _mat: ShaderMaterial

static var _shader: Shader


func _init() -> void:
	if _shader == null:
		_shader = load("res://shaders/glass.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	material = _mat
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_sync)


func style(fill: Color, border: Color = Color(0, 0, 0, 0), r: float = 12.0, bw: float = 1.0, blur_lvl: float = 0.0) -> Glass:
	fill_top = fill
	fill_bot = fill
	border_col = border
	border_w = bw if border.a > 0.0 else 0.0
	radius = Vector4(r, r, r, r)
	blur = blur_lvl
	_sync()
	return self


func pad(l: float, t: float, r: float, b: float) -> Glass:
	add_theme_constant_override("margin_left", int(l))
	add_theme_constant_override("margin_top", int(t))
	add_theme_constant_override("margin_right", int(r))
	add_theme_constant_override("margin_bottom", int(b))
	return self


func _sync() -> void:
	_mat.set_shader_parameter("rect_size", size)
	_mat.set_shader_parameter("radius", radius)
	_mat.set_shader_parameter("fill_top", fill_top)
	_mat.set_shader_parameter("fill_bot", fill_bot)
	_mat.set_shader_parameter("border_col", border_col)
	_mat.set_shader_parameter("border_w", border_w)
	_mat.set_shader_parameter("blur", blur if Ui.blur_ok else 0.0)
	_mat.set_shader_parameter("dash", dash)
	_mat.set_shader_parameter("inset_col", inset_col)
	_mat.set_shader_parameter("inset_h", inset_h)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
