extends CharacterBody2D

# 1. Tworzymy własny sygnał, który wyemitujemy w momencie śmierci
signal player_died

# Movement speed of the player
@export var speed: float = 100.0
@export var max_health: float = 100.0
var health: float = 100.0
var is_dead: bool = false ## Flaga zapobiegająca wykonywaniu akcji po śmierci

@onready var animated_sprite_2d: AnimatedSprite2D = $"postac anim"
@onready var laser_anim: AnimatedSprite2D = $laser_anim
@onready var bron_anim: AnimatedSprite2D = $bron_anim
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var flashlight: PointLight2D = $Flashlight
@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var laser_hc_width: float = 130.0
@export var damage: float = 20.0
@onready var ray_cast_2d: RayCast2D = $RayCast2D

@export var shot_sound: AudioStream
@export var reloading_sound: AudioStream
@export var got_hit_sound: AudioStream
@export var empty_mag_sound: AudioStream


signal health_changed(current_health)

func _ready() -> void:
	health = max_health

@onready var gui: Control = $Control
func _physics_process(_delta: float) -> void:
	# Jeśli gracz nie żyje, natychmiast przerywamy funkcję (nie można się ruszać ani obracać)
	if is_dead:
		return
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
		
	velocity = velocity.move_toward(Vector2.ZERO, speed * 0.2)

	move_and_slide()
	look_at(get_global_mouse_position())
	
	if velocity.length() != 0:
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("default")
		
	if Input.is_action_just_pressed("reload"):
		can_shoot = false
		play_sound_effect(reloading_sound)
		animation_player.play("reload_progress")
		gui.visible = true
		await get_tree().create_timer(1.0).timeout
		
		var main_scene = get_tree().current_scene as MainScene
		current_amo = 16
		gui.visible = false
		main_scene._change_amo()
		can_shoot = true

		
		
	if Input.is_action_just_pressed("shoot") and can_shoot and current_amo > 0:
		play_sound_effect(shot_sound)
		laser_anim.play("shoot")
		bron_anim.play("shoot")
		_handle_laser()
		timer.start(0.35)
		can_shoot = false
	elif Input.is_action_just_pressed("shoot") and current_amo <= 0:
		play_sound_effect(empty_mag_sound)


func play_sound_effect(_new_sound_effect) -> void:
	audio_stream_player_2d.pitch_scale = randf_range(0.95, 1.05)
	audio_stream_player_2d.stream = _new_sound_effect
	audio_stream_player_2d.play()
	


var can_shoot: bool = true
var current_amo: int = 16
func _handle_laser() -> void:
	current_amo -=1
	var main_scene = get_tree().current_scene as MainScene
	main_scene._change_amo()
	if ray_cast_2d.is_colliding():
		var collision_point = ray_cast_2d.get_collision_point()
		var dis = laser_anim.global_position.distance_to(collision_point)
		
		laser_anim.scale.x = dis/laser_hc_width * 0.95
		var obj_hit_by_laser = ray_cast_2d.get_collider()
		if obj_hit_by_laser and obj_hit_by_laser.is_in_group("Enemies"):
			print("shot an enemy", obj_hit_by_laser.get_instance_id())
			obj_hit_by_laser._get_hit(damage)
	else:
		laser_anim.scale.x = ray_cast_2d.target_position.x / laser_hc_width


func _get_hit(damage_dealt: float) -> void:
	# Jeśli gracz już nie żyje, ignorujemy kolejne obrażenia
	if is_dead:
		return
	
	play_sound_effect(got_hit_sound)
	health -= damage_dealt
	health_changed.emit(health)
	
	if health <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return
		
	print("DIED")
	is_dead = true
	z_index = 4
	# A. Wyłączamy fizykę gracza (żeby wrogowie nie przestawiali jego zwłok)
	collision_shape_2d.set_deferred("disabled", true)
	
	# B. Ukrywamy broń oraz efekt lasera
	laser_anim.visible = false
	bron_anim.visible = false
	flashlight.visible = false
	
	# C. opcjonalnie: zatrzymujemy animację lub zmieniamy sprite
	animated_sprite_2d.stop()
	
	# D. Kluczowy moment: emitujemy sygnał śmierci do systemu gry!
	player_died.emit()


func _on_timer_timeout() -> void:
	can_shoot = true
