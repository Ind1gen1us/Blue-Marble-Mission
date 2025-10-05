extends Button

@export var image_path: String
@export var location_name: String
@export_multiline var location_description: String

var panel_instance: PanelContainer = null
var is_pinned: bool = false  # tracks if user clicked to keep it open
var info_panel: PackedScene = load("res://scenes/UI_scene/location_panel.tscn")


func _ready() -> void:
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("pressed", Callable(self, "_on_pressed"))


func _on_mouse_entered() -> void:
	if not panel_instance:
		panel_instance = info_panel.instantiate()
		get_tree().root.add_child(panel_instance)
		panel_instance.setup([image_path, location_name, location_description])
	
	panel_instance.visible = true

	# Smartly position the panel relative to this button
	position_panel_smart(panel_instance, self)


func _on_mouse_exited() -> void:
	if panel_instance and not is_pinned:
		panel_instance.visible = false

func _on_pressed() -> void:
	if not panel_instance:
		return
	
	# Toggle pinned state
	is_pinned = !is_pinned
	
	# If unpinned, hide the panel
	if not is_pinned:
		panel_instance.visible = false
	# If pinned, make sure panel is visible
	else:
		panel_instance.visible = true


# -------------------------
# Smart panel positioning (dummy, implement as needed)
# -------------------------
func position_panel_smart(panel: PanelContainer, button: Button) -> void:
	# Placeholder - insert your positioning logic here
	pass
