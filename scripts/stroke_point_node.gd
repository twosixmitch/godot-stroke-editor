class_name StrokePointNode
extends Node


var is_active: bool


func setup(number: int):
	%Label.text = "%s" % number


func make_active(active: bool):
	is_active = active
	var color = %ColorRect.color
	color.a =  1 if active else 0.3
	%ColorRect.color = color
	%Label.visible = active
