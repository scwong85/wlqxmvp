extends Control
## Boot scene: confirms services are alive, then routes to the title screen.

const Backdrop = preload("res://scenes/shared/backdrop.gd")


func _ready() -> void:
	add_child(Backdrop.new())
	print("BOOT_OK locale=%s keys=%d" % [Loc.locale, Loc.all_keys().size()])
	# One frame so the engine finishes its first draw before we switch scenes.
	await get_tree().process_frame
	Router.goto("title")
