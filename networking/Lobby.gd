extends Node

const PORT = 26462
const MAX_PLAYERS = 32
const CHARACTER   = preload('res://character/Character.gd')

const CHARACTERS = {
	'Dragonewt': preload('res://character/dragonewt/Dragonewt.tscn'),
	'Knight':    preload('res://character/knight/Knight.tscn'      ),
	'Rogue':     preload('res://character/rogue/Rogue.tscn'        ),
	'Wizard':    preload('res://character/wizard/Wizard.tscn'      )
}

# store the host in this object
var host = null

# list of players connected to the server
var _players = {}
# contains info relative to the user of this instance
var my_player = {
	name  = 'unnamed',
	team  = CHARACTER.TEAM.neutral,
	score = 0
}


# store the maps selected in a specific order
# (for now just store one map)
var _map_selected = null


func _ready():
	# add all callbacks
	get_tree().connect('network_peer_connected'   , self, '_player_connected'   )
	get_tree().connect('network_peer_disconnected', self, '_player_disconnected')
	get_tree().connect('connected_to_server'      , self, '_connection_ok'      )
	get_tree().connect('connection_failed'        , self, '_connection_fail'    )
	get_tree().connect('server_disconnected'      , self, '_server_disconnected')


## PUBLIC METHODS ##

func create_host(map_path):
	# prepare a host
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	var err = host.create_server(PORT, MAX_PLAYERS - 1)
	if err != OK:
		print('Failed to create host.')
		return null
	
	# host is ready
	get_tree().set_network_peer(host)
	self.host = host
	_select_map(map_path)
	return host


func join_host(ip):
	# get an IP to connect to
	if not ip.is_valid_ip_address():
		print('Invalid IP address.')
		return null
	
	# connect to host
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	var err = host.create_client(ip, PORT)
	if err != OK:
		print('Failed to connect to server: ' + ip)
		return null
	
	# client is ready
	get_tree().set_network_peer(host)
	self.host = host
	return host


func leave_host():
	var peer_id = get_tree().get_network_unique_id()
	# disconnect from server
	#get_tree().disconnect_network_peer(peer_id)
	# return to main menu
	get_tree().change_scene('res://menu/MainMenu.tscn')

## CALLBACKS ##

# player is now connected
func _player_connected(id):
	print('player with ID ' + str(id) + ' just connected.')

# player leaving server
func _player_disconnected(id):
	_players.erase(id)   # remove player
	delete_character(id) # remove the character if any
	print('player with ID ' + str(id) + ' left.')

# player connecting to server
func _connection_ok():
	print(my_player.name + ' joined server.')
	var id = get_tree().get_network_unique_id()
	rpc('_register_player', id, my_player)

# couldn't even connect to the server
func _connection_fail():
	print('Failed to connect to server.')

# server kicked us of from the server
func _server_disconnected():
	print('Kicked out of server.')


## CALLBACKS for CLIENTS ##

# add the player to the list
remote func _register_player(id, data):
	
	# local player register itself in its own list
	_players[id] = data
	print('Player ' + data.name + ' registered.')
	
	# if we are the server, send info about other players to the new one
	if get_tree().is_network_server():
		# send map to load
		rpc_id(id, '_select_map', _map_selected)
		# register server (necessary if server doesn't call _register_player)
		rpc_id(id, '_register_player', 1, data)
		# register other remote players
		for peer_id in _players:
			rpc_id(id, '_register_player', peer_id, _players[peer_id])
		
		# load the characters already on the map
		var characters = get_node('/root/Entities').get_children()
		for character in characters:
			# spawn already present characters
			var peer_id    = character.get_network_master()
			var class_name = character.get_class()
			var position   = character.translation
			rpc_id(id, 'spawn_character', peer_id, class_name, position)


# receive map to load
remote func _select_map(map_path):
	# TODO: check that map exists in files
	if map_path == null:
		return
	# store the current map and switch to it
	_map_selected = map_path
	get_tree().change_scene(map_path)


## MANAGE CHARACTERS ##

# spawn character on all peers
sync func spawn_character(peer_id, character_name, spawn_position):
	# check that we try to spawn the right character
	if not CHARACTERS.has(character_name):
		print('invalid character: ' + character_name)
		return
	# generate the character
	var character = CHARACTERS[character_name].instance()
	character.set_name(str(peer_id))
	# set the peer id of this character
	character.set_peer_id(peer_id)
	if peer_id == get_tree().get_network_unique_id():
		character.set_network_master(peer_id)
	character.translation = spawn_position
	# add the character
	get_node('/root/Entities').add_child(character)
	print(character_name + ' spawned for player ' + str(peer_id))


# remove a character
sync func delete_character(peer_id):
	var entities  = get_node('/root/Entities')
	var id = str(peer_id)
	if not entities.has_node(id):
		print("Couldn't find character with ID " + id)
		return
	var character = entities.get_node(id)
	# remove the node
	entities.remove_child(character)


