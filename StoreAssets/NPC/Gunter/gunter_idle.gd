extends CharacterBody3D

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true)

const SIT_TO_STAND := "Gunter_Standup"
const STAND_TO_SIT := "Gunter_Sitting_Down"
const SIT_IDLE := "Gunter_Sitting_Idle"
const BREATHING_IDLE := "Breathing_Idle"
const WALK := "Gunter_Walking"

const WALK_SPEED := 0.6
const WALK_DISTANCE := 5.0

const MIN_SIT_TIME := 15.0
const MAX_SIT_TIME := 35.0

const MIN_BREATHER_TIME := 2.0
const MAX_BREATHER_TIME := 5.0

const WALKS_BEFORE_RETURN := 2

var home_position: Vector3
var walks_done := 0
var target_position: Vector3
var walking := false


func _ready():
	print("GUNTER: Starting")

	if animation_player == null:
		push_error("GUNTER: AnimationPlayer not found")
		return

	print("GUNTER: AnimationPlayer found")

	print("GUNTER: Available animations:")

	for animation_name in animation_player.get_animation_list():
		print("  -> ", animation_name)

	home_position = global_position

	setup_animation(SIT_IDLE, true)
	play_animation(SIT_IDLE)

	print("GUNTER: Sitting idle")

	await get_tree().create_timer(
		randf_range(MIN_SIT_TIME, MAX_SIT_TIME)
	).timeout

	start_working()


func _physics_process(_delta):
	if not walking:
		return

	var direction := global_position.direction_to(target_position)
	direction.y = 0.0

	var distance := global_position.distance_to(target_position)

	print(
		"GUNTER: distance = ",
		distance,
		" target = ",
		target_position,
		" current = ",
		global_position
	)

	# Reached destination
	if distance < 0.15:
		velocity = Vector3.ZERO
		walking = false
		return

	direction = direction.normalized()

	# Face the direction Günter is travelling
	if direction.length() > 0.01:
		var target_rotation := atan2(direction.x, direction.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			0.15
		)

	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	velocity.y = 0.0

	move_and_slide()

	# Stop if his collision capsule is blocked
	if get_slide_collision_count() > 0:
		velocity = Vector3.ZERO
		walking = false

		print("GUNTER: Obstacle encountered")
func setup_animation(animation_name: String, looping: bool):
	var animation = animation_player.get_animation(animation_name)

	if animation == null:
		push_error(
			"GUNTER: Animation not found: "
			+ animation_name
		)
		return

	if looping:
		animation.loop_mode = Animation.LOOP_LINEAR
	else:
		animation.loop_mode = Animation.LOOP_NONE


func play_animation(
	animation_name: String,
	blend_time: float = 0.25,
	speed: float = 1.0
):
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name, blend_time, speed)
	else:
		push_error(
			"GUNTER: Missing animation: "
			+ animation_name
		)

func start_working():
	print("GUNTER: Getting up")

	setup_animation(SIT_TO_STAND, false)
	play_animation(SIT_TO_STAND, 0.25)

	await animation_player.animation_finished

	walks_done = 0

	walk_somewhere()


func walk_somewhere():
	if walks_done >= WALKS_BEFORE_RETURN:
		return_to_stool()
		return

	print("GUNTER: Going for a wander")

	var random_offset := Vector3(
		randf_range(-WALK_DISTANCE, WALK_DISTANCE),
		0.0,
		randf_range(-WALK_DISTANCE, WALK_DISTANCE)
	)

	target_position = home_position + random_offset

	setup_animation(WALK, true)
	play_animation(WALK, 0.25)

	walking = true

	await wait_until_stopped()

	print("GUNTER: Stopping for a breather")

	setup_animation(BREATHING_IDLE, true)
	play_animation(BREATHING_IDLE, 0.35)

	await get_tree().create_timer(
		randf_range(
			MIN_BREATHER_TIME,
			MAX_BREATHER_TIME
		)
	).timeout

	walks_done += 1

	walk_somewhere()


func wait_until_stopped():
	while walking:
		await get_tree().process_frame


func return_to_stool():
	print("GUNTER: Returning to stool")

	target_position = home_position

	setup_animation(WALK, true)
	play_animation(WALK, 0.25)

	walking = true

	await wait_until_stopped()

	print("GUNTER: Sitting down")

	setup_animation(STAND_TO_SIT, false)
	play_animation(STAND_TO_SIT, 0.25)

	await animation_player.animation_finished

	setup_animation(SIT_IDLE, true)
	play_animation(SIT_IDLE, 0.25)

	print("GUNTER: Back on stool")

	await get_tree().create_timer(
		randf_range(MIN_SIT_TIME, MAX_SIT_TIME)
	).timeout

	start_working()
