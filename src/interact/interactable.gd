class_name Interactable
extends Node

export(PackedScene) var _control_scene: PackedScene

func show_dialog() -> void:
	var control := _control_scene.instance()
	assert(control is Popup)
	Dialog.add_popup(control)
