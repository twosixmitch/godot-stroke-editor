class_name Bounds

@warning_ignore("shadowed_global_identifier")
var min: Vector2 = Vector2(9999999, 9999999)
@warning_ignore("shadowed_global_identifier")
var max: Vector2 = Vector2(-9999999, -9999999)


func fit(position: Vector2):
	if position.x < min.x:
		min.x = position.x
	
	if position.x > max.x:
		max.x = position.x
		
	if position.y < min.y:
		min.y = position.y
		
	if position.y > max.y:
		max.y = position.y
