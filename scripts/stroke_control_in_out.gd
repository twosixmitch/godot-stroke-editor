class_name StrokeControlInOut extends Node2D


const IN_COLOR = Color.LIME_GREEN
const OUT_COLOR = Color.INDIAN_RED

var is_in: bool = false


func setup(is_in_point: bool):
	self.is_in = is_in_point
	
	if is_in_point:
		%Background.modulate = IN_COLOR
	else:
		%Background.modulate = OUT_COLOR


func collides_with(global_pos: Vector2) -> bool:
	return %Background.get_rect().has_point(%Background.to_local(global_pos))
