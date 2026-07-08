using Godot;
using Scaffold.Core;
using Scaffold.Engine.Subsystems;

namespace Scaffold.UI;

/// <summary>
/// F5-toggled debug overlay, loaded on startup by <see cref="Game"/> into
/// Interface/DebugLayer/DebugRoot. Only processes (updating its labels) while visible.
/// </summary>
public partial class DebugOverlay : Control
{
	[Export]
	private Label PerformanceLabel { get; set; }

	[Export]
	private Label GameStateLabel { get; set; }

	[Export]
	private Label BuildLabel { get; set; }

	/// <summary>
	/// Starts hidden and not processing until toggled on, and writes the static build info text.
	/// </summary>
	public override void _Ready()
	{
		SetOverlayVisible(false);

		// Must stay fully qualified: this file's namespace is Scaffold.UI, which sits under
		// Scaffold alongside Scaffold.Engine - an unqualified "Engine" resolves to that
		// namespace instead of Godot's Engine class and fails to compile.
		string godotVersion = (string)Godot.Engine.GetVersionInfo()["string"];
		string gameVersion = (string)ProjectSettings.GetSetting("application/config/version", "0.0.0");
		BuildLabel.Text = $"Game {gameVersion}\nGodot {godotVersion}";
	}

	/// <summary>
	/// Toggles the overlay on and off when the "toggle_debug" action is pressed.
	/// </summary>
	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed("toggle_debug"))
		{
			SetOverlayVisible(!Visible);
		}
	}

	/// <summary>
	/// Shows or hides the overlay, only processing (updating the stats blocks) while visible.
	/// </summary>
	private void SetOverlayVisible(bool visible)
	{
		Visible = visible;
		SetProcess(visible);
	}

	/// <summary>
	/// Refreshes the engine performance and game state blocks. Only runs while the overlay is visible.
	/// </summary>
	public override void _Process(double delta)
	{
		double fps = Godot.Engine.GetFramesPerSecond();
		double memoryMb = Performance.GetMonitor(Performance.Monitor.MemoryStatic) / (1024.0 * 1024.0);
		double cpuMs = Performance.GetMonitor(Performance.Monitor.TimeProcess) * 1000.0;
		double vramMb = Performance.GetMonitor(Performance.Monitor.RenderVideoMemUsed) / (1024.0 * 1024.0);

		PerformanceLabel.Text =
			$"FPS: {fps:F0}\n" +
			$"Memory: {memoryMb:F1} MB\n" +
			$"CPU: {cpuMs:F1} ms\n" +
			$"VRAM: {vramMb:F1} MB";

		double nodeCount = Performance.GetMonitor(Performance.Monitor.ObjectNodeCount);
		WorldInstance world = Game.Instance.GetWorld();
		int entityCount = world.GetEntities().GetChildCount();
		int effectCount = world.GetEffects().GetChildCount();
		int activeLoads = Game.Instance.GetEngineSubsystem<SceneSubsystem>().GetActiveLoadCount();

		GameStateLabel.Text =
			$"Nodes: {nodeCount:F0}\n" +
			$"Entities: {entityCount}\n" +
			$"Effects: {effectCount}\n" +
			$"Active Loads: {activeLoads}";
	}
}
