class_name Serialization


static func import(file_lines: Array[PackedStringArray]) -> Array[Trace]:
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


static func export(traces: Array[Trace]) -> Array[PackedStringArray]:
	var results: Array[PackedStringArray] = []
	
	for trace in traces:
		var values = [trace.character, "1000"]
	
		for s_idx in range(0, trace.strokes.size()):
			var stroke = trace.strokes[s_idx]
			for point in stroke.points:
				values.append("s:%s" % s_idx)
				values.append("%s" % point.x)
				values.append("%s" % point.y)
		
		results.append(PackedStringArray(values))
		
	return results
