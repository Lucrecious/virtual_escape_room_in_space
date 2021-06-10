extends CanvasLayer

func _ready() -> void:
	layer = 1
	return

func add_popup(control: Popup) -> void:
	if not control: return
	add_child(control)
	control.popup_centered()
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		control.connect('hide', Input, 'set_mouse_mode', [Input.MOUSE_MODE_CAPTURED])
	
	control.connect('hide', control, 'queue_free')
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
