class_name StrokeEditor 

extends Control

enum EditorMode { EDIT, ADD }

@export var character: Label
@export var character_list: ItemList
@export var stroke_tree: Tree
@export var stroke_point_scene: PackedScene

var traces: Array[Trace] = []
var stroke_point_nodes: Dictionary
var selected_character_index: int = -1
var selected_stroke_index: int = -1
var selected_point_indices: Array = []
var editor_mode: EditorMode

var left_mouse_held: bool
var shift_key_held: bool
var ctrl_key_held: bool


func _ready():
	%AddStrokeButton.disabled = true
	%LoadFileDialog.file_selected.connect(self.load_file_selected)
	%SaveFileDialog.file_selected.connect(self.save_file_selected)
	%FileMenuButton.get_popup().id_pressed.connect(_on_file_item_menu_pressed)
	%EditMenuButton.get_popup().id_pressed.connect(_on_edit_item_menu_pressed)


func _input(event):
	if traces.size() == 0:
		return
	
	if stroke_point_nodes.size() == 0:
		return	
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if collides_with_gui(event.position):
			return # Ignore input
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		left_mouse_held = event.is_pressed()
		
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		shift_key_held = event.is_pressed()
	
	if event is InputEventKey and event.keycode == KEY_CTRL:
		ctrl_key_held = event.is_pressed()
	
	# Input based on Editor mode	
	if editor_mode == EditorMode.ADD:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if collides_with_point(event.position) == null:
				add_point(event.position)
	else:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var point = collides_with_point(event.position)
			if point:
				if shift_key_held:
					point.toggle_selection()
				elif !point.is_selected:
					deselect_all_points()
					point.select()
					#handle_stroke_point_chosen(point.index)
			else:
				deselect_all_points()
		if event is InputEventMouseMotion and left_mouse_held and ctrl_key_held:
			move_selected_points(event.relative)
	
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			deselect_all_points()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
			delete_selected_points()
		elif ctrl_key_held:
			if event is InputEventKey and event.keycode == KEY_A:
				select_all_points()
			if event is InputEventKey and event.keycode == KEY_D:
				deselect_all_points()
		elif event is InputEventKey and event.pressed:
			if event.keycode == KEY_W:
				move_selected_points(Vector2(0, -1))
			elif event.keycode == KEY_A:
				move_selected_points(Vector2(-1, 0))
			elif event.keycode == KEY_S:
				move_selected_points(Vector2(0, 1))
			elif event.keycode == KEY_D:
				move_selected_points(Vector2(1, 0))


func collides_with_point(_position: Vector2) -> StrokePointNode:
	for point: StrokePointNode in stroke_point_nodes[selected_stroke_index]:	
		if point.collides_with(_position):
			return point
	return null
	

func collides_with_gui(_position: Vector2) -> bool:
	if %StrokesPanelContainer.get_rect().has_point(_position):
		return true
	if %CharacterPanelContainer.get_rect().has_point(_position):
		return true
	if %Menu.get_rect().has_point(_position):
		return true
	if %EditorControlsPanel.get_rect().has_point(_position):
		return true
	return false		


func add_point(_global_position: Vector2):
	var stroke = stroke_point_nodes[selected_stroke_index]
	var point = stroke_point_scene.instantiate() as StrokePointNode
	
	stroke.append(point)
	point.setup(stroke.size()-1)
	
	%PointsContainer.add_child(point)
	point.global_position = _global_position	
	
	var root = stroke_tree.get_root()
	var stroke_item = root.get_child(selected_stroke_index)
	var point_item = stroke_tree.create_item(stroke_item)
	
	var pos = point.position
	point_item.set_text(0, "Point %s  (%s, %s)" % [point.index, pos.x, pos.y])
	point_item.set_meta("type", "point")


func move_selected_points(direction: Vector2):
	if shift_key_held:
		direction = direction * 10
		
	var stroke = stroke_point_nodes[selected_stroke_index]
	for point in stroke:
		if point.is_selected:
			point.position = point.position + direction
	
	refresh_stroke_tree_point_names()


func refresh_stroke_tree_point_names():
	var root = stroke_tree.get_root()
	var stroke_item = root.get_child(selected_stroke_index)
	
	var stroke = stroke_point_nodes[selected_stroke_index]
	
	for point in stroke:
		var point_item = stroke_item.get_child(point.index)
		point_item.set_text(0, "Point %s  (%s, %s)" % [point.index, point.position.x, point.position.y])		


