using Godot;
using Scaffold.Core;

namespace Scaffold.World.Subsystems;

/// <summary>
/// Minimal example of a <see cref="WorldSubsystem"/> - use as a template for new ones.
/// </summary>
public partial class ExampleSubsystem : WorldSubsystem
{
	/// <summary>
	/// Prints a greeting once the player has entered the world.
	/// </summary>
	protected override void OnWorldInitialized()
	{
		GD.Print("Hello World!");
	}
}
