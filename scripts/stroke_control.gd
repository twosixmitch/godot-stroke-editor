class_name StrokeControl extends Node2D


var index: int = -1
var is_active: bool
var is_selected: bool
var in_point: StrokeControlInOut
var out_point: StrokeControlInOut

const ACTIVE_COLOR = Color(0.5, 0.5, 0.5, 1)
const SELECTED_COLOR = Color(0.9, 0, 0.9, 1)


func setup(idx: int, pos: Vector2):
	self.index = idx
	self.position = pos
	%Background.self_modulate = ACTIVE_COLOR


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


func collides_with(global_pos: Vector2) -> bool:
	return %Background.get_rect().has_point(%Background.to_local(global_pos))
