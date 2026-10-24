extends CharacterBody3D

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

@onready var camera: Camera3D = $Camera3D
@onready var animation = $"CollisionShape3D/among-defult/AnimationPlayer"
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

func _ready() -> void:
	animation.speed_scale = 3
	if sync.is_multiplayer_authority():
		camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.clear_current()

# Рух
func _physics_process(delta: float) -> void:
	if not sync.is_multiplayer_authority():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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
