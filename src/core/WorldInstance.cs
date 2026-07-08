using Godot;
using System;

namespace Scaffold.Core;

/// <summary>
/// The active game world: hosts the loaded level, spawned entities/effects, and world
/// subsystems, and fires <see cref="OnWorldInitialized"/> once a level has finished loading.
/// </summary>
public partial class WorldInstance : Node3D
{
    private Node3D _levelRoot;
    private Node3D _entityRoot;
    private Node3D _effectRoot;

    /// <summary>
    /// Fires each time the world finishes initializing (i.e. whenever the player enters
    /// a world). <see cref="WorldSubsystem"/>s should not do anything before this fires.
    /// </summary>
    public event Action OnWorldInitialized;

    /// <summary>
    /// Signals that post-load setup can run, by firing <see cref="OnWorldInitialized"/>.
    /// Call once a level has been added under <see cref="GetLevel"/>.
    /// </summary>
    public void Initialize()
    {
        OnWorldInitialized?.Invoke();
    }

    /// <summary>
    /// Gets the root node that loaded level scenes are parented under, caching the lookup.
    /// </summary>
    public Node3D GetLevel()
    {
        _levelRoot ??= GetNode<Node3D>("LevelRoot");
        return _levelRoot;
    }

    /// <summary>
    /// Gets the root node that entities are parented under, caching the lookup.
    /// </summary>
    public Node3D GetEntities()
    {
        _entityRoot ??= GetNode<Node3D>("EntityRoot");
        return _entityRoot;
    }

    /// <summary>
    /// Gets the root node that effects are parented under, caching the lookup.
    /// </summary>
    public Node3D GetEffects()
    {
        _effectRoot ??= GetNode<Node3D>("EffectRoot");
        return _effectRoot;
    }
}