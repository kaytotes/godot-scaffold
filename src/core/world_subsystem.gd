class_name WorldSubsystem
extends Subsystem
## Base class for subsystems scoped to the current [WorldInstance], expected to live
## under World/WorldSubsystems. Does nothing until the world has been initialized.
##
## Subclasses that override [method Node._ready] must call [code]super()[/code] first,
## or they never hook up to [signal WorldInstance.world_initialized].

## The owning world, found structurally in [method Node._ready].
var world: WorldInstance

## Whether the world has finished initializing and this subsystem is up and running.
## Set internally; treat as read-only.
var is_active := false


## Gets the owning [WorldInstance] and subscribes to its initialization.
func _ready() -> void:
	world = get_node("../..") as WorldInstance
	world.world_initialized.connect(_handle_world_initialized)


## Called each time the world finishes initializing. Override to do the subsystem's
## actual work; nothing should happen before this is called.
func _on_world_initialized() -> void:
	pass


## Marks this subsystem active before running its own initialization logic.
func _handle_world_initialized() -> void:
	is_active = true
	_on_world_initialized()
