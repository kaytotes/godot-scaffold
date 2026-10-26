class_name PauseMenu
extends Control
## In-game pause menu, loaded on demand by [WorldBuilderSubsystem] when gameplay
## starts and torn down again when returning to the main menu.

@export var return_to_menu_button: Button
@export var quit_button: Button


## Starts closed and wires up button press handlers.
func _ready() -> void:
	_set_paused(false)

	return_to_menu_button.pressed.connect(_on_return_to_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


## Toggles the pause menu open/closed when the "toggle_pause" action is pressed.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		_set_paused(not visible)


## Shows or hides the pause menu and pauses/unpauses the scene tree to match.
func _set_paused(paused: bool) -> void:
	visible = paused
	get_tree().paused = paused


## Closes the pause menu and returns to the main menu via
## [method WorldBuilderSubsystem.return_to_menu], which tears down the current world
## and also frees this pause menu instance.
func _on_return_to_menu_pressed() -> void:
	_set_paused(false)
	var builder := Game.instance.get_engine_subsystem(WorldBuilderSubsystem) as WorldBuilderSubsystem
	builder.return_to_menu()


## Handles the Quit button press by shutting down the game.
func _on_quit_pressed() -> void:
	Game.instance.shutdown()
