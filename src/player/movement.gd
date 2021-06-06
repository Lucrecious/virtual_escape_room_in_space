class_name Movement
extends Spatial

signal started_moving()
signal stopped_moving()

export(float) var movement_speed := 10.0
export(float) var gravity := 98.0

onready var _body := get_parent() as KinematicBody
onready var _controller := NodE.get_sibling(self, Controller) as Controller

func _ready() -> void:
	assert(_body, 'must be child of kinematicbody')
	assert(_controller, 'must be set')

var is_moving := false
var _velocity := Vector3(0, 0, 0)
func _physics_process(delta: float) -> void:
	var dir_z := int(_controller.is_action_pressed('forward')) - int(_controller.is_action_pressed('back'))
	var dir_x := int(_controller.is_action_pressed('right')) - int(_controller.is_action_pressed('left'))
	
	var new_is_moving := dir_z or dir_x
	
	if is_moving != new_is_moving:
		is_moving = new_is_moving
		if is_moving:
			emit_signal('started_moving')
		else:
			emit_signal('stopped_moving')
	
	var dirv_z := _body.global_transform.basis.z * -dir_z
	var dirv_x := _body.global_transform.basis.x * dir_x
	var dir := (dirv_x + dirv_z).normalized()
	
	_velocity = (Vector3(1, 0, 1) * dir * movement_speed) + (Vector3(0, 1, 0) * _velocity)
	_velocity.y -= gravity * delta * delta
	_velocity = _body.move_and_slide_with_snap(_velocity, Vector3.DOWN * 10.0, Vector3.UP)
	
	
	
	
