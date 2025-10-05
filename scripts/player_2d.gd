extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -350.0

@onready var animated_sprite = $AnimatedSprite2D  
@onready var sound = $AudioStreamPlayer

func _play_sound() -> void:
	if  not sound.playing:
		sound.play()

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump with boost button
	if Input.is_action_just_pressed("boost") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get horizontal input
	var direction := 0.0
	if Input.is_action_pressed("left"):
		direction = -1.0
	elif Input.is_action_pressed("right"):
		direction = 1.0
	
	# Set horizontal velocity
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Handle animations
	if direction != 0:
		_play_sound()
		animated_sprite.animation = "walking"
		animated_sprite.flip_h = direction > 0  # Flip when moving right
	else:
		animated_sprite.animation = "idle"
		sound.stop()
	
	move_and_slide()
	position.x = clamp(position.x, 0, 1152)
	position.y = clamp(position.y, 0, 648)
