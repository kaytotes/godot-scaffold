using Godot;

namespace Scaffold.Core;

/// <summary>
/// Marker base class for subsystems mounted under Game/EngineSubsystems, discoverable
/// via <see cref="Game.GetEngineSubsystem{T}"/>.
/// </summary>
public partial class Subsystem : Node
{
}
