class_name StrokePath

var index: int
var points: Array[Point]


func _init(idx: int):
	self.index = idx
	self.points = []


class Point:
	var position: Vector2
	var in_position: Vector2
	var out_position: Vector2
