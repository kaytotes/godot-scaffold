class_name SceneSubsystem
extends Subsystem
## Central async scene loader. Supports any number of concurrent loads for different
## scene paths (deduping repeated requests for the same path onto the same in-flight
## load), and transparently loads/shows and unloads/hides a loading screen while any
## request wants one.

## Emitted whenever any requested scene finishes loading, regardless of caller.
signal scene_loaded(path: String, scene: Node)

## Emitted whenever any requested scene fails to load, regardless of caller.
signal scene_load_failed(path: String)

const LOADING_SCENE_PATH := "res://content/ui/loading.tscn"

@export var loading_layer: CanvasLayer
@export var loading_root: Node

var _loading_screen: Node
var _active_loads: Dictionary[String, LoadRequest] = {}


## Polls every in-progress threaded load's status each frame and finalizes or fails
## each one as it completes.
func _process(_delta: float) -> void:
	if _active_loads.is_empty():
		return

	# values() returns a copy, so finishing a load can safely remove it mid-loop.
	for request: LoadRequest in _active_loads.values():
		var status := ResourceLoader.load_threaded_get_status(request.scene_path)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_finalize_request(request)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load Scene: %s" % request.scene_path)
			_fail_request(request)


## Starts an async threaded load of the given scene. If the scene is already loading,
## the new hooks are attached to that in-progress load instead of starting a duplicate.
## Any number of different scenes can be loading at once.
## [br][br]
## [param scene]: resource path (or [code]uid://[/code]) of the scene to load.[br]
## [param show_loading_screen]: whether this load should trigger the loading screen.[br]
## [param on_loaded]: called with the instantiated scene once this load finishes.[br]
## [param on_failed]: called if this load fails.
func load_scene(scene: String, show_loading_screen: bool,
		on_loaded := Callable(), on_failed := Callable()) -> void:
	if _active_loads.has(scene):
		var in_progress: LoadRequest = _active_loads[scene]

		if on_loaded.is_valid():
			in_progress.on_loaded.append(on_loaded)

		if on_failed.is_valid():
			in_progress.on_failed.append(on_failed)

		if show_loading_screen and not in_progress.show_loading_screen:
			in_progress.show_loading_screen = true
			_update_loading_screen()

		return

	var request := LoadRequest.new(scene, show_loading_screen)

	if on_loaded.is_valid():
		request.on_loaded.append(on_loaded)

	if on_failed.is_valid():
		request.on_failed.append(on_failed)

	var error := ResourceLoader.load_threaded_request(scene)

	if error != OK:
		push_error("Failed to start loading Scene: %s" % scene)
		_fail_request(request)
		return

	_active_loads[scene] = request
	_update_loading_screen()


## Whether any scene load is currently in progress.
func is_loading() -> bool:
	return not _active_loads.is_empty()


## Whether the given scene is currently loading.
func is_scene_loading(scene: String) -> bool:
	return _active_loads.has(scene)


## The number of scene loads currently in progress.
func get_active_load_count() -> int:
	return _active_loads.size()


## Instantiates the finished scene and completes its load request.
func _finalize_request(request: LoadRequest) -> void:
	var packed_scene := ResourceLoader.load_threaded_get(request.scene_path) as PackedScene

	if packed_scene == null:
		push_error("Loaded Scene was not a PackedScene: %s" % request.scene_path)
		_fail_request(request)
		return

	var scene := packed_scene.instantiate()

	_active_loads.erase(request.scene_path)
	_update_loading_screen()

	scene_loaded.emit(request.scene_path, scene)

	for on_loaded: Callable in request.on_loaded:
		if on_loaded.is_valid():
			on_loaded.call(scene)


## Removes the request and notifies its failure hooks.
func _fail_request(request: LoadRequest) -> void:
	_active_loads.erase(request.scene_path)
	_update_loading_screen()

	scene_load_failed.emit(request.scene_path)

	for on_failed: Callable in request.on_failed:
		if on_failed.is_valid():
			on_failed.call()


## Loads and shows the loading screen while any active load wants it, and unloads it
## again once none do, rather than keeping it resident for the whole game. It's loaded
## synchronously since it's small and needs to appear the instant it's needed.
## Uses load() rather than preload() so it isn't held in memory while unused.
func _update_loading_screen() -> void:
	var should_show := false

	for request: LoadRequest in _active_loads.values():
		if request.show_loading_screen:
			should_show = true
			break

	if should_show and _loading_screen == null:
		_loading_screen = (load(LOADING_SCENE_PATH) as PackedScene).instantiate()
		loading_root.add_child(_loading_screen)
	elif not should_show and _loading_screen != null:
		_loading_screen.queue_free()
		_loading_screen = null

	loading_layer.visible = should_show


## One in-flight threaded load, plus every caller's hooks waiting on it.
class LoadRequest:
	var scene_path: String
	var show_loading_screen: bool
	var on_loaded: Array[Callable] = []
	var on_failed: Array[Callable] = []

	func _init(path: String, show_loading: bool) -> void:
		scene_path = path
		show_loading_screen = show_loading
