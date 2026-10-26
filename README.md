# godot-scaffold

A starting point for a Godot 4 (GDScript) project that already boots to a working game
loop instead of an empty scene: a main menu, async level loading with a loading screen, a
pause menu, and a debug overlay are all wired up and ready to build gameplay on top of.

<img width="925" height="530" alt="image" src="https://github.com/user-attachments/assets/ccfff457-65cc-47ee-95df-3d977ffddfe6" />


## Why this exists

Every new Godot project ends up rebuilding the same handful of things before any
actual gameplay work can start: a scene loader that doesn't block the main thread, a
loading screen, a menu that can start and stop a level, a pause screen, some way to see
FPS/memory while debugging, and a sane place to put systems that should only run once a
level is actually loaded. None of that is specific to any one game, and it's tedious and
error-prone to reinvent per-project.

This scaffold packages that boilerplate once, with the ordering and lifecycle bugs
(singleton-not-ready-yet, UI kept resident forever, double-loading the same scene, etc.)
already found and fixed, so a new project starts from "the game already runs" instead of
from zero.

## Problems it solves

- **Non-blocking scene loading.** `SceneSubsystem` wraps Godot's threaded resource loader
  so any number of scenes can load concurrently, repeated requests for the same path are
  deduped onto the same in-flight load, and callers get `on_loaded`/`on_failed` callbacks
  rather than polling.
- **A loading screen that doesn't cost anything when it's not in use.** The loading
  screen scene is loaded synchronously the instant something needs it and freed again the
  instant nothing does, instead of sitting resident in memory for the whole session.
- **UI that isn't all permanently in memory.** The main menu and debug overlay are loaded
  once at startup since they're needed immediately/always; the pause menu is loaded lazily
  the first time gameplay starts and torn down again when returning to the menu.
- **A place for gameplay systems that only make sense mid-level.** `WorldSubsystem` is a
  base class for systems that live under `World/WorldSubsystems` from the start but must
  do nothing until a level has actually finished loading (`is_active` /
  `_on_world_initialized()`).
- **A consistent way to find things.** Both engine-level and world-level systems are
  discoverable by convention (`Game.instance.get_engine_subsystem(SceneSubsystem)`,
  `WorldSubsystem.world`) instead of every script hunting for its own dependencies ad hoc.

## Key architecture

```
Game (singleton, Game.instance)
├─ EngineSubsystems              always alive, discoverable via get_engine_subsystem()
│  ├─ SceneSubsystem             central async scene loader + loading screen owner
│  └─ WorldBuilderSubsystem      builds/tears down a level, owns the pause menu's lifecycle
├─ World (WorldInstance)
│  ├─ LevelRoot / EntityRoot / EffectRoot   cleared and rebuilt on every level load
│  └─ WorldSubsystems            systems that wait for WorldInstance.world_initialized
└─ Interface
   ├─ MenuLayer / LoadingLayer / PauseLayer / DebugLayer / HUDLayer
      each a CanvasLayer with a "*Root" mount point that on-demand UI scenes
      get parented under via SceneSubsystem, rather than living in the main scene
```

A few things worth knowing before you extend this:

- **Godot calls `_ready()` bottom-up.** A child's `_ready()` runs *before* its parent's.
  Anything that needs `Game.instance` (or a `WorldInstance`) during its own `_ready()`
  either fetches it structurally via a relative `get_node()` call, or connects to a
  signal that fires later (`Game.game_initialized`, `WorldInstance.world_initialized`)
  instead of assuming the singleton already exists. `WorldSubsystem` and `Game._ready()`
  are the reference examples for this.
- **Call `super()` when overriding `_ready()` in a `WorldSubsystem`.** Godot 4 doesn't run
  the parent class's `_ready()` for you, and `WorldSubsystem` uses it to find its world
  and connect to `world_initialized`. Skip it and the subsystem silently never activates.
- **Subsystems are found by node name, not by type search.**
  `get_engine_subsystem(SceneSubsystem)` looks up `EngineSubsystems/SceneSubsystem` using
  the script's `class_name` - the child node's name in the scene must match it exactly.
  It returns a plain `Subsystem`, so cast it to keep autocompletion and type checks:
  `var scenes := Game.instance.get_engine_subsystem(SceneSubsystem) as SceneSubsystem`.
- **Use `load()`, not `preload()`, for on-demand UI.** A `preload()`ed scene stays in
  memory as long as the script that preloads it, which for these scripts is the whole
  game. The loading screen and pause menu go through `load()` /
  `SceneSubsystem.load_scene()` so they only take up memory while they're showing.
- **Class names are global.** GDScript has no namespaces, so every `class_name` (`Game`,
  `Subsystem`, `MainMenu`, ...) shares one global namespace with the engine and any
  addons. If one clashes, rename the scaffold's class (and, for engine subsystems, its
  node in `core/game.tscn` to match).
- **Lambdas capture local variables by value.** Assigning to a member variable from inside
  a lambda works; assigning to a local variable doesn't carry back out. The scaffold uses
  named methods for its load callbacks, which sidesteps this.
- **Untyped code shows up as a warning.** The `untyped_declaration` warning is turned on in
  Project Settings (Debug > GDScript), so variables, parameters, and return types without
  a static type get flagged in the editor.

## Usage

This is meant to be pulled down as a one-time starting point, not tracked as an upstream
dependency - grab the files, strip the git history, and rename everything to your project.

### 1. Get the raw files (no `.git` directory)

```bash
git clone --depth 1 <this-repo-url> my-game
cd my-game
rm -rf .git      # PowerShell: Remove-Item -Recurse -Force .git
git init         # optional: start a fresh history for your own project
```

(Or just download the repo as a ZIP from your git host and extract it - that never has a
`.git` directory in the first place.)

### 2. Open it in Godot

Open `project.godot` in Godot 4.7+ (the standard build is enough - .NET isn't needed),
let it regenerate the `.godot/` cache, and hit run - you should land on the main menu
with Play/Quit working already.

### 3. Rename the project

The only project-specific name is `godot-scaffold`. In the editor, open
**Project > Project Settings > Application > Config** and change **Name** (it's
`config/name` in `project.godot`), then update this README's title to match.
