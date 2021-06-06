class_name CameraUpDown
extends Spatial

export(NodePath) var _pivot_path := NodePath()

onready var _body := get_parent() as KinematicBody
onready var _pivot := get_node_or_null(_pivot_path) as Position3D
onready var _controller := NodE.get_sibling(self, Controller) as Controller


func _ready() -> void:
	assert(_body, 'must be child of kinematicbody')
	assert(_pivot, 'must be set')
	assert(_controller, 'must be sibling')
	
	_controller.connect('unhandled_input', self, '_on_unhandled_input')

func _on_unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	
	if event.is_action_pressed('toggle_first_person_mode'):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	
	if not event is InputEventMouseMotion: return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	var motion := event as InputEventMouseMotion
	
	_body.rotate_y(-motion.relative.x * PI * 0.002)
	_pivot.rotate_x(-motion.relative.y * PI * 0.0007)
	_pivot.rotation.x = clamp(_pivot.rotation.x, -PI / 3.0, PI / 3.0)
