class_name MainMenu
extends Control
## Main menu UI, loaded on startup by [Game] into Interface/MenuLayer/MenuRoot.

# Placeholder level for Play; swap for a real level-select flow later.
const TESTBED_SCENE_UID := "uid://d1rkx522hrguc"

@export var play_button: Button
@export var quit_button: Button


## Wires up button press handlers.
func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


## Handles the Play button press by building the testbed level.
func _on_play_pressed() -> void:
	var builder := Game.instance.get_engine_subsystem(WorldBuilderSubsystem) as WorldBuilderSubsystem
	builder.build(TESTBED_SCENE_UID)


## Handles the Quit button press by shutting down the game.
func _on_quit_pressed() -> void:
	Game.instance.shutdown()
