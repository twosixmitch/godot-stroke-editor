class_name StrokeEditor
extends Control


@export var stroke_point_scene: PackedScene  # TODO: Old remove
@export var stroke_control_scene: PackedScene
@export var stroke_control_in_out_scene: PackedScene

@onready var stroke_tree_view: StrokeTreeView = %StrokeTree

# raw data
var traces: Array[Trace] = []
var stroke_paths: Array[StrokePath] = []  

# on-screen visuals for the current stroke
var stroke_controls: Array[StrokeControl] = []
var stroke_points: Array[StrokePointNode] = []
var selected_stroke_control: StrokeControl

var selected_character_index: int = -1
var selected_stroke_index: int = -1

var left_mouse_held: bool
var right_mouse_held: bool
var shift_key_held: bool
var ctrl_key_held: bool
var is_previewing: bool


func _ready():
	%LoadFileDialog.file_selected.connect(self.load_file_selected)
	%SaveFileDialog.file_selected.connect(self.save_file_selected)
	
	%FileMenuButton.get_popup().id_pressed.connect(_on_file_item_menu_pressed)
	%EditMenuButton.get_popup().id_pressed.connect(_on_edit_item_menu_pressed)
	
	stroke_tree_view.on_stroke_selected.connect(_on_stroke_tree_stroke_selected)
	stroke_tree_view.on_stroke_control_selected.connect(_on_stroke_tree_stroke_control_selected)


func _input(event):
	if traces.size() == 0:
		return
	
	if stroke_paths.size() == 0:
		return
		
	if is_previewing:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if collides_with_gui(event.position):
			return # Ignore input
		else:
			if %CharacterLabel.get_rect().has_point(event.position) == false:
				return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		left_mouse_held = event.is_pressed()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		right_mouse_held = event.is_pressed()
		
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		shift_key_held = event.is_pressed()
	
	if event is InputEventKey and event.keycode == KEY_CTRL:
		ctrl_key_held = event.is_pressed()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		deselect_all_controls()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		delete_selected_points()
		
	if ctrl_key_held:
		if event is InputEventKey and event.keycode == KEY_A:
			select_all_points()
		if event is InputEventKey and event.keycode == KEY_D:
			deselect_all_controls()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			move_selected_points(Vector2(0, -1))
		elif event.keycode == KEY_A:
			move_selected_points(Vector2(-1, 0))
		elif event.keycode == KEY_S:
			move_selected_points(Vector2(0, 1))
		elif event.keycode == KEY_D:
			move_selected_points(Vector2(1, 0))
		
	if event is InputEventMouseButton and event.pressed:
		deselect_all_controls()
		selected_stroke_control = collides_with_control_point(event.position)
		
		if selected_stroke_control:
			selected_stroke_control.select()
		else:
			selected_stroke_control = null
			if event.button_index == MOUSE_BUTTON_LEFT:
				add_stroke_control(event.position)
				refresh_stroke_line()
	
	if event is InputEventMouseMotion and left_mouse_held and selected_stroke_control != null:
		move_control_point([selected_stroke_control], Vector2(event.relative))
		stroke_tree_view.refresh_stroke_control(selected_stroke_index, selected_stroke_control)
		refresh_stroke_line()
	
	if event is InputEventMouseMotion and right_mouse_held and selected_stroke_control != null:
		move_control_in_and_out_point(selected_stroke_control, Vector2(event.relative))
		refresh_stroke_line()


func load_file_selected(path: String):
	if FileAccess.file_exists(path):	
		var file = FileAccess.open(path, FileAccess.READ)
		var _header = file.get_csv_line()
		
		var lines: Array[PackedStringArray] = []
		while not file.eof_reached():
			lines.append(file.get_csv_line())
		
		traces = Serialization.import(lines)
	
		%CharacterList.clear()
		for trace in traces:
			%CharacterList.add_item("%s" % trace.character)
			
		%CharacterList.select(0)
		change_character(0)
		
		%FileMenuButton.get_popup().set_item_disabled(1, false)
		%AddStrokeButton.disabled = false
		%PreviewButton.disabled = false
		
		for idx in range(0, %EditMenuButton.get_popup().get_item_count()):
			%EditMenuButton.get_popup().set_item_disabled(idx, false)
		
		return true
	return false
	

