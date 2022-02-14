extends KinematicBody

###################-VARIABLES-####################

const SWAY = 35
const VSWAY = 35

# Cutscene test
var cutscene_test = preload("res://CutsceneBase.tscn").instance()
onready var scene_changer = preload("res://SceneChanger.tscn").instance()
onready var death_screen = preload("res://Levels/Main/DeathScreen.tscn").instance()

# Camera
export(float) var mouse_sensitivity = 8.0
export(float) var FOV = 80.0
var mouse_axis := Vector2()
onready var head = $Head
onready var cam = $Head/Camera
onready var hand = $Head/Hand
onready var handLoc = $Head/HandLoc
onready var muzzle = $Head/Hand/P38/Muzzle
onready var aimcast = $Head/Camera/RayCast
onready var animPlayer = $AnimationPlayer
# Move
var velocity := Vector3()
var direction := Vector3()
var move_axis := Vector2()
var snap := Vector3()
var sprint_enabled := true
var sprinting := false
var damage = 35
# Walk
const FLOOR_MAX_ANGLE: float = deg2rad(46.0)
export(float) var gravity = 30.0
export(int) var walk_speed = 10
export(int) var sprint_speed = 16
export(int) var acceleration = 8
export(int) var deacceleration = 10
export(float, 0.0, 1.0, 0.05) var air_control = 0.3
export(int) var jump_height = 10
var _speed: int
var _is_sprinting_input := false
var _is_jumping_input := false
export(int) var health = 100
var can_shoot := true
var dead := false
var isDead := false
##################################################
var sKey
var aKey
var dKey
var wKey
var shiftKey
var leftMouseClick
var spacebarKey

# Called when the node enters the scene tree
func _ready() -> void:
	hand.set_as_toplevel(true)
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.fov = FOV
	sKey = InputEventKey.new()
	sKey.scancode = KEY_S
	aKey = InputEventKey.new()
	aKey.scancode = KEY_A
	dKey = InputEventKey.new()
	dKey.scancode = KEY_D
	wKey = InputEventKey.new()
	wKey.scancode = KEY_W
	#shiftKey = InputEventKey.new()
	#shiftKey.scancode = KEY_SHIFT
	#spacebarKey = InputEventKey.new()
	#spacebarKey.scancode = KEY_SPACE
	#leftMouseClick = InputEventMouseButton.new()
	#leftMouseClick.scancode = BUTTON_LEFT

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta: float) -> void:
	hand.global_transform.origin = handLoc.global_transform.origin
	hand.rotation.y = lerp_angle(hand.rotation.y, rotation.y, SWAY * delta)
	hand.rotation.x = lerp_angle(hand.rotation.x, head.rotation.x, VSWAY * delta)
	
	if dead:
		death()
	else:
		move_axis.x = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
		move_axis.y = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		
		if Input.is_action_just_pressed("move_jump"):
			_is_jumping_input = true
		
		if Input.is_action_pressed("move_sprint"):
			_is_sprinting_input = true
		
		if Input.is_action_just_pressed("enter_cutscene"):
			print("Entering cutscene")
			get_tree().change_scene("res://CutsceneBase.tscn")

func takeDamage(damage):
	animPlayer.play("Pain")
	health -= damage
	if health <= 0:
		dead = true

func death():
	if not isDead:
		add_child(death_screen)
		isDead = true

# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	if not dead:
		if Input.is_action_just_pressed("fire") and can_shoot:
			print("Shot!")
			can_shoot = false
			animPlayer.play("fire")
			if aimcast.is_colliding():
				var target = aimcast.get_collider()
				if target.is_in_group("enemy"):
					target.takeDamage(damage)
		walk(delta)


# Called when there is an input event
func _input(event: InputEvent) -> void:
	if not dead:
		if event is InputEventMouseMotion:
			mouse_axis = event.relative
			camera_rotation()


func walk(delta: float) -> void:
	direction_input()
	
	if is_on_floor():
		snap = -get_floor_normal() - get_floor_velocity() * delta
		
		# Workaround for sliding down after jump on slope
		if velocity.y < 0:
			velocity.y = 0
		
		jump()
	else:
		# Workaround for 'vertical bump' when going off platform
		if snap != Vector3.ZERO && velocity.y != 0:
			velocity.y = 0
		
		snap = Vector3.ZERO
		
		velocity.y -= gravity * delta
	
	sprint(delta)
	
	accelerate(delta)
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, FLOOR_MAX_ANGLE)
	_is_jumping_input = false
	_is_sprinting_input = false


