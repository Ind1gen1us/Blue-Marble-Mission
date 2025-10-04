extends Node3D

# Planet template scene
@export var planet_template: PackedScene

# Planet textures/animations
@export var mercury_frames: SpriteFrames
@export var venus_frames: SpriteFrames
@export var earth_frames: SpriteFrames
@export var mars_frames: SpriteFrames
@export var jupiter_frames: SpriteFrames
@export var saturn_frames: SpriteFrames
@export var uranus_frames: SpriteFrames
@export var neptune_frames: SpriteFrames

# Asteroid settings
@export var asteroid_count: int = 50
@export var asteroid_mesh: Mesh

# Sun reference
@onready var sun = $Sun

# Planet data structure: [distance, size, orbit speed, rotation speed, initial angle (degrees), orbital tilt (degrees)]
var planet_data = {
	# make planets bigger
	"Mercury": [40, 4.0, 0.02, 1.5, 0, 0],
	"Venus": [70, 9.0, 0.015, 0.8, 50, 0],
	"Earth": [100, 10.0, 0.012, 1.0, 120, 0],
	"Mars": [140, 5.0, 0.01, 1.0, 180, 0],
	"Jupiter": [250, 25.0, 0.006, 2.0, 240, 0],
	"Saturn": [340, 22.0, 0.005, 1.8, 300, 0],
	"Uranus": [420, 18.0, 0.003, 1.3, 45, 0],
	"Neptune": [490, 17.0, 0.002, 1.2, 90, 0]
}

var planets = {}
var asteroids = []
var time_passed: float = 0.0

func _ready():
	setup_solar_system()
	setup_asteroid_belt()
	setup_background_galaxies()
	$main_music.play()

func setup_solar_system():
	# Create planets (only if texture is provided or always with fallback)
	create_planet("Mercury", mercury_frames, planet_data["Mercury"])
	create_planet("Venus", venus_frames, planet_data["Venus"])
	create_planet("Earth", earth_frames, planet_data["Earth"])
	create_planet("Mars", mars_frames, planet_data["Mars"])
	create_planet("Jupiter", jupiter_frames, planet_data["Jupiter"])
	create_planet("Saturn", saturn_frames, planet_data["Saturn"])
	create_planet("Uranus", uranus_frames, planet_data["Uranus"])
	create_planet("Neptune", neptune_frames, planet_data["Neptune"])

func create_planet(planet_name: String, frames: SpriteFrames, data: Array):
	var distance = data[0]
	var size = data[1]
	var orbit_speed = data[2]
	var rotation_speed = data[3]
	
	# Create orbit container
	var orbit = Node3D.new()
	orbit.name = planet_name + "_Orbit"
	orbit.position = Vector3(0, 500, 0)  # Same Y as sun
	add_child(orbit)
	
	# Create planet instance
	var planet
	
	# Try using template + texture if both exist
	if planet_template and frames:
		planet = planet_template.instantiate()
		var sprite = planet.get_node("AnimatedSprite3D")  # get the child node
		if sprite:
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		planet.sprite_frames = frames
		planet.scale_size = size
		planet.rotation_speed = rotation_speed
		print("✓ Created %s with custom texture" % planet_name)
	
	# Try using template without texture (will use default or create sprite)
	elif planet_template:
		planet = planet_template.instantiate()

		print("⚠ Created %s with template (no custom texture)" % planet_name)
	
	# Fallback: create simple colored sphere
	else:
		planet = create_simple_planet(size, planet_name)
		print("⚠ Created %s as fallback sphere (no template)" % planet_name)
	
	planet.name = planet_name
	planet.position = Vector3(distance, 0, 0)
	orbit.add_child(planet)
	
	# Store reference with orbit data
	planets[planet_name] = {
		"orbit": orbit,
		"planet": planet,
		"distance": distance,
		"orbit_speed": orbit_speed
	}

func create_simple_planet(size: float, planet_name: String = "Unknown") -> Node3D:
	# Create a container node for consistency with template
	var container = Node3D.new()
	
	var planet = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2
	planet.mesh = sphere
	
	# Add material with planet-specific colors
	var mat = StandardMaterial3D.new()
	
	# Assign colors based on planet name for visual distinction
	match planet_name:
		"Mercury":
			mat.albedo_color = Color(0.6, 0.6, 0.6)  # Gray
		"Venus":
			mat.albedo_color = Color(0.9, 0.7, 0.3)  # Yellow-brown
		"Earth":
			mat.albedo_color = Color(0.2, 0.4, 0.8)  # Blue
		"Mars":
			mat.albedo_color = Color(0.8, 0.3, 0.2)  # Red
		"Jupiter":
			mat.albedo_color = Color(0.8, 0.6, 0.4)  # Orange-brown
		"Saturn":
			mat.albedo_color = Color(0.9, 0.8, 0.6)  # Pale yellow
		"Uranus":
			mat.albedo_color = Color(0.6, 0.8, 0.9)  # Light blue
		"Neptune":
			mat.albedo_color = Color(0.3, 0.4, 0.9)  # Deep blue
		_:
			mat.albedo_color = Color(randf(), randf(), randf())  # Random
	
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.3
	mat.roughness = 0.7
	planet.material_override = mat
	
	container.add_child(planet)
	return container

