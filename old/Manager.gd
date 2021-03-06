extends Node

# camera to use when no character is controlled
onready var _camera_node = $Camera

# store the currently controlled character
var _current_character = null
# store all characters in the scene here
var _characters = {}

func _ready():
	#_camera_node.make_current()
	pass

# manage mouse movements
func _input(event):
	# on escape display the menu
	if Input.is_key_pressed(KEY_ESCAPE): 
		get_tree().quit()

func _process(delta):
	pass



# return the list of characters of specified team in the given radius
func get_characters(team, position, radius):
	var out = []
	for c in _characters:
		if c.team == team and position.distance_to(c.global_transform.origin) < radius:
			out.append(c)
	return out




#func _ready():
#	var new_player = preload('res://player/Player.tscn').instance()
#	var id = get_tree().get_network_unique_id()
#	new_player.name = str(id)
#	new_player.set_network_master(id)
#	get_tree().get_root().add_child(new_player)
#	var info = Network.self_data
#	new_player.init(info.name, info.position, false)