class_name WorldBuilderSubsystem
extends Subsystem
## Owns the gameplay session lifecycle: builds a level into [WorldInstance], toggles
## the main menu, and loads/tears down the pause menu to match.

const PAUSE_MENU_SCENE_PATH := "res://content/ui/pause_menu.tscn"

@export var world: WorldInstance
@export var menu_layer: CanvasLayer
@export var pause_root: Node
@export var scene_subsystem: SceneSubsystem

var _is_building := false
var _pause_menu: Node


## Clears the current world, loads the pause menu (on the first call only), and loads
## the given level scene into the world via [SceneSubsystem], hiding the menu layer
## while it loads.
## [br][br]
## [param scene]: resource path (or [code]uid://[/code]) of the level scene to load.[br]
## [param _save_slot]: save slot to build from. Currently unused.
func build(scene: String, _save_slot: int = 0) -> void:
	if _is_building:
		push_warning("Already loading World: %s" % scene)
		return

	_is_building = true

	menu_layer.visible = false

	await _clear()

	_load_pause_menu()

	scene_subsystem.load_scene(scene, true, _on_world_loaded)


## Clears the current world, tears down the pause menu, and shows the main menu again.
func return_to_menu() -> void:
	await _clear()

	menu_layer.visible = true

	if is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
	_pause_menu = null


## Loads the pause menu the first time gameplay starts. It's reused across subsequent
## level loads and only torn down in [method return_to_menu].
func _load_pause_menu() -> void:
	if _pause_menu != null:
		return

	scene_subsystem.load_scene(PAUSE_MENU_SCENE_PATH, false, _on_pause_menu_loaded)


func _on_pause_menu_loaded(pause: Node) -> void:
	_pause_menu = pause
	pause_root.add_child(pause)


## Parents the loaded level under the world, initializes the world once it's in the
## tree, and clears the [method build] in-progress guard.
func _on_world_loaded(level: Node) -> void:
	world.get_level().add_child(level)

	await get_tree().process_frame

	world.initialize()

	_is_building = false


## Queues all effects, entities, and level children for removal and waits a frame
## for them to be freed.
func _clear() -> void:
	_clear_children(world.get_effects())
	_clear_children(world.get_entities())
	_clear_children(world.get_level())

	await get_tree().process_frame


## Queues every direct child of [param root] for removal.
func _clear_children(root: Node) -> void:
	for child: Node in root.get_children():
		child.queue_free()
