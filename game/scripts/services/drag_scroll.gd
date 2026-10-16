extends Node
## Touch / mouse drag scrolling for every vertical ScrollContainer (autoload).
## A finger or mouse drag that starts anywhere inside a scrollable list (also on a button) scrolls it; a plain tap
## still presses the button. After the drag the list keeps a little momentum. The mouse wheel is untouched.

const THRESHOLD := 12.0
const FRICTION := 4.0

var enabled: bool = true
var _scrolls: Array = []
var _target: ScrollContainer = null
var _start: Vector2 = Vector2.ZERO
var _last: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _held_button: BaseButton = null
var _velocity: float = 0.0
var _remainder: float = 0.0
var _coast: ScrollContainer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(n: Node) -> void:
	if n is ScrollContainer:
		_scrolls.append(n)
		n.tree_exiting.connect(_forget.bind(n))


func _forget(n: Node) -> void:
	_scrolls.erase(n)
	if _target == n:
		_reset()
	if _coast == n:
		_coast = null


func _reset() -> void:
	_release_button()
	_target = null
	_dragging = false


func _release_button() -> void:
	if _held_button != null and is_instance_valid(_held_button):
		_held_button.disabled = false
	_held_button = null


## The innermost visible, scrollable list under a point (None if there is none).
func scroll_at(pos: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	for s in _scrolls:
		var sc: ScrollContainer = s
		if not is_instance_valid(sc) or not sc.is_visible_in_tree() or sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
			continue
		if not sc.get_global_rect().has_point(pos):
			continue
		var bar := sc.get_v_scroll_bar()
		if bar.max_value - bar.page <= 1.0:
			continue
		if best == null or best.is_ancestor_of(sc):
			best = sc
	return best


func _input(event: InputEvent) -> void:
	if enabled:
		handle(event)


## Returns true when the event was part of a scroll drag (and so was swallowed).
func handle(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return _press(event.pressed, event.position)
	if event is InputEventScreenDrag:
		return _move(event.position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return _dragging  # the touch itself is handled above
		return _press(event.pressed, event.position)
	if event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return _dragging
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			return _move(event.position)
	return false


func _press(pressed: bool, pos: Vector2) -> bool:
	if pressed:
		_coast = null
		_velocity = 0.0
		_remainder = 0.0
		_target = scroll_at(pos)
		_start = pos
		_last = pos
		_dragging = false
		return false
	var was := _dragging
	if was and _target != null:
		_coast = _target
	_reset()
	if was:
		_swallow()
	return was


func _move(pos: Vector2) -> bool:
	if _target == null:
		return false
	if not _dragging:
		var d := pos - _start
		if d.length() < THRESHOLD or absf(d.y) < absf(d.x):
			return false
		_dragging = true
		_cancel_press(_start)
	var dy := pos.y - _last.y
	_last = pos
	_scroll_by(_target, -dy)
	_velocity = lerpf(_velocity, -dy / maxf(get_process_delta_time(), 0.001), 0.4)
	_swallow()
	return true


## Moves the list; a fraction of a pixel is kept for the next call.
func _scroll_by(sc: ScrollContainer, amount: float) -> void:
	_remainder += amount
	var whole := int(_remainder)
	_remainder -= whole
	sc.scroll_vertical += whole


## A button that was pressed when the drag began must not fire when the finger lifts.
func _cancel_press(pos: Vector2) -> void:
	_release_button()
	var hit := _button_at(_target, pos)
	if hit != null:
		_held_button = hit
		hit.disabled = true


func _button_at(node: Node, pos: Vector2) -> BaseButton:
	for c in node.get_children():
		var found := _button_at(c, pos)
		if found != null:
			return found
	if node is BaseButton and node.is_visible_in_tree() and (node as Control).get_global_rect().has_point(pos):
		return node
	return null


func _swallow() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _coast == null or _dragging:
		return
	if not is_instance_valid(_coast) or absf(_velocity) < 20.0:
		_coast = null
		return
	_scroll_by(_coast, _velocity * delta)
	_velocity *= maxf(0.0, 1.0 - FRICTION * delta)