func save_file_selected(path: String):
	save_changes()
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	var font_size = %CharacterLabel.get_theme_font_size("font_size")
	var lines = Serialization.export(traces, font_size)
	
	for line in lines:
		file.store_csv_line(line)
	
	file.close()
	return true
	
	
func save_changes():
	var trace = traces[selected_character_index]
	trace.font_size = %CharacterLabel.get_theme_font_size("font_size")
	
	trace.strokes.clear()
	for stroke_path in stroke_paths:
		var trace_stroke = TraceStroke.new()
		for stroke_point in stroke_path.points:
			var trace_point = TraceStroke.Point.new()
			trace_point.position = stroke_point.position
			
			if stroke_point.in_position:
				trace_point.in_position = stroke_point.in_position
			else:
				trace_point.in_position = Vector2.ZERO
			
			if stroke_point.out_position:
				trace_point.out_position = stroke_point.out_position
			else:
				trace_point.out_position = Vector2.ZERO
			
			trace_stroke.points.append(trace_point)
		trace.strokes.append(trace_stroke)
	
	
func change_character(index: int):
	selected_character_index = index
	selected_stroke_index = -1
		
	# Delete old on screen visuals
	delete_stroke_controls()
	%StrokeLine.clear_points()
	%StrokePath.curve.clear_points()
	
	var trace = traces[index]
	%CharacterLabel.text = "%s" % trace.character

	stroke_paths.clear()
	create_stroke_paths(trace)
	
	stroke_tree_view.clear()
	stroke_tree_view.setup(stroke_paths)
	
	if trace.strokes.size() > 0:
		change_stroke(0)
	
	if is_previewing:
		delete_preview_stroke_points()
		#create_points(%StrokePath)
		create_start_point(%StrokePath)
		
	
func delete_stroke_controls():
	for stroke_control in stroke_controls:
		if stroke_control.in_point:
			stroke_control.in_point.queue_free()
			
		if stroke_control.out_point:
			stroke_control.out_point.queue_free()
		
		stroke_control.queue_free()
	stroke_controls.clear()


func create_stroke_paths(trace: Trace):
	var font_size = %CharacterLabel.get_theme_font_size("font_size")
	var trace_scale = float(font_size) / float(trace.font_size)
	var trace_scale_vec = Vector2(trace_scale, trace_scale)
	
	for s_idx in range(0, trace.strokes.size()):
		var stroke = trace.strokes[s_idx]
				
		var stroke_path = StrokePath.new(s_idx)
		stroke_paths.append(stroke_path)
		
		for p_idx in range(0, stroke.points.size()):		
			var point = StrokePath.Point.new()
			point.position = clamp_vector(stroke.points[p_idx].position * trace_scale_vec)
			point.in_position = clamp_vector(stroke.points[p_idx].in_position * trace_scale_vec)
			point.out_position = clamp_vector(stroke.points[p_idx].out_position * trace_scale_vec)
			stroke_path.points.append(point)


func change_stroke(stroke_index: int):
	if stroke_index == selected_stroke_index:
		return

	selected_stroke_index = stroke_index
	
	delete_stroke_controls()
	create_stroke_controls(stroke_paths[stroke_index])
	
	%StrokePath.curve.clear_points()
	for control in stroke_controls:
		%StrokePath.curve.add_point(control.position)
		
		if control.in_point:
			%StrokePath.curve.set_point_in(control.index, control.in_point.position)
		
		if control.out_point:
			%StrokePath.curve.set_point_out(control.index, control.out_point.position)
	
	refresh_stroke_line()
	stroke_tree_view.select_stroke(stroke_index)


