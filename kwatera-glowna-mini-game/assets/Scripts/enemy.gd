extends CharacterBody2D

# Main enemy script. 
# The whole script will be heavily commented this shit a bit to complicated for me. All of the comments were written by hand at 2am...
# I doubt anyone will be ever reading this code but u can see how my mental deteriorates with every next comment
# Planning to do script documentation in repo.

# I SHOULD'VE JUST DO THE STATE MASHINE IN DIFFERENT SCRIPTS, THAT WOULD BE SO MUCH BETTER

enum State { ROAM, CHASE }
var current_state = State.ROAM ## Set starting state of the enemy to ROAM

# Each state has a differnt movement speed set up.
const ROAM_SPEED = 20.0
const CHASE_SPEED = 30.0

@export var health: float = 60 ## Enemy health

@export var roam_radius: float = 200.0 ## The distance that enemy can roam in freely. 
@export var lose_sight_delay: float = 0.8 ## Time the enemy remembers the player
var lose_sight_timer: float = 0.0 ## Timer responisble for smooth transition from chase to roam

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D ## Reference to the navigation agent
@onready var roam_timer: Timer = $RoamTimer ## Reference to the roam timer that takes care of the pauses between choosing new points for roaming
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D  ## Reference to the CollisionShape that is supposed to detect player
@onready var enemy_collider: CollisionShape2D = $CollisionShape2D ## Enemy collider
@onready var postac_anim: AnimatedSprite2D = $"postac anim" ## Reference to the enemy sprite

@onready var laser_anim: AnimatedSprite2D = $laser_anim ## Refernce to the animation sprite of the laser 
@onready var bron_anim: AnimatedSprite2D = $bron_anim ## Reference to the animation sprite of the weapon
@onready var laser: RayCast2D = $laser ## Reference to the enemies raycast that takes care of applying dmg

var laser_detection_len: float ## Value that will be overriden by the detection area radius
@export var laser_dmg_len: float = 130.0 ## Specifically the lenght that enemy shot can reach
@export var damage_dealt: float = 10 ## Damage that enemy deals to the player

var target_player: Node2D = null ## If in chase state this variable is resposible for moving towards the player
var player_in_area: Node2D = null  ## Variable that saves calculation power for raycasting. Raycasting will not begin if the player is not in the area
var home_position: Vector2  ## Starting variable for finding new spot to roam to

var nav_map_RID: RID ## RID of the navigation map so that it doesn't have to be called everytime enemy is picking new roam target

@export_flags_2d_physics var line_of_sight_mask: int = 1 # Masks for the "line of sight" ray casting.	

var detection_radius: float = 200.0  ## Detection radius that is being overriden by the raidus of the node CollisionShape2D

func _ready() -> void:
	roam_timer.one_shot = true ## Forcing the roam timer to be a oneshot, so that it will not send a signal periodacally
	home_position = global_position ## Get the home position for roaming as starting enemy position
	
	# Check if the detection shape is not null and if it is a circle. If that is true override the detection radius variable
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_radius = detection_shape.shape.radius
	
	laser_detection_len = detection_radius ## Overwritting the laser detection lenght with radius
		
	call_deferred("_init_navigation") ## Safely turn on navigation for the enemy


func _init_navigation() -> void: ## Navigation safe start script 
	nav_map_RID = get_world_2d().navigation_map
	
	# If map iteration is equal to zero it means that it has not yet fully loaded, so we make it wait until we get the signal that the map is changed
	if NavigationServer2D.map_get_iteration_id(nav_map_RID) == 0:
		await NavigationServer2D.map_changed
		
	# At this point map is loaded and we can pick first roam target
	_pick_new_roam_target()


