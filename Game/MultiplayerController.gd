extends Control

var peer
var last_num_of_players

@onready var players = $VBoxContainer2/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		host_game(5632)
		
	last_num_of_players = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not "--server" in OS.get_cmdline_args():
		if last_num_of_players != len(GameManager.Players):
			for n in players.get_children():
				players.remove_child(n)
				n.queue_free()
			for p in GameManager.Players:
				var label = Label.new()
				label.text = GameManager.Players[p].name
				players.add_child(label)
				
			last_num_of_players = len(GameManager.Players)
		
#Client and Server
func peer_connected(id):
	print("Player Connected " + str(id))
	
#Client and Server
func peer_disconnected(id):
	print("Player disconnected " + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.name == str(id):
			p.queue_free()
		
#Client
func connected_to_server():
	print("Connected to server")
	SendPlayerInformation.rpc_id(1, $VBoxContainer/HBoxContainer/LineEdit.text, multiplayer.get_unique_id())
	
#Client
func connection_failed():
	print("couldn't connect")
	
func show_others():
	$VBoxContainer.hide()
	$VBoxContainer2.show()

func host_game(port):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	if error != OK:
		print("Cannot Host " + error)
		return	
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	show_others()
	print("Waiting for Players!")

func _on_host_pressed():
	host_game(int($VBoxContainer/HBoxContainer2/LineEdit3.text))
	SendPlayerInformation($VBoxContainer/HBoxContainer/LineEdit.text, multiplayer.get_unique_id())

func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client($VBoxContainer/HBoxContainer2/LineEdit2.text, int($VBoxContainer/HBoxContainer2/LineEdit3.text))
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	show_others()

@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name" : name,
			"id" : id,
			"score" : 0
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)

@rpc("any_peer", "call_local")	
func StartGame():
	var scene = load("res://Game/testScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_start_pressed():
	StartGame.rpc()