func create_stroke_controls(stroke_path: StrokePath):
	for p_idx in range(0, stroke_path.points.size()):	
		var control = stroke_control_scene.instantiate() as StrokeControl
		%ControlsContainer.add_child(control)
		stroke_controls.append(control)
		
		var stroke_path_point = stroke_path.points[p_idx]
		control.setup(p_idx, stroke_path_point.position)
		
		if stroke_path_point.in_position and stroke_path_point.in_position != Vector2.ZERO:
			control.in_point = stroke_control_in_out_scene.instantiate()
			control.in_point.setup(true)
			control.in_point.position = stroke_path_point.in_position
			control.add_child(control.in_point)
		
		if stroke_path_point.out_position and stroke_path_point.out_position != Vector2.ZERO:
			control.out_point = stroke_control_in_out_scene.instantiate()
			control.out_point.setup(false)
			control.out_point.position = stroke_path_point.out_position
			control.add_child(control.out_point)


func refresh_stroke_line():
	%StrokeLine.clear_points()
	for point in %StrokePath.curve.get_baked_points():
		%StrokeLine.add_point(point)


func collides_with_control_point(pos: Vector2) -> StrokeControl:
	for point in stroke_controls:	
		if point.collides_with(pos):
			return point
	return null


func collides_with_gui(_position: Vector2) -> bool:
	if %StrokesPanelContainer.get_rect().has_point(_position):
		return true
	if %CharacterPanelContainer.get_rect().has_point(_position):
		return true
	if %Menu.get_rect().has_point(_position):
		return true
	return false
	

func add_stroke_control(global_pos: Vector2):
	var local_position = %StrokeLine.to_local(global_pos)
	
	# Update the raw data
	var stroke_path = stroke_paths[selected_stroke_index]
	
	var stroke_path_point = StrokePath.Point.new()
	stroke_path_point.position = local_position
	stroke_path.points.append(stroke_path_point)
	
	# Update the on screen visuals
	var stroke_control = stroke_control_scene.instantiate() as StrokeControl
	%ControlsContainer.add_child(stroke_control)
	stroke_control.setup(stroke_controls.size(), local_position)
	stroke_control.select()
	stroke_controls.append(stroke_control)
	
	%StrokePath.curve.add_point(local_position)
	
	stroke_tree_view.add_stroke_control(stroke_path.index, stroke_control)


func move_selected_points(direction: Vector2):
	if shift_key_held:
		direction = direction * 10
		
	var stroke_path = stroke_paths[selected_stroke_index]
	var moved = false
	
	for control in stroke_controls:
		if control.is_selected:
			control.position = clamp_vector(control.position + direction)
			%StrokePath.curve.set_point_position(control.index, control.position)
			stroke_path.points[control.index].position = control.position
			moved = true
	
	if moved:
		stroke_tree_view.refresh_stroke(stroke_path)
		refresh_stroke_line()


func move_control_point(controls: Array[StrokeControl], direction: Vector2):
	var stroke_path = stroke_paths[selected_stroke_index]
	
	for control in controls:
		control.position = control.position + direction
		%StrokePath.curve.set_point_position(control.index, control.position)
		stroke_path.points[control.index].position = control.position


func move_control_in_and_out_point(control: StrokeControl, direction: Vector2):
	if control.in_point == null:
		control.in_point = stroke_control_in_out_scene.instantiate()
		control.in_point.setup(true)
		control.add_child(control.in_point)
		
	if control.out_point == null:
		control.out_point = stroke_control_in_out_scene.instantiate()
		control.out_point.setup(false)
		control.add_child(control.out_point)
	
	var point_in_pos = %StrokePath.curve.get_point_in(control.index)
	%StrokePath.curve.set_point_in(control.index, point_in_pos + direction)
	control.in_point.position = point_in_pos + direction
	
	var point_out_pos = %StrokePath.curve.get_point_out(control.index)
	%StrokePath.curve.set_point_out(control.index, point_out_pos + -direction)
	control.out_point.position = point_out_pos + -direction
	
	var stroke_path = stroke_paths[selected_stroke_index]
	var stroke_path_point: StrokePath.Point = stroke_path.points[control.index]
	stroke_path_point.in_position = control.in_point.position
	stroke_path_point.out_position = control.out_point.position


