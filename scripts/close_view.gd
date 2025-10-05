extends Node3D

# References
@export var camera: Camera3D
@onready var solar_system: Node3D = get_parent().get_parent() as Node3D  # getting world scene
@export var interaction_distance: float = 30.0  # How close to trigger Earth view
@export var earth_view_scene: PackedScene  # The Earth close-up UI scene

var earth_view_instance: Control = null
var is_in_earth_view: bool = false
var can_view_earth: bool = false

func _process(delta: float) -> void:
	if is_in_earth_view:
		return
	check_earth_proximity()

func check_earth_proximity() -> void:
	if not camera or not solar_system:
		return
	
	var camera_pos = camera.global_position
	var earth_pos = solar_system.get_planet_position("Earth")
	var distance = camera_pos.distance_to(earth_pos)
	
	# Check if close enough to Earth
	if distance < interaction_distance:
		if not can_view_earth:
			can_view_earth = true
			print("Press E to view Earth")
	else:
		can_view_earth = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action") and can_view_earth:
		if not is_in_earth_view:
			enter_earth_view()
		else:
			exit_earth_view()

func enter_earth_view() -> void:
	if not earth_view_scene:
		push_error("Earth view scene not assigned!")
		return
	
	# Instantiate Earth close-up view
	earth_view_instance = earth_view_scene.instantiate() as Control
	
	get_tree().root.add_child(earth_view_instance)
	
	# Connect exit signal
	if earth_view_instance.has_signal("exit_requested"):
		earth_view_instance.exit_requested.connect(exit_earth_view)
	
	# Disable spacecraft controls
	is_in_earth_view = true
	if camera.get_script():
		camera.set_process(false)
	
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var cursor_texture = load("res://assets/2D_assets/crosshair186.png")
	var hotspot = Vector2(64, 64)  # clicks on center of cursor
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, hotspot)



func exit_earth_view() -> void:
	if earth_view_instance:
		earth_view_instance.queue_free()
		earth_view_instance = null
	
	is_in_earth_view = false
	
	# Re-enable spacecraft controls
	if camera.get_script():
		camera.set_process(true)
	
	# Hide cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
