extends Node3D

@onready var player_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawn_points: Node3D = $SpawnPoints
@onready var crew_hud: Control = $GameHUD/HUDS/CrewHUD
@onready var killer_hud: Control = $GameHUD/HUDS/KillerHUD
@onready var sabotage_hud: Control = $SabotageLayer/SabotageHUD

@export var player_scene: PackedScene
@export var crew_bar: Range
@export var killer_bar: Range

const TASKS_PER_PLAYER := 4

var ready_players: Array = []
var spawning_started := false
var assigned_tasks := {}
var progress := 0.0
var percent_per_task := 0.0
var my_tasks: Array = []

func _ready() -> void:
	player_spawner.spawn_path = NodePath("../Players")
	player_spawner.spawn_function = _spawn_player
	var local_id = multiplayer.get_unique_id()
	var is_killer = local_id == GameState.killer_id
	crew_hud.visible = not is_killer
	killer_hud.visible = is_killer
	crew_bar.max_value = 100
	killer_bar.max_value = 100
	if multiplayer.is_server():
		_mark_player_ready(1)
	else:
		_tell_server_map_ready.rpc_id(1)

#Бінди
func _input(event: InputEvent) -> void:
	var is_killer = multiplayer.get_unique_id() == GameState.killer_id
	if event.is_action_pressed("ui_use"):
		pass
	if event.is_action_pressed("ui_report"):
		pass
	if is_killer:
		if event.is_action_pressed("ui_sabotage"):
			sabotage_hud.show()
			$Players.get_node(str(multiplayer.get_unique_id())).set_controls_enabled(false)
		if event.is_action_pressed("ui_kill"):
			pass
		if event.is_action_pressed("ui_accept"):
			pass

func _on_close_pressed() -> void:
	sabotage_hud.hide()
	$Players.get_node(str(multiplayer.get_unique_id())).set_controls_enabled(true)

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
	_assign_tasks()

func _spawn_player(data: Dictionary) -> Node:
	var id: int = int(data["id"])
	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id, true)
	player.position = data["position"]
	player.rotation = data["rotation"]
	player.set_suit_color_index(int(GameState.player_color_indices.get(id, 0)))
	return player

func _assign_tasks() -> void:
	var all_ids: Array = []
	for t in get_tree().get_nodes_in_group("tasks"):
		all_ids.append(str(t.get_path()))
	var crew: Array = GameState.player_ids.filter(func(id): return id != GameState.killer_id)
	if crew.is_empty() or all_ids.is_empty():
		return
	var per_player := mini(TASKS_PER_PLAYER, all_ids.size())
	percent_per_task = 100.0 / float(crew.size() * per_player)
	for pid in crew:
		all_ids.shuffle()
		assigned_tasks[pid] = all_ids.slice(0, per_player)
		receive_tasks.rpc_id(pid, assigned_tasks[pid])
	update_progress.rpc(0.0)

@rpc("authority", "call_local", "reliable")
func receive_tasks(ids: Array) -> void:
	my_tasks = ids.duplicate()

func is_my_task(task_id: String) -> bool:
	return task_id in my_tasks

func finish_task(task_id: String) -> void:
	my_tasks.erase(task_id)
	request_complete_task.rpc_id(1, task_id)

@rpc("any_peer", "call_local", "reliable")
func request_complete_task(task_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = 1
	if not assigned_tasks.has(sender) or task_id not in assigned_tasks[sender]:
		return
	assigned_tasks[sender].erase(task_id)
	progress = minf(progress + percent_per_task, 100.0)
	update_progress.rpc(progress)
	if progress >= 100.0:
		print("Мирні виграли")

@rpc("authority", "call_local", "reliable")
func update_progress(value: float) -> void:
	crew_bar.value = value
	killer_bar.value = value

@rpc("any_peer", "reliable")
func _tell_server_map_ready() -> void:
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	if id in GameState.player_ids:
		_mark_player_ready(id)

@rpc("any_peer", "call_local", "reliable")
func request_teleport() -> void:
	if not multiplayer.is_server():
		return
	var requester := multiplayer.get_remote_sender_id()
	if requester == 0:
		requester = 1
	var points := spawn_points.get_children()
	points.shuffle()
	var targets := {}
	for i in range(GameState.player_ids.size()):
		var marker: Node3D = points[i % points.size()]
		targets[GameState.player_ids[i]] = {"pos": marker.global_position, "rot": marker.global_rotation.y}
	do_teleport.rpc(targets, requester)

@rpc("authority", "call_local", "reliable")
func do_teleport(targets: Dictionary, requester: int) -> void:
	var my_id := multiplayer.get_unique_id()
	var me := $Players.get_node_or_null(str(my_id))
	if me == null:
		return
	if targets.has(my_id):
		me.teleport_to(targets[my_id]["pos"], targets[my_id]["rot"])
	if my_id == requester:
		me.set_controls_enabled(true)
