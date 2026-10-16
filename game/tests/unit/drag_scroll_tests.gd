extends RefCounted
## Drag scrolling: a finger or mouse drag scrolls a list even when it starts on a button, a tap still presses it.

const DragScrollScript = preload("res://scripts/services/drag_scroll.gd")

var check: Callable


func _touch(pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.pressed = pressed
	e.position = pos
	return e


func _drag(pos: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.position = pos
	return e


func run(check_fn: Callable, loc: Node) -> void:
	check = check_fn
	var root: Node = loc.get_tree().current_scene
	var ds: Node = DragScrollScript.new()
	root.add_child(ds)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.position = Vector2(0, 0)
	sc.size = Vector2(300, 400)
	root.add_child(sc)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(300, 0)
	sc.add_child(box)
	var buttons: Array = []
	var pressed := [0]
	for i in 20:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 100)
		b.pressed.connect(func() -> void: pressed[0] += 1)
		box.add_child(b)
		buttons.append(b)
	sc.notification(Container.NOTIFICATION_SORT_CHILDREN)
	sc.get_v_scroll_bar().max_value = 2000.0
	sc.get_v_scroll_bar().page = 400.0
	check.call(ds.scroll_at(Vector2(50, 50)) == sc, "drag: a scrollable list is found under the pointer")
	check.call(ds.scroll_at(Vector2(500, 50)) == null, "drag: nothing is found outside any list")
	# A tap does not scroll.
	ds.handle(_touch(true, Vector2(50, 150)))
	check.call(not ds.handle(_drag(Vector2(53, 152))), "drag: a small wobble is not a drag")
	check.call(not ds.handle(_touch(false, Vector2(53, 152))), "drag: a tap passes through")
	check.call(sc.scroll_vertical == 0, "drag: a tap leaves the list where it was")
	# A sideways swipe is ignored.
	ds.handle(_touch(true, Vector2(50, 150)))
	check.call(not ds.handle(_drag(Vector2(150, 160))), "drag: a mostly sideways swipe is not a scroll")
	ds.handle(_touch(false, Vector2(150, 160)))
	# A vertical drag starting on a button scrolls the list (the content moves with the finger).
	ds.handle(_touch(true, Vector2(50, 300)))
	var swallowed: bool = ds.handle(_drag(Vector2(50, 250)))
	check.call(swallowed, "drag: a vertical drag is taken over")
	ds.handle(_drag(Vector2(50, 200)))
	check.call(sc.scroll_vertical >= 90 and sc.scroll_vertical <= 110, "drag: dragging up 100 px scrolls the list down by 100 (got %d)" % sc.scroll_vertical)
	check.call(ds.handle(_touch(false, Vector2(50, 200))), "drag: lifting the finger after a drag is swallowed")
	check.call(pressed[0] == 0, "drag: no button fired during the drag")
	var after_drag: int = sc.scroll_vertical
	ds.handle(_touch(true, Vector2(50, 100)))
	ds.handle(_drag(Vector2(50, 180)))
	ds.handle(_drag(Vector2(50, 400)))
	check.call(sc.scroll_vertical < after_drag, "drag: dragging down scrolls back up")
	ds.handle(_touch(false, Vector2(50, 400)))
	check.call(buttons.all(func(b: Button) -> bool: return not b.disabled), "drag: no button stays disabled afterwards")
	# Mouse drag works too, the wheel is untouched, and emulated mouse events from a touch are ignored.
	sc.scroll_vertical = 0
	ds._coast = null
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	m.pressed = true
	m.position = Vector2(60, 300)
	ds.handle(m)
	var mm := InputEventMouseMotion.new()
	mm.position = Vector2(60, 200)
	mm.button_mask = MOUSE_BUTTON_MASK_LEFT
	ds.handle(mm)
	check.call(sc.scroll_vertical > 50, "drag: a mouse drag scrolls the list")
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(60, 200)
	ds.handle(up)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	check.call(not ds.handle(wheel), "drag: the wheel is left to the list itself")
	sc.queue_free()
	ds.queue_free()
