extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

@onready var head = $Head

var camera_pitch = 0.0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

			camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
			camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))

			head.rotation.x = camera_pitch

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# WASD movement
	var input_dir = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1

	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1

	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
