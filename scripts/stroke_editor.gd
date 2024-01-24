class_name StrokeEditor 

extends Control

enum EditorMode { EDIT, ADD }

@export var character: Label
@export var character_list: ItemList
@export var stroke_tree: Tree
@export var stroke_point_scene: PackedScene

var traces: Array[Trace]
var stroke_point_nodes: Dictionary
var selected_character_index: int = -1
var selected_stroke_index: int = -1
var selected_stroke_point_index: int = -1
var shift_key_held: bool
var editor_mode: EditorMode


func _ready():
	%SaveButton.disabled = true
	%LoadButton.pressed.connect(self.load_pressed)
	%SaveButton.pressed.connect(self.save_pressed)
	%LoadFileDialog.file_selected.connect(self.load_file_selected)
	%SaveFileDialog.file_selected.connect(self.save_file_selected)
	EventBus.stroke_point_pressed.connect(_on_stroke_point_pressed)
	

func _on_stroke_point_pressed(point_index: int):
	if editor_mode == EditorMode.EDIT:
		handle_stroke_point_chosen(point_index)
		

func handle_stroke_point_chosen(point_index: int):
	# Have I clicked on a point for the first time?
	if selected_stroke_point_index == -1:
		select_point(point_index)
	# Have I clicked on an already selected point?
	elif point_index == selected_stroke_point_index:
		deselect_point(selected_stroke_point_index)
	# I have clicked on a different point so I should switch selection to it
	else:
		deselect_point(selected_stroke_point_index)
		select_point(point_index)
	

func _input(event):
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		shift_key_held = event.is_pressed()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if selected_stroke_point_index > -1:
			deselect_all_points()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		delete_selected_points()
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			move_selected_points(Vector2(0, -1))
		elif event.keycode == KEY_A:
			move_selected_points(Vector2(-1, 0))
		elif event.keycode == KEY_S:
			move_selected_points(Vector2(0, 1))
		elif event.keycode == KEY_D:
			move_selected_points(Vector2(1, 0))


func move_selected_points(direction: Vector2):
	if shift_key_held:
		direction = direction * 10
		
	var points = stroke_point_nodes[selected_stroke_index]
	for point in points:
		if point.is_active and point.is_selected:
			point.position = point.position + direction


func load_pressed():
	get_node(^"LoadFileDialog").popup_centered()
	
	
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
		
		%SaveButton.disabled = false
		%TraceControlsPanel.visible = true
		
		return true
	return false


func save_pressed():
	get_node(^"SaveFileDialog").popup_centered()


func save_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var lines = Serialization.export(traces)
	for line in lines:
		file.store_csv_line(line)
	file.close()
	return true

	
func change_character(index: int):
	selected_character_index = index
	
	editor_mode = EditorMode.EDIT
	%EditCheckBox.button_pressed = true
	%AddCheckBox.button_pressed = false
	
	var trace = traces[index]
	%CharacterLabel.text = "%s" % trace.character
	
	selected_stroke_index = -1
	selected_stroke_point_index = -1
	
	stroke_tree.clear()
	
	for key in stroke_point_nodes.keys():
		for item in stroke_point_nodes[key]:
			item.queue_free()

	stroke_point_nodes.clear()
	
	if trace.strokes.size() > 0:
		create_stroke_tree(trace)
		create_stroke_point_nodes(trace)
		change_stroke(0)


func create_stroke_point_nodes(trace: Trace):
	var strokes = trace.strokes
	for s_idx in range(0, strokes.size()):
		var stroke = strokes[s_idx]
		var active = s_idx == 0
		
		stroke_point_nodes[s_idx] = []
		
		for p_idx in range(0, stroke.points.size()):
			var point_node = stroke_point_scene.instantiate() as StrokePointNode
			stroke_point_nodes[s_idx].append(point_node)
			
			point_node.setup(p_idx)
			point_node.make_active(active)
			
			# TODO: point_node.position = (point_position * trace_scale_vec) + translation
			point_node.position = stroke.points[p_idx]
			%TracePointsContainer.add_child(point_node)


func create_stroke_tree(trace: Trace):
	var root = stroke_tree.create_item()
	stroke_tree.hide_root = true
	
	var strokes = trace.strokes
	for s_idx in range(0, strokes.size()):
		var stroke = strokes[s_idx]
	
		var parent_node = stroke_tree.create_item(root)
		parent_node.set_text(0, "Stroke %s" % s_idx)
		
		for p_idx in range(0, stroke.points.size()):
			var point_node = stroke_tree.create_item(parent_node)
			point_node.set_text(0, "Point %s" % p_idx)
	

func change_stroke(stroke_index):
	if stroke_index == selected_stroke_index:
		return
	
	var old_stroke_index = selected_stroke_index
	var new_stroke_index = stroke_index
	
	selected_stroke_index = new_stroke_index
	
	# We are changing the selected stroke
	if old_stroke_index > -1:
		for point in stroke_point_nodes[old_stroke_index]:
			point.deselect()
			point.make_active(false)
	
	for point in stroke_point_nodes[new_stroke_index]:
		point.make_active(true)
		

func deselect_point(point_index: int):
	selected_stroke_point_index = -1  # TODO: Introduce a selected indices array? Or has selected check
	var point = stroke_point_nodes[selected_stroke_index][point_index]
	point.deselect()


func select_point(point_index: int):
	selected_stroke_point_index = point_index
	var point = stroke_point_nodes[selected_stroke_index][point_index]
	point.select()


func select_all_points():
	selected_stroke_point_index = 0
	for point in stroke_point_nodes[selected_stroke_index]:
		point.select()
		

func deselect_all_points():
	selected_stroke_point_index = -1
	for point in stroke_point_nodes[selected_stroke_index]:
		point.deselect()


func delete_selected_points():
	if selected_stroke_index > -1:
		selected_stroke_point_index = -1
		var all_points: Array = stroke_point_nodes[selected_stroke_index]
		var selected_points = all_points.filter(func(point): return point.is_selected)
		
		# TODO: Update stroke tree
		
		for selected_point in selected_points:
			selected_point.queue_free()
			all_points.erase(selected_point)


func _on_item_list_item_activated(index):
	if index != selected_character_index:
		change_character(index)
	

func _on_tree_item_activated():
	# switch_mode(EditorMode.EDIT) # TODO: Implement
	var item = stroke_tree.get_selected()
	
	var stroke_index = -1
	var point_index = -1
	
	if item.get_child_count() > 0:
		# Selected a stroke
		stroke_index = item.get_index()
		if stroke_index == selected_stroke_index:
			if selected_stroke_point_index > -1:
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


func _on_edit_check_box_pressed():
	editor_mode = EditorMode.EDIT


func _on_add_check_box_pressed():
	editor_mode = EditorMode.ADD
	if selected_stroke_index > -1 and selected_stroke_point_index > -1:
		deselect_point(selected_stroke_point_index)
