using System;
using System.Runtime.InteropServices;
using Godot; 


[GlobalClass]
public partial class DesktopIconCalculator: RefCounted
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    // the Listview binairy value to get the item spacing (icon spacing)
    private const uint LVM_GETITEMSPACING = 0x1033;

    /// <summary>
    /// Gets the current grid size in pixels
    /// </summary>
    public static Vector2I GetGridSize()
    {
        IntPtr progman = FindWindow("Progman", null);
        IntPtr shellDllDefView = FindWindowEx(progman, IntPtr.Zero, "SHELLDLL_DefView", null);

        if (shellDllDefView == IntPtr.Zero)
        {
            IntPtr workerW = IntPtr.Zero;
            while ((workerW = FindWindowEx(IntPtr.Zero, workerW, "WorkerW", null)) != IntPtr.Zero)
            {
                shellDllDefView = FindWindowEx(workerW, IntPtr.Zero, "SHELLDLL_DefView", null);
                if (shellDllDefView != IntPtr.Zero) break;
            }
        }

        IntPtr sysListView32 = FindWindowEx(shellDllDefView, IntPtr.Zero, "SysListView32", null);
        if (sysListView32 == IntPtr.Zero)
        {
            return new Vector2I (10, 10);
        }

        IntPtr result = SendMessage(sysListView32, LVM_GETITEMSPACING, IntPtr.Zero, IntPtr.Zero);
        int packedSpacing = result.ToInt32();

        int iconWidth = packedSpacing & 0xFFFF;
        int iconHeight = (packedSpacing >> 16) & 0xFFFF;

        if (iconWidth <= 0) iconWidth = 10;
        if (iconHeight <= 0) iconHeight = 10;

        return new Vector2I (iconWidth, iconHeight);
    }

    /// <summary>
    /// Calculates max icons based on real-time screen bounds and icon sizing.
    /// </summary>
    public static Vector2I GetMaxDesktopIcons(Vector2I screenSize)
    {
        Vector2I iconSize = GetGridSize();

        return new Vector2I(screenSize.X / iconSize.X, screenSize.Y / iconSize.Y);
    }
}