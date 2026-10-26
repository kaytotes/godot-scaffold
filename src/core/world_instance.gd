class_name WorldInstance
extends Node3D
## The active game world: hosts the loaded level, spawned entities/effects, and world
## subsystems, and emits [signal world_initialized] once a level has finished loading.

## Emitted each time the world finishes initializing (i.e. whenever the player enters
## a world). [WorldSubsystem]s should not do anything before this fires.
signal world_initialized

var _level_root: Node3D
var _entity_root: Node3D
var _effect_root: Node3D


## Signals that post-load setup can run, by emitting [signal world_initialized].
## Call once a level has been added under [method get_level].
func initialize() -> void:
	world_initialized.emit()


## Gets the root node that loaded level scenes are parented under, caching the lookup.
func get_level() -> Node3D:
	if _level_root == null:
		_level_root = get_node("LevelRoot") as Node3D
	return _level_root


## Gets the root node that entities are parented under, caching the lookup.
func get_entities() -> Node3D:
	if _entity_root == null:
		_entity_root = get_node("EntityRoot") as Node3D
	return _entity_root


## Gets the root node that effects are parented under, caching the lookup.
func get_effects() -> Node3D:
	if _effect_root == null:
		_effect_root = get_node("EffectRoot") as Node3D
	return _effect_root
