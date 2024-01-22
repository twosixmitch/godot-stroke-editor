class_name LanguageFileInfo


var filename: String
var language: Enums.LanguageType
var data_type: Enums.DataType
var set_type: String


func _init(filename, language, data_type, set_type):
	self.filename  = filename
	self.language  = language
	self.data_type = data_type
	
	if set_type:
		self.set_type = set_type
