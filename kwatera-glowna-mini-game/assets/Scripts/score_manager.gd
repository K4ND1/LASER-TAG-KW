
extends Node
const SAVE_PATH = "user://highscores.json" ## Reference to the path that json files are supposed to be saved at 
## This path will be automatically overwritten when exporting to html format

# The function is static bcuz this whole script is an autoscript that runs without a scene attached to it
static func save_new_score(new_score: int) -> Array:
	# Load scores into a array and appends a new score that is given as a parameter
	var scores = load_scores()
	scores.append(new_score)
	
	# Sortin the array in order to be able to display it later
	scores.sort()
	scores.reverse()
	
	# We are slicing the array so that only top 5 scores remain in history
	if scores.size() > 5:
		scores = scores.slice(0, 5)
		
	# We are opening a file in write mode
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		# If the file is at it's right place save it as a json and close the file
		var json_string = JSON.stringify(scores)
		file.store_string(json_string)
		file.close()
		
	# This whole function returns the list of highscores so that it can be displayed in the menu
	return scores


static func load_scores() -> Array:
	# If the file doesnt exist return an empty array
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	
	# Opens the file safely in read mode
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		# We are getting the text from the current file and then parsing it into json format
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		
		# If the formating was succesful return the data in json format
		if json.parse(content) == OK:
			return json.data
	return []
