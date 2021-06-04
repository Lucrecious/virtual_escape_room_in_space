class_name Movement
extends Spatial

export(float) var movement_speed := 10.0

onready var _body := get_parent() as KinematicBody
onready var _controller := NodE.get_sibling(self, Controller) as Controller

func _ready() -> void:
	assert(_body, 'must be child of kinematicbody')
	assert(_controller, 'must be set')

func _physics_process(delta: float) -> void:
	var dir_z := int(_controller.is_action_pressed('forward')) - int(_controller.is_action_pressed('back'))
	var dir_x := int(_controller.is_action_pressed('right')) - int(_controller.is_action_pressed('left'))
	
	var dirv_z := _body.global_transform.basis.z * -dir_z
	var dirv_x := _body.global_transform.basis.x * dir_x
	var dir := (dirv_x + dirv_z).normalized()
	
	_body.move_and_slide_with_snap(dir * movement_speed, Vector3.DOWN * 10.0, Vector3.UP)
