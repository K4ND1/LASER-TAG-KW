extends Marker2D

@export var enemy_scene: PackedScene ## Enemy prefab
@export var max_enemies: int = 7 ## Maximal amount of enemies in the scene

## Reference to the collision radius of the spawner
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D


func _on_timer_timeout() -> void:
	# If player is in the area do not engage
	if player_in_area != null:
		return
	
	# We are first counting how many enemies are there currently and if it exeeds the limit we are returning
	var current_enemies = get_tree().get_nodes_in_group("Enemies").size()
	if current_enemies >= max_enemies:
		return
		
	# If can spawn, instantiate an enemy
	var enemy_instance = enemy_scene.instantiate()
	
	# We are spawinging the enemy at the position of the spawner and then we put the 
	# enemy instance as the child of the main scene
	enemy_instance.global_position = global_position	
	get_tree().current_scene.add_child(enemy_instance)

#----------------------------------------------------------
# If the players is in detection area of the spawner do not spawn the enemy from
# this specific spawner 
var player_in_area
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_area = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_area = null
#----------------------------------------------------------
