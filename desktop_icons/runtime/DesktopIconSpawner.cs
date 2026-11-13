using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;


[GlobalClass]
public partial class DesktopIconSpawner : RefCounted
{
    [Signal]
    public delegate void MultipleIconsCreationProgressChangedEventHandler(float newPercentage);
    [Signal]
    public delegate void MultipleIconsCreationFinishedEventHandler();
    [Signal]
    public delegate void DesktopIconHiddenStateChangedEventHandler();

    /// <summary>
    /// The path to the user's desktop folder, used by windows for the current desktop icons
    /// </summary>
    private static string desktopPath => System.Environment.GetFolderPath(System.Environment.SpecialFolder.Desktop);


    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    private static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);

    private const int SHCNE_UPDATEITEM = 0x00002000;
    private const int SHCNE_UPDATEDIR = 0x00001000;
    private const uint SHCNF_PATHW = 0x0005;
    private const uint SHCNF_FLUSH = 0x1000;

    /// <summary>
    /// Creates a new icon on the desktop of the player.
    /// </summary>
    /// <param name="iconName">The name of the generated icon.</param>
    /// <param name="bonusScriptArguments">Arguments added the desktop icon.</param>
    public static void CreateDesktopIcon(string iconName, string bonusScriptArguments = "", string visualIconPath = "")
    {
        // only do this if this is running on windows
        if (!OperatingSystem.IsWindows())
        {
            GD.PrintErr("Desktop icons creation is only supported on windows.");
            return;
        }

        // get the path the generated desktop icon will be placed
        string iconPath = Path.Combine(desktopPath, iconName + ".lnk");
        // get the path to the godot game executable
        string gameExePath = OS.GetExecutablePath();
        // get the path to the folder that contains the .exe of this program 
        string exeDir = Path.GetDirectoryName(gameExePath);
        // refrence to the cmdline arguments that will be added to the desktop icon
        string scriptArguments;
        
        // get if this is running in a build version, or editor
        bool isEditor = Engine.IsEditorHint() || OS.HasFeature("editor");

        if (isEditor)
        {
            // get the path to the "res://" folder
            string resFolderPath = ProjectSettings.GlobalizePath("res://");
            // get the arguments added to the running of the desktop icon
            scriptArguments = $"--path \"{resFolderPath}\" --scene \"uid://bm4s1rhk1a26i\" {bonusScriptArguments}".Trim();
        }
        else
        {
            // if not running in the editor, only have the bonus script args
            scriptArguments = bonusScriptArguments.Trim();
        }
        
        // get the type of the powershell program
        Type shellType = Type.GetTypeFromProgID("WScript.Shell");
        // create a new powershell program
        dynamic shell = Activator.CreateInstance(shellType);
        // create a desktop shortcut
        dynamic shortcut = shell.CreateShortcut(iconPath);

        // set the directory the desktop shortcut is running from
        shortcut.WorkingDirectory = exeDir;
        // set the path of the desktop shortcut
        shortcut.TargetPath = gameExePath;
        // add the arguments of the shortcut
        shortcut.Arguments = scriptArguments;
        // add the icon to the desktop shortcut
        if (visualIconPath == ""){shortcut.IconLocation = gameExePath;} else {shortcut.IconLocation = visualIconPath;}
        // save the desktop icon
        shortcut.Save();
    }


    /// <summary>
    /// Deletes a desktop icon with the same name as <c>iconName</c>.
    /// </summary>
    /// <param name="iconName">The name the, to be deleted, desktop icon has.</param>
    public static void DeleteDesktopIcon(string iconName)
    {
        // get the path the generated desktop icon was placed
        string iconPath = Path.Combine(desktopPath, iconName + ".lnk");

        // if the file actually exists, delete it
        if (File.Exists(iconPath))
        {
            File.Delete(iconPath);
        }
    }


    /// <summary>
    /// quickly deletes multiple desktop icons which names match <c>iconNames</c> using multithreading
    /// </summary>
    /// <param name="iconNames">The names of desktop icons that should get removed</param>
    public static void DeleteMultipleIcons(Godot.Collections.Array<String> iconNames)
    {
        // only do this if this is running on windows
        if (!OperatingSystem.IsWindows())
        {
            GD.PrintErr("Desktop icons creation is only supported on windows.");
            return;
        }

        // multithread the removal of each given desktop icon
        Parallel.ForEach(iconNames, DeleteDesktopIcon);
    }


    /// <summary>
    /// Creates multiple icons given by <c>iconArguments</c> in a quick enviorenment (C# instead of GDScript).
    /// </summary>
    /// <param name="iconArguments">The arguments the generated shortcut should have with the name first and then the argument that fits that name.</param>
    public void CreateMultipleIcons(Godot.Collections.Dictionary<Resource, String> iconArguments)
    {
        // get refrences to the total icons there are to be made and how many are already made
        int total_icons = iconArguments.Count;

        // create the given icons in another thread, so the main game can keep running through icon creation
        Task.Run(() =>
        {
            // get the godot dictionary as a C# List
            List<KeyValuePair<Resource, string>> icons = iconArguments.ToList();

            // go through every icon, to create it
            for (int i = 0; i < icons.Count; i++)
            {
                // get the resource and bonus arguments 
                KeyValuePair<Resource, string> item = icons[i];
                Resource resource = item.Key;
                string bonusArguments = item.Value;

                // get the name of the icon
                string iconName = resource.Get("name").AsString();
                if (string.IsNullOrEmpty(iconName)) continue;

                // get the path to the visual icon
                string visualIconPath = resource.Get("visual_icon_path").AsString();

                // create the desktop icon
                CreateDesktopIcon(iconName, bonusArguments, visualIconPath);

                // update the signal indicating the amount of icons completed
                int completed_icons = i + 1;
                float progress = (float)completed_icons / total_icons * 100.0f;
                EmitSignal(SignalName.MultipleIconsCreationProgressChanged, progress);
            }
            EmitSignal(SignalName.MultipleIconsCreationFinished);
        });

    }


    /// <summary>
    /// Creates multiple icons given by <c>iconArguments</c> in parallel using multithreading in a quick enviorenment (C# instead of GDScript).
    /// </summary>
    /// <param name="iconArguments">The arguments the generated shortcut should have with the name first and then the argument that fits that name.</param>
    public void CreateMultipleIconsParallel(Godot.Collections.Dictionary<Resource, String> iconArguments)
    {
        // get refrences to the total icons there are to be made and how many are already made
        int total_icons = iconArguments.Count;
        int completed_icon_count = 0;

        // create the given icons in another thread, so the main game can keep running through icon creation
        Task.Run(() =>
        {
            // also run the creation in parallel to eachother, so that it is completed faster

            Parallel.ForEach(iconArguments, iconArgument =>
            {
                // check if the key is a valid key, and thus is allowed to be created
                if (iconArgument.Key.Get("name").AsString() == string.Empty)
                {
                    GD.PrintErr("Generating desktop icons requires a Resource with a 'name' parameter that can convert to a string.");
                    return;
                }

                // get the name of this desktop icon
                string iconName = iconArgument.Key.Get("name").AsString();

                // create the desktop icon
                CreateDesktopIcon(iconName, iconArgument.Value, iconArgument.Key.Get("visual_icon_path").AsString());

                // get the current percentage how many files are done
                int completed_icons = System.Threading.Interlocked.Increment(ref completed_icon_count);
                float progress = (float)completed_icons / total_icons * 100.0f;
                EmitSignal(SignalName.MultipleIconsCreationProgressChanged, progress);
            });
            
            EmitSignal(SignalName.MultipleIconsCreationFinished);
        });
    }


    /// <summary>
    /// sets all the currently displayed (or hidden) desktop icons to be displayed or hidden, depending on the value of <paramref name="hide"/>.
    /// </summary>
    /// <param name="hide">If the desktop icons should be hidden or shown when running this.</param>
    public async void SetUserIconHiddenState(bool hide)
    {
        // only do this if this is running on windows
        if (!OperatingSystem.IsWindows())
        {
            GD.PrintErr("Desktop icons creation is only supported on windows.");
            return;
        }

        // get the shared desktop
        string publicDesktop = System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonDesktopDirectory);

        // get all the items in the desktops folders and add it to an array
        string[] localItemPaths = Directory.GetFiles(desktopPath).Concat(Directory.GetDirectories(desktopPath)).ToArray();
        string[] sharedItemPaths = Directory.GetFiles(publicDesktop).Concat(Directory.GetDirectories(publicDesktop)).ToArray();
        string[] itemPaths = localItemPaths.Concat(sharedItemPaths).ToArray();

        await Task.Run(() =>
        {
            // go through each icons path multithreaded and set it's file attribute to be hidden
            Parallel.ForEach(itemPaths, path =>
            {
                try
                {
                    // get the attributes associated with the current file's path
                    FileAttributes attributes = File.GetAttributes(path);
                    // get if the file is currently hidden
                    bool isHidden = attributes.HasFlag(FileAttributes.Hidden);

                    // if the file isn't hidden, and it should, hide it
                    if (hide && !isHidden)
                    {
                        File.SetAttributes(path, attributes | FileAttributes.Hidden | FileAttributes.System);
                    }
                    // if it should be visible and isn't, show it again
                    else if (!hide && isHidden)
                    {
                        File.SetAttributes(path, attributes & ~FileAttributes.Hidden & ~FileAttributes.System);
                    }
                }
                catch
                {
                    GD.PrintErr($"Could for some silly reason not set file attributes of the file at path: {path}");
                }
            });
        });

        RefreshDesktopFolder();
        

        EmitSignal(SignalName.DesktopIconHiddenStateChanged);
    }


    public static void RefreshSingleIcon(string iconName)
    {
        string iconPath = Path.Combine(desktopPath, iconName + ".lnk");
        IntPtr ptr = Marshal.StringToHGlobalAuto(iconPath);
        // Tell Windows only this specific item changed, and flush the event queue
        SHChangeNotify(SHCNE_UPDATEITEM, SHCNF_PATHW | SHCNF_FLUSH, ptr, IntPtr.Zero);
        Marshal.FreeHGlobal(ptr);
    }

    public static void RefreshMultipleIcons(Godot.Collections.Array<string> iconNames)
    {
        foreach (string iconName in iconNames)
        {
            string iconPath = Path.Combine(desktopPath, iconName + ".lnk");
            IntPtr ptr = Marshal.StringToHGlobalAuto(iconPath);
            SHChangeNotify(SHCNE_UPDATEITEM, SHCNF_PATHW, ptr, IntPtr.Zero);
            Marshal.FreeHGlobal(ptr);
        }
        
        // Single flush at the end to force Explorer to render the queued updates
        SHChangeNotify(SHCNE_UPDATEITEM, SHCNF_FLUSH, IntPtr.Zero, IntPtr.Zero);
    }

    public static void RefreshDesktopFolder()
    {
        IntPtr ptr = Marshal.StringToHGlobalAuto(desktopPath);
        SHChangeNotify(SHCNE_UPDATEDIR, SHCNF_PATHW | SHCNF_FLUSH, ptr, IntPtr.Zero);
        Marshal.FreeHGlobal(ptr);
    }
}
