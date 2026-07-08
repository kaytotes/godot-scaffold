# godot-scaffold

A starting point for a Godot 4 (C#) project that already boots to a working game loop
instead of an empty scene: a main menu, async level loading with a loading screen, a
pause menu, and a debug overlay are all wired up and ready to build gameplay on top of.

<img width="925" height="530" alt="image" src="https://github.com/user-attachments/assets/ccfff457-65cc-47ee-95df-3d977ffddfe6" />


## Why this exists

Every new Godot + C# project ends up rebuilding the same handful of things before any
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
  deduped onto the same in-flight load, and callers get `onLoaded`/`onFailed` callbacks
  rather than polling.
- **A loading screen that doesn't cost anything when it's not in use.** The loading
  screen scene is loaded synchronously the instant something needs it and freed again the
  instant nothing does, instead of sitting resident in memory for the whole session.
- **UI that isn't all permanently in memory.** The main menu and debug overlay are loaded
  once at startup since they're needed immediately/always; the pause menu is loaded lazily
  the first time gameplay starts and torn down again when returning to the menu.
- **A place for gameplay systems that only make sense mid-level.** `WorldSubsystem` is a
  base class for systems that live under `World/WorldSubsystems` from the start but must
  do nothing until a level has actually finished loading (`IsActive` / `OnWorldInitialized`).
- **A consistent way to find things.** Both engine-level and world-level systems are
  discoverable by convention (`Game.GetEngineSubsystem<T>()`, `WorldSubsystem.World`)
  instead of every script hunting for its own dependencies ad hoc.

## Key architecture

```
Game (singleton, Game.Instance)
├─ EngineSubsystems              always alive, discoverable via GetEngineSubsystem<T>()
│  ├─ SceneSubsystem             central async scene loader + loading screen owner
│  └─ WorldBuilderSubsystem      builds/tears down a level, owns the pause menu's lifecycle
├─ World (WorldInstance)
│  ├─ LevelRoot / EntityRoot / EffectRoot   cleared and rebuilt on every level load
│  └─ WorldSubsystems            systems that wait for WorldInstance.OnWorldInitialized
└─ Interface
   ├─ MenuLayer / LoadingLayer / PauseLayer / DebugLayer / HUDLayer
      each a CanvasLayer with a "*Root" mount point that on-demand UI scenes
      get parented under via SceneSubsystem, rather than living in the main scene
```

A few things worth knowing before you extend this:

- **Godot calls `_Ready()` bottom-up.** A child's `_Ready()` runs *before* its parent's.
  Anything that needs `Game.Instance` (or a `WorldInstance`) during its own `_Ready()`
  either fetches it structurally via a relative `GetNode` call, or subscribes to a
  deferred event (`Game.OnGameInitialized`, `WorldInstance.OnWorldInitialized`) instead of
  assuming the singleton already exists. `WorldSubsystem` and `Game._Ready()` are the
  reference examples for this.
- **Watch for the `Engine` namespace collision.** Any file whose namespace nests under
  the project's root namespace (see [Usage](#usage) below) will have Godot's `Engine`
  class shadowed by the project's own `<Namespace>.Engine` namespace if one exists (e.g.
  `Scaffold.Engine.Subsystems`). An unqualified `Engine.GetFramesPerSecond()` silently
  resolves to the wrong thing and fails to compile - qualify it as `Godot.Engine` instead.
  See `DebugOverlay.cs` for the concrete case.
- **Subsystems are found by node name, not by type search.** `Game.GetEngineSubsystem<T>()`
  looks up `EngineSubsystems/{typeof(T).Name}` - the child node's name in the scene must
  match the class name exactly.

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

### 2. Rename the project and namespace

Everything in this scaffold is namespaced under `Scaffold.` (e.g. `Scaffold.Core`,
`Scaffold.UI`) and named after the project `godot-scaffold` (the `.csproj`/`.sln` file
names, `project.godot`'s app name, and the C# assembly/root namespace). Rename both to
match your own project, e.g. `Scaffold.` → `Pirate.` / `Western.` / `Shooter.`, and
`godot-scaffold` → `pirate-game`.

Run whichever rename script matches your shell from the project root - both prompt you
for the new namespace and project name, then rewrite file contents and rename the
`.csproj`/`.sln` files to match:

```bash
./scripts/rename-project.sh
```

```powershell
.\scripts\rename-project.ps1
```

Or do it by hand: find-and-replace `Scaffold.` with `YourNamespace.` and `godot-scaffold`
with `your-project-name` across the repo, then rename `godot-scaffold.csproj` and
`godot-scaffold.sln` to match, and update `<RootNamespace>` in the `.csproj` (it's
`godotscaffold`, with the dash stripped, so update it the same way).

### 3. Open it in Godot

Open `project.godot` in Godot 4.7+, let it regenerate the `.godot/` cache, and hit run -
you should land on the main menu with Play/Quit working already.
