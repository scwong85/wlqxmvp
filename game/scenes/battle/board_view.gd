extends Control
## Draws the battle board and turns taps into cell coordinates. It never changes the battle.
## Portrait: 6 columns x 8 rows as the rules see it. Landscape: the same board turned a quarter turn
## (screen column = board row, screen row = board column), so the cells keep their meaning.

const PortraitArt = preload("res://scenes/shared/portrait_art.gd")
signal cell_tapped(cell: Vector2i)

const CombatGrid = preload("res://scripts/domain/combat/combat_grid.gd")
const BattleText = preload("res://scenes/battle/battle_text.gd")

var battle: RefCounted = null
var rotated: bool = false              # landscape variant
var move_cells: Dictionary = {}        # cell -> true, shown as walkable
var target_cells: Dictionary = {}      # cell -> true, shown as attackable / supportable
var range_cells: Dictionary = {}       # cell -> true, the technique's reach (dim)
var selected_id: String = ""           # inspected unit
var chosen_target: String = ""         # target waiting for confirmation
var popups: Array = []                 # [{cell, text, color, age}]
var support_mode: bool = false

var _origin := Vector2.ZERO
var _cell := 48.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	custom_minimum_size = Vector2(240, 320)


func _process(delta: float) -> void:
	if popups.is_empty():
		set_process(false)
		return
	for p in popups:
		p.age += delta
	popups = popups.filter(func(p: Dictionary) -> bool: return p.age < 1.1)
	queue_redraw()


func add_popup(cell: Vector2i, text: String, color: Color) -> void:
	popups.append({"cell": cell, "text": text, "color": color, "age": 0.0})
	set_process(true)


func _layout() -> void:
	var cols := CombatGrid.H if rotated else CombatGrid.W
	var rows := CombatGrid.W if rotated else CombatGrid.H
	_cell = floorf(minf(size.x / cols, size.y / rows))
	_origin = Vector2(floorf((size.x - _cell * cols) / 2.0), floorf((size.y - _cell * rows) / 2.0))


func cell_rect(c: Vector2i) -> Rect2:
	_layout()
	var sx := c.y if rotated else c.x
	var sy := c.x if rotated else c.y
	return Rect2(_origin + Vector2(sx, sy) * _cell, Vector2(_cell, _cell))


func cell_center(c: Vector2i) -> Vector2:
	return cell_rect(c).get_center()


