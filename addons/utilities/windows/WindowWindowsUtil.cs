using Godot;
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

[GlobalClass]
public partial class WindowWindowsUtil : RefCounted
{

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);
    [DllImport("user32.dll")]
    private static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")]
    private static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll", EntryPoint = "GetWindowLong")]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("dwmapi.dll")]
    private static extern int DwmGetWindowAttribute(IntPtr hwnd, int dwAttribute, out int pvAttribute, int cbAttribute);

    private const int SM_XVIRTUALSCREEN = 76;
    private const int SM_YVIRTUALSCREEN = 77;
    private const int SM_CXVIRTUALSCREEN = 78;
    private const int SM_CYVIRTUALSCREEN = 79;

    private const uint GW_OWNER = 4;
    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TOOLWINDOW = 0x00000080;
    private const int DWMWA_CLOAKED = 14;

    
    /// <summary>
    /// A struct that represents the values of a window
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;

        public int Width => Right - Left;
        public int Height => Bottom - Top;
    }

    /// <summary>
    /// Gets the positions of all the currently opened windows
    /// </summary>
    /// <returns>A dictionary with the window's titles and their respective RECT</returns>
    public static Godot.Collections.Dictionary<string, Rect2I> GetOpenWindowPositions()
    {
        var result = new Godot.Collections.Dictionary<string, Rect2I>();

        if (!OperatingSystem.IsWindows())
        {
            GD.PrintErr("Getting window positions is only supported on Windows.");
            return result;
        }

        int vLeft = GetSystemMetrics(SM_XVIRTUALSCREEN);
        int vTop = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int vRight = vLeft + GetSystemMetrics(SM_CXVIRTUALSCREEN);
        int vBottom = vTop + GetSystemMetrics(SM_CYVIRTUALSCREEN);

        EnumWindows((hWnd, lParam) =>
        {
            if (IsWindowVisible(hWnd))
            {
                if (!IsWindowVisible(hWnd)) return true;

                int exStyle = System.Environment.Is64BitProcess 
                    ? (int)GetWindowLongPtr(hWnd, GWL_EXSTYLE) 
                    : GetWindowLong(hWnd, GWL_EXSTYLE);
                if ((exStyle & WS_EX_TOOLWINDOW) != 0) return true;

                if (GetWindow(hWnd, GW_OWNER) != IntPtr.Zero) return true;

                int cloaked = 0;
                if (DwmGetWindowAttribute(hWnd, DWMWA_CLOAKED, out cloaked, sizeof(int)) == 0 && cloaked != 0)
                    return true;
                
                
                StringBuilder sb = new StringBuilder(256);
                GetWindowText(hWnd, sb, sb.Capacity);
                string title = sb.ToString();

                if (!string.IsNullOrWhiteSpace(title))
                {
                    GetWindowRect(hWnd, out RECT rect);

                    bool isWithinScreen = rect.Left > -30000 && rect.Width > 0 && rect.Height > 0 &&
                                          rect.Right > vLeft && rect.Left < vRight &&
                                          rect.Bottom > vTop && rect.Top < vBottom;

                    if (isWithinScreen)
                    {
                        Rect2I outputRect = new Rect2I(
                            rect.Left,
                            rect.Top,
                            rect.Width,
                            rect.Height
                        );

                        string uniqueKey = title;
                        int counter = 1;
                        while (result.ContainsKey(uniqueKey))
                        {
                            uniqueKey = $"{title} ({counter++})";
                        }

                        result.Add(uniqueKey, outputRect);
                    }
                }
            }
            return true;
        }, IntPtr.Zero);

        return result;
    }
}
