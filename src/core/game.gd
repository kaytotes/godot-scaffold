class_name Game
extends Node
## Root game node. Holds the global [member instance] singleton, loads the
## always-resident startup UI (main menu, debug overlay), and provides lookups for
## the world and engine subsystems.

## Emitted once, the frame after the game has finished its own setup.
signal game_initialized

const MAIN_MENU_SCENE_PATH := "res://content/ui/main_menu.tscn"
const DEBUG_OVERLAY_SCENE_PATH := "res://content/ui/debug.tscn"

## The running game. Set in [method Node._ready].
static var instance: Game

var _world: WorldInstance


## Registers this instance as the global [member instance], defers emitting
## [signal game_initialized], and loads the always-resident startup UI
## (main menu, debug overlay).
func _ready() -> void:
	instance = self

	# Deferred so nodes that connect during their own _ready (which can run before
	# or after this one, depending on tree position) don't miss it.
	(func() -> void: game_initialized.emit()).call_deferred()

	var scenes := get_engine_subsystem(SceneSubsystem) as SceneSubsystem

	# Load Menu Scene (shows the loading screen)
	scenes.load_scene(MAIN_MENU_SCENE_PATH, true, _on_main_menu_loaded)

	# Load Debug Overlay (no loading screen)
	scenes.load_scene(DEBUG_OVERLAY_SCENE_PATH, false, _on_debug_overlay_loaded)


## Gets the active [WorldInstance], caching the lookup after the first call.
func get_world() -> WorldInstance:
	if _world == null:
		_world = get_node("World") as WorldInstance
	return _world


## Looks up an engine subsystem under the "EngineSubsystems" node by its class name.
## The subsystem node's name must match the script's [code]class_name[/code] exactly.
## [codeblock]
## var scenes := Game.instance.get_engine_subsystem(SceneSubsystem) as SceneSubsystem
## [/codeblock]
func get_engine_subsystem(type: Script) -> Subsystem:
	return get_node("EngineSubsystems/%s" % type.get_global_name()) as Subsystem


## Shuts down the running game and quits the application.
func shutdown() -> void:
	# Do Other Stuff

	get_tree().quit()


func _on_main_menu_loaded(menu: Node) -> void:
	get_node("Interface/MenuLayer/MenuRoot").add_child(menu)


func _on_debug_overlay_loaded(overlay: Node) -> void:
	get_node("Interface/DebugLayer/DebugRoot").add_child(overlay)
