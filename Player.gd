extends KinematicBody2D

const UP = Vector2(0,-1)
const SLOPE_STOP = 64
const DROP_THRU_BIT = 1

var velocity = Vector2()
var move_speed = 2 * Globals.UNIT_SIZE
var gravity
var max_jump_velocity
var min_jump_velocity
var is_grounded
var is_jumping = false

var max_jump_height = .8 * Globals.UNIT_SIZE
var min_jump_height = .2 * Globals.UNIT_SIZE
var jump_duration = 0.4

onready var raycasts = $RayCasts

func _ready():
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)
	
func _physics_process(delta):
	_get_input()
	#Apply gravity
	velocity.y += gravity * delta
	
	if is_jumping && velocity.y >= 0:
		is_jumping = false
	velocity = move_and_slide(velocity, UP, SLOPE_STOP)
	is_grounded = !is_jumping && get_collision_mask_bit(DROP_THRU_BIT) && _check_is_grounded()
	_assign_animation()
	
	
func _input(event):
	if event.is_action_pressed('jump') && is_grounded:
		if Input.is_action_pressed('ui_down'):
			set_collision_mask_bit(DROP_THRU_BIT, false)
		else:
			velocity.y = max_jump_velocity
			#homebrew attempt at bunnyhop
			velocity.x += 33 * (-int(Input.is_action_pressed('ui_left')) + int(Input.is_action_pressed('ui_right')))
			is_jumping = true
	if event.is_action_released('jump') && velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity
		
func _get_input():
	var move_direction = -int(Input.is_action_pressed('ui_left')) + int(Input.is_action_pressed('ui_right'))
	velocity.x = lerp(velocity.x, move_speed * move_direction, _get_h_weight())
	if move_direction < 0:
		$Sprite.flip_h = true
	if move_direction > 0:
		$Sprite.flip_h = false
		
func _get_h_weight():
	if is_grounded:
		return 0.2
	else:
		return 0.1
		
func _check_is_grounded():
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
		else:
			return false

func _assign_animation():
	var anim = 'idle' 
	if !is_grounded:
		anim = 'jump'
	elif velocity.x != 0:
		anim = 'run'
	elif velocity.x == 0:
		anim = 'idle'
		
	if $AnimationPlayer.assigned_animation != anim:
		$AnimationPlayer.play(anim)

func _on_Area2D_body_exited(body):
	set_collision_mask_bit(DROP_THRU_BIT, true)
