using Godot;
using System;
using System.IO;
using System.Threading.Tasks;

[GlobalClass]
public partial class DesktopIconAnimator : Node
{
    private bool _isAnimating = false;
    private int _currentFrame = 0;

    /// <summary>
    /// Starts an asynchronous loop that updates the desktop shortcut's icon at ~2 FPS (every 500ms)
    /// using DesktopIconSpawner for creation and frame updates.
    /// </summary>
    public async void StartIconAnimation(string iconName, string bonusScriptArguments, string[] frameIconPaths)
    {
        // Prevent starting multiple concurrent loops if already running
        if (_isAnimating || !OperatingSystem.IsWindows() || frameIconPaths == null || frameIconPaths.Length == 0)
            return;

        _isAnimating = true;

        // Ensure the initial shortcut is created using DesktopIconSpawner
        DesktopIconSpawner.CreateDesktopIcon(iconName, bonusScriptArguments, frameIconPaths[0]);

        while (_isAnimating)
        {
            // Wait 500ms for 2 FPS
            await ToSignal(GetTree().CreateTimer(0.5f), SceneTreeTimer.SignalName.Timeout);

            if (!_isAnimating) break;

            try
            {
                // Cycle to the next frame index
                _currentFrame = (_currentFrame + 1) % frameIconPaths.Length;

                // Update the shortcut frame using your spawner's built-in creation method
                DesktopIconSpawner.CreateDesktopIcon(iconName, bonusScriptArguments, frameIconPaths[_currentFrame]);
                GD.Print(frameIconPaths[_currentFrame]);
            }
            catch (Exception)
            {
                // Catch potential file-lock exceptions if Windows Explorer is reading the .lnk file simultaneously
            }
        }
    }

    /// <summary>
    /// Stops the animation loop and deletes the shortcut from the desktop.
    /// </summary>
    /// <param name="iconName">The name of the shortcut to delete.</param>
    public void StopAndCleanupAnimation(string iconName)
    {
        _isAnimating = false;
        DesktopIconSpawner.DeleteDesktopIcon(iconName);
    }

    public void StopAnimation()
    {
        _isAnimating = false;
    }
}