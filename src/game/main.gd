class_name Game_Main
extends Node

var _is_capturing := false

onready var hud := NodE.get_child(self, Game_HUD) as Game_HUD
onready var level := NodE.get_child(self, Level) as Level

func _ready() -> void:
	assert(level, 'level must be set initially')

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	
	if event.is_action_pressed('ui_cancel'):
		_is_capturing = not _is_capturing
		if _is_capturing:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
