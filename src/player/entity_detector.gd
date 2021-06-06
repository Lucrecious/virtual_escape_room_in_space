class_name EntityDetector
extends Spatial

signal entity_detected()

func _ready() -> void:
	var controller := NodE.get_sibling(self, Controller) as Controller
	assert(controller, 'must be sibling')
	
	controller.connect('unhandled_input', self, '_on_unhandled_input')

func get_collider() -> Spatial: return _collider

var _collider: Spatial
func _on_unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not motion: return
	
	var space := get_world().direct_space_state
	var camera := get_viewport().get_camera()
	
	var mouse_position: Vector2
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_position = get_viewport().size / 2.0
	else:
		mouse_position = motion.position
	
	var origin := camera.project_ray_origin(mouse_position)
	var normal := camera.project_ray_normal(mouse_position)
	
	var results := space.intersect_ray(origin, origin + normal * 100.0)
	if results.empty():
		results.collider = null
	
	if _collider == results.collider: return
	
	_collider = results.collider
	emit_signal('entity_detected')

