class_name MoveToPoint
extends Node

const closeness_threshold := 1.0

onready var _body := get_parent() as KinematicBody
onready var _controller := NodE.get_sibling(self, Controller_Virtual) as Controller_Virtual

var _target_location := Vector3.ZERO
var _moving_to_target := false

func _ready() -> void:
	assert(_body, 'must be child of kinematicbody')
	assert(_controller, 'must be a sibling')

func set_target_location(location: Vector3) -> void:
	_moving_to_target = true
	
	if (_target_location - location).length() < closeness_threshold: return
	_target_location = location

func _physics_process(__: float) -> void:
	if not _moving_to_target:
		_controller.release('forward')
		return
	
	
	var delta := _body.global_transform.origin - _target_location
	delta.y = 0.0
	if _moving_to_target:
		if delta.length_squared() < closeness_threshold * closeness_threshold:
			_moving_to_target = false
			return
		
		_controller.press('forward')
		_body.look_at(Vector3(_target_location.x, _body.global_transform.origin.y, _target_location.z), Vector3.UP)









