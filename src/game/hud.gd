class_name Game_HUD
extends Node

onready var _vbox := $ColorRect/Center/VBox as VBoxContainer
onready var leave_button := $Leave as Button

func add_username(text: String) -> void:
	var label := Label.new()
	label.focus_mode = Control.FOCUS_NONE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	_vbox.add_child(label)

func set_usernames(names: PoolStringArray) -> void:
	for n in names:
		add_username(n)

func clear_usernames() -> void:
	for child in _vbox.get_children():
		child.queue_free()
