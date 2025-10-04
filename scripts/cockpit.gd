extends Control

# This creates a spacecraft cockpit with 3D space view
# Attach this to a Control node

@export var cockpit_texture: Texture2D  # Your spacecraft interior PNG
@export var parallax_amount: float = 20.0  # How much the cockpit moves with camera
@export var fade_in_duration: float = 1.0
@export var camera_shake_intensity: float = 0.0  # For movement effects

@onready var cockpit_sprite: TextureRect = $CockpitFrame
@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var camera: Camera3D = $SubViewportContainer/SubViewport/Camera3D

var camera_base_rotation: Vector3 = Vector3.ZERO
var time_passed: float = 0.0

func _ready():
	# Setup viewport and camera
	setup_viewport()
	
	# Setup the cockpit frame
	setup_cockpit()
	
	# Store initial camera rotation
	if camera:
		camera_base_rotation = camera.rotation
	
	# Fade in effect
	fade_in()
	
	# Connect to window resize
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()  # Set initial size

func _on_window_resized():
	if viewport:
		# Make viewport match window size
		viewport.size = get_viewport_rect().size

func setup_viewport():
	# Create SubViewportContainer if it doesn't exist
	if not has_node("SubViewportContainer"):
		viewport_container = SubViewportContainer.new()
		viewport_container.name = "SubViewportContainer"
		add_child(viewport_container)
		
		# Create SubViewport
		viewport = SubViewport.new()
		viewport.name = "SubViewport"
		viewport_container.add_child(viewport)
		
		# Create Camera3D
		camera = Camera3D.new()
		camera.name = "Camera3D"
		viewport.add_child(camera)
	
	# Make viewport fill the screen (behind cockpit)
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.z_index = -1  # Behind the cockpit frame

func setup_cockpit():
	# Set the texture
	
	# Make it cover the whole screen with proper sizing
	cockpit_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	cockpit_sprite.anchor_left = 0.0
	cockpit_sprite.anchor_top = 0.0
	cockpit_sprite.anchor_right = 1.0
	cockpit_sprite.anchor_bottom = 1.0
	cockpit_sprite.offset_left = 0.0
	cockpit_sprite.offset_top = 0.0
	cockpit_sprite.offset_right = 0.0
	cockpit_sprite.offset_bottom = 0.0
	
	# Stretch to fit the canvas exactly
	cockpit_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cockpit_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	
	cockpit_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Put it in front but not blocking UI
	cockpit_sprite.z_index = 10

func _process(delta: float) -> void:
	time_passed += delta
	
	if camera and parallax_amount > 0:
		# Subtle parallax effect based on camera rotation
		var cam_rotation = camera.rotation_degrees
		cockpit_sprite.position.x = -cam_rotation.y * parallax_amount
		cockpit_sprite.position.y = cam_rotation.x * parallax_amount
	
	# Camera shake/movement effects
	if camera and camera_shake_intensity > 0:
		animate_camera_movement(delta)

# Simulate spacecraft movement with camera
func animate_camera_movement(delta: float):
	# Gentle bobbing motion
	var bob = sin(time_passed * 2.0) * 0.02 * camera_shake_intensity
	camera.position.y = bob
	
	# Slight rolling motion
	var roll = sin(time_passed * 1.5) * 0.5 * camera_shake_intensity
	camera.rotation_degrees.z = roll

# Call this to simulate acceleration/deceleration
func set_movement_intensity(intensity: float):
	camera_shake_intensity = intensity
	
	# Optional: Add motion blur or speed lines here

# Call this to rotate the camera (steering)
func steer_camera(direction: Vector2, speed: float = 1.0):
	if camera:
		camera.rotation.y += direction.x * speed * get_process_delta_time()
		camera.rotation.x += direction.y * speed * get_process_delta_time()
		
		# Clamp rotation to prevent spinning
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(45))
		camera.rotation.y = clamp(camera.rotation.y, deg_to_rad(-45), deg_to_rad(45))

func fade_in():
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_in_duration)
	await tween.finished
	queue_free()
