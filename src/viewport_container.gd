extends ViewportContainer

onready var _viewport := NodE.get_child(self, Viewport) as Viewport

func _ready() -> void:
	connect('mouse_entered', self, 'grab_focus')
	connect('mouse_exited', self, 'release_focus')

func _gui_input(event: InputEvent) -> void:
	_viewport.unhandled_input(event)
