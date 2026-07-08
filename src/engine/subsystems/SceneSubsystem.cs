using Godot;
using Scaffold.Core;
using System;
using System.Collections.Generic;

namespace Scaffold.Engine.Subsystems;

/// <summary>
/// Central async scene loader. Supports any number of concurrent loads for different scene
/// paths (deduping repeated requests for the same path onto the same in-flight load), and
/// transparently loads/shows and unloads/hides a loading screen while any request wants one.
/// </summary>
public partial class SceneSubsystem : Subsystem
{
	private const string LoadingScenePath = "res://content/ui/loading.tscn";

	[Export]
	private CanvasLayer LoadingLayer { get; set; }

	[Export]
	private Node LoadingRoot { get; set; }

	private Node _loadingScreen;

	/// <summary>
	/// Fires whenever any requested scene finishes loading, regardless of caller.
	/// </summary>
	public event Action<string, Node> OnSceneLoaded;

	/// <summary>
	/// Fires whenever any requested scene fails to load, regardless of caller.
	/// </summary>
	public event Action<string> OnSceneLoadFailed;

	private class LoadRequest
	{
		public string ScenePath;
		public bool ShowLoadingScreen;
		public List<Action<Node>> OnLoaded = [];
		public List<Action> OnFailed = [];
	}

	private readonly Dictionary<string, LoadRequest> _activeLoads = [];

	/// <summary>
	/// Starts an async threaded load of the given scene. If the scene is already loading,
	/// the new hooks are attached to that in-progress load instead of starting a duplicate.
	/// Any number of different scenes can be loading at once.
	/// </summary>
	/// <param name="scene">Resource path of the scene to load.</param>
	/// <param name="showLoadingScreen">Whether this load should trigger the loading screen (see <see cref="UpdateLoadingScreen"/>).</param>
	/// <param name="onLoaded">Called with the instantiated scene once this load finishes.</param>
	/// <param name="onFailed">Called if this load fails.</param>
	public void Load(string scene, bool showLoadingScreen, Action<Node> onLoaded = null, Action onFailed = null)
	{
		if (_activeLoads.TryGetValue(scene, out LoadRequest inProgress))
		{
			if (onLoaded != null)
				inProgress.OnLoaded.Add(onLoaded);

			if (onFailed != null)
				inProgress.OnFailed.Add(onFailed);

			if (showLoadingScreen && !inProgress.ShowLoadingScreen)
			{
				inProgress.ShowLoadingScreen = true;
				UpdateLoadingScreen();
			}

			return;
		}

		var request = new LoadRequest { ScenePath = scene, ShowLoadingScreen = showLoadingScreen };

		if (onLoaded != null)
			request.OnLoaded.Add(onLoaded);

		if (onFailed != null)
			request.OnFailed.Add(onFailed);

		Error error = ResourceLoader.LoadThreadedRequest(scene);

		if (error != Error.Ok)
		{
			GD.PushError($"Failed to start loading Scene: {scene}");
			FailRequest(request);
			return;
		}

		_activeLoads[scene] = request;
		UpdateLoadingScreen();
	}

	/// <summary>
	/// Polls every in-progress threaded load's status each frame and finalizes or fails
	/// each one as it completes.
	/// </summary>
	/// <param name="delta">Elapsed time since the previous frame.</param>
	public override void _Process(double delta)
	{
		if (_activeLoads.Count == 0)
		{
			return;
		}

		// Snapshot first: finishing a load mutates _activeLoads mid-iteration.
		var requests = new List<LoadRequest>(_activeLoads.Values);

		foreach (LoadRequest request in requests)
		{
			var progress = new Godot.Collections.Array();

			ResourceLoader.ThreadLoadStatus status =
				ResourceLoader.LoadThreadedGetStatus(request.ScenePath, progress);

			if (status == ResourceLoader.ThreadLoadStatus.Loaded)
			{
				Finalize(request);
			}
			else if (status == ResourceLoader.ThreadLoadStatus.Failed)
			{
				GD.PushError($"Failed to load Scene: {request.ScenePath}");
				FailRequest(request);
			}
		}
	}

	/// <summary>
	/// Instantiates the finished scene and completes its load request.
	/// </summary>
	private void Finalize(LoadRequest request)
	{
		if (ResourceLoader.LoadThreadedGet(request.ScenePath) is not PackedScene packedScene)
		{
			GD.PushError($"Loaded Scene was not a PackedScene: {request.ScenePath}");
			FailRequest(request);
			return;
		}

		Node scene = packedScene.Instantiate();

		_activeLoads.Remove(request.ScenePath);
		UpdateLoadingScreen();

		OnSceneLoaded?.Invoke(request.ScenePath, scene);

		foreach (Action<Node> onLoaded in request.OnLoaded)
			onLoaded(scene);
	}

	/// <summary>
	/// Removes the request and notifies its failure hooks.
	/// </summary>
	private void FailRequest(LoadRequest request)
	{
		_activeLoads.Remove(request.ScenePath);
		UpdateLoadingScreen();

		OnSceneLoadFailed?.Invoke(request.ScenePath);

		foreach (Action onFailed in request.OnFailed)
			onFailed();
	}

	/// <summary>
	/// Loads and shows the loading screen while any active load wants it, and unloads it
	/// again once none do, rather than keeping it resident for the whole game. It's loaded
	/// synchronously since it's small and needs to appear the instant it's needed.
	/// </summary>
	private void UpdateLoadingScreen()
	{
		bool shouldShow = false;

		foreach (LoadRequest request in _activeLoads.Values)
		{
			if (request.ShowLoadingScreen)
			{
				shouldShow = true;
				break;
			}
		}

		if (shouldShow && _loadingScreen == null)
		{
			_loadingScreen = ResourceLoader.Load<PackedScene>(LoadingScenePath).Instantiate();
			LoadingRoot.AddChild(_loadingScreen);
		}
		else if (!shouldShow && _loadingScreen != null)
		{
			_loadingScreen.QueueFree();
			_loadingScreen = null;
		}

		LoadingLayer.Visible = shouldShow;
	}

	/// <summary>
	/// Whether any scene load is currently in progress.
	/// </summary>
	public bool IsLoading()
	{
		return _activeLoads.Count > 0;
	}

	/// <summary>
	/// Whether the given scene is currently loading.
	/// </summary>
	public bool IsLoading(string scene)
	{
		return _activeLoads.ContainsKey(scene);
	}

	/// <summary>
	/// The number of scene loads currently in progress.
	/// </summary>
	public int GetActiveLoadCount()
	{
		return _activeLoads.Count;
	}
}
