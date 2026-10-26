class_name DebugOverlay
extends Control
## F5-toggled debug overlay, loaded on startup by [Game] into
## Interface/DebugLayer/DebugRoot. Only processes (updating its labels) while visible.

@export var performance_label: Label
@export var game_state_label: Label
@export var build_label: Label


## Starts hidden and not processing until toggled on, and writes the static build info text.
func _ready() -> void:
	_set_overlay_visible(false)

	var godot_version: String = Engine.get_version_info()["string"]
	var game_version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	build_label.text = "Game %s\nGodot %s" % [game_version, godot_version]


## Refreshes the engine performance and game state blocks. Only runs while the overlay
## is visible.
func _process(_delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	var memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var cpu_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var vram_mb := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0)

	performance_label.text = (
		"FPS: %.0f\nMemory: %.1f MB\nCPU: %.1f ms\nVRAM: %.1f MB"
		% [fps, memory_mb, cpu_ms, vram_mb]
	)

	var node_count := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var world := Game.instance.get_world()
	var entity_count := world.get_entities().get_child_count()
	var effect_count := world.get_effects().get_child_count()
	var scenes := Game.instance.get_engine_subsystem(SceneSubsystem) as SceneSubsystem
	var active_loads := scenes.get_active_load_count()

	game_state_label.text = (
		"Nodes: %.0f\nEntities: %d\nEffects: %d\nActive Loads: %d"
		% [node_count, entity_count, effect_count, active_loads]
	)


## Toggles the overlay on and off when the "toggle_debug" action is pressed.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_set_overlay_visible(not visible)


## Shows or hides the overlay, only processing (updating the stats blocks) while visible.
func _set_overlay_visible(overlay_visible: bool) -> void:
	visible = overlay_visible
	set_process(overlay_visible)
