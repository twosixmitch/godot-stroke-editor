class_name StrokePointNode
extends Node


var is_active: bool
var is_selected: bool
var index: int

const ACTIVE_COLOR = Color(0, 0, 0, 1)
const IN_ACTIVE_COLOR = Color(0, 0, 0, 0.2)
const SELECTED_COLOR = Color(0.9, 0, 0.9, 1)


func setup(_index: int):
	index = _index
	%Label.text = "%s" % index
	%Background.self_modulate = ACTIVE_COLOR


func make_active(active: bool):
	is_active = active
	%Background.self_modulate = ACTIVE_COLOR if active else IN_ACTIVE_COLOR
	%Label.visible = active
	

func select():
	%Background.self_modulate = SELECTED_COLOR
	is_selected = true


func deselect():
	%Background.self_modulate = ACTIVE_COLOR
	is_selected = false
	

func toggle_selection():
	if is_selected:
		deselect()
	else:
		select()


func collides_with(position: Vector2) -> bool:
	return %Background.get_rect().has_point(%Background.to_local(position))