func change_character(index: int):
	selected_character_index = index
	
	editor_mode = EditorMode.EDIT
	%EditCheckBox.button_pressed = true
	%AddCheckBox.button_pressed = false
	
	selected_stroke_index = -1
	stroke_tree.clear()
	
	for key in stroke_point_nodes.keys():
		for point in stroke_point_nodes[key]:
			point.queue_free()
	stroke_point_nodes.clear()
	
	var trace = traces[index]
	%CharacterLabel.text = "%s" % trace.character
	
	if trace.strokes.size() > 0:
		create_stroke_point_nodes(trace)
		create_stroke_tree()
		change_stroke(0)


func create_stroke_point_nodes(trace: Trace):
	for s_idx in range(0, trace.strokes.size()):
		var stroke = trace.strokes[s_idx]
		var active = s_idx == 0
		
		stroke_point_nodes[s_idx] = []
		
		for p_idx in range(0, stroke.points.size()):
			var point = stroke_point_scene.instantiate() as StrokePointNode
			point.setup(p_idx)
			point.make_active(active)
			
			%PointsContainer.add_child(point)
			stroke_point_nodes[s_idx].append(point)
			
			# TODO: point_node.position = (point_position * trace_scale_vec) + translation
			point.position = stroke.points[p_idx]
			
			
func create_stroke_tree():
	var root = stroke_tree.create_item()
	stroke_tree.hide_root = true
	
	for s_idx in stroke_point_nodes.keys():
		var stroke_item = stroke_tree.create_item(root)
		stroke_item.set_text(0, "Stroke %s" % s_idx)
		stroke_item.set_meta("type", "stroke")
		
		var stroke_points = stroke_point_nodes[s_idx]
		for point_node in stroke_points:
			var point_item = stroke_tree.create_item(stroke_item)	
			var pos = point_node.position
			point_item.set_text(0, "Point %s  (%s, %s)" % [point_node.index, pos.x, pos.y])
			point_item.set_meta("type", "point")


func change_stroke(stroke_index):
	if stroke_index == selected_stroke_index:
		return
	
	var old_stroke_index = selected_stroke_index
	var new_stroke_index = stroke_index
	
	selected_point_indices = []
	selected_stroke_index = new_stroke_index
	
	# We are changing the selected stroke
	if old_stroke_index > -1:
		for point in stroke_point_nodes[old_stroke_index]:
			point.deselect()
			point.make_active(false)
	
	for point in stroke_point_nodes[new_stroke_index]:
		point.make_active(true)


func select_point(point_index: int):
	selected_point_indices.push_back(point_index)
	var point = stroke_point_nodes[selected_stroke_index][point_index]
	point.select()


func select_all_points():
	for point in stroke_point_nodes[selected_stroke_index]:
		point.select()


func deselect_point(point_index: int):
	var point = stroke_point_nodes[selected_stroke_index][point_index]
	point.deselect()


func deselect_all_points():
	for point in stroke_point_nodes[selected_stroke_index]:
		point.deselect()


func delete_selected_points():
	var stroke = stroke_point_nodes[selected_stroke_index]
	var selected_points = stroke.filter(func(point): return point.is_selected)
	
	# Gather up the indices of the selected point nodes
	var selected_indices: Array = []
	for idx in range(0, stroke.size()):
		if stroke[idx].is_selected:
			selected_indices.append(idx)
	
	# Delete the original point nodes
	for selected_point in selected_points:
		stroke.erase(selected_point)
		selected_point.queue_free()
	
	# Re-assign indices to remaining point nodes	
	for idx in range(0, stroke.size()):
		stroke[idx].setup(idx)
	
	# Clear out the deleted points from the stroke tree
	var root = stroke_tree.get_root()
	var stroke_tree_item = root.get_child(selected_stroke_index)
	
	var selected_tree_items: Array = []
	for idx in selected_indices:
		selected_tree_items.append(stroke_tree_item.get_child(idx))
	
	for tree_item in selected_tree_items:
		stroke_tree_item.remove_child(tree_item)
	
	refresh_stroke_tree_point_names()


func _on_item_list_item_activated(index):
	if index != selected_character_index:
		change_character(index)


