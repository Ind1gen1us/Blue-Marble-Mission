extends Area3D

@export var speed = 0.07
@onready var sprite = $CollisionShape3D/AnimatedSprite3D
@onready var sound_effect = $AudioStreamPlayer

var path: PathFollow3D

func _ready():
	# Get the parent PathFollow3D node
	path = get_parent() as PathFollow3D
	if path == null:
		push_error("Player must be a child of PathFollow3D!")
	else:
		# Disable looping so it doesn't wrap around
		path.loop = false

func follow_path(delta):
	if path == null:
		return
	
	var new_progress = path.progress_ratio
	
	if Input.is_action_pressed("left"):
		new_progress -= delta * speed
	if Input.is_action_pressed("right"):
		new_progress += delta * speed
	
	# Clamp to keep within 0-1 range (stops at beginning/end)
	path.progress_ratio = clamp(new_progress, 0.0, 1.0)

func _process(delta: float) -> void:
	follow_path(delta)
	
	# Determine direction for animation
	var direction = 0
	if Input.is_action_pressed("left") and path.progress_ratio > 0.0:
		direction = -1
	if Input.is_action_pressed("right") and path.progress_ratio < 1.0:
		direction = 1
	
	# Handle sprite animation and flipping
	if direction != 0:
		# Only play sound if it's not already playing
		if not sound_effect.playing:
			sound_effect.play()
		sprite.animation = "walking"
		sprite.flip_h = direction > 0
	else:
		sound_effect.stop()
		sprite.animation = "idle"

func _on_area_entered(area: Area3D) -> void:
	print("can detect area")
