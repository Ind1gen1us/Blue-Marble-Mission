extends Camera3D

#@export var follow_speed: float = 3.0  # Lower = smoother but more lag
#@export var offset: Vector3 = Vector3(0, 5, 10)  # Camera position offset
#
#var target_position: Vector3
#
#func _ready():
	## Set initial position
	#target_position = get_parent().global_position + offset
#
#func _process(delta: float) -> void:
	## Get the target position (player position + offset)
	#var player = get_parent()
	#target_position = player.global_position + offset
	#
	## Smoothly interpolate to target position
	#global_position = global_position.lerp(target_position, follow_speed * delta)
	#
	## Optional: Make camera look at player
	#look_at(player.global_position, Vector3.UP)
