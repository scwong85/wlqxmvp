extends Control
## A chibi character as a control: set `look`, `pose` and `face`; it animates itself. The drawing is delegated to a
## ChibiSkin (the code skin now, sprite sheets later), so every screen that shows a character uses this one node.

const CodeSkin = preload("res://scenes/shared/chibi_code_skin.gd")
const PortraitArt = preload("res://scenes/shared/portrait_art.gd")

var look: Dictionary = {}
var pose: String = "idle"
var face: String = "neutral"
var skin: RefCounted = CodeSkin.new()
var animate: bool = true
var dim: bool = false          # not the speaker: drawn darker
var flip: bool = false         # face left
var sprite: Texture2D = null   # painted full-body figure (when art exists); the code skin draws otherwise
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


## Use the painted full-body figure of `who` ("hero" or a character id), if there is one. Returns whether art was found.
func use_figure(who: String, gender: String = "m") -> bool:
	sprite = PortraitArt.figure_for(who, gender)
	queue_redraw()
	return sprite != null


## A static painted figure, animated from the pose parameters: breathing, bounce, lean, tilt, squash.
func _draw_sprite() -> void:
	var tsz := sprite.get_size()
	var h := size.y * clampf(tsz.y / 940.0, 0.82, 1.0)
	var w := h * tsz.x / tsz.y
	if w > size.x:
		h *= size.x / w
		w = size.x
	var prm: Dictionary = CodeSkin.pose_params(pose, _t if animate else 0.0)
	var sy := 1.0
	var lift := 0.0
	if pose == "kneel":
		sy = 0.86
	elif pose == "idle":
		sy = 1.0 + float(prm.yoff) * 0.9
	else:
		lift = float(prm.yoff) * h * 1.2
	var rot := float(prm.lean) * 0.35 + float(prm.tilt)
	var feet := Vector2(size.x * 0.5, size.y - 3.0)
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, w * 0.36, Color(0, 0, 0, 0.26))
	var xf := Transform2D(rot, Vector2(-1.0 if flip else 1.0, sy), 0.0, feet + Vector2(0, -lift))
	draw_set_transform_matrix(xf)
	draw_texture_rect(sprite, Rect2(-w * 0.5, -h, w, h), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _process(delta: float) -> void:
	if not animate or not is_visible_in_tree():
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return
	modulate = Color(0.62, 0.66, 0.66, 1.0) if dim else Color.WHITE
	if sprite != null:
		_draw_sprite()
		return
	if flip:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	skin.draw(self, Rect2(Vector2.ZERO, size), look, pose, face, _t)
