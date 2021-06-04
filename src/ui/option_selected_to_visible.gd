extends OptionButton

export(Array, NodePath) var _controls_path := []

var _controls := []

func _ready() -> void:
	for path in _controls_path:
		var control := get_node_or_null(path) as Control
		assert(control, 'must be control')
		if not control: continue
		_controls.push_back(control)
	
	connect('item_selected', self, '_on_item_selected')
	_on_item_selected(selected)

func _on_item_selected(index: int) -> void:
	for i in _controls.size():
		_controls[i].visible = (index == i)
