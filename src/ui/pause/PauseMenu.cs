using Godot;
using Scaffold.Core;
using Scaffold.Engine.Subsystems;

namespace Scaffold.UI;

/// <summary>
/// In-game pause menu, loaded on demand by <see cref="WorldBuilderSubsystem"/> when
/// gameplay starts and torn down again when returning to the main menu.
/// </summary>
public partial class PauseMenu : Control
{
	[Export]
	private Button ReturnToMenuButton { get; set; }

	[Export]
	private Button QuitButton { get; set; }

	/// <summary>
	/// Starts closed and wires up button press handlers.
	/// </summary>
	public override void _Ready()
	{
		SetPaused(false);

		ReturnToMenuButton.Pressed += OnReturnToMenuPressed;
		QuitButton.Pressed += OnQuitPressed;
	}

	/// <summary>
	/// Toggles the pause menu open/closed when the "toggle_pause" action is pressed.
	/// </summary>
	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed("toggle_pause"))
		{
			SetPaused(!Visible);
		}
	}

	/// <summary>
	/// Shows or hides the pause menu and pauses/unpauses the scene tree to match.
	/// </summary>
	private void SetPaused(bool paused)
	{
		Visible = paused;
		GetTree().Paused = paused;
	}

	/// <summary>
	/// Closes the pause menu and returns to the main menu via <see cref="WorldBuilderSubsystem.ReturnToMenu"/>,
	/// which tears down the current world and also frees this pause menu instance.
	/// </summary>
	private void OnReturnToMenuPressed()
	{
		SetPaused(false);
		Game.Instance.GetEngineSubsystem<WorldBuilderSubsystem>().ReturnToMenu();
	}

	/// <summary>
	/// Handles the Quit button press by shutting down the game.
	/// </summary>
	private void OnQuitPressed()
	{
		Game.Instance.Shutdown();
	}
}
