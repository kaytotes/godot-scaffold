class_name ExampleSubsystem
extends WorldSubsystem
## Minimal example of a [WorldSubsystem] - use as a template for new ones.
##
## If you override [method Node._ready], call [code]super()[/code] first so the base
## class can hook up to the world.


## Prints a greeting once the player has entered the world.
func _on_world_initialized() -> void:
	print("Hello World!")
