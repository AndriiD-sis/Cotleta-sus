extends CharacterBody3D

var controls_enabled := true
var near_vent = null
var vents: Array = []
var vent_index := 0
var previous_vent_state := false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SUIT_COLORS: Array[Color] = [
	Color("#FF0000"),
	Color("#FF7F00"),
	Color("#FFFF00"),
	Color("#00C853"),
	Color("#2979FF"),
	Color("#3F00FF"),
	Color("#8E24AA"),
	Color("#FF4081")
]

@export var is_walking: bool = false
@export var in_vent := false

@onready var camera: Camera3D = $Camera3D
@onready var animation = $"CollisionShape3D/among-defult/AnimationPlayer"
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var model: Node3D = $"CollisionShape3D/among-defult"
@onready var base_layer := collision_layer
@onready var base_mask := collision_mask

func _ready() -> void:
	animation.speed_scale = 3
	if sync.is_multiplayer_authority():
		camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Рух
func _physics_process(delta: float) -> void:
	if not sync.is_multiplayer_authority():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if in_vent:
		return
	var input_dir := Vector2.ZERO
	if controls_enabled:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	is_walking = direction.length() > 0.01
	move_and_slide()
	
#Камера
func _input(event):
	if not sync.is_multiplayer_authority():
		return
	if not controls_enabled:
		return
	if event.is_action_pressed("ui_accept"):
		if in_vent:
			exit_vent()
		else:
			try_enter_vent()
		return
	if in_vent:
		if event.is_action_pressed("ui_left"):
			_vent_step(-1)
		elif event.is_action_pressed("ui_right"):
			_vent_step(1)
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.003)
		camera.rotate_x(-event.relative.y * 0.003)
		camera.rotation.x = clamp(camera.rotation.x,deg_to_rad(-80),deg_to_rad(80))

#анімки для різних осіб
func _process(_delta: float) -> void:
	if is_walking:
		if animation.current_animation != "walk":
			animation.play("walk")
	else:
		if animation.is_playing():
			animation.stop()
	if previous_vent_state != in_vent:
		model.visible = not in_vent
		previous_vent_state = in_vent

#зміна кольору
func set_suit_color_index(color_index: int) -> void:
	var color = SUIT_COLORS[posmod(color_index, SUIT_COLORS.size())]
	_recolor_parts(self, color)

func _recolor_parts(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		var node_name = node.name.to_lower()
		if mesh_instance.mesh != null:
			for i in range(mesh_instance.mesh.get_surface_count()):
				var mat = mesh_instance.get_active_material(i)
				if not mat is StandardMaterial3D:
					continue
				var material_name = mat.resource_name.to_lower()
				if node_name in ["body", "back"] or material_name in ["body", "back"]:
					var new_mat = mat.duplicate() as StandardMaterial3D
					new_mat.albedo_color = color
					mesh_instance.set_surface_override_material(i, new_mat)
	for child in node.get_children():
		_recolor_parts(child, color)

#блок руху
func set_controls_enabled(value: bool) -> void:
	controls_enabled = value
	if value:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_walking = false

#телепорт
func teleport_to(pos: Vector3, rot_y: float) -> void:
	global_position = pos
	rotation = Vector3(0, rot_y, 0)
	velocity = Vector3.ZERO

#функції люка
func try_enter_vent() -> void:
	if near_vent == null:
		return
	vents = get_tree().get_nodes_in_group("vents")
	vents.sort_custom(func(a, b): return str(a.get_path()) < str(b.get_path()))
	vent_index = vents.find(near_vent)
	in_vent = true
	model.visible = false
	is_walking = false
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	global_position = near_vent.spot()

func exit_vent() -> void:
	in_vent = false
	model.visible = true
	collision_layer = base_layer
	collision_mask = base_mask

func _vent_step(dir: int) -> void:
	if vents.size() < 2:
		return
	vent_index = posmod(vent_index + dir, vents.size())
	global_position = vents[vent_index].spot()
