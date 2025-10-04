extends Node3D

@export var sprite_frames: SpriteFrames  # Assign your planet animation
@export var rotation_speed: float = 0.5  # How fast the planet rotates
@export var scale_size: float = 1.0  # Planet size
@export var glow_intensity: float = 0.2  # Optional glow effect

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready():
	setup_sprite()
	scale = Vector3(scale_size, scale_size, scale_size)

func setup_sprite():
	if not animated_sprite:
		# Create AnimatedSprite3D if it doesn't exist
		animated_sprite = AnimatedSprite3D.new()
		animated_sprite.name = "AnimatedSprite3D"
		add_child(animated_sprite)
	
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.animation = "default"
		animated_sprite.play()
	
	# Configure sprite properties
	animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	animated_sprite.pixel_size = 0.01
	

func _process(delta: float) -> void:
	# Self-rotation (planet spinning)
	rotate_y(rotation_speed * delta)
