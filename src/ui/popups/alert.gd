class_name AlertDialog
extends AcceptDialog

enum {
	ERROR_CLIENT,
	ERROR_NETWORK,
}

onready var _text := $CenterContainer/Text as Label

func appear(text: String, alert_type: int) -> void:
	match alert_type:
		ERROR_CLIENT: window_title = 'Cient Error'
		ERROR_NETWORK: window_title = 'Network Error'
		_:
			assert(false, 'all alert types should be defined')
			window_title = 'Error'
	
	_text.text = text
	popup_centered()
