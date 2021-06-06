extends ViewportContainer

onready var _viewport := NodE.get_child(self, Viewport) as Viewport

func _ready() -> void:
	connect('mouse_entered', self, '_grab_focus')
	connect('mouse_exited', self, '_release_focus')

func _grab_focus() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: return
	grab_focus()

func _release_focus() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: return
	release_focus()

func _gui_input(event: InputEvent) -> void:
	_viewport.unhandled_input(event)