func _physics_process(delta: float) -> void:
	# Switches from walk and default anims
	_handle_animations()
	
	# Take care of the hysteresis when player is on the edge of the detection area
	_check_detection_hysteresis()

	# State mashine, nothing else to say here
	match current_state:
		State.ROAM:
			_roam_behavior(delta)
			# If players is in the area and the enemy has sight of him transition to the chase state
			if player_in_area and _has_line_of_sight():
				_transition_to_chase(player_in_area)
			
		State.CHASE:
			_chase_behavior(delta)
			if player_in_area and _has_line_of_sight():
				lose_sight_timer = 0.0 ## Reset the timer to 0 cuz we are not currently handling transition from chase to roam
			else:
				# Else start the timer for transitioning from chase to roam.
				lose_sight_timer += delta
				if lose_sight_timer >= lose_sight_delay:
					_transition_to_roam()
	
	move_and_slide() ## Built in godot function that allows character body 2d move and slide on walls

# --- HYSTERESIS ---: Handles enemy glitching when player is on the border of the detection area 
func _check_detection_hysteresis() -> void:
	# If players is in the area check it also manually by looking at the distance. 
	# If after checking manually he's not, then set player_in_area tu null
	if player_in_area:
		var distance = global_position.distance_to(player_in_area.global_position)
		if distance > (detection_radius + 10.0):
			player_in_area = null

# --- LINE OF SIGHT, RAYCASTING ---: Using godots built in physics handling checks if the player is in direct sight of the enemy
func _has_line_of_sight() -> bool:
	# If player in area isn't null set current target to it, else set it to target_player.
	# If both of these variables are null then end this function
	var current_target = player_in_area if player_in_area else target_player
	if not current_target:
		return false
	
	## We are getting a temporary reference the the world space state
	var space_state = get_world_2d().direct_space_state
	## We are making a variable that generates a ray from the position of the enemy to the current position of the enemy
	var query = PhysicsRayQueryParameters2D.create(global_position, current_target.global_position)
	
	# Make the ray exclude in his detection the enemy object. And apply the mask that was set in inspector
	query.exclude = [get_rid()]
	query.collision_mask = line_of_sight_mask
	
	# If the ray is not being intercepted by an obstacle return true, else return false
	var result = space_state.intersect_ray(query)
	if result:
		return result.collider == current_target
	return false

# --- STATE TRANSITION ---: Two functions that take care of the state mashines transitions. 
# They dont handle when the transition happen, they only apply it
func _transition_to_chase(player: Node2D) -> void:
	#print("CHASE") ## [DEBUG]
	
	target_player = player ## Set target to player
	current_state = State.CHASE ## Change the state in current state
	lose_sight_timer = 0.0 ## Reset lose sight timer
	roam_timer.stop() ## Stop roam timer, cuz the enemy is not roaming anymore

func _transition_to_roam() -> void:
	#print("ROAM") ## [DEBUG]
	
	target_player = null ## Reset the target
	current_state = State.ROAM ## Change state in current state
	
	# Set the position that the enemy has lost the player as a new home position and pich a new roam target
	home_position = global_position 
	_pick_new_roam_target()

# --- ROAM FUNCTIONS ---: Set of functions that take care of the enemy behaviour during the roam state
func _roam_behavior(delta: float) -> void:
	_on_collision_with_wall() ## When colliding with an obstacle force to find a new roam target

	# If the enemy has reached the roam destination change his velocity to zero.
	# If at that point the roam timer is not going of, start it for the random amount of time ranging from 1 to 3 secs
	# When the timer runs out it will send a signal to the _on_roam_timer_timeout and it will trigger a new point to roam to
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		if roam_timer.is_stopped():
			roam_timer.start(randf_range(1.0, 3.0))
		return
	
	# A function that will be calculating the right speed based on the distance from the obstacle
	_calculate_scaling_ms(ROAM_SPEED, 5.0, 5.0, delta)


func _pick_new_roam_target() -> void:
	roam_timer.stop()
	
	# We are getting a random offset within the boundries of the roam radius, also setting minimum lenght for that point.
	var random_offset: Vector2 = Vector2.ZERO
	while random_offset.length() < 30:
		random_offset = Vector2(
			randf_range(-roam_radius, roam_radius),
			randf_range(-roam_radius, roam_radius)
		)
		
	# We set that offset to the current home roaming position
	var desired_point = home_position + random_offset
	
	# We are making the enemy pick a safe point on the navigation map through a ref to RID. Then we apply it as new target point.
	var safe_point = NavigationServer2D.map_get_closest_point(nav_map_RID, desired_point)
	nav_agent.target_position = safe_point