func setup_asteroid_belt():
	# Asteroid belt between Mars and Jupiter (radius 24-28)
	var belt_container = Node3D.new()
	belt_container.name = "AsteroidBelt"
	belt_container.position = Vector3(0, 500, 0)
	add_child(belt_container)
	
	for i in range(asteroid_count):
		var asteroid = create_asteroid()
		
		# Random position in belt
		var angle = randf() * TAU
		var distance = randf_range(24, 28)
		var y_offset = randf_range(-2, 2)
		
		asteroid.position = Vector3(
			cos(angle) * distance,
			y_offset,
			sin(angle) * distance
		)
		
		# Random rotation
		asteroid.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		
		belt_container.add_child(asteroid)
		asteroids.append({
			"node": asteroid,
			"orbit_speed": randf_range(0.1, 0.3),
			"angle": angle,
			"distance": distance
		})

func create_asteroid() -> MeshInstance3D:
	var asteroid = MeshInstance3D.new()
	
	if asteroid_mesh:
		asteroid.mesh = asteroid_mesh
	else:
		# Create random rocky shape
		var box = BoxMesh.new()
		box.size = Vector3(
			randf_range(0.1, 0.3),
			randf_range(0.1, 0.3),
			randf_range(0.1, 0.3)
		)
		asteroid.mesh = box
	
	# Gray rocky material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4) * randf_range(0.8, 1.2)
	mat.roughness = 0.9
	asteroid.material_override = mat
	
	return asteroid

func setup_background_galaxies():
	# Add distant galaxies as decorative sprites
	var galaxy_container = Node3D.new()
	galaxy_container.name = "Galaxies"
	add_child(galaxy_container)
	
	# Create 5-10 distant galaxies
	for i in range(randi_range(5, 10)):
		var galaxy = create_galaxy_sprite()
		
		# Random distant position
		var angle = randf() * TAU
		var distance = randf_range(100, 200)
		var height = randf_range(450, 550)
		
		galaxy.position = Vector3(
			cos(angle) * distance,
			height,
			sin(angle) * distance
		)
		
		galaxy.rotation.y = randf() * TAU
		galaxy_container.add_child(galaxy)

func create_galaxy_sprite() -> Sprite3D:
	var galaxy = Sprite3D.new()
	
	# Create a simple galaxy texture (you can replace with actual texture)
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Draw a simple spiral galaxy shape
	for y in range(64):
		for x in range(64):
			var dx = x - 32
			var dy = y - 32
			var dist = sqrt(dx * dx + dy * dy)
			if dist < 30:
				var brightness = (30 - dist) / 30.0
				var color = Color(0.8, 0.8, 1.0, brightness * 0.5)
				img.set_pixel(x, y, color)
	
	galaxy.texture = ImageTexture.create_from_image(img)
	galaxy.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	galaxy.modulate = Color(randf_range(0.8, 1.0), randf_range(0.8, 1.0), 1.0)
	galaxy.pixel_size = 0.5
	
	return galaxy

func _process(delta: float) -> void:
	time_passed += delta
	
	# Orbit planets
	for planet_name in planets:
		var data = planets[planet_name]
		data["orbit"].rotate_y(data["orbit_speed"] * delta * 0.1)
	
	# Orbit asteroids
	for asteroid_data in asteroids:
		asteroid_data["angle"] += asteroid_data["orbit_speed"] * delta
		var ast_node = asteroid_data["node"]
		var parent = ast_node.get_parent()
		if parent:
			var distance = asteroid_data["distance"]
			ast_node.position.x = cos(asteroid_data["angle"]) * distance
			ast_node.position.z = sin(asteroid_data["angle"]) * distance
			
			# Slow rotation
			ast_node.rotate_y(delta * 0.5)
			ast_node.rotate_x(delta * 0.3)

# Helper function to get planet position
func get_planet_position(planet_name: String) -> Vector3:
	if planets.has(planet_name):
		return planets[planet_name]["planet"].global_position
	return Vector3.ZERO

# Helper function to focus camera on planet
func focus_on_planet(planet_name: String, camera: Camera3D, distance: float = 5.0):
	if planets.has(planet_name) and camera:
		var planet_pos = get_planet_position(planet_name)
		camera.look_at(planet_pos, Vector3.UP)
		# Position camera at distance
		var direction = (camera.global_position - planet_pos).normalized()
		camera.global_position = planet_pos + direction * distance
