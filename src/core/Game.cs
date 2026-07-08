using Godot;
using Scaffold.Engine.Subsystems;
using System;

namespace Scaffold.Core;

/// <summary>
/// Root game node. Holds the global <see cref="Instance"/> singleton, loads the
/// always-resident startup UI (main menu, debug overlay), and provides lookups for
/// the world and engine subsystems.
/// </summary>
public partial class Game : Node
{
    private const string MainMenuScenePath = "res://content/ui/main_menu.tscn";
    private const string DebugOverlayScenePath = "res://content/ui/debug.tscn";

    public static Game Instance { get; private set; }

    public event Action OnGameInitialized;

    private WorldInstance _world;

    /// <summary>
    /// Registers this instance as the global <see cref="Instance"/>, defers firing
    /// <see cref="OnGameInitialized"/>, and loads the always-resident startup UI
    /// (main menu, debug overlay).
    /// </summary>
    public override void _Ready()
    {
        base._Ready();

        Instance = this;

        // Deferred so nodes that subscribe during their own _Ready (which can
        // run before or after this one, depending on tree position) don't miss it.
        Callable.From(() => OnGameInitialized?.Invoke()).CallDeferred();

        // Load Menu Scene
        GetEngineSubsystem<SceneSubsystem>().Load(MainMenuScenePath, showLoadingScreen: true,
            onLoaded: menu => GetNode("Interface/MenuLayer/MenuRoot").AddChild(menu));

        // Load Debug Overlay
        GetEngineSubsystem<SceneSubsystem>().Load(DebugOverlayScenePath, showLoadingScreen: false,
            onLoaded: debug => GetNode("Interface/DebugLayer/DebugRoot").AddChild(debug));
    }

    /// <summary>
    /// Gets the active <see cref="WorldInstance"/>, caching the lookup after the first call.
    /// </summary>
    public WorldInstance GetWorld()
    {
        _world ??= GetNode<WorldInstance>("World");
        return _world;
    }

    /// <summary>
    /// Looks up an engine subsystem under the "EngineSubsystems" node by its type name.
    /// </summary>
    /// <typeparam name="T">The subsystem type to find. The subsystem node's name must match the type name.</typeparam>
    public T GetEngineSubsystem<T>() where T : Subsystem
    {
        return GetNode<T>($"EngineSubsystems/{typeof(T).Name}");
    }

    /// <summary>
    /// Shuts down the running game and quits the application.
    /// </summary>
    public void Shutdown()
    {
		// Do Other Stuff

        GetTree().Quit();
    }
}