func camera_rotation() -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if mouse_axis.length() > 0:
		var horizontal: float = -mouse_axis.x * (mouse_sensitivity / 100)
		var vertical: float = -mouse_axis.y * (mouse_sensitivity / 100)
		
		mouse_axis = Vector2()
		
		rotate_y(deg2rad(horizontal))
		head.rotate_x(deg2rad(vertical))
		
		# Clamp mouse rotation
		var temp_rot: Vector3 = head.rotation_degrees
		temp_rot.x = clamp(temp_rot.x, -90, 90)
		head.rotation_degrees = temp_rot


func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if move_axis.x >= 0.5:
		direction -= aim.z
	if move_axis.x <= -0.5:
		direction += aim.z
	if move_axis.y <= -0.5:
		direction -= aim.x
	if move_axis.y >= 0.5:
		direction += aim.x
	direction.y = 0
	direction = direction.normalized()


func accelerate(delta: float) -> void:
	# Where would the player go
	var _temp_vel: Vector3 = velocity
	var _temp_accel: float
	var _target: Vector3 = direction * _speed
	
	_temp_vel.y = 0
	if direction.dot(_temp_vel) > 0:
		_temp_accel = acceleration
		
	else:
		_temp_accel = deacceleration
	
	if not is_on_floor():
		_temp_accel *= air_control
	
	# Interpolation
	_temp_vel = _temp_vel.linear_interpolate(_target, _temp_accel * delta)
	
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	
	# Make too low values zero
	if direction.dot(velocity) == 0:
		var _vel_clamp := 0.01
		if abs(velocity.x) < _vel_clamp:
			velocity.x = 0
		if abs(velocity.z) < _vel_clamp:
			velocity.z = 0


func jump() -> void:
	if _is_jumping_input:
		velocity.y = jump_height
		snap = Vector3.ZERO


func sprint(delta: float) -> void:
	if can_sprint():
		_speed = sprint_speed
		cam.set_fov(lerp(cam.fov, FOV * 1.05, delta * 8))
		sprinting = true
		
	else:
		_speed = walk_speed
		cam.set_fov(lerp(cam.fov, FOV, delta * 8))
		sprinting = false


func can_sprint() -> bool:
	return (sprint_enabled and is_on_floor() and _is_sprinting_input and move_axis.x >= 0.5)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fire":
		can_shoot = true



func _on_DownPad_button_down():
	sKey.pressed = true
	Input.parse_input_event(sKey)


func _on_DownPad_button_up():
	sKey.pressed = false
	Input.parse_input_event(sKey)


func _on_LeftPad_button_down():
	aKey.pressed = true
	Input.parse_input_event(aKey)


func _on_LeftPad_button_up():
	aKey.pressed = false
	Input.parse_input_event(aKey)


func _on_RightPad_button_down():
	dKey.pressed = true
	Input.parse_input_event(dKey)


func _on_RightPad_button_up():
	dKey.pressed = false
	Input.parse_input_event(dKey)


func _on_UpPad_button_down():
	wKey.pressed = true
	Input.parse_input_event(wKey)


func _on_UpPad_button_up():
	wKey.pressed = false
	Input.parse_input_event(wKey)


func _on_ShootButton_button_down():
	if can_shoot:
			print("Shot!")
			can_shoot = false
			animPlayer.play("fire")
			if aimcast.is_colliding():
				var target = aimcast.get_collider()
				if target.is_in_group("enemy"):
					target.takeDamage(damage)
	#leftMouseClick.pressed = true
	#Input.parse_input_event(leftMouseClick)


func _on_ShootButton_button_up():
	pass
	#leftMouseClick.pressed = false
	#Input.parse_input_event(leftMouseClick)


func _on_JumpButton_button_down():
	_is_jumping_input = true
	# spacebarKey.pressed = true
	# Input.parse_input_event(spacebarKey)


func _on_JumpButton_button_up():
	_is_jumping_input = false
	#spacebarKey.pressed = false
	#Input.parse_input_event(spacebarKey)


func _on_RunButton_button_down():
	_is_sprinting_input = true
	#shiftKey.pressed = true
	#Input.parse_input_event(shiftKey)


func _on_RunButton_button_up():
	_is_sprinting_input = false
