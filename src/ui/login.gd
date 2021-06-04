class_name Screen_Login
extends Control

signal create_pressed()
signal join_pressed()


export(bool) var _start_offline := false

onready var _create_button := $CenterContainer/Content/Host/Create as Button
onready var _join_button := $CenterContainer/Content/Join/Join as Button

onready var _username_label := $CenterContainer/Content/Username as LineEdit
onready var _create_room_label := $CenterContainer/Content/Host/RoomName as LineEdit
onready var _join_room_label := $CenterContainer/Content/Join/RoomID as LineEdit

func get_username() -> String: return _username_label.text
func get_room_name() -> String: return _create_room_label.text
func get_room_id() -> String: return _join_room_label.text

var _is_online := false

func online() -> void:
	if _is_online: return
	_is_online = true
	_create_button.disabled = false
	_join_button.disabled = false

func offline() -> void:
	if not _is_online: return
	_is_online = false
	_create_button.disabled = true
	_join_button.disabled = true

func _ready() -> void:
	_create_button.connect('pressed', self, '_on_create_pressed')
	_join_button.connect('pressed', self, '_on_join_pressed')
	
	if _start_offline:
		_is_online = true
		offline()
	else:
		_is_online = false
		online()

func _on_join_pressed() -> void:
	if get_username().empty():
		_error_empty_username()
		return
	
	if get_room_id().empty():
		_error_empty_room_id()
		return
	
	emit_signal('join_pressed')

func _on_create_pressed() -> void:
	if get_username().empty():
		_error_empty_username()
		return
	
	if get_room_name().empty():
		_error_empty_room_name()
		return
	
	emit_signal('create_pressed')

func _error_empty_room_id() -> void:
	var alert := Popups.create_alert(get_viewport())
	alert.appear('Must enter a room id.', AlertDialog.ERROR_CLIENT)

func _error_empty_room_name() -> void:
	var alert := Popups.create_alert(get_viewport())
	alert.appear('Must enter a room name.', AlertDialog.ERROR_CLIENT)

func _error_empty_username() -> void:
	var alert := Popups.create_alert(get_viewport())
	alert.appear('Must enter a username.', AlertDialog.ERROR_CLIENT)
	



