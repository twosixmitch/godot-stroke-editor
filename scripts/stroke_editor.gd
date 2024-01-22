class_name StrokeEditor 

extends Control

@export var character: Label
@export var character_list: ItemList
@export var stroke_tree: Tree
@export var stroke_point_scene: PackedScene

var traces: Array[Trace]
var stroke_point_nodes: Dictionary
var selected_character_index: int = -1
var selected_stroke_index: int = -1
var selected_stroke_point_index: int = -1


func _ready():
	%LoadButton.pressed.connect(self.load_pressed)
	%LoadFileDialog.file_selected.connect(self.load_file_selected)
	

func load_pressed():
	get_node(^"LoadFileDialog").popup_centered()


func load_file_selected(path: String):
	if FileAccess.file_exists(path):	
		var file = FileAccess.open(path, FileAccess.READ)
		var _header = file.get_csv_line()
		
		var lines: Array[PackedStringArray] = []
		while not file.eof_reached():
			lines.append(file.get_csv_line())
		
		self.load(lines)
		
		return true
	return false


func load(file_lines: Array[PackedStringArray]):
	traces = create_trace_models(file_lines)
	
	character_list.clear()
	for trace in traces:
		character_list.add_item("%s" % trace.character)
	
	character_list.select(0)
	change_character(0)
	
	
func create_trace_models(file_lines: Array[PackedStringArray]) -> Array[Trace]:
	var results: Array[Trace] = []
	
	for line in file_lines:
		var trace = Trace.new()
		trace.character = line[0]
		
		var current_stroke_id: String = ""
		var current_stroke: Trace.Stroke = null

		for index in range(2, line.size(), 3):
			var stroke_id = line[index]
			var point_x   = line[index+1]
			var point_y   = line[index+2]

			if stroke_id != current_stroke_id:
				current_stroke_id = stroke_id
				current_stroke = Trace.Stroke.new()
				trace.strokes.append(current_stroke)
			
			# TODO: Remove negative
			var point = Vector2(int(point_x), -int(point_y))
			current_stroke.points.append(point)

		results.append(trace)
		
	return results
	
	
func change_character(index: int):
	selected_character_index = index
	
	var trace = traces[index]
	%CharacterLabel.text = "%s" % trace.character
	
	create_stroke_tree(trace)
	create_stroke_point_nodes(trace)
	
	change_stroke(0, -1)
	

func create_stroke_point_nodes(trace: Trace):
	for key in stroke_point_nodes.keys():
		for item in stroke_point_nodes[key]:
			item.queue_free()
	
	stroke_point_nodes.clear()
	
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
			
			#point_node.position = (point_position * trace_scale_vec) + translation
			point_node.position = stroke.points[p_idx]
			%TracePointsContainer.add_child(point_node)


func create_stroke_tree(trace: Trace):
	stroke_tree.clear()
	
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
	

func change_stroke(stroke_index: int, point_index: int):
	if [stroke_index, point_index] == [selected_stroke_index, selected_stroke_point_index]:
		# Nothing should change, early escape
		return
	
	var old_stroke_index = selected_stroke_index
	var new_stroke_index = stroke_index
	
	var old_point_index = selected_stroke_point_index
	var new_point_index = point_index
	
	selected_stroke_index = new_stroke_index
	selected_stroke_point_index = new_point_index
	
	if old_stroke_index == new_stroke_index:
		# We are changing the selected point		
		if new_point_index == -1:
			pass # TODO: deselect all points
		else:
			pass # TODO: select this point only
	else:
		# We are changing the selected stroke
		if old_stroke_index > -1:
			for point in stroke_point_nodes[old_stroke_index]:
				point.make_active(false)
		
		for point in stroke_point_nodes[new_stroke_index]:
			point.make_active(true)	


func _on_item_list_item_activated(index):
	change_character(index)
	

func _on_tree_item_activated():
	var item = stroke_tree.get_selected()
	
	var stroke_index = -1
	var point_index = -1
	
	if item.get_child_count() > 0:
		# Selected a stroke
		stroke_index = item.get_index()
	else:
		# Selected a stroke point
		point_index = item.get_index()
		stroke_index = item.get_parent().get_index()
	
	change_stroke(stroke_index, point_index)