func clamp_vector(vector: Vector2) -> Vector2:
	return Vector2(roundi(vector.x), roundi(vector.y))


func create_in_out_points(stroke_control: StrokeControl):
	if stroke_control.in_point == null:
		stroke_control.in_point = stroke_control_in_out_scene.instantiate()
		stroke_control.in_point.setup(true)
		stroke_control.add_child(stroke_control.in_point)
		
	if stroke_control.out_point == null:
		stroke_control.out_point = stroke_control_in_out_scene.instantiate()
		stroke_control.out_point.setup(false)
		stroke_control.add_child(stroke_control.out_point)


func select_point(point_index: int):
	var stroke_control = stroke_controls[point_index]
	stroke_control.select()


func select_all_points():
	for stroke_control in stroke_controls:
		stroke_control.select()


func deselect_point(point_index: int):
	var stroke_control = stroke_controls[point_index]
	stroke_control.deselect()


func deselect_all_controls():
	for stroke_control in stroke_controls:
		stroke_control.deselect()


func delete_selected_points():
	var not_selected_controls = stroke_controls.filter(func(point): return point.is_selected == false)
	
	for control in stroke_controls:
		if  control.is_selected:
			control.queue_free()
			
	stroke_controls = not_selected_controls
	
	for idx in range(0, stroke_controls.size()):
		stroke_controls[idx].index = idx
	
	var stroke_path = stroke_paths[selected_stroke_index]
	stroke_path.points.clear()
	%StrokePath.curve.clear_points()
	
	for control in stroke_controls:
		var point = StrokePath.Point.new()
		stroke_path.points.append(point)
		point.position = control.position
		
		%StrokePath.curve.add_point(control.position)
		
		if control.in_point:
			point.in_position = control.in_point.position
			%StrokePath.curve.set_point_in(control.index, control.in_point.position)
		if control.out_point:
			point.out_position = control.out_point.position
			%StrokePath.curve.set_point_out(control.index, control.out_point.position)
	
	stroke_tree_view.clear()
	stroke_tree_view.setup(stroke_paths)
	stroke_tree_view.select_stroke(selected_stroke_index)
	refresh_stroke_line()


func _on_item_list_item_activated(index):
	if index != selected_character_index:
		save_changes()
		change_character(index)


func has_selected_points() -> bool:
	return stroke_controls.any(func(point): return point.is_selected)


func handle_stroke_point_chosen(point_index: int):
	var selected_controls = stroke_controls.filter(func(point): return point.is_selected)
	
	# Have I clicked on a point for the first time?
	if selected_controls.size() == 0:
		select_point(point_index)
	# Have I clicked on an already selected point?
	elif stroke_controls[point_index] in selected_controls:
		deselect_point(point_index)
	# I have clicked on a different point so I should switch selection to it
	else:
		deselect_all_controls()
		select_point(point_index)


func _on_add_stroke_button_pressed():
	var stroke_count = stroke_paths.size()
	var stroke_path = StrokePath.new(stroke_count)
	stroke_paths.append(stroke_path)
	stroke_tree_view.add_stroke(stroke_path.index)
	
	if stroke_count == 0:
		selected_stroke_index = 0
	else:
		change_stroke(stroke_count)
		

func _on_stroke_tree_stroke_selected(stroke_idx: int):
	if is_previewing:
		change_stroke(stroke_idx)
		delete_preview_stroke_points()
		#create_points(%StrokePath)
		create_start_point(%StrokePath)
		return
	
	if stroke_idx == selected_stroke_index:
		if has_selected_points():
			deselect_all_controls()
		else:
			select_all_points()
	else:
		change_stroke(stroke_idx)


func _on_stroke_tree_stroke_control_selected(stroke_idx: int, control_idx: int):
	if is_previewing:
		change_stroke(stroke_idx)
		delete_preview_stroke_points()
		#create_points(%StrokePath)
		create_start_point(%StrokePath)
		return
		
	if stroke_idx == selected_stroke_index:
		handle_stroke_point_chosen(control_idx)
	else:
		change_stroke(stroke_idx)
		select_point(control_idx)


