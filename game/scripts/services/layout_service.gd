extends Node
## Chooses between the landscape and portrait layouts from the window's shape and keeps the
## 2D stretch base size in step with it. Screens ask `Layout.is_portrait()` and listen to
## `mode_changed` to re-arrange themselves, so rotating a phone or resizing a browser just works.
##
## Browsers cannot reliably force an orientation (iOS Safari never allows it), so the game follows
## the device. `toggle_fullscreen()` additionally asks Android browsers to lock portrait.

signal mode_changed(mode: String)

const LANDSCAPE := "landscape"
const PORTRAIT := "portrait"
## Logical design sizes. Portrait is narrower than landscape's height so text stays readable on phones:
## a 390 px wide phone shows this at 0.72x, i.e. a 22 px font is about 16 CSS px.
const LANDSCAPE_SIZE := Vector2i(1280, 720)
const PORTRAIT_SIZE := Vector2i(540, 960)

var mode: String = LANDSCAPE
var _forced: bool = false


static func mode_for(window_size: Vector2) -> String:
	return PORTRAIT if window_size.y > window_size.x else LANDSCAPE


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()


func is_portrait() -> bool:
	return mode == PORTRAIT


## Logical width the current layout can use (for sizing pop-ups).
func usable_width() -> float:
	return float(get_tree().root.get_visible_rect().size.x)


func usable_height() -> float:
	return float(get_tree().root.get_visible_rect().size.y)


func _on_window_resized() -> void:
	if _forced:
		return
	apply(mode_for(Vector2(get_tree().root.size)))


## Switches layout mode. No-op when already in that mode (but always makes sure the base size matches).
func apply(new_mode: String) -> void:
	var size := PORTRAIT_SIZE if new_mode == PORTRAIT else LANDSCAPE_SIZE
	if get_tree().root.content_scale_size != size:
		get_tree().root.content_scale_size = size
	if new_mode != mode:
		mode = new_mode
		print("LAYOUT_MODE ", mode)
		mode_changed.emit(mode)


## For tests: pins the mode regardless of the window shape (pass "" to follow the window again).
func force(new_mode: String) -> void:
	_forced = new_mode != ""
	if _forced:
		apply(new_mode)
	else:
		_on_window_resized()


## Web only: toggles browser fullscreen and, entering it, asks the browser to lock portrait.
func toggle_fullscreen() -> void:
	if not OS.has_feature("web"):
		return
	var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		JavaScriptBridge.eval("try{ if(screen.orientation && screen.orientation.unlock){ screen.orientation.unlock(); } }catch(e){}")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		JavaScriptBridge.eval("try{ if(screen.orientation && screen.orientation.lock){ screen.orientation.lock('portrait').catch(function(){}); } }catch(e){}")


func fullscreen_available() -> bool:
	return OS.has_feature("web")
