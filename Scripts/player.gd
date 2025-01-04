extends CharacterBody2D

@export var speed = 600
@export var gravity = 30
@export var jump_force = 200

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D
@onready var crouch_raycast1 = $CrouchRaycast1
@onready var crouch_raycast2 = $CrouchRaycast2
@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var jump_height_timer = $JumpHeightTimer

var is_crouching = false
var stuck_under_object = false
var can_coyote_jump = false
var jump_buffered = false

var standing_cs = preload("res://Resources/player_standing_collision_shape.tres")
var crouching_cs = preload("res://Resources/player_crouching_colission_shape.tres")




func _physics_process(delta):
	
	if(!is_on_floor()) && (can_coyote_jump == false):
		velocity.y += gravity
		if(velocity.y > 1000):
			velocity.y = 1000 
			
	if(Input.is_action_just_pressed("jump")):
		jump_height_timer.start()
		jump()
	
	var horizontal_direction = Input.get_axis("move_left","move_right") 
	velocity.x = speed * horizontal_direction
	
	
	if(horizontal_direction!=0):
		switch_direction(horizontal_direction)
		
		
	if(Input.is_action_just_pressed("crouch")):
		crouch()
	elif Input.is_action_just_released("crouch"):
		if(above_head_is_empty()):
			stand()
		else:
			if stuck_under_object!=true:
				stuck_under_object = true
				print("Player stuck, setting stuck under object to true")
				
	if stuck_under_object && above_head_is_empty():
		if !Input.is_action_pressed("crouch"):
			stand()
			stuck_under_object = false
			print("Player was stuck")
		
		
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	#Started to fall
	if was_on_floor && !is_on_floor() && velocity.y >=0 :
		can_coyote_jump = true
		coyote_timer.start()
	update_animations(horizontal_direction)


	#Touched Ground
	if !was_on_floor && is_on_floor():
		if(jump_buffered == true):
			jump_buffered = false
			print("buffered jump")
			jump()
			
func _on_coyote_timer_timeout() -> void:
	can_coyote_jump = false
	
func _on_jump_buffer_timer_timeout() -> void:
	jump_buffered = false
	
func _on_jump_height_timer_timeout() -> void:
	if !Input.is_action_pressed("jump"):
		if velocity.y < -300:
			velocity.y = -300
			print("Lowjump")
	else:
		print("Highjump")

func above_head_is_empty():
	var result = !crouch_raycast1.is_colliding() && !crouch_raycast2.is_colliding()
	return result
	



func update_animations(horizontal_direction):	
	if(is_on_floor()):
		if(horizontal_direction == 0):
			if(is_crouching):
				ap.play("crouch")
			else:
				ap.play("idle")
		else:
			if(is_crouching):
				ap.play("crouch_walk")
			else:
				ap.play("run")
	else:
		if(is_crouching == false):
			if(velocity.y < 0):
				ap.play("jump")
			elif (velocity.y > 0):
				ap.play("fall")
		else:
			ap.play("crouch")
			

func switch_direction(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 5

func crouch():
	if(is_crouching):
		return
	is_crouching = true
	cshape.shape = crouching_cs
	cshape.position.y = 7
func stand():
	if(is_crouching == false):
		return
	is_crouching = false
	cshape.shape = standing_cs
	cshape.position.y = 1
	
func jump():
	if(is_on_floor()) || can_coyote_jump:
		velocity.y = -jump_force
		if can_coyote_jump:
			can_coyote_jump = false
		else:
			if(!jump_buffered):
				jump_buffered = true
				print("Jump buffered")
				jump_buffer_timer.start()