func cell_at(p: Vector2) -> Vector2i:
	_layout()
	var q := (p - _origin) / _cell
	var sx := floori(q.x)
	var sy := floori(q.y)
	var c := Vector2i(sy, sx) if rotated else Vector2i(sx, sy)
	return c if CombatGrid.in_bounds(c) and q.x >= 0.0 and q.y >= 0.0 else Vector2i(-1, -1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := cell_at(event.position)
		if CombatGrid.in_bounds(c):
			cell_tapped.emit(c)
			accept_event()


func _draw() -> void:
	if battle == null:
		return
	_layout()
	var font := get_theme_default_font()
	for c in CombatGrid.all_cells():
		var r := cell_rect(c)
		var shade := Color(0.16, 0.12, 0.09, 0.92) if (c.x + c.y) % 2 == 0 else Color(0.20, 0.15, 0.11, 0.92)
		draw_rect(r, shade)
		var terrain: String = battle.grid.terrain_at(c)
		if terrain == "cover":
			draw_rect(r.grow(-_cell * 0.14), Color(0.35, 0.55, 0.38, 0.55))
			for i in 3:
				var x := r.position.x + _cell * (0.28 + 0.22 * i)
				draw_line(Vector2(x, r.position.y + _cell * 0.72), Vector2(x - 4, r.position.y + _cell * 0.4), Color(0.7, 0.9, 0.6, 0.8), 3.0)
		elif terrain == "hazard":
			draw_rect(r.grow(-2), Color(0.85, 0.4, 0.15, 0.35))
			for i in 4:
				var o := _cell * 0.25 * i
				draw_line(r.position + Vector2(o, 0), r.position + Vector2(0, o), Color(1.0, 0.6, 0.2, 0.8), 2.0)
		if range_cells.has(c):
			draw_rect(r, Color(0.9, 0.6, 0.2, 0.18))
		if move_cells.has(c):
			draw_rect(r.grow(-1), Color(0.3, 0.85, 0.7, 0.28))
		if target_cells.has(c):
			draw_rect(r.grow(-1), Color(0.3, 0.9, 0.5, 0.35) if support_mode else Color(0.95, 0.25, 0.2, 0.38))
			draw_rect(r.grow(-2), Color(1, 1, 1, 0.8), false, 2.0)
		draw_rect(r, Color(0.79, 0.64, 0.36, 0.3), false, 1.0)
	var active: RefCounted = battle.active()
	for u in battle.units:
		if not u.alive():
			continue
		_draw_unit(u, font, active == u)
	for p in popups:
		var pos := cell_center(p.cell) + Vector2(-_cell * 0.3, -_cell * 0.35 - 30.0 * p.age)
		var col: Color = p.color
		col.a = clampf(1.4 - p.age, 0.0, 1.0)
		draw_string(font, pos + Vector2(1, 1), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(_cell * 0.42), Color(0, 0, 0, col.a))
		draw_string(font, pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(_cell * 0.42), col)


## Which painted figure stands for an enemy template (round head tokens). Templates not listed keep the diamond.
const TEMPLATE_FIGURE := {"bandit_scout": "bandit", "bandit_brute": "bandit", "bandit_archer": "bandit", "bandit_leader": "leader",
		"villager": "villager", "masked_guard": "mask_hui", "chi_mask": "mask_chi", "xuan_mask": "mask_xuan", "cangwu_senior": "master_gu",
		"guild_enforcer": "guild_master", "dock_thug": "bandit", "hermit_master": "elder"}


func _token_texture(u: RefCounted) -> Texture2D:
	var fid := ""
	if u.id == "hero":
		fid = "hero"
	elif u.team == "player":
		fid = str(u.id)
	else:
		fid = str(TEMPLATE_FIGURE.get(str(u.template), ""))
	if fid == "":
		return null
	var game: Node = Engine.get_main_loop().root.get_node("Game")
	var gender := str(game.state.player.look.get("gender", "m")) if game.state != null else "m"
	return PortraitArt.figure_for(fid, gender)


## A round head-and-shoulders crop of a painted figure.
func _draw_token(center: Vector2, rad: float, tex: Texture2D, tint: Color) -> void:
	var sz := tex.get_size()
	var side := minf(sz.x, sz.y * 0.9)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		var d := Vector2(cos(a), sin(a))
		pts.append(center + d * rad)
		uvs.append(Vector2(((sz.x - side) * 0.5 + (0.5 + d.x * 0.5) * side) / sz.x, ((0.5 + d.y * 0.5) * side) / sz.y))
	draw_colored_polygon(pts, tint, uvs, tex)


func _draw_unit(u: RefCounted, font: Font, is_active: bool) -> void:
	var r := cell_rect(u.pos)
	var center := r.get_center() + Vector2(0, -_cell * 0.06)
	var rad := _cell * 0.31
	var body_col := Color(0.30, 0.78, 0.62) if u.team == "player" else Color(0.82, 0.36, 0.30)
	if u.npc:
		body_col = Color(0.85, 0.78, 0.45)
	if u.broken:
		body_col = body_col.darkened(0.45)
	var token: Texture2D = _token_texture(u)
	if token != null:
		draw_circle(center, rad * 1.14, body_col)   # team-coloured rim
		_draw_token(center, rad, token, Color(0.55, 0.55, 0.55) if u.broken else Color.WHITE)
	elif u.team == "player":
		draw_circle(center, rad, body_col)
	else:
		var pts := PackedVector2Array([center + Vector2(0, -rad * 1.1), center + Vector2(rad * 1.1, 0), center + Vector2(0, rad * 1.1), center + Vector2(-rad * 1.1, 0)])
		draw_colored_polygon(pts, body_col)
	if is_active:
		draw_arc(center, rad * 1.28, 0, TAU, 32, Color(1.0, 0.9, 0.4), 3.0)
	if selected_id == u.id:
		draw_rect(r.grow(-2), Color(0.6, 0.9, 1.0), false, 3.0)
	if chosen_target == u.id:
		draw_rect(r.grow(-2), Color(1.0, 0.85, 0.3), false, 4.0)
	if u.guarding:
		draw_arc(center, rad * 1.1, -2.2, -0.9, 10, Color(0.8, 0.95, 1.0), 4.0)
	if token == null:
		var glyph: String = Loc.t(u.name_key).substr(0, 1)
		var fs := int(_cell * 0.38)
		var gs := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, center + Vector2(-gs.x / 2.0, fs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.04, 0.12, 0.11))
	# bars: hp (green) and resolve (amber)
	var bw := _cell * 0.78
	var bx := r.position.x + (_cell - bw) / 2.0
	var by := r.position.y + _cell * 0.84
	draw_rect(Rect2(bx, by, bw, 5), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(bx, by, bw * float(u.hp) / float(u.max_hp), 5), Color(0.35, 0.9, 0.45))
	draw_rect(Rect2(bx, by + 6, bw, 3), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(bx, by + 6, bw * float(u.resolve) / float(u.max_resolve), 3), Color(0.95, 0.75, 0.25))
	# status dots
	var i := 0
	for s in u.statuses:
		var col := Color(0.9, 0.2, 0.2) if s.id == "bleed" else Color(0.35, 0.6, 1.0) if s.id == "slow" else Color(0.75, 0.45, 0.95)
		draw_circle(r.position + Vector2(_cell * 0.14 + i * _cell * 0.17, _cell * 0.13), _cell * 0.065, col)
		i += 1
	if u.broken:
		draw_string(font, r.position + Vector2(_cell * 0.62, _cell * 0.24), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(_cell * 0.34), Color(1.0, 0.85, 0.2))
