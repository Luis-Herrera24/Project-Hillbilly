extends CharacterBody3D

enum States { PATROL, COMBAT, SEARCH }

@onready var player = %Player

var health = 5
var state = States.PATROL
var hit_audio: AudioStreamPlayer3D
var death_audio: AudioStreamPlayer3D
var patrol_points = []
var patrol_radius = 10.0
var number_of_patrol_points = 5 
var current_target = 0
var speed = 1.0
var arrived_distance = 1.0
var navigation_agent: NavigationAgent3D
var patrol_timer: Timer
var wait_time = 3.0
var is_waiting = false
var attack_distance = 2
var sight_distance = 20

func _process(delta):
	match state:
		States.PATROL:
			patrol_behavior(delta)
		States.COMBAT:
			combat_behavior(delta)
		States.SEARCH:
			search_behavior(delta)

func spawn():
	navigation_agent = NavigationAgent3D.new()
	add_child(navigation_agent)
	generate_patrol_points()
	if patrol_points.size() > 0:
		navigation_agent.set_target_position(patrol_points[current_target])
	
	if patrol_timer:
		patrol_timer.wait_time = wait_time

func patrol_behavior(delta):
	if patrol_points.size() <= 0 or is_waiting: return
	
	var player_position = player.global_transform.origin
	var location = global_transform.origin
	var target_location = patrol_points[current_target]
	
	if location.distance_to(target_location) <= arrived_distance:
		is_waiting = true
		patrol_timer.start()

	var next_point = navigation_agent.get_next_path_position()
	
	if next_point != Vector3.INF:
		var direction = (next_point - location).normalized()
		velocity = direction * speed
		move_and_slide()
		if player_heard() or player_in_fov(direction):
			state = States.COMBAT
			return


func combat_behavior(delta):
	if player == null: return 

	var player_position = player.global_transform.origin
	var location = global_transform.origin
	
	navigation_agent.set_target_position(player_position)
	
	if location.distance_to(player_position) <= attack_distance:
		attack_player()
	else:
		var next_point = navigation_agent.get_next_path_position()
		if next_point != Vector3.INF:
			var direction = (next_point - location).normalized()
			velocity = direction * speed
			move_and_slide()
			if not player_heard() and not player_in_fov(direction):
				state = States.SEARCH
				return

func search_behavior(delta):
	state = States.PATROL
	return

func player_heard():
	var detection_radius = 10.0
	if not player.is_moving: return false
	if state == States.COMBAT: detection_radius = detection_radius * 2.0
	elif player.is_crouching: detection_radius = detection_radius / 2.0
	elif player.is_sprinting: detection_radius = detection_radius * 2.0
	if global_transform.origin.distance_to(player.global_transform.origin) < detection_radius:
		return true
	return false

func player_in_fov(current_direction):
	var direction_to_player = (player.global_transform.origin - global_transform.origin).normalized()
	var distance_to_player = (player.global_transform.origin - global_transform.origin).length()
	var angle_to_player = acos(current_direction.dot(direction_to_player))
	angle_to_player = rad_to_deg(angle_to_player)
	
	var crouching_modifier = 1.0
	if %Player.is_crouching: crouching_modifier = 0.5
	if angle_to_player <= 30.0  * crouching_modifier:
		if distance_to_player <= sight_distance * crouching_modifier:
			if not player_obscured():
				return true
	return false

func player_obscured():
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = global_transform.origin
	ray_query.to = %Player.global_transform.origin
	var result = space_state.intersect_ray(ray_query)
	return result and result.collider != %Player

func attack_player():
	pass

func apply_damage(damage):
	health -= damage
	if hit_audio: hit_audio.play()
	if health <= 0:
		die()

func die():
	if death_audio:
		death_audio.play()
	else: 
		queue_free()

func generate_patrol_points():
	var rng = RandomNumberGenerator.new()
	for i in range(number_of_patrol_points):
		var random_direction = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
		var random_distance = rng.randf_range(0, patrol_radius)
		var patrol_point = global_transform.origin + random_direction * random_distance
		patrol_points.append(patrol_point)