func _on_file_item_menu_pressed(id: int):
	match id:
		0: 
			get_node(^"LoadFileDialog").popup_centered()
		1: 
			get_node(^"SaveFileDialog").popup_centered()
		_: 
			print("Unknown file menu item")


func _on_edit_item_menu_pressed(id: int):
	var selected_points = stroke_controls.filter(func(point): return point.is_selected)
	
	if selected_points.size() == 0 and id < 7:
		return
	
	match id:
		0: 
			EditMenu.align_selected_points_left(selected_points)
			stroke_tree_view.refresh_stroke(stroke_paths[selected_stroke_index])
		1: 
			EditMenu.align_selected_points_right(selected_points)
			stroke_tree_view.refresh_stroke(stroke_paths[selected_stroke_index])
		2: 
			EditMenu.align_selected_points_top(selected_points)
			stroke_tree_view.refresh_stroke(stroke_paths[selected_stroke_index])
		3: 
			EditMenu.align_selected_points_bottom(selected_points)
			stroke_tree_view.refresh_stroke(stroke_paths[selected_stroke_index])
		5:
			EditMenu.distribute_points_horizontally(selected_points)
		6:
			EditMenu.distribute_points_vertically(selected_points)
		8:
			move_stroke(-1)
		9:
			move_stroke(1)
		11:
			delete_all_strokes()
		_: 
			print("Unknown edit menu item")
			
			
func move_stroke(direction: int):
	if selected_stroke_index + direction == -1:
		return
		
	if selected_stroke_index + direction == stroke_paths.size():
		return
		
	#var new_stroke_index = selected_stroke_index + direction
		
	# TODO: Update the stroke_nodes
	#stroke_nodes[selected_stroke_index].index = new_stroke_index
	#stroke_nodes[new_stroke_index].index = selected_stroke_index
	#stroke_nodes.sort_custom(func(a, b): return a.index < b.index)
	#selected_stroke_index = new_stroke_index
	#
	#%StrokeTree.clear()
	#create_stroke_tree()


func delete_all_strokes():
	selected_stroke_index = -1
	stroke_paths.clear()
	stroke_tree_view.clear()
	stroke_tree_view.setup(stroke_paths)
	%StrokeLine.clear_points()
	%StrokePath.curve.clear_points()
	delete_stroke_controls()


func _on_preview_button_toggled(toggled_on):
	if stroke_paths.size() == 0:
		return
		
	is_previewing = toggled_on
	
	if toggled_on:
		deselect_all_controls()
		#create_points(%StrokePath)
		create_start_point(%StrokePath)
	else:
		delete_preview_stroke_points()


func create_points(path: Path2D):
	var point_width = 32.0
	var desired_separation = 80.0
	
	var path_length = path.curve.get_baked_length() - (point_width * 2.0)
	
	var estimated_point_count = path_length / desired_separation 
	var actual_point_count = roundi(estimated_point_count)
	var actual_separation = path_length / actual_point_count
	
	for index in range(0, actual_point_count + 1):
		var baked = null
		if index == actual_point_count:
			baked = path.curve.sample_baked_with_rotation(point_width + path_length)
		else:
			baked = path.curve.sample_baked_with_rotation(point_width + (index * actual_separation))
		
		var point_node = stroke_point_scene.instantiate() as StrokePointNode
		point_node.setup(index)
		stroke_points.append(point_node)
		%PointsContainer.add_child(point_node)
		point_node.transform = baked * Transform2D.FLIP_Y


func create_start_point(path: Path2D):	
	var baked = path.curve.sample_baked_with_rotation(0)
	var point_node = stroke_point_scene.instantiate() as StrokePointNode
	point_node.setup(0)
	stroke_points.append(point_node)
	%PointsContainer.add_child(point_node)
	point_node.transform = baked * Transform2D.FLIP_Y


func delete_preview_stroke_points():
	for point_node in stroke_points:
		point_node.queue_free()
	stroke_points.clear()