func _on_roam_timer_timeout() -> void: ## Signal from timer
	#print("TIMER RUN OUT") ##[DEBUG]
	_pick_new_roam_target()

# --- CHASE FUNCTION ---: This func takes care of enemy behaviour during chase state
func _chase_behavior(delta: float) -> void:
	# If the target player is not set to null then we ignore the function
	if target_player:
		# IMPORTANT This shit is carrying all of the bugs on its shoulders
		# If the distance from the last know player position is closer than current player position by certain amount of pixels
		# ignore the update. This takes of lot's of calculation power and helps with jittering
		if nav_agent.target_position.distance_to(target_player.global_position) > 10.0:
			nav_agent.target_position = target_player.global_position
		
		# If the raycast that handles laser bumps into the enemy go into attack mode and extend it
		if laser.get_collider() != null and laser.get_collider().is_in_group("Player"):
			laser.scale.x = laser_dmg_len
			_apply_dmg(delta)
		
		# Desribed with the function itself
		_calculate_scaling_ms(CHASE_SPEED, 5.0, 10.0, delta)

@export var _shooting_time_delay: float = 1.0
var _shooting_timer: float = 0
func _apply_dmg(in_delta: float):
	if _shooting_timer < _shooting_time_delay:
		_shooting_timer += in_delta
	else:
		_shooting_timer = 0

		var collision_point = laser.get_collision_point()
		var dis = laser_anim.global_position.distance_to(collision_point)
	
		laser_anim.scale.x = dis/laser_dmg_len * 0.95 # hardcoded, can't figure this shit out
		
		target_player._get_hit(damage_dealt)
		laser_anim.play("shoot")
		bron_anim.play("shoot")
		
		
#---------------------------------------------------------
func _calculate_scaling_ms(MS: float, distance_to_trigger: float, rotation_speed: float, delta_in: float) -> void:
	
		var next_path_pos = nav_agent.get_next_path_position() ## Holds the position of the next path position 
		var distance_to_next = global_position.distance_to(next_path_pos) ## Holds the distance from enemy to that next path position
		var direction = global_position.direction_to(next_path_pos) ## Holds the direction to the next path position
		
		# If the distance to the next path position is less than distance_to_trigger pixels the 
		# movement will scale to it so that it can avoid overshooting
		if distance_to_next > distance_to_trigger:
			velocity = direction * MS
			global_rotation = lerp_angle(global_rotation, direction.angle(), rotation_speed * delta_in)
		else:
			velocity = direction * (MS * (distance_to_next / 5.0))
	

# --- DETECTION TRIGGERS ---
func _on_detection_area_body_entered(body: Node2D) -> void:
	# If the body that entered the area is in group player assing it to player_in_area
	if body.is_in_group("Player"):
		player_in_area = body 

func _on_collision_with_wall() -> void:
	# Get all of the collision with the main characterBody2D collider and seperate the one with 
	# a body that is an obstacle. If it is an obstacle pick a new target to roam to.
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("obstacles") or collider.is_in_group("Enemies"):
			#print("Collided with an obstacle")
			_pick_new_roam_target()

func _get_hit(damage: float) -> void:
	health -= damage
	if health <= 0:
		_die()

func _die() -> void:
	set_physics_process(false)

	enemy_collider.set_deferred("disabled", true)
	detection_shape.set_deferred("disabled", true)
	
	_change_anim_stat("enemy_death")
	var main_scene = get_tree().current_scene as MainScene
	if main_scene:
		main_scene.add_kill()
	
	await get_tree().create_timer(3.0).timeout
	
	queue_free()

func _handle_animations() -> void:
	if velocity.length() != 0:
		_change_anim_stat("walk")
	else:
		_change_anim_stat("default")

var current_anim_state: String = "default"
func _change_anim_stat(new_state) -> void:
	if current_anim_state != new_state:
		postac_anim.play(new_state)
		current_anim_state = new_state
