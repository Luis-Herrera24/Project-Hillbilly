extends "res://scripts/Weapon.gd"

const SWING_SPEED = 10.0
const BOB_SPEED = 0.025
const BOB_OFFSET = 0.01
const ANIM_SPEED = 8.0

@onready var original_rotation_degrees = rotation_degrees
@onready var original_position = position
var swing_rotation_degrees = Vector3 (-95, 55, 5)
var swing_position = Vector3 (-0.9, -0.4, -1.093)

func _ready():
	damage = 2
	range = Vector3(50.0, 50.0, 3)
	ranged = false 
	original_pos = position
	original_rot = rotation
	block_pos = Vector3 (-0.221, 0.289, -0.688)
	block_rot = Vector3 (-1.5, 31, 28)
	bob_max = position.y + BOB_OFFSET
	bob_min = position.y - BOB_OFFSET
	swing_duration = 0.4

func _process(delta):
	if not visible: 
		is_blocking = false
		return
	
	if is_swinging:
		if swing_timer > swing_duration / 2:
			rotation_degrees = rotation_degrees.lerp(swing_rotation_degrees, SWING_SPEED * delta)
			position = position.lerp(swing_position, SWING_SPEED * delta)
		else:
			rotation_degrees = rotation_degrees.lerp(original_rotation_degrees, SWING_SPEED * delta)
			position = position.lerp(original_position, SWING_SPEED * delta)
		
		swing_timer -= delta
		if swing_timer <= 0.0:
			is_swinging = false
			player.can_switch = true
			position = original_position
			rotation_degrees = original_rotation_degrees
	
	if is_blocking:
		rotation_degrees = rotation_degrees.lerp(block_rot, ANIM_SPEED * delta)
		position = position.lerp(block_pos, ANIM_SPEED * delta)
	elif position.direction_to(original_position) > Vector3(0.5,0.5,0.5):
		rotation_degrees = rotation_degrees.lerp(original_rotation_degrees, ANIM_SPEED * delta)
		position = position.lerp(original_position, ANIM_SPEED * delta)
	
	var bob_speed
	if not %Player.is_moving or %Player.is_crouching:
		bob_speed = BOB_SPEED * 0.25
	elif %Player.is_sprinting:
		bob_speed = BOB_SPEED * 2
	else:
		bob_speed = BOB_SPEED 
	
	if bob_up:
		if position.y >= bob_max: bob_up = false
		position.y += bob_speed * delta
	else:
		if position.y <= bob_min: bob_up = true
		position.y -= bob_speed * delta
