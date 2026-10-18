extends StyleBox
## A scroll-like panel box: ink-brown ground with a faint paper grain, a gold outer line, a fine inner line and small
## gold studs at the corners. Drawn with plain rectangles so it scales to any size and costs nothing to ship.

const TILE := 256.0

var bg: Color = Color(0.10, 0.07, 0.05, 0.88)
var line: Color = Color("c9a45c")
var inner_line: Color = Color(0.79, 0.64, 0.36, 0.45)
var weight: float = 2.0
var gap: float = 5.0
var studs: bool = true
var paper: Texture2D = null
var paper_tint: Color = Color(0.34, 0.27, 0.19, 0.5)


func _draw(item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	rs.canvas_item_add_rect(item, rect, bg)
	if paper != null:
		var tsz := paper.get_size()
		var y := rect.position.y
		while y < rect.end.y - 0.5:
			var th := minf(TILE, rect.end.y - y)
			var x := rect.position.x
			while x < rect.end.x - 0.5:
				var tw := minf(TILE, rect.end.x - x)
				rs.canvas_item_add_texture_rect_region(item, Rect2(x, y, tw, th), paper.get_rid(),
						Rect2(0, 0, tw / TILE * tsz.x, th / TILE * tsz.y), paper_tint)
				x += TILE
			y += TILE
	_outline(item, rect, weight, line)
	if gap > 0.0 and rect.size.x > gap * 4.0 and rect.size.y > gap * 4.0:
		_outline(item, rect.grow(-gap - weight), 1.0, inner_line)
	if studs and rect.size.x > 40.0 and rect.size.y > 40.0:
		var s := weight * 3.0
		for c in [rect.position, Vector2(rect.end.x - s, rect.position.y), Vector2(rect.position.x, rect.end.y - s), rect.end - Vector2(s, s)]:
			rs.canvas_item_add_rect(item, Rect2(c, Vector2(s, s)), line)


func _outline(item: RID, r: Rect2, w: float, c: Color) -> void:
	var rs := RenderingServer
	rs.canvas_item_add_rect(item, Rect2(r.position, Vector2(r.size.x, w)), c)
	rs.canvas_item_add_rect(item, Rect2(Vector2(r.position.x, r.end.y - w), Vector2(r.size.x, w)), c)
	rs.canvas_item_add_rect(item, Rect2(r.position, Vector2(w, r.size.y)), c)
	rs.canvas_item_add_rect(item, Rect2(Vector2(r.end.x - w, r.position.y), Vector2(w, r.size.y)), c)
