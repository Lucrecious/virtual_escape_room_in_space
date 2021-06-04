extends Node

const alert_dialog_scene := preload('res://src/ui/popups/alert.tscn')

func create_alert(viewport: Viewport) -> AlertDialog:
	var dialog := alert_dialog_scene.instance() as AlertDialog
	viewport.add_child(dialog, viewport.get_child_count() - 1)
	
	return dialog
