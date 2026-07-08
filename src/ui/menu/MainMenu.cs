using Godot;
using Scaffold.Core;
using Scaffold.Engine.Subsystems;

namespace Scaffold.UI;

/// <summary>
/// Main menu UI, loaded on startup by <see cref="Game"/> into Interface/MenuLayer/MenuRoot.
/// </summary>
public partial class MainMenu : Control
{
	// Placeholder level for Play; swap for a real level-select flow later.
	private const string TestbedSceneUid = "uid://d1rkx522hrguc";

	[Export]
	private Button PlayButton { get; set; }

	[Export]
	private Button QuitButton { get; set; }

	/// <summary>
	/// Wires up button press handlers.
	/// </summary>
	public override void _Ready()
	{
		PlayButton.Pressed += OnPlayPressed;
		QuitButton.Pressed += OnQuitPressed;
	}

	/// <summary>
	/// Handles the Play button press by building the testbed level.
	/// </summary>
	private void OnPlayPressed()
	{
		Game.Instance.GetEngineSubsystem<WorldBuilderSubsystem>().Build(TestbedSceneUid);
	}

	/// <summary>
	/// Handles the Quit button press by shutting down the game.
	/// </summary>
	private void OnQuitPressed()
	{
		Game.Instance.Shutdown();
	}
}