func _on_tree_item_activated():
	# switch_mode(EditorMode.EDIT) # TODO: Implement
	var item = stroke_tree.get_selected()	
	var type = item.get_meta("type")

	var stroke_index = -1
	var point_index = -1
	
	#if item.get_child_count() > 0:
	if type == "stroke":
		# Selected a stroke
		stroke_index = item.get_index()
		if stroke_index == selected_stroke_index:
			if has_selected_points():
				deselect_all_points()
			else:
				select_all_points()
		else:
			change_stroke(stroke_index)
	else:
		# Selected a stroke point
		point_index = item.get_index()
		stroke_index = item.get_parent().get_index()
		if stroke_index == selected_stroke_index:
			handle_stroke_point_chosen(point_index)
		else:
			change_stroke(stroke_index)
			select_point(point_index)


func has_selected_points() -> bool:
	var stroke = stroke_point_nodes[selected_stroke_index]
	return stroke.any(func(point): return point.is_selected)


func handle_stroke_point_chosen(point_index: int):
	var stroke = stroke_point_nodes[selected_stroke_index]
	var selected_points = stroke.filter(func(point): return point.is_selected)
	
	# Have I clicked on a point for the first time?
	if selected_points.size() == 0:
		select_point(point_index)
	# Have I clicked on an already selected point?
	elif stroke[point_index] in selected_points:
		deselect_point(point_index)
	# I have clicked on a different point so I should switch selection to it
	else:
		deselect_all_points()
		select_point(point_index)


func _on_edit_check_box_pressed():
	editor_mode = EditorMode.EDIT


func _on_add_check_box_pressed():
	editor_mode = EditorMode.ADD
	if selected_stroke_index > -1:
		deselect_all_points()
		

func _on_file_item_menu_pressed(id: int):
	match id:
		0: 
			get_node(^"LoadFileDialog").popup_centered()
		1: 
			get_node(^"SaveFileDialog").popup_centered()
		_: 
			print("Unknown file menu item")


func load_file_selected(path: String):
	if FileAccess.file_exists(path):	
		var file = FileAccess.open(path, FileAccess.READ)
		var _header = file.get_csv_line()
		
		var lines: Array[PackedStringArray] = []
		while not file.eof_reached():
			lines.append(file.get_csv_line())
		
		traces = Serialization.import(lines)
	
		character_list.clear()
		for trace in traces:
			character_list.add_item("%s" % trace.character)
		
		character_list.select(0)
		change_character(0)
		
		%FileMenuButton.get_popup().set_item_disabled(1, false)
		%EditorControlsPanel.visible = true
		%AddStrokeButton.disabled = false
		
		for idx in range(0, %EditMenuButton.get_popup().get_item_count()):
			%EditMenuButton.get_popup().set_item_disabled(idx, false)
		
		return true
	return false


func save_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var lines = Serialization.export(traces)
	for line in lines:
		file.store_csv_line(line)
	file.close()
	return true
		

func _on_edit_item_menu_pressed(id: int):
	var stroke = stroke_point_nodes[selected_stroke_index]
	var selected_points = stroke.filter(func(point): return point.is_selected)
	
	if selected_points.size() == 0 and id < 7:
		return
	
	match id:
		0: 
			EditMenu.align_selected_points_left(selected_points)
			refresh_stroke_tree_point_names()
		1: 
			EditMenu.align_selected_points_right(selected_points)
			refresh_stroke_tree_point_names()
		2: 
			EditMenu.align_selected_points_top(selected_points)
			refresh_stroke_tree_point_names()
		3: 
			EditMenu.align_selected_points_bottom(selected_points)
			refresh_stroke_tree_point_names()
		5:
			EditMenu.distribute_points_horizontally(selected_points)
		6:
			EditMenu.distribute_points_vertically(selected_points)
		8:
			# TODO: increase stroke index
			print("increase stroke index")
			
		9:
			# TODO: decrease stroke index
			print("decrease stroke index")
		11:
			print("delete all  stuff!!!!!!!")
			delete_all_strokes()
		_: 
			print("Unknown edit menu item")

func delete_all_strokes():
	selected_stroke_index = -1
	stroke_tree.clear()
	
	for key in stroke_point_nodes.keys():
		for point in stroke_point_nodes[key]:
			point.queue_free()
	stroke_point_nodes.clear()


func _on_add_stroke_button_pressed():
	var stroke_count = stroke_point_nodes.size()
	stroke_point_nodes[stroke_count] = []
	
	var root = stroke_tree.get_root()
	var stroke_item = stroke_tree.create_item(root)
	stroke_item.set_text(0, "Stroke %s" % stroke_count)
	stroke_item.set_meta("type", "stroke")
