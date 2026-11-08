using Godot;
using System;
using System.Runtime.InteropServices;

[GlobalClass]
public partial class TransparentWindowComponent : Node {

    [DllImport("user32.dll", EntryPoint = "GetWindowLong")]
    private static extern int GetWindowLong32(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")]
    private static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint = "SetWindowLong")]
    private static extern int SetWindowLong32(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtr")]
    private static extern IntPtr SetWindowLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int CX, int CY, uint uFlags);

    private const int GwlExStyle = -20;
    private const int WsExLayered = 0x80000;
    private const int WsExTransparent = 0x20; 

    private const uint SwpNomove = 0x0002;
    private const uint SwpNosize = 0x0001;
    private const uint SwpNozorder = 0x0004;
    private const uint SwpFramechanged = 0x0020;

    private IntPtr _hWnd;

    public void InitializeForWindow(Window targetWindow)
    {
        if (targetWindow == null)
        {
            GD.PrintErr("TransparentWindowComponent received a null window!");
            return;
        }

        int windowId = targetWindow.GetWindowId();
        _hWnd = (IntPtr)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle, windowId);
        
        targetWindow.TransparentBg = true;

        SetClickThrough(true);
    }

    public void SetClickThrough(bool clickthrough)
    {
        if (_hWnd == IntPtr.Zero) return;

        int exStyle = System.Environment.Is64BitProcess 
            ? (int)GetWindowLongPtr64(_hWnd, GwlExStyle) 
            : GetWindowLong32(_hWnd, GwlExStyle);

        if (clickthrough)
        {
            exStyle |= WsExLayered | WsExTransparent;
        }
        else
        {
            exStyle &= ~WsExTransparent;
            exStyle |= WsExLayered;
        }

        if (System.Environment.Is64BitProcess)
            SetWindowLongPtr64(_hWnd, GwlExStyle, (IntPtr)exStyle);
        else
            SetWindowLong32(_hWnd, GwlExStyle, exStyle);

        SetWindowPos(_hWnd, IntPtr.Zero, 0, 0, 0, 0, SwpNomove | SwpNosize | SwpNozorder | SwpFramechanged);
    }
}