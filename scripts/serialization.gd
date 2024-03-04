class_name Serialization


static func import(file_lines: Array[PackedStringArray]) -> Array[Trace]:
	var results: Array[Trace] = []
	
	for line in file_lines:
		if line.size() == 1:
			continue
	
		var trace = Trace.new()
		trace.character = line[0]
		trace.font_size = line[1].to_int()
		
		var current_stroke_id: String = ""
		var current_stroke: TraceStroke = null

		for index in range(2, line.size(), 7):
			var stroke_id = line[index]
		
			if stroke_id != current_stroke_id:
				current_stroke_id = stroke_id
				current_stroke = TraceStroke.new()
				trace.strokes.append(current_stroke)
			
			var position = Vector2(int(line[index+1]), int(line[index+2]))
			var in_position = Vector2(int(line[index+3]), int(line[index+4]))
			var out_position = Vector2(int(line[index+5]), int(line[index+6]))
			
			var trace_point = TraceStroke.Point.new()
			trace_point.position = position
			trace_point.in_position = in_position
			trace_point.out_position = out_position
			current_stroke.points.append(trace_point)

		results.append(trace)
		
	return results


static func export(traces: Array[Trace], font_size: int) -> Array[PackedStringArray]:
	var results: Array[PackedStringArray] = []
	results.append(PackedStringArray(["Character", "Font Size", "Strokes"]))
	
	for trace in traces:
		var values = [trace.character, font_size]
	
		for s_idx in range(0, trace.strokes.size()):
			var stroke = trace.strokes[s_idx]
			for point in stroke.points:
				values.append("s:%s" % s_idx)
				
				values.append("%s" % point.position.x)
				values.append("%s" % point.position.y)
				
				values.append("%s" % point.in_position.x)
				values.append("%s" % point.in_position.y)
				
				values.append("%s" % point.out_position.x)
				values.append("%s" % point.out_position.y)
		
		results.append(PackedStringArray(values))
		
	return results
