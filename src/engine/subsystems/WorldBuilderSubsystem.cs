using Godot;
using Scaffold.Core;
using System.Threading.Tasks;

namespace Scaffold.Engine.Subsystems;

/// <summary>
/// Owns the gameplay session lifecycle: builds a level into <see cref="WorldInstance"/>,
/// toggles the main menu, and loads/tears down the pause menu to match.
/// </summary>
public partial class WorldBuilderSubsystem : Subsystem
{
	private const string PauseMenuScenePath = "res://content/ui/pause_menu.tscn";

	[Export]
	private WorldInstance World { get; set; }

	[Export]
	private CanvasLayer MenuLayer { get; set; }

	[Export]
	private Node PauseRoot { get; set; }

	[Export]
	private SceneSubsystem SceneSubsystem { get; set; }

	private bool _isBuilding;
	private Node _pauseMenu;

	/// <summary>
	/// Clears the current world, loads the pause menu (on the first call only), and loads
	/// the given level scene into the world via <see cref="SceneSubsystem"/>, hiding the
	/// menu layer while it loads.
	/// </summary>
	/// <param name="scene">Resource path of the level scene to load.</param>
	/// <param name="saveSlot">Save slot to build from. Currently unused.</param>
	public async void Build(string scene, int saveSlot = 0)
	{
		if (_isBuilding)
		{
			GD.PushWarning($"Already loading World: {scene}");
			return;
		}

		_isBuilding = true;

		MenuLayer.Visible = false;

		await Clear();

		LoadPauseMenu();

		SceneSubsystem.Load(scene, showLoadingScreen: true, onLoaded: OnWorldLoaded);
	}

	/// <summary>
	/// Clears the current world, tears down the pause menu, and shows the main menu again.
	/// </summary>
	public async void ReturnToMenu()
	{
		await Clear();

		MenuLayer.Visible = true;

		_pauseMenu?.QueueFree();
		_pauseMenu = null;
	}

	/// <summary>
	/// Loads the pause menu the first time gameplay starts. It's reused across subsequent
	/// level loads and only torn down in <see cref="ReturnToMenu"/>.
	/// </summary>
	private void LoadPauseMenu()
	{
		if (_pauseMenu != null)
		{
			return;
		}

		SceneSubsystem.Load(PauseMenuScenePath, showLoadingScreen: false, onLoaded: pause =>
		{
			_pauseMenu = pause;
			PauseRoot.AddChild(pause);
		});
	}

	/// <summary>
	/// Parents the loaded level under the world, initializes the world once it's in the
	/// tree, and clears the <see cref="Build"/> in-progress guard.
	/// </summary>
	/// <param name="level">The instantiated level scene.</param>
	private async void OnWorldLoaded(Node level)
	{
		World.GetLevel().AddChild(level);

		await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

		World.Initialize();

		_isBuilding = false;
	}

	/// <summary>
	/// Queues all effects, entities, and level children for removal and waits a frame
	/// for them to be freed.
	/// </summary>
	private async Task Clear()
	{
		ClearChildren(World.GetEffects());
		ClearChildren(World.GetEntities());
		ClearChildren(World.GetLevel());

		await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
	}

	/// <summary>
	/// Queues every direct child of <paramref name="root"/> for removal.
	/// </summary>
	private void ClearChildren(Node root)
	{
		foreach (Node child in root.GetChildren())
		{
			child.QueueFree();
		}
	}
}
