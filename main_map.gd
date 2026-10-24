extends Node3D

@export var player_scene: PackedScene

@onready var player_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawn_points: Node3D = $SpawnPoints
@onready var crew_hud: Control = $GameHUD/HUDS/CrewHUD
@onready var killer_hud: Control = $GameHUD/HUDS/KillerHUD

var ready_players: Array = []
var spawning_started := false

func _ready() -> void:
	player_spawner.spawn_path = NodePath("../Players")
	player_spawner.spawn_function = _spawn_player
	var local_id = multiplayer.get_unique_id()
	var is_killer = local_id == GameState.killer_id
	crew_hud.visible = not is_killer
	killer_hud.visible = is_killer
	if multiplayer.is_server():
		_mark_player_ready(1)
	else:
		_tell_server_map_ready.rpc_id(1)

#Бінди
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_use"):
		pass
	if event.is_action_pressed("ui_report"):
		pass
	if event.is_action_pressed("ui_sabotage"):
		pass
	if event.is_action_pressed("ui_kill"):
		pass
	if event.is_action_pressed("ui_accept"):
		pass

func _mark_player_ready(id: int) -> void:
	if id not in ready_players:
		ready_players.append(id)
	if ready_players.size() == GameState.player_ids.size():
		_spawn_all_players()

func _spawn_all_players() -> void:
	if not multiplayer.is_server() or spawning_started:
		return
	spawning_started = true
	var points = spawn_points.get_children()
	points.shuffle()
	for i in range(GameState.player_ids.size()):
		var marker = points[i % points.size()]
		var spawn_data = {
			"id": GameState.player_ids[i],
			"position": marker.position,
			"rotation": marker.rotation
		}
		player_spawner.spawn(spawn_data)

func _spawn_player(data: Dictionary) -> Node:
	var id: int = int(data["id"])
	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id, true)
	player.position = data["position"]
	player.rotation = data["rotation"]
	player.set_suit_color_index(int(GameState.player_color_indices.get(id, 0)))
	return player

@rpc("any_peer", "reliable")
func _tell_server_map_ready() -> void:
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	if id in GameState.player_ids:
		_mark_player_ready(id)
