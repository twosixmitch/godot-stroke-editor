class_name StrokeTreeView extends Tree


signal on_stroke_selected(stroke_idx: int)
signal on_stroke_control_selected(stroke_idx: int, control_idx: int)


func setup(stroke_paths: Array[StrokePath]):
	var root = create_item()
	hide_root = true
	
	for s_idx in range(0, stroke_paths.size()):
		var stroke_path = stroke_paths[s_idx]
		var stroke_item = %StrokeTree.create_item(root)
		stroke_item.set_text(0, "Stroke %s" % s_idx)
		stroke_item.set_meta("type", "stroke")
		
		for p_idx in range(0, stroke_path.points.size()):
			var stroke_point = stroke_path.points[p_idx]
			var point_item = %StrokeTree.create_item(stroke_item)	
			point_item.set_text(0, "Point %s  (%s, %s)" % [p_idx, stroke_point.position.x, stroke_point.position.y])
			point_item.set_meta("type", "point")


func select_stroke(stroke_idx: int):
	var root = get_root()
	
	for stroke_item in root.get_children():
		stroke_item.set_custom_bg_color(0, Color.TRANSPARENT)
		for point_item in stroke_item.get_children():
			point_item.set_custom_bg_color(0, Color.TRANSPARENT)
	
	var stroke_item = root.get_child(stroke_idx)
	stroke_item.set_custom_bg_color(0, Color.BLACK)
	for point_item in stroke_item.get_children():
		point_item.set_custom_bg_color(0, Color.BLACK)
	

func refresh_stroke(stroke_path: StrokePath):
	var root = get_root()
	var stroke_item = root.get_child(stroke_path.index)
	
	for p_idx in range(0, stroke_path.points.size()):
		var stroke_point = stroke_path.points[p_idx]
		var point_item = stroke_item.get_child(p_idx)
		point_item.set_text(0, "Point %s  (%s, %s)" % [p_idx, stroke_point.position.x, stroke_point.position.y])


func refresh_stroke_control(stroke_idx: int, control: StrokeControl):
	var root = get_root()
	var stroke_item = root.get_child(stroke_idx)
	var point_item = stroke_item.get_child(control.index)
	point_item.set_text(0, "Point %s  (%s, %s)" % [control.index, control.position.x, control.position.y])
	
	
func add_stroke(stroke_idx: int):
	var root = get_root()
	var stroke_item = create_item(root)
	stroke_item.set_text(0, "Stroke %s" % stroke_idx)
	stroke_item.set_meta("type", "stroke")
	stroke_item.set_custom_bg_color(0, Color.BLACK)
	

func add_stroke_control(stroke_idx: int, stroke_control: StrokeControl):
	var root = get_root()
	var stroke_item = root.get_child(stroke_idx)
	var point_item = create_item(stroke_item)
	point_item.set_text(0, "Point %s  (%s, %s)" % [stroke_control.index, stroke_control.position.x, stroke_control.position.y])
	point_item.set_meta("type", "point")
	point_item.set_custom_bg_color(0, Color.BLACK)


func _on_tree_item_activated():
	var item = get_selected()	
	var type = item.get_meta("type")
	
	if type == "stroke":
		on_stroke_selected.emit(item.get_index())
		select_stroke(item.get_index())
	else:
		on_stroke_control_selected.emit(item.get_parent().get_index(), item.get_index())
		select_stroke(item.get_parent().get_index())
