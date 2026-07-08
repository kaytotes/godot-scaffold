using Godot;

namespace Scaffold.Core;

/// <summary>
/// Base class for subsystems scoped to the current <see cref="WorldInstance"/>, expected
/// to live under World/WorldSubsystems. Does nothing until the world has been initialized.
/// </summary>
public partial class WorldSubsystem : Subsystem
{
	protected WorldInstance World { get; private set; }

	/// <summary>
	/// Whether the world has finished initializing and this subsystem is up and running.
	/// </summary>
	public bool IsActive { get; private set; }

	/// <summary>
	/// Gets the owning <see cref="WorldInstance"/> and subscribes to its initialization.
	/// </summary>
	public override void _Ready()
	{
		base._Ready();

		World = GetNode<WorldInstance>("../..");
		World.OnWorldInitialized += HandleWorldInitialized;
	}

	/// <summary>
	/// Marks this subsystem active before running its own initialization logic.
	/// </summary>
	private void HandleWorldInitialized()
	{
		IsActive = true;
		OnWorldInitialized();
	}

	/// <summary>
	/// Called each time the world finishes initializing. Override to do the subsystem's
	/// actual work; nothing should happen before this is called.
	/// </summary>
	protected virtual void OnWorldInitialized()
	{
	}
}
