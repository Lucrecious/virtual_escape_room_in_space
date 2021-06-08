class_name EntityDetector
extends Spatial

signal entity_detected()

var _pointer3d: MeshInstance

func _ready() -> void:
	var controller := NodE.get_sibling(self, Controller) as Controller
	assert(controller, 'must be sibling')
	
	controller.connect('unhandled_input', self, '_on_unhandled_input')
	
	_pointer3d = MeshInstance.new()
	var cube := CubeMesh.new()
	cube.size = Vector3.ONE * .05
	var spatial_material := SpatialMaterial.new()
	spatial_material.albedo_color = Color.darkred
	cube.material = spatial_material
	_pointer3d.mesh = cube
	var node := Node.new()
	node.add_child(_pointer3d)
	add_child(node)

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
		results.position = Vector3()
	
	if not results.collider:
		_pointer3d.visible = false
	else:
		_pointer3d.visible = true
		_pointer3d.global_transform.origin = results.position
	
	if _collider == results.collider: return
	
	_collider = results.collider
	emit_signal('entity_detected')

