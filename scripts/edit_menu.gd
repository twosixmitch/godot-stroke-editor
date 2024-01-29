class_name EditMenu


static func align_selected_points_left(points: Array):
	# pick the smallest X value and assign to all
	var bounds = find_position_bounds(points)
	assign_x_position_to(bounds.min.x, points)


static func align_selected_points_right(points: Array):
	# pick the largest X value and assign to all
	var bounds = find_position_bounds(points)
	assign_x_position_to(bounds.max.x, points)


static func align_selected_points_top(points: Array):
	# pick the smallest Y value and assign to all
	var bounds = find_position_bounds(points)
	assign_y_position_to(bounds.min.y, points)


static func align_selected_points_bottom(points: Array):
	var bounds = find_position_bounds(points)
	assign_y_position_to(bounds.max.y, points)
	
	
static func find_position_bounds(points: Array) -> Bounds:	
	var bounds = Bounds.new()
	for point in points:
		bounds.fit(point.position)
	return bounds


static func assign_x_position_to(x: int, points: Array):
	for point in points:
		var pos = point.position
		pos.x = x
		point.position = pos


static func assign_y_position_to(y: int, points: Array):
	for point in points:
		var pos = point.position
		pos.y = y
		point.position = pos


static func distribute_points_horizontally(points: Array):
	if points.size() < 2:
		return
		
	points.sort_custom(func(a, b): return a.index < b.index)
	
	var bounds = find_position_bounds(points)
	var distance = abs(bounds.min.x - bounds.max.x)
	var separation = distance / (points.size()-1)

	for idx in range(0, points.size()):
		var point = points[idx]
		
		if idx == 0:
			point.position.x = bounds.min.x
		elif idx == points.size()-1:
			point.position.x = bounds.max.x
		else:
			point.position.x = roundi(bounds.min.x + (separation * idx))


static func distribute_points_vertically(points: Array):
	if points.size() < 2:
		return
		
	points.sort_custom(func(a, b): return a.index < b.index)
	
	var bounds = find_position_bounds(points)
	var distance = abs(bounds.min.y - bounds.max.y)
	var separation = distance / (points.size()-1)

	for idx in range(0, points.size()):
		var point = points[idx]
		
		if idx == 0:
			point.position.y = bounds.min.y
		elif idx == points.size()-1:
			point.position.y = bounds.max.y
		else:
			point.position.y = roundi(bounds.min.y + (separation * idx))
