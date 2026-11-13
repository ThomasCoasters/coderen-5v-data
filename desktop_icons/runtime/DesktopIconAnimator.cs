using Godot;
using System;
using System.IO;
using System.Threading.Tasks;

[GlobalClass]
public partial class DesktopIconAnimator : Node
{
    private bool _isAnimating = false;
    private int _currentFrame = 0;

    public async void StartIconAnimation(string iconName, string bonusScriptArguments, string[] frameIconPaths, float timePerFrame)
    {
        // Prevent starting multiple concurrent loops if already running
        if (_isAnimating || !OperatingSystem.IsWindows() || frameIconPaths == null || frameIconPaths.Length == 0)
            return;

        _isAnimating = true;

        // Ensure the initial shortcut is created using DesktopIconSpawner
        DesktopIconSpawner.CreateDesktopIcon(iconName, bonusScriptArguments, frameIconPaths[0]);

        while (_isAnimating)
        {
            await ToSignal(GetTree().CreateTimer(timePerFrame), SceneTreeTimer.SignalName.Timeout);

            if (!_isAnimating) break;

            try
            {
                // Cycle to the next frame index
                _currentFrame = (_currentFrame + 1) % frameIconPaths.Length;

                // Update the shortcut frame using your spawner's built-in creation method
                DesktopIconSpawner.CreateDesktopIcon(iconName, bonusScriptArguments, frameIconPaths[_currentFrame]);
                DesktopIconSpawner.RefreshSingleIcon(iconName);
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