
extends Node3D

var peer = ENetMultiplayerPeer.new()

@export var player_scene: PackedScene

@onready var player_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var start_button: Button = $LobbyHUD/Control/Start
@onready var ip_get: LineEdit = $Join_data/Control/IP
@onready var port_get: LineEdit = $Join_data/Control/Port

func _ready() -> void:
	player_spawner.spawn_function = _spawn_player
	start_button.pressed.connect(_on_start_pressed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _show_lobby_hud() -> void:
	$LobbyHUD.show()
	start_button.disabled = not multiplayer.is_server()

func _on_host_pressed() -> void:
	var error = peer.create_server(1487, 7)
	if error != OK:
		print("Помилка сервера: ", error)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	GameState.player_color_indices.clear()
	GameState.player_color_indices[1] = 0
	player_spawner.spawn({"id": 1, "color_index": 0})
	$Chose_host.hide()
	_show_lobby_hud()

func _on_enter_pressed() -> void:
	var ip = ip_get.text.strip_edges()
	var port = int(port_get.text.strip_edges())
	var client_peer = ENetMultiplayerPeer.new()
	var error = client_peer.create_client(ip, port)
	if error != OK:
		print("Помилка створення клієнта: ", error)
		_on_connection_failed()
		return
	peer = client_peer
	multiplayer.multiplayer_peer = peer

func _on_back_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_back_chose_pressed() -> void:
	$Chose_host.show()
	$Join_data.hide()

func _on_join_pressed() -> void:
	$Chose_host.hide()
	$Join_data.show()

func _on_connected_to_server() -> void:
	$Chose_host.hide()
	$Join_data.hide()
	_show_lobby_hud()

func _on_connection_failed() -> void:
	$Join_data.show()
	ip_get.text = "Wrong IP"
	port_get.text = "Wrong Port"
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

#Бінди
func _input(event: InputEvent) -> void:
	if $LobbyHUD.visible:
		if event.is_action_pressed("ui_accept"):
			_on_start_pressed()

func _on_start_pressed() -> void:
	if not multiplayer.is_server():
		return
	peer.refuse_new_connections = true
	var ids: Array = [1]
	for id in multiplayer.get_peers():
		if id not in ids:
			ids.append(id)
	var selected_killer: int = ids.pick_random()
	switch_to_map.rpc(ids, selected_killer, GameState.player_color_indices)
	
func _on_peer_connected(id: int) -> void:
	var color_index = _get_free_color_index()
	if color_index == -1:
		peer.disconnect_peer(id)
		return
	GameState.player_color_indices[id] = color_index
	player_spawner.spawn({"id": id,"color_index": color_index})

func _on_peer_disconnected(id: int) -> void:
	GameState.player_color_indices.erase(id)

func _spawn_player(data: Variant) -> Node:
	var id = int(data["id"])
	var color_index = int(data["color_index"])
	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id, true)
	player.set_suit_color_index(color_index)
	return player

func _get_free_color_index() -> int:
	var used_indices: Array = GameState.player_color_indices.values()
	for index in range(8):
		if not used_indices.has(index):
			return index
	return -1

func exit_game(id: int) -> void: #not use
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id: int) -> void:
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id: int) -> void:
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()

@rpc("authority", "call_local", "reliable")
func switch_to_map(ids: Array, selected_killer: int, colors: Dictionary) -> void:
	GameState.player_ids = ids.duplicate()
	GameState.killer_id = selected_killer
	GameState.player_color_indices = colors.duplicate()
	var error = get_tree().change_scene_to_file("res://main-map.tscn")
	if error != OK:
		push_error("Не вдалося завантажити основну карту.")
