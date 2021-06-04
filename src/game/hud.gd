class_name Game_HUD
extends Node

onready var _vbox := $Center/VBox as VBoxContainer

func add_username(text: String) -> void:
	var label := Label.new()
	label.text = text
	_vbox.add_child(label)

func set_usernames(names: PoolStringArray) -> void:
	for n in names:
		add_username(n)

func clear_usernames() -> void:
	for child in _vbox.get_children():
		child.queue_free()
