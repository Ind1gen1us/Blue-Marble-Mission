extends Camera3D

@onready var sound :AudioStreamPlayer = $engine_sound
@export var move_speed: float = 10.0
@export var boost_multiplier: float = 2.0
@export var mouse_sensitivity: float = 0.005
@export var fov_min: float = 60.0
@export var fov_max: float = 120.0
@export var fov_speed: float = 10.0
@export var smoothness: float = 5.0
@export var roll_angle: float = 3.0  # degrees of roll when strafing
@export var camera_shake_intensity: float = 0.5  # Shake on boost

var velocity: Vector3 = Vector3.ZERO
var target_fov: float
var angular_velocity: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO
var base_position_offset: Vector3 = Vector3.ZERO
var shake_offset: Vector3 = Vector3.ZERO
var time_passed: float = 0.0
var engine_playing := false

func _ready() -> void:
	target_fov = fov
	sound.volume_db = -10.0
	target_rotation = rotation
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.global_position = Vector3(0, 500, 150)  # Just outside Earth's orbit
	self.look_at(Vector3(0, 500, 0), Vector3.UP)  # Looking at the sun

func _play_sound(track) -> void:
	sound.stream = load(track)
	if not sound.playing:
		sound.play()
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Update target rotation instead of direct rotation
		target_rotation.y -= event.relative.x * mouse_sensitivity
		target_rotation.x -= event.relative.y * mouse_sensitivity
		target_rotation.x = clamp(target_rotation.x, deg_to_rad(-30.0), deg_to_rad(30.0)) # so that it cannot do 360

func _process(delta: float) -> void:
	time_passed += delta
		# --- Compute speed and target FOV ---
# --- Determine movement & boost ---
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("forward"):
		input_vector.y -= 1.0
	if Input.is_action_pressed("backward"):
		input_vector.y += 1.0
	if Input.is_action_pressed("left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("right"):
		input_vector.x += 1.0
	input_vector = input_vector.normalized()
	
	# --- Smooth rotation (prevents cockpit detachment) --- 
	rotation.x = lerp_angle(rotation.x, target_rotation.x, smoothness * delta) 
	rotation.y = lerp_angle(rotation.y, target_rotation.y, smoothness * delta) 
	# --- Compute directions (in world space) --- 
	var forward = -global_transform.basis.z 
	var right = global_transform.basis.x 
	# Keep movement horizontal 
	forward.y = 0.0 
	right.y = 0.0 
	forward = forward.normalized() 
	right = right.normalized()

	var is_boosting = Input.is_action_pressed("boost") and input_vector.length() > 0

	# --- Compute speed ---
	var current_speed = move_speed
	if is_boosting:
		current_speed *= boost_multiplier
		target_fov = fov_max
	else:
		target_fov = fov_min + input_vector.length() * 20.0

	# --- Handle engine sound ---
	if input_vector.length() > 0:
		var desired_track ="res://assets/music/boost_engine_track.tres" if is_boosting else "res://assets/music/normal_engine_track.tres"
		if sound.stream.resource_path != desired_track or not sound.playing:
			sound.stream = load(desired_track)
			sound.play()
	else:
		if sound.playing:
			sound.stop()

	# --- Camera shake on boost ---
	if is_boosting:
		shake_offset = Vector3(
			sin(time_passed * 50.0) * camera_shake_intensity * 0.01,
			cos(time_passed * 45.0) * camera_shake_intensity * 0.01,
			sin(time_passed * 40.0) * camera_shake_intensity * 0.005
		)
	else:
		shake_offset = shake_offset.lerp(Vector3.ZERO, 10.0 * delta)
	
	# --- Direct movement with shake ---
	velocity = (forward * input_vector.y + right * input_vector.x) * current_speed
	
	# Apply small local shake (doesn't affect global position)
	var local_shake = transform.basis * shake_offset
	position += local_shake
	
	# Move in world space
	global_position += velocity * delta
	
	# Remove shake for next frame
	position -= local_shake
	
	# --- Smooth FOV ---
	fov = lerp(fov, target_fov, fov_speed * delta)
	
	# --- Sideways roll for strafing ---
	var target_roll = deg_to_rad(-input_vector.x * roll_angle)
	target_rotation.z = target_roll
	rotation.z = lerp_angle(rotation.z, target_rotation.z, smoothness * delta)

func _input(event: InputEvent) -> void:
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
