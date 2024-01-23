class_name StrokePointNode
extends Node


var is_active: bool
var is_selected: bool
var index: int


func setup(_index: int):
	index = _index
	%Label.text = "%s" % index


func make_active(active: bool):
	is_active = active
	var color = %Background.color
	color.a = 1.0 if active else 0.3
	%Background.color = color
	%Label.visible = active
	
	if !active:
		deselect()
	

func select():
	%SelectedFrame.visible = true
	is_selected = true


func deselect():
	%SelectedFrame.visible = false
	is_selected = false
	

func toggle_selection():
	if is_selected:
		deselect()
	else:
		select()


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_active:
			EventBus.stroke_point_pressed.emit(index)
