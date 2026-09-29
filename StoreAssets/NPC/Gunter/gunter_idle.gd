extends Node3D

@onready var animation_player = $AnimationPlayer

func _ready():
	var animation = animation_player.get_animation("mixamo_com")
	animation.loop_mode = Animation.LOOP_LINEAR
	animation_player.play("mixamo_com")
	
