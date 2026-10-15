extends Control
## A chibi character as a control: set `look`, `pose` and `face`; it animates itself. The drawing is delegated to a
## ChibiSkin (the code skin now, sprite sheets later), so every screen that shows a character uses this one node.

const CodeSkin = preload("res://scenes/shared/chibi_code_skin.gd")

var look: Dictionary = {}
var pose: String = "idle"
var face: String = "neutral"
var skin: RefCounted = CodeSkin.new()
var animate: bool = true
var dim: bool = false          # not the speaker: drawn darker
var flip: bool = false         # face left
var _t: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func setup(new_look: Dictionary, new_pose: String = "idle", new_face: String = "neutral") -> void:
	look = new_look
	pose = new_pose
	face = new_face
	queue_redraw()


func _process(delta: float) -> void:
	if not animate or not is_visible_in_tree():
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return
	modulate = Color(0.62, 0.66, 0.66, 1.0) if dim else Color.WHITE
	if flip:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	skin.draw(self, Rect2(Vector2.ZERO, size), look, pose, face, _t)
